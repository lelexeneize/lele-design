const express = require('express');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json({ limit: '10mb' }));

// ─── Static files ─────────────────────────────────────────
app.use(express.static(path.join(__dirname)));

// ─── API mock handlers (local dev) ───────────────────────

// POST /api/create-coupon + GET /api/create-coupon
app.all('/api/create-coupon', (req, res) => {
  if (req.method === 'GET') {
    return res.json([]);
  }
  const { type = 'credits', value = 10, detail = '', count = 1, prefix = 'REGALO' } = req.body;
  const codes = [];
  for (let i = 0; i < count; i++) {
    const seg = () => Math.random().toString(36).substring(2, 6).toUpperCase();
    codes.push((prefix || 'REGALO') + '-' + seg() + '-' + seg());
  }
  res.json({ created: codes.length, codes });
});

// POST /api/create-license
app.post('/api/create-license', (req, res) => {
  const { plan = 'essential', count = 1 } = req.body;
  const keys = [];
  const chars = '0123456789ABCDEF';
  for (let i = 0; i < count; i++) {
    const prefix = plan.substring(0, 2).toUpperCase();
    const segments = [];
    for (let j = 0; j < 4; j++) {
      let seg = '';
      for (let k = 0; k < 6; k++) seg += chars[Math.floor(Math.random() * 16)];
      segments.push(seg);
    }
    keys.push(`${prefix}-${segments.join('-')}`);
  }
  res.json({ created: keys.length, keys });
});

// POST /api/create-preference
app.post('/api/create-preference', (req, res) => {
  const { plan = 'essential' } = req.body;
  const PLANS = {
    essential: { title: 'Sabina Optimizer - Essential', price: 45000 },
    pro: { title: 'Sabina Optimizer - Pro', price: 65000 },
    elite: { title: 'Sabina Optimizer - Elite', price: 85000 },
    starter: { title: 'Diseño - Starter', price: 35000 },
    designpro: { title: 'Diseño - Pro', price: 95000 },
    enterprise: { title: 'Diseño - Enterprise', price: 239000 }
  };
  const p = PLANS[plan];
  if (!p) return res.status(400).json({ error: 'Plan inválido' });
  res.json({
    id: 'local-' + Date.now(),
    init_point: `http://localhost:${PORT}/pages/pago-exitoso.html?plan=${plan}`,
    plan
  });
});

// POST /api/email
app.post('/api/email', (req, res) => {
  console.log('📧 Email (mock):', req.body);
  res.json({ sent: true, note: 'Mock email sent (local dev)' });
});

// POST /api/webhook
app.post('/api/webhook', (req, res) => {
  console.log('🔔 Webhook (mock):', req.body?.action);
  res.json({ ok: true, key: 'MOCK-LOCAL-DEV-KEY', plan: req.body?.data?.metadata?.plan || 'essential' });
});

// GET /api/validate-license
app.get('/api/validate-license', (req, res) => {
  const { key } = req.query;
  if (!key) return res.status(400).json({ valid: false, error: 'Key requerida' });
  res.json({ valid: true, plan: 'essential', key });
});

// ─── Fallback a index.html ───────────────────────────────
app.get('*', (req, res) => {
  const filePath = path.join(__dirname, req.path === '/' ? 'index.html' : req.path);
  if (fs.existsSync(filePath)) {
    return res.sendFile(filePath);
  }
  res.redirect('/');
});

app.listen(PORT, () => {
  console.log(`\n  🚀 Lele Oficial — Servidor local iniciado`);
  console.log(`  📍 http://localhost:${PORT}`);
  console.log(`  📍 http://localhost:${PORT}/pages/optimizer.html`);
  console.log(`  📍 http://localhost:${PORT}/pages/login.html`);
  console.log(`\n  Presioná Ctrl+C para detener\n`);
});
