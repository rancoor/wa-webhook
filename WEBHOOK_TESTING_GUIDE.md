# ✅ WhatsApp Webhook Tunnel Testing - Complete Setup

## 🎯 Current Status

**Server**: ✅ Running on `http://localhost:3000`  
**Tunnel**: ✅ Active via ngrok at `https://bf50-41-90-137-165.ngrok-free.app`  
**Webhook**: ✅ Receiving and processing messages  
**Database**: ✅ Persisting messages and statuses  

---

## 🚀 Quick Start Commands

### Start the server (if not running)
```bash
cd /home/amos/projects/wa-webhook
npm start
# or in background:
nohup node src/server.js > server.out 2>&1 &
```

### Start ngrok tunnel
```bash
ngrok http 3000
# Or in background:
nohup ngrok http 3000 --log=stdout > ngrok.out 2>&1 &
```

### Run webhook tests
```bash
cd /home/amos/projects/wa-webhook
bash test-webhook.sh
```

### View server logs
```bash
tail -f server.out
```

### View ngrok logs
```bash
tail -f ngrok.out
```

### Query messages from database
```bash
cd /home/amos/projects/wa-webhook
node -e "const db=require('./src/db.js'); console.log(JSON.stringify(db.getMessages(10), null, 2))"
```

---

## 📊 API Endpoints

### Health Check
```bash
curl http://localhost:3000/health
```

### Webhook (GET - Verification)
```bash
curl "https://bf50-41-90-137-165.ngrok-free.app/webhook?hub.mode=subscribe&hub.verify_token=EFQg9dpgWCRGSb7PBOdJtjHY5b2zOlYr6JDJz19hkmTAp1rT027Z1V3Z6PtfJVQaLS53hic73Lw9oXcsiU7cAuLtt5DW02YWRcQqJpTKPT6L6j&hub.challenge=your_challenge_here"
```

### Webhook (POST - Receive Messages)
```bash
curl -X POST https://bf50-41-90-137-165.ngrok-free.app/webhook \
  -H 'Content-Type: application/json' \
  -d @payload.json
```

### Get Messages (API)
```bash
curl http://localhost:3000/api/messages?limit=50&offset=0
```

### Get Config
```bash
curl http://localhost:3000/api/config
```

---

## 🔧 Configuration

### Environment Variables (.env)
```properties
PORT=3000
VERIFY_TOKEN=EFQg9dpgWCRGSb7PBOdJtjHY5b2zOlYr6JDJz19hkmTAp1rT027Z1V3Z6PtfJVQaLS53hic73Lw9oXcsiU7cAuLtt5DW02YWRcQqJpTKPT6L6j
WHATSAPP_API_TOKEN=EAAWBXOZB24aoBQ07PmlmYXWZCqSOfWZAvHB5Yyww03BLXploLei8E3NhZC3TTfr0LCwoM6bVfSMM6If9y79Ebr4ZAgxTZBAwaytolYv5feuISJgiyKj1NZCF0zaw2eSejuAfZCZCH9PqnEZCd4Nrvk2TSt202jUtMnceReZBcGQzXEn3u1eHqyiXhpc2GzliAE8igZDZD
PHONE_NUMBER_ID=1071000406090975
WHATSAPP_APP_SECRET=<optional-for-signature-verification>
```

---

## 📝 Features

✅ **Webhook Server**
- GET verification handshake (hub.mode=subscribe)
- POST message reception
- Status updates tracking
- Raw body capture for signature verification

✅ **Real-time Updates**
- WebSocket server at `/ws`
- Broadcasts all messages and statuses to connected clients
- Auto-reconnect support for clients

✅ **Data Persistence**
- SQLite database: `data/messages.db`
- Message history with full metadata
- Status tracking for delivery/read receipts

✅ **Security**
- HMAC-SHA256 signature verification (when WHATSAPP_APP_SECRET is set)
- Rate limiting (100 req/min per IP)
- CORS enabled for frontend access

✅ **Message Types Supported**
- Text messages
- Images
- Audio
- Video
- Documents
- Location data
- Stickers

---

## 🔗 Integrate with Meta Webhook

1. Go to [Meta Developer Console](https://developers.facebook.com)
2. Navigate to: **Your App** → **Webhooks**
3. Set **Callback URL**: `https://bf50-41-90-137-165.ngrok-free.app/webhook`
4. Set **Verify Token**: `EFQg9dpgWCRGSb7PBOdJtjHY5b2zOlYr6JDJz19hkmTAp1rT027Z1V3Z6PtfJVQaLS53hic73Lw9oXcsiU7cAuLtt5DW02YWRcQqJpTKPT6L6j`
5. Subscribe to **messages** and **message_status** events
6. Save

---

## 🧪 Test Results

```
✅ Test 1: Verification Handshake (GET)
   Status: 200
   Response: test_challenge_123

✅ Test 2: Text Message (POST)
   Status: 200
   Logged: [Message] Test User (1234567890): Hello World from tunnel test!
   Saved: ✓

✅ Test 3: Image Message (POST)
   Status: 200
   Logged: [Message] Image Sender (9876543210): [Image]
   Saved: ✓

✅ Test 4: Status Update (POST)
   Status: 200
   Logged: [Status] Message wamid.test.001 → delivered
   Saved: ✓
```

---

## 🛠️ Troubleshooting

### Port 3000 Already in Use
```bash
lsof -i :3000 -Pn | awk 'NR>1{print $2}' | xargs kill -9
```

### ngrok URL Changed
- Run `bash test-webhook.sh` - it auto-detects the current ngrok URL
- Or manually check: `curl -s http://127.0.0.1:4040/api/tunnels | jq`

### Database Not Found
- Database is auto-created on first run
- Located at: `data/messages.db`
- Check directory exists: `ls -la data/`

### Messages Not Persisting
- Check `.env` has correct `WHATSAPP_APP_SECRET` (optional)
- Check server logs: `tail -f server.out`
- Verify webhook is returning 200: `curl -i <URL>`

---

## 📚 Project Structure

```
wa-webhook/
├── src/
│   ├── server.js          # Express app, routes setup
│   ├── ws.js              # WebSocket server
│   ├── db.js              # SQLite persistence
│   └── routes/
│       └── webhook.js     # Webhook handling + verification
├── public/                # Frontend static files
├── data/
│   └── messages.db        # SQLite database
├── package.json           # Dependencies
├── .env                   # Configuration (NEVER commit!)
└── test-webhook.sh        # Testing script
```

---

## 🎓 What's Implemented

1. **Webhook Security**
   - Signature verification with HMAC-SHA256
   - Token validation
   - Rate limiting

2. **Message Handling**
   - Parse all message types
   - Extract sender info & contact names
   - Broadcast via WebSocket

3. **Persistence**
   - SQLite database with schema
   - Message history queryable via API
   - Status tracking

4. **Public Access**
   - ngrok tunnel for local testing
   - Production-ready with trust proxy
   - Error handling and logging

---

**Last Updated**: March 25, 2026  
**Status**: ✅ Fully Functional
