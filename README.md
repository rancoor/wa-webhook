# WhatsApp Webhook Receiver

A Node.js/Express app that receives WhatsApp Cloud API webhook events and displays them in a real-time chat dashboard.

---

## Quick Start

### 1. Install dependencies

```bash
npm install
```

### 2. Configure environment

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

Edit `.env`:

```
PORT=3000
VERIFY_TOKEN=my_secret_verify_token   # pick any string, paste into Meta too
WHATSAPP_API_TOKEN=                   # from Meta Developer Console
PHONE_NUMBER_ID=                      # from Meta Developer Console
```

### 3. Run the server

```bash
# Production
npm start

# Development (auto-restart)
npm run dev
```

Open http://localhost:3000 in your browser.

---

## Connecting to Meta Developer Console

You need a **public HTTPS URL** for your server. Use [ngrok](https://ngrok.com) for local development:

```bash
ngrok http 3000
```

This gives you a URL like `https://abc123.ngrok.io`.

### Steps in Meta Developer Console

1. Go to **WhatsApp → Configuration → Webhooks**
2. Click **Edit**
3. Set **Callback URL** to: `https://your-ngrok-url.ngrok.io/webhook`
4. Set **Verify Token** to the same value as `VERIFY_TOKEN` in your `.env`
5. Click **Verify and Save**
6. Subscribe to the **messages** field

Once verified, incoming messages from your WhatsApp number will appear in the dashboard in real time.

---

## Project Structure

```
wa-webhook/
├── src/
│   ├── server.js          # Express app entry point
│   ├── ws.js              # WebSocket server (broadcasts to dashboard)
│   └── routes/
│       └── webhook.js     # GET (Meta verification) + POST (incoming messages)
├── public/
│   └── index.html         # Chat dashboard (connects via WebSocket)
├── .env                   # Your secrets (not committed to git)
├── .env.example           # Template
└── package.json
```

---

## How It Works

```
WhatsApp User
     │
     ▼
Meta Cloud API
     │  POST /webhook
     ▼
Express Server  ──── broadcasts via WebSocket ────▶  Browser Dashboard
     │
     ▼  GET /webhook
Meta Verification ✅
```

1. Meta sends a `GET /webhook` with a challenge to verify your token
2. Incoming messages arrive as `POST /webhook` JSON payloads
3. The server parses the payload and broadcasts it over WebSocket
4. The browser dashboard receives the event and renders it live

---

## Webhook Payload (Meta format)

```json
{
  "object": "whatsapp_business_account",
  "entry": [{
    "changes": [{
      "value": {
        "messages": [{
          "from": "254700000000",
          "id": "wamid.xxx",
          "timestamp": "1234567890",
          "type": "text",
          "text": { "body": "Hello!" }
        }],
        "contacts": [{
          "wa_id": "254700000000",
          "profile": { "name": "Customer Name" }
        }]
      }
    }]
  }]
}
```

Supported message types: `text`, `image`, `audio`, `video`, `document`, `location`, `sticker`.
