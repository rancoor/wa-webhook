#!/bin/bash

cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                      🔍 WEBHOOK DIAGNOSTIC REPORT                         ║
╚════════════════════════════════════════════════════════════════════════════╝

📌 KEY FINDINGS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Your webhook SERVER is working:
   • Node.js running on port 3000
   • Responds to POST requests with 200 OK
   • Processes and logs messages
   • Saves to database

✅ Your ngrok TUNNEL is working:
   • Public URL: https://bf50-41-90-137-165.ngrok-free.app
   • Forwards traffic correctly
   • Test messages through ngrok: SUCCESS

❌ Meta webhooks are NOT reaching your server:
   • No POST requests from Meta detected
   • Only test requests from your local machine are coming through

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔧 TROUBLESHOOTING CHECKLIST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 1: VERIFY META CONSOLE CONFIGURATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Go to: https://developers.facebook.com/apps/

1a. Webhook URL (CRITICAL):
    ☐ Is it set to: https://bf50-41-90-137-165.ngrok-free.app/webhook ?
    ☐ Does it NOT have trailing slash?
    ☐ Did you click "Verify and Save"?
    ☐ Did you see "✅ Verified" message?

1b. Verify Token (CRITICAL):
    ☐ Is it EXACTLY this:
       EFQg9dpgWCRGSb7PBOdJtjHY5b2zOlYr6JDJz19hkmTAp1rT027Z1V3Z6PtfJVQaLS53hic73Lw9oXcsiU7cAuLtt5DW02YWRcQqJpTKPT6L6j
    ☐ Did it copy without extra spaces?

1c. Subscribed Events (CRITICAL):
    ☐ messages (checked)
    ☐ message_status (checked)
    ☐ Did you click "Subscribe to these fields"?

Step 2: TEST THE VERIFICATION HANDSHAKE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Run this command:

curl "https://bf50-41-90-137-165.ngrok-free.app/webhook?hub.mode=subscribe&hub.verify_token=EFQg9dpgWCRGSb7PBOdJtjHY5b2zOlYr6JDJz19hkmTAp1rT027Z1V3Z6PtfJVQaLS53hic73Lw9oXcsiU7cAuLtt5DW02YWRcQqJpTKPT6L6j&hub.challenge=test123"

Expected response: "test123" (the challenge token)

If you get a 403, the verify token is WRONG.
If you get "test123", the handshake works ✓

Step 3: CHECK YOUR PHONE NUMBER CONFIGURATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
In Meta Console under WhatsApp → Phone Number Settings:

☐ Is a test phone number configured?
☐ Is your phone number added as a test recipient?
☐ Do you have the phone number ID: 1071000406090975 ?

Step 4: SEND TEST MESSAGE FROM META CONSOLE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Go to: WhatsApp → API Setup
2. Click "Try it Out" or "Send Test Message"
3. Select your test phone number
4. Send a message

Then check your server logs:
  tail -f /home/amos/projects/wa-webhook/server.out

You should see:
  [Message] Your Name (phone): Your message

Step 5: COMMON ISSUES & FIXES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ Webhook URL not verified (403 on handshake):
   → Check verify token is copied exactly (no spaces/typos)
   → Check URL has NO trailing slash
   → Check you clicked "Verify and Save"

❌ ngrok URL changed (happens if ngrok restarts):
   → Run: curl -s http://127.0.0.1:4040/api/tunnels | jq '.tunnels[0].public_url'
   → Update Meta console with NEW URL
   → Re-verify the webhook

❌ "This app is in development mode":
   → Add your WhatsApp phone number as a test recipient
   → In Meta console: Apps & Pages → Your App → Roles → Test Users

❌ "Your app doesn't have permission":
   → Make sure you have WhatsApp Business API access
   → Check WHATSAPP_API_TOKEN in .env is valid
   → Request permission if denied

❌ Messages sending but not received:
   → Check that sender phone is added as test recipient
   → Check phone number format (usually: +country code + number)
   → Verify PHONE_NUMBER_ID in .env: 1071000406090975

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚀 QUICK VERIFICATION TEST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Run this to verify handshake works:

curl -v "https://bf50-41-90-137-165.ngrok-free.app/webhook?hub.mode=subscribe&hub.verify_token=EFQg9dpgWCRGSb7PBOdJtjHY5b2zOlYr6JDJz19hkmTAp1rT027Z1V3Z6PtfJVQaLS53hic73Lw9oXcsiU7cAuLtt5DW02YWRcQqJpTKPT6L6j&hub.challenge=challenge123"

Look for:
  < HTTP/1.1 200 OK    ← Must be 200
  challenge123         ← Must return the challenge value

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 ENVIRONMENT CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

echo ""
echo "Current .env configuration:"
cat /home/amos/projects/wa-webhook/.env

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Server logs (last 15 lines):"
tail -15 /home/amos/projects/wa-webhook/server.out
