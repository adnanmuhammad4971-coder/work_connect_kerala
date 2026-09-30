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
  const { language, service } = req.query;

  const serviceText = service && service !== 'All Services'
    ? service
    : 'cleaning, construction, coconut climbing, event workers, general labour';

  const twiml = language === 'Malayalam'
    ? `<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Say voice="alice" language="en-IN">
    Namaskaram. Work Connect Kerala il ninnum vilikkunnath.
    Kerala vil ${serviceText} thudangiya services
    labhyamakkunna oru workforce service aanu njangalude.
    Thangalku ethenkilum worker service aavashyamundo?
    Engalude team uyarne bandhapedunnathaanu. Nanni.
  </Say>
  <Pause length="2"/>
  <Hangup/>
</Response>`
    : `<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Say voice="alice">
    Hello! This is Work Connect Kerala calling.
    We provide skilled workers for ${serviceText}
    and many more services across all districts of Kerala.
    Do you currently need any worker service?
    Our team will contact you shortly. Thank you.
  </Say>
  <Pause length="2"/>
  <Hangup/>
</Response>`;

  res.type('text/xml');
  res.send(twiml);
});

// ─── Make AI Call ────────────────────────────────────────────────────
app.post('/make-call', async (req, res) => {
  const { toNumber, language, service } = req.body;

  if (!toNumber) {
    return res.status(400).json({ error: 'Phone number required' });
  }

  try {
    const formattedNumber = toNumber.startsWith('+') ? toNumber : `+91${toNumber}`;
    
    // Construct URL for TwiML endpoint (using the host from the request)
    const protocol = req.headers['x-forwarded-proto'] || req.protocol;
    const host = req.get('host');
    const twimlUrl = `${protocol}://${host}/twiml?language=${encodeURIComponent(language || '')}&service=${encodeURIComponent(service || '')}`;

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

// ─── Start Server ────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Work Connect Kerala AI Call Server running on port ${PORT}`);
});
