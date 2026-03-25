#!/bin/bash

# Get the public ngrok URL
NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[0].public_url' 2>/dev/null || echo "")

if [ -z "$NGROK_URL" ]; then
  echo "❌ Error: Could not get ngrok tunnel URL. Make sure ngrok is running."
  exit 1
fi

WEBHOOK_URL="$NGROK_URL/webhook"
echo "📡 Testing webhook at: $WEBHOOK_URL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test 1: GET verification handshake
echo ""
echo "📋 Test 1: Verification Handshake (GET)"
curl -s "$WEBHOOK_URL?hub.mode=subscribe&hub.verify_token=EFQg9dpgWCRGSb7PBOdJtjHY5b2zOlYr6JDJz19hkmTAp1rT027Z1V3Z6PtfJVQaLS53hic73Lw9oXcsiU7cAuLtt5DW02YWRcQqJpTKPT6L6j&hub.challenge=test_challenge_123" -w "\nHTTP Status: %{http_code}\n\n"

# Test 2: POST text message
echo "📋 Test 2: Text Message (POST)"
curl -s -X POST "$WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d '{
    "object": "whatsapp_business_account",
    "entry": [{
      "changes": [{
        "value": {
          "messages": [{
            "id": "wamid.test.001",
            "from": "1234567890",
            "timestamp": "1711320000",
            "type": "text",
            "text": {"body": "Hello World from tunnel test!"}
          }],
          "contacts": [{
            "wa_id": "1234567890",
            "profile": {"name": "Test User"}
          }]
        }
      }]
    }]
  }' -w "\nHTTP Status: %{http_code}\n\n"

# Test 3: POST image message
echo "📋 Test 3: Image Message (POST)"
curl -s -X POST "$WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d '{
    "object": "whatsapp_business_account",
    "entry": [{
      "changes": [{
        "value": {
          "messages": [{
            "id": "wamid.test.002",
            "from": "9876543210",
            "timestamp": "1711320001",
            "type": "image",
            "image": {"id": "img_123", "mime_type": "image/jpeg", "sha256": "abc123"}
          }],
          "contacts": [{
            "wa_id": "9876543210",
            "profile": {"name": "Image Sender"}
          }]
        }
      }]
    }]
  }' -w "\nHTTP Status: %{http_code}\n\n"

# Test 4: POST status update
echo "📋 Test 4: Status Update (POST)"
curl -s -X POST "$WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d '{
    "object": "whatsapp_business_account",
    "entry": [{
      "changes": [{
        "value": {
          "statuses": [{
            "id": "wamid.test.001",
            "status": "delivered",
            "timestamp": "1711320005"
          }]
        }
      }]
    }]
  }' -w "\nHTTP Status: %{http_code}\n\n"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Webhook tests complete!"
echo ""
echo "📊 View server logs:"
echo "   tail -f server.out"
echo ""
echo "📊 View database:"
echo "   sqlite3 data/messages.db 'SELECT * FROM messages LIMIT 5;'"
