const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

// Ensure data directory exists
const dataDir = path.join(__dirname, '../data');
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

const dbPath = path.join(dataDir, 'messages.db');
const db = new Database(dbPath);

// Enable foreign keys
db.pragma('foreign_keys = ON');

// Create tables
db.exec(`
  CREATE TABLE IF NOT EXISTS messages (
    id TEXT PRIMARY KEY,
    from_phone TEXT NOT NULL,
    from_name TEXT,
    type TEXT,
    text TEXT,
    timestamp INTEGER,
    raw_data TEXT,
    received_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS statuses (
    id TEXT PRIMARY KEY,
    message_id TEXT,
    status TEXT,
    timestamp INTEGER,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (message_id) REFERENCES messages(id)
  );

  CREATE INDEX IF NOT EXISTS idx_messages_phone ON messages(from_phone);
  CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages(timestamp);
  CREATE INDEX IF NOT EXISTS idx_statuses_message ON statuses(message_id);
`);

function saveMessage(msg) {
  try {
    const stmt = db.prepare(`
      INSERT INTO messages (id, from_phone, from_name, type, text, timestamp, raw_data)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `);
    
    stmt.run(
      msg.id,
      msg.from,
      msg.name,
      msg.type,
      msg.text,
      msg.timestamp,
      JSON.stringify(msg.raw)
    );
    
    console.log('[DB] Message saved:', msg.id);
  } catch (err) {
    console.error('[DB] Error saving message:', err.message);
  }
}

function saveStatus(status) {
  try {
    const stmt = db.prepare(`
      INSERT INTO statuses (id, message_id, status, timestamp)
      VALUES (?, ?, ?, ?)
    `);
    
    stmt.run(
      status.id,
      status.message_id,
      status.status,
      status.timestamp
    );
    
    console.log('[DB] Status saved:', status.id);
  } catch (err) {
    console.error('[DB] Error saving status:', err.message);
  }
}

function getMessages(limit = 50, offset = 0) {
  try {
    const stmt = db.prepare(`
      SELECT * FROM messages
      ORDER BY timestamp DESC
      LIMIT ? OFFSET ?
    `);
    
    return stmt.all(limit, offset);
  } catch (err) {
    console.error('[DB] Error fetching messages:', err.message);
    return [];
  }
}

function close() {
  db.close();
}

module.exports = {
  db,
  saveMessage,
  saveStatus,
  getMessages,
  close
};
