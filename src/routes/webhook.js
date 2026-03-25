const express = require('express');
const crypto = require('crypto');
const router = express.Router();
const { broadcast } = require('../ws');
const { saveMessage, saveStatus } = require('../db');

// ── Webhook signature verification ────────────────────
function verifyWebhookSignature(rawBody, signatureHeader) {
  const appSecret = process.env.WHATSAPP_APP_SECRET;
  if (!appSecret) {
    console.warn('[Webhook] Warning: WHATSAPP_APP_SECRET not set, skipping signature verification');
    return true;
  }

  if (!signatureHeader) return false;

  const hash = crypto
    .createHmac('sha256', appSecret)
    .update(rawBody)
    .digest('hex');

  const expectedSignature = `sha256=${hash}`;

  try {
    const sigBuf = Buffer.from(signatureHeader);
    const expBuf = Buffer.from(expectedSignature);
    if (sigBuf.length !== expBuf.length) return false;
    return crypto.timingSafeEqual(sigBuf, expBuf);
  } catch (err) {
    console.error('[Webhook] Signature verification error:', err.message);
    return false;
  }
}

// ── GET /webhook — Meta verification handshake ────────
router.get('/', (req, res) => {
  const mode      = req.query['hub.mode'];
  const token     = req.query['hub.verify_token'];
  const challenge = req.query['hub.challenge'];

  console.log(`[Webhook] Verification request — mode: ${mode}, token: ${token}`);

  if (mode === 'subscribe' && token === process.env.VERIFY_TOKEN) {
    console.log('[Webhook] ✅ Verified successfully');
    return res.status(200).send(challenge);
  }

  console.warn('[Webhook] ❌ Verification failed — token mismatch');
  res.sendStatus(403);
});

// ── POST /webhook — Incoming messages from Meta ───────
router.post('/', (req, res) => {
  // Verify webhook signature
  const signature = req.headers['x-hub-signature-256'];
  if (!verifyWebhookSignature(req.rawBody, signature)) {
    console.warn('[Webhook] ❌ Signature verification failed');
    return res.sendStatus(403);
  }

  const body = req.body;

  // Acknowledge immediately (Meta requires 200 within 20s)
  res.sendStatus(200);

  if (body.object !== 'whatsapp_business_account') {
    console.log('[Webhook] Non-WhatsApp event, ignoring');
    return;
  }

  try {
    const entry   = body.entry?.[0];
    const changes = entry?.changes?.[0];
    const value   = changes?.value;

    if (!value) return;

    // ── Incoming messages ──────────────────────────
    if (value.messages?.length) {
      const contacts = value.contacts || [];
      value.messages.forEach(msg => {
        const phone = msg.from;
        const contact = contacts.find(c => c.wa_id === phone);
        const name  = contact?.profile?.name || phone;

        let text = '';
        switch (msg.type) {
          case 'text':     text = msg.text?.body || '';          break;
          case 'image':    text = '[Image]';                     break;
          case 'audio':    text = '[Audio]';                     break;
          case 'video':    text = '[Video]';                     break;
          case 'document': text = `[Document: ${msg.document?.filename || ''}]`; break;
          case 'location': text = `[Location: ${msg.location?.latitude}, ${msg.location?.longitude}]`; break;
          case 'sticker':  text = '[Sticker]';                   break;
          default:         text = `[${msg.type}]`;
        }

        console.log(`[Message] ${name} (${phone}): ${text}`);

        // Save to database
        saveMessage({
          id: msg.id,
          from: phone,
          name,
          text,
          type: msg.type,
          timestamp: msg.timestamp,
          raw: msg,
        });

        // Push to all connected dashboard clients via WebSocket
        broadcast({
          event: 'message',
          data: {
            id:        msg.id,
            from:      phone,
            name,
            text,
            type:      msg.type,
            timestamp: msg.timestamp,
            raw:       msg,
          }
        });
      });
    }

    // ── Status updates ─────────────────────────────
    if (value.statuses?.length) {
      value.statuses.forEach(status => {
        console.log(`[Status] Message ${status.id} → ${status.status}`);
        
        // Save to database
        saveStatus({
          id: status.id,
          message_id: status.id,
          status: status.status,
          timestamp: status.timestamp,
        });
        
        broadcast({ event: 'status', data: status });
      });
    }

  } catch (err) {
    console.error('[Webhook] Parse error:', err.message);
  }
});

module.exports = router;
