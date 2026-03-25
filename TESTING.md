# 🚀 WhatsApp Webhook Testing Guide

Your webhook is now publicly accessible via ngrok!

## 📍 Tunnel URLs

- **Public URL**: `https://babb-41-90-137-165.ngrok-free.app`
- **Webhook Endpoint**: `https://babb-41-90-137-165.ngrok-free.app/webhook`
- **Config Endpoint**: `https://babb-41-90-137-165.ngrok-free.app/api/config`
- **Health Check**: `https://babb-41-90-137-165.ngrok-free.app/health`

## 🔧 Setup in Meta Developer Console

1. Go to [Meta Developers Dashboard](https://developers.facebook.com/apps)
2. Select your WhatsApp Business Account app
3. Navigate to: **Messenger → Configuration → Webhooks**
4. Click **Edit Subscription**
5. Set:
   - **Callback URL**: `https://babb-41-90-137-165.ngrok-free.app/webhook`
   - **Verify Token**: Check your `.env` file for `VERIFY_TOKEN` value

6. Click **Verify and Save**

## ✅ Test the Setup Locally

### 1. Test Health Endpoint
```bash
curl https://babb-41-90-137-165.ngrok-free.app/health
```

Expected response:
```json
{"status":"ok","uptime":...}
```

### 2. Test Config Endpoint
```bash
curl https://babb-41-90-137-165.ngrok-free.app/api/config
```

Expected response:
```json
{
  "webhookUrl": "https://babb-41-90-137-165.ngrok-free.app/webhook",
  "verifyToken": "your_verify_token"
}
```

### 3. Test Webhook Verification (Simulate Meta)
```bash
curl -X GET "https://babb-41-90-137-165.ngrok-free.app/webhook?hub.mode=subscribe&hub.challenge=test123&hub.verify_token=YOUR_VERIFY_TOKEN"
```

Expected response: `test123` (the challenge string)

### 4. Test with Test Message
```bash
curl -X POST https://babb-41-90-137-165.ngrok-free.app/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "object": "whatsapp_business_account",
    "entry": [{
      "changes": [{
        "value": {
          "messages": [{
            "id": "test123",
            "from": "1234567890",
            "timestamp": 1640001234,
            "type": "text",
            "text": {"body": "Hello from test!"}
          }],
          "contacts": [{
            "wa_id": "1234567890",
            "profile": {"name": "Test User"}
          }]
        }
      }]
    }]
  }'
```

## 📊 Monitor Incoming Messages

1. **Check database** (last 10 messages):
```bash
curl https://babb-41-90-137-165.ngrok-free.app/api/messages?limit=10
```

2. **Connect to WebSocket** for real-time updates:
```bash
wscat -c wss://babb-41-90-137-165.ngrok-free.app/ws
```

Then receive events like:
```json
{
  "event": "message",
  "data": {
    "id": "message_id",
    "from": "1234567890",
    "name": "Sender Name",
    "text": "Message content",
    "type": "text",
    "timestamp": 1640001234
  }
}
```

## 🔐 Webhook Signature Verification

The server validates incoming webhooks using HMAC-SHA256. Set in `.env`:
```
WHATSAPP_APP_SECRET=your_app_secret_from_meta
```

Meta sends the signature in the `X-Hub-Signature-256` header.

## 📝 View Server Logs

```bash
tail -f /tmp/server.log
```

## 🛑 Stop Tunnel

Press `Ctrl+C` to stop ngrok and the tunnel will be closed.

---

**Note**: The ngrok URL changes every time you restart. Update Meta Developer Console if needed!
