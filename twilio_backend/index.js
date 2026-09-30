const express = require('express');
const cors = require('cors');
const twilio = require('twilio');

const app = express();
app.use(express.json());
app.use(cors()); // Allow all origins (Flutter Web)

// ─── Twilio Setup ────────────────────────────────────────────────────
const TWILIO_ACCOUNT_SID = process.env.TWILIO_ACCOUNT_SID;
const TWILIO_AUTH_TOKEN  = process.env.TWILIO_AUTH_TOKEN;
const TWILIO_FROM_NUMBER = process.env.TWILIO_FROM_NUMBER || '+17372508034';

const client = twilio(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN);

// ─── Health Check ────────────────────────────────────────────────────
app.get('/', (req, res) => {
  res.json({ status: 'ok', service: 'Work Connect Kerala - AI Call Backend' });
});

// ─── TwiML Generator Route (Required for Twilio Trial Accounts) ──────
app.post('/twiml', (req, res) => {
  const { language, service, callId } = req.query;
  const script = req.body.script;

  const serviceText = service && service !== 'All Services'
    ? service
    : 'cleaning, construction, coconut climbing, event workers, general labour';

  const defaultMalayalam = `Namaskaram. Work Connect Kerala il ninnum vilikkunnath.
Kerala vil ${serviceText} thudangiya services
labhyamakkunna oru workforce service aanu njangalude.
Thangalku ethenkilum worker service aavashyamundo?`;

  const defaultEnglish = `Hello! This is Work Connect Kerala calling.
We provide skilled workers for ${serviceText}
and many more services across all districts of Kerala.
Do you currently need any worker service?`;

  const speechText = script || (language === 'Malayalam' ? defaultMalayalam : defaultEnglish);
  const voiceLang = language === 'Malayalam' ? 'en-IN' : 'en-US';

  const twiml = `<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Gather input="speech" action="/gather?callId=${encodeURIComponent(callId || '')}" speechTimeout="auto" language="en-IN">
    <Say voice="alice" language="${voiceLang}">${speechText}</Say>
  </Gather>
  <Say voice="alice">Thank you, we will contact you. Goodbye.</Say>
  <Pause length="1"/>
  <Hangup/>
</Response>`;

  res.type('text/xml');
  res.send(twiml);
});

// ─── Gather Speech Webhook ───────────────────────────────────────────
app.post('/gather', async (req, res) => {
  const { callId } = req.query;
  const { SpeechResult } = req.body;
  
  if (callId && SpeechResult) {
    try {
      // Use Firebase REST API to update the document (Allowed by our new rules for unauthenticated users)
      const firestoreUrl = `https://firestore.googleapis.com/v1/projects/jazeera-733f3/databases/(default)/documents/ai_calls/${callId}?updateMask.fieldPaths=customerResponse`;
      
      await fetch(firestoreUrl, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fields: {
            customerResponse: { stringValue: SpeechResult }
          }
        })
      });
      console.log(`✅ Saved customer response for ${callId}: ${SpeechResult}`);
    } catch (error) {
      console.error('❌ Failed to update Firestore:', error.message);
    }
  }

  // Acknowledge after gathering
  res.type('text/xml');
  res.send(`<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Say voice="alice">Thank you, our team will review your response and contact you soon. Goodbye.</Say>
  <Hangup/>
</Response>`);
});

// ─── Make AI Call ────────────────────────────────────────────────────
app.post('/make-call', async (req, res) => {
  const { toNumber, language, service, callId, script } = req.body;

  if (!toNumber) {
    return res.status(400).json({ error: 'Phone number required' });
  }

  try {
    const formattedNumber = toNumber.startsWith('+') ? toNumber : `+91${toNumber}`;
    
    // Construct URL for TwiML endpoint (using the host from the request)
    const protocol = req.headers['x-forwarded-proto'] || req.protocol;
    const host = req.get('host');
    const twimlUrl = `${protocol}://${host}/twiml?language=${encodeURIComponent(language || '')}&service=${encodeURIComponent(service || '')}&callId=${encodeURIComponent(callId || '')}`;

    const call = await client.calls.create({
      to: formattedNumber,
      from: TWILIO_FROM_NUMBER,
      url: twimlUrl,
    });

    console.log(`✅ Call initiated: ${call.sid} → ${formattedNumber}`);
    res.json({ success: true, sid: call.sid, status: call.status });

  } catch (error) {
    console.error('❌ Twilio error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// ─── WhatsApp AI Voice Message ───────────────────────────────────────
const googleTTS = require('google-tts-api');
const axios = require('axios');

app.post('/send-whatsapp-voice', async (req, res) => {
  const { toNumber, script, language, callId } = req.body;

  if (!toNumber) return res.status(400).json({ error: 'Phone number required' });
  if (!script) return res.status(400).json({ error: 'Script required for WhatsApp Voice' });

  try {
    const formattedNumber = toNumber.startsWith('+') ? toNumber.substring(1) : (toNumber.startsWith('91') ? toNumber : `91${toNumber}`);
    
    // Generate Audio URLs using google-tts-api for long text
    const langCode = language === 'Malayalam' ? 'ml' : 'en';
    const urls = googleTTS.getAllAudioUrls(script, {
      lang: langCode,
      slow: false,
      host: 'https://translate.google.com',
      splitPunct: ',.?',
    });

    const WA_TOKEN = process.env.WHATSAPP_TOKEN;
    const WA_PHONE_ID = process.env.WHATSAPP_PHONE_ID;

    if (!WA_TOKEN || !WA_PHONE_ID) {
      // Return success with a warning if not configured yet so frontend can test
      console.log(`⚠️ WhatsApp Voice generated but not sent. URL count: ${urls.length}`);
      return res.json({ 
        success: true, 
        audioUrl: urls.length > 0 ? urls[0].url : '',
        warning: 'WhatsApp API credentials missing. Showing audio preview only.' 
      });
    }

    // Send via WhatsApp Cloud API
    const messageIds = [];
    for (const item of urls) {
      const waResponse = await axios.post(
        `https://graph.facebook.com/v17.0/${WA_PHONE_ID}/messages`,
        {
          messaging_product: 'whatsapp',
          to: formattedNumber,
          type: 'audio',
          audio: { link: item.url }
        },
        { headers: { Authorization: `Bearer ${WA_TOKEN}` } }
      );
      messageIds.push(waResponse.data.messages[0].id);
    }

    console.log(`✅ WhatsApp Voice sent to ${formattedNumber} (${urls.length} parts)`);
    res.json({ success: true, messageId: messageIds[0], audioUrl: urls[0].url });
  } catch (error) {
    console.error('❌ WhatsApp error:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// ─── Start Server ────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Work Connect Kerala AI Call Server running on port ${PORT}`);
});
