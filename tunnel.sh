#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  WhatsApp Webhook Tunnel Setup${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"

# Check if server is running
if ! curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${YELLOW}Starting server...${NC}"
    npm start > /tmp/server.log 2>&1 &
    sleep 3
fi

echo -e "${GREEN}✓ Server running on http://localhost:3000${NC}\n"

# Start ngrok
echo -e "${YELLOW}Starting ngrok tunnel...${NC}\n"
ngrok http 3000 --log=stdout 2>&1 | while IFS= read -r line; do
    if [[ $line =~ "Forwarding" ]]; then
        # Extract HTTPS URL
        NGROK_URL=$(echo "$line" | grep -oP 'https://[a-z0-9-]+\.ngrok(?:\.io|\.app)' | head -1)
        if [ ! -z "$NGROK_URL" ]; then
            echo -e "\n${GREEN}═══════════════════════════════════════════════════════${NC}"
            echo -e "${GREEN}✓ Tunnel Ready!${NC}"
            echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}\n"
            
            echo -e "${BLUE}📍 Public URL:${NC}"
            echo -e "   ${GREEN}${NGROK_URL}${NC}\n"
            
            echo -e "${BLUE}📍 Webhook URL:${NC}"
            echo -e "   ${GREEN}${NGROK_URL}/webhook${NC}\n"
            
            echo -e "${BLUE}📍 Local Config URL:${NC}"
            echo -e "   ${GREEN}${NGROK_URL}/api/config${NC}\n"
            
            echo -e "${YELLOW}To use in Meta Developer Console:${NC}"
            echo -e "   1. Go to: https://developers.facebook.com/apps"
            echo -e "   2. Select your WhatsApp Business Account app"
            echo -e "   3. Go to: Configuration → Webhooks"
            echo -e "   4. Enter Callback URL: ${GREEN}${NGROK_URL}/webhook${NC}"
            echo -e "   5. Verify Token: Check your .env VERIFY_TOKEN\n"
            
            echo -e "${YELLOW}Test the webhook:${NC}"
            echo -e "   curl ${NGROK_URL}/health\n"
            
            echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"
        fi
    fi
    
    # Forward output
    echo "$line"
done
