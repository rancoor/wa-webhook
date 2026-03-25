#!/bin/bash

# WhatsApp Webhook - Single Command Startup
# Usage: ./start.sh
# This starts both the server and ngrok tunnel in one command

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
PORT=3000
PROJECT_NAME="wa-webhook"

# Cleanup function
cleanup() {
  echo -e "\n${YELLOW}Shutting down...${NC}"
  kill $SERVER_PID 2>/dev/null || true
  kill $NGROK_PID 2>/dev/null || true
  exit 0
}

trap cleanup SIGINT SIGTERM

# Header
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  WhatsApp Webhook - Local Dev + ngrok Tunnel         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"

# Check dependencies
echo -e "${YELLOW}Checking dependencies...${NC}"

if ! command -v node &> /dev/null; then
  echo -e "${RED}✗ Node.js not found${NC}"
  exit 1
fi

if ! command -v ngrok &> /dev/null; then
  echo -e "${RED}✗ ngrok not found${NC}"
  echo -e "${YELLOW}Install ngrok: https://ngrok.com/download${NC}"
  exit 1
fi

if ! command -v npm &> /dev/null; then
  echo -e "${RED}✗ npm not found${NC}"
  exit 1
fi

echo -e "${GREEN}✓ All dependencies found${NC}\n"

# Kill any existing process on port
if lsof -i :$PORT >/dev/null 2>&1; then
  echo -e "${YELLOW}Killing existing process on port $PORT...${NC}"
  lsof -ti :$PORT | xargs kill -9 2>/dev/null || true
  sleep 1
fi

# Start server
echo -e "${YELLOW}Starting Node.js server on port $PORT...${NC}"
npm start > /tmp/wa-webhook-server.log 2>&1 &
SERVER_PID=$!
echo -e "${GREEN}✓ Server PID: $SERVER_PID${NC}"

# Wait for server to be ready
echo -e "${YELLOW}Waiting for server to start...${NC}"
MAX_ATTEMPTS=30
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  if curl -s http://localhost:$PORT/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Server is ready${NC}\n"
    break
  fi
  ATTEMPT=$((ATTEMPT + 1))
  sleep 1
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
  echo -e "${RED}✗ Server failed to start${NC}"
  cat /tmp/wa-webhook-server.log
  exit 1
fi

# Start ngrok in background
echo -e "${YELLOW}Starting ngrok tunnel...${NC}"
ngrok http $PORT --log=stdout > /tmp/wa-webhook-ngrok.log 2>&1 &
NGROK_PID=$!
echo -e "${GREEN}✓ ngrok PID: $NGROK_PID${NC}"

# Wait for ngrok to establish tunnel
sleep 3

# Get ngrok URL from API
NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[0].public_url' 2>/dev/null || echo "")

if [ -z "$NGROK_URL" ]; then
  echo -e "${YELLOW}Waiting for ngrok tunnel to establish...${NC}"
  sleep 2
  NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[0].public_url' 2>/dev/null || echo "")
fi

if [ -z "$NGROK_URL" ]; then
  echo -e "${RED}✗ Failed to establish ngrok tunnel${NC}"
  cat /tmp/wa-webhook-ngrok.log
  cleanup
  exit 1
fi

# Display information
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ✅ EVERYTHING IS RUNNING!                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}🚀 Server Status:${NC}"
echo -e "   Local:   ${GREEN}http://localhost:$PORT${NC}"
echo -e "   Status:  ${GREEN}✓ Running${NC}\n"

echo -e "${GREEN}🌐 Tunnel Status:${NC}"
echo -e "   Public:  ${GREEN}${NGROK_URL}${NC}"
echo -e "   Status:  ${GREEN}✓ Active${NC}\n"

echo -e "${BLUE}📋 Useful URLs:${NC}"
echo -e "   Dashboard:   ${GREEN}http://localhost:$PORT${NC}"
echo -e "   Health:      ${GREEN}http://localhost:$PORT/health${NC}"
echo -e "   Config:      ${GREEN}http://localhost:$PORT/api/config${NC}"
echo -e "   Webhook:     ${GREEN}${NGROK_URL}/webhook${NC}"
echo -e "   Messages:    ${GREEN}${NGROK_URL}/api/messages${NC}\n"

echo -e "${YELLOW}📝 For Meta Developer Console:${NC}"
echo -e "   Callback URL: ${GREEN}${NGROK_URL}/webhook${NC}"
echo -e "   Verify Token: Check your .env file\n"

echo -e "${YELLOW}🧪 Test the webhook:${NC}"
echo -e "   ${GREEN}curl ${NGROK_URL}/health${NC}\n"

echo -e "${YELLOW}📊 View server logs:${NC}"
echo -e "   ${GREEN}tail -f /tmp/wa-webhook-server.log${NC}\n"

echo -e "${YELLOW}📊 View ngrok logs:${NC}"
echo -e "   ${GREEN}tail -f /tmp/wa-webhook-ngrok.log${NC}\n"

echo -e "${YELLOW}Press Ctrl+C to stop${NC}\n"

# Keep running
wait
