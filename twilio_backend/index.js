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

// ─── Make AI Call ────────────────────────────────────────────────────
app.post('/make-call', async (req, res) => {
  const { toNumber, language, service } = req.body;

  if (!toNumber) {
    return res.status(400).json({ error: 'Phone number required' });
  }

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

  try {
    const formattedNumber = toNumber.startsWith('+') ? toNumber : `+91${toNumber}`;

    const call = await client.calls.create({
      to: formattedNumber,
      from: TWILIO_FROM_NUMBER,
      twiml: twiml,
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
