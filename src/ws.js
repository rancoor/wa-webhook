const WebSocket = require('ws');

let wss;

function initWss(server) {
  wss = new WebSocket.Server({ server, path: '/ws' });

  wss.on('connection', (ws, req) => {
    const ip = req.socket.remoteAddress;
    console.log(`[WS] Client connected from ${ip} — total: ${wss.clients.size}`);

    ws.send(JSON.stringify({ event: 'connected', data: { message: 'WebSocket connected' } }));

    ws.on('close', () => {
      console.log(`[WS] Client disconnected — total: ${wss.clients.size}`);
    });

    ws.on('error', err => console.error('[WS] Error:', err.message));
  });

  console.log('[WS] WebSocket server initialized at /ws');
}

function broadcast(payload) {
  if (!wss) return;
  const msg = JSON.stringify(payload);
  let successCount = 0;
  let errorCount = 0;

  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      try {
        client.send(msg);
        successCount++;
      } catch (err) {
        console.error('[WS] Broadcast error:', err.message);
        errorCount++;
      }
    }
  });

  if (errorCount > 0) {
    console.warn(`[WS] Broadcast: ${successCount} sent, ${errorCount} failed`);
  }
}

module.exports = { initWss, broadcast };
