# 🚀 Deploying to Vercel

Your WhatsApp Webhook Receiver is now ready for Vercel deployment!

## Quick Start

### 1. Install Vercel CLI
```bash
npm i -g vercel
```

### 2. Deploy to Vercel
```bash
vercel
```

This will:
- Ask you to log in to Vercel (or create an account)
- Ask for project name (suggest: `wa-webhook-receiver`)
- Set up environment variables
- Deploy to a production URL

### 3. Set Environment Variables in Vercel

After deployment, go to your **Vercel Dashboard** → **Settings** → **Environment Variables** and add:

```
VERIFY_TOKEN=EFQg9dpgWCRGSb7PBOdJtjHY5b2zOlYr6JDJz19hkmTAp1rT027Z1V3Z6PtfJVQaLS53hic73Lw9oXcsiU7cAuLtt5DW02YWRcQqJpTKPT6L6j

WHATSAPP_API_TOKEN=EAAWBXOZB24aoBQ07PmlmYXWZCqSOfWZAvHB5Yyww03BLXploLei8E3NhZC3TTfr0LCwoM6bVfSMM6If9y79Ebr4ZAgxTZBAwaytolYv5feuISJgiyKj1NZCF0zaw2eSejuAfZCZCH9PqnEZCd4Nrvk2TSt202jUtMnceReZBcGQzXEn3u1eHqyiXhpc2GzliAE8igZDZD

PHONE_NUMBER_ID=1071000406090975
```

**OR** use the `.env.example` for reference, then add them via CLI:

```bash
vercel env add VERIFY_TOKEN
vercel env add WHATSAPP_API_TOKEN
vercel env add PHONE_NUMBER_ID
```

### 4. Redeploy with Environment Variables
```bash
vercel --prod
```

## Your Live Webhook URL

Once deployed, your webhook will be available at:

```
https://your-project-name.vercel.app/webhook
```

Use this URL in your **Meta Developer Console** → **Webhooks** configuration.

## Important Notes

⚠️ **Database Limitation**: Vercel's serverless functions have ephemeral storage, meaning the SQLite database will reset on redeploy. For production, consider:
- MongoDB (free tier available)
- Firebase Firestore
- Supabase
- AWS DynamoDB

For now, the database will work during the deployment but reset when you redeploy.

## Testing

After deployment, test your webhook:

```bash
# Health check
curl https://your-project-name.vercel.app/health

# Config endpoint (shows webhook URL)
curl https://your-project-name.vercel.app/api/config

# Get messages
curl https://your-project-name.vercel.app/api/messages
```

## Local Development

Still works normally:

```bash
npm start
./start.sh  # For server + ngrok tunnel
```

## Logs

View deployment logs in Vercel Dashboard → **Functions** → **Logs**

## Troubleshooting

### 500 Error on Webhook
- Check environment variables are set correctly in Vercel
- Verify token matches Meta Developer Console
- Check Function logs in Vercel Dashboard

### Database Not Persisting
- This is expected on Vercel (ephemeral storage)
- Messages stored during a deployment will be lost on redeploy
- Use a cloud database for persistence

## Next Steps

1. Deploy to Vercel
2. Add environment variables
3. Configure Meta Developer Console webhook
4. Send a test message
5. Check logs to verify it's working

Good luck! 🎉
