const functions = require("firebase-functions");
const admin = require("firebase-admin");
const twilio = require("twilio");

admin.initializeApp();

// ─── Twilio Credentials (stored securely in Firebase environment) ───
const TWILIO_ACCOUNT_SID = "";
const TWILIO_AUTH_TOKEN = "";
const TWILIO_FROM_NUMBER = "+17372508034";

const client = twilio(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN);

// ─── Make AI Call ────────────────────────────────────────────────────
exports.makeAiCall = functions.https.onCall(async (data, context) => {
  const { toNumber, callId, language, service } = data;

  if (!toNumber) {
    throw new functions.https.HttpsError("invalid-argument", "Phone number required");
  }

  const serviceText = service && service !== "All Services"
    ? service
    : "cleaning, construction, coconut climbing, event workers, general labour";

  // Build TwiML based on language
  const twiml = language === "Malayalam"
    ? `<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Say voice="Polly.Aditi" language="hi-IN">
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
  <Say voice="Polly.Joanna">
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
    const formattedNumber = toNumber.startsWith("+") ? toNumber : `+91${toNumber}`;

    const call = await client.calls.create({
      to: formattedNumber,
      from: TWILIO_FROM_NUMBER,
      twiml: twiml,
      record: true,
    });

    // Update Firestore with call SID and status
    if (callId) {
      await admin.firestore().collection("ai_calls").doc(callId).update({
        twilioSid: call.sid,
        status: "calling",
      });
    }

    return { success: true, sid: call.sid, status: call.status };
  } catch (error) {
    console.error("Twilio call error:", error);
    if (callId) {
      await admin.firestore().collection("ai_calls").doc(callId).update({
        status: "failed",
      });
    }
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// ─── Twilio Status Callback ──────────────────────────────────────────
exports.twilioStatusCallback = functions.https.onRequest(async (req, res) => {
  const { CallSid, CallStatus, CallDuration, RecordingUrl } = req.body;

  try {
    // Find call record by Twilio SID
    const snap = await admin.firestore()
      .collection("ai_calls")
      .where("twilioSid", "==", CallSid)
      .limit(1)
      .get();

    if (!snap.empty) {
      const updates = {
        status: CallStatus === "completed" ? "completed" : CallStatus,
        callDuration: CallDuration || "0",
      };
      if (RecordingUrl) updates.recordingUrl = RecordingUrl;

      await snap.docs[0].ref.update(updates);
    }
  } catch (error) {
    console.error("Status callback error:", error);
  }

  res.sendStatus(200);
});
