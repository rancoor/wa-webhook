require('dotenv').config();
const crypto = require('crypto');
const { broadcast } = require('../../ws');
const { saveMessage, saveStatus } = require('../../db');

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

module.exports = async (req, res) => {
  // GET - Meta verification handshake
  if (req.method === 'GET') {
    const mode      = req.query['hub.mode'];
    const token     = req.query['hub.verify_token'];
    const challenge = req.query['hub.challenge'];

    console.log(`[Webhook] Verification request — mode: ${mode}, token: ${token}`);

    if (mode === 'subscribe' && token === process.env.VERIFY_TOKEN) {
      console.log('[Webhook] ✅ Verified successfully');
      return res.status(200).send(challenge);
    }

    console.warn('[Webhook] ❌ Verification failed — token mismatch');
    return res.status(403).send('Forbidden');
  }

  // POST - Incoming messages from Meta
  if (req.method === 'POST') {
    const signature = req.headers['x-hub-signature-256'];
    const rawBody = req.body ? JSON.stringify(req.body) : '';
    
    if (!verifyWebhookSignature(rawBody, signature)) {
      console.warn('[Webhook] ❌ Signature verification failed');
      return res.status(403).send('Forbidden');
    }

    const body = req.body;
    res.status(200).send('ok');

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
            case 'text': text = msg.text?.body || ''; break;
            case 'image': text = `[Image: ${msg.image?.caption || 'no caption'}]`; break;
            case 'audio': text = '[Audio message]'; break;
            case 'video': text = `[Video: ${msg.video?.caption || 'no caption'}]`; break;
            case 'document': text = `[Document: ${msg.document?.filename || 'unnamed'}]`; break;
            case 'location': text = `[Location: ${msg.location?.latitude}, ${msg.location?.longitude}]`; break;
            case 'sticker': text = '[Sticker]'; break;
            default: text = `[${msg.type}]`;
          }

          const messageData = {
            id: msg.id,
            from_phone: phone,
            from_name: name,
            type: msg.type,
            text,
            timestamp: msg.timestamp,
            raw_data: JSON.stringify(msg)
          };

          console.log(`[Webhook] 📨 Message from ${name} (${phone}): "${text}"`);
          
          try {
            saveMessage(messageData);
            broadcast({ event: 'message', data: messageData });
          } catch (err) {
            console.error('[Webhook] Error saving message:', err.message);
          }
        });
      }

      // ── Status updates ─────────────────────────────
      if (value.statuses?.length) {
        value.statuses.forEach(status => {
          const statusData = {
            message_id: status.id,
            status: status.status,
            timestamp: status.timestamp
          };

          console.log(`[Webhook] 📊 Status: msg ${status.id} → ${status.status}`);
          
          try {
            saveStatus(statusData);
            broadcast({ event: 'status', data: statusData });
          } catch (err) {
            console.error('[Webhook] Error saving status:', err.message);
          }
        });
      }
    } catch (err) {
      console.error('[Webhook] Error processing webhook:', err.message);
    }
  }

  res.status(405).send('Method Not Allowed');
};
