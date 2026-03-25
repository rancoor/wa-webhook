require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const rateLimit = require('express-rate-limit');
const webhookRouter = require('./routes/webhook');

const app = express();

// Trust reverse proxy headers (ngrok, load balancers, Vercel)
app.set('trust proxy', true);

// ── Middleware ────────────────────────────────────────
app.use(cors());

// Rate limiting for webhooks (100 requests per minute per IP)
const webhookLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  message: 'Too many webhook requests from this IP, please try again later',
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req, res) => !req.ip, // Skip if no valid IP (shouldn't happen with trust proxy)
});

// Raw body needed for webhook signature verification (optional future use)
app.use((req, res, next) => {
  if (req.path === '/webhook' && req.method === 'POST') {
    let raw = '';
    req.setEncoding('utf8');
    req.on('data', chunk => raw += chunk);
    req.on('end', () => {
      req.rawBody = raw;
      try { req.body = JSON.parse(raw); } catch (e) { req.body = {}; }
      next();
    });
  } else {
    express.json()(req, res, next);
  }
});

// ── Static frontend (only in local/dev, not needed for serverless) ───
if (!process.env.VERCEL) {
  app.use(express.static(path.join(__dirname, '../public')));
}

// ── Routes ────────────────────────────────────────────
app.use('/webhook', webhookLimiter, webhookRouter);

// Health check
app.get('/health', (req, res) => res.json({ status: 'ok', uptime: process.uptime() }));

// Config endpoint — lets the frontend know the webhook URL and verify token
app.get('/api/config', (req, res) => {
  const host = req.headers['x-forwarded-host'] || req.headers.host;
  const proto = req.headers['x-forwarded-proto'] || (req.secure ? 'https' : 'http');
  res.json({
    webhookUrl: `${proto}://${host}/webhook`,
    verifyToken: process.env.VERIFY_TOKEN || '(not set — check .env)',
  });
});

// Messages API endpoint
app.get('/api/messages', (req, res) => {
  const { getMessages } = require('./db');
  const limit = Math.min(parseInt(req.query.limit) || 50, 500);
  const offset = parseInt(req.query.offset) || 0;
  const messages = getMessages(limit, offset);
  res.json(messages);
});

// ── Start (only if not serverless) ────────────────────
if (!process.env.VERCEL) {
  const http = require('http');
  const { initWss } = require('./ws');
  const server = http.createServer(app);
  initWss(server);
  
  const PORT = process.env.PORT || 3000;
  server.listen(PORT, () => {
    console.log(`\n✅  WA Webhook Receiver running`);
    console.log(`   Local:   http://localhost:${PORT}`);
    console.log(`   Webhook: http://localhost:${PORT}/webhook`);
    console.log(`   Token:   ${process.env.VERIFY_TOKEN || '(not set)'}\n`);
  });
}

module.exports = app;
