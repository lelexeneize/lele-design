const crypto = require('crypto');
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://qovtekqxruusqhscacqn.supabase.co';
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY || 'sb_publishable_iZ9oKQoxTU0ui2kAUhCcLg_CrXpI1S2';
const ADMIN_SECRET = process.env.ADMIN_SECRET || 'n6PgGztTRf3ruweEicLB18Q0YyFAM5oh';

function generateKey(plan) {
  const prefix = plan.substring(0, 2).toUpperCase();
  const segments = [];
  for (let i = 0; i < 4; i++) {
    segments.push(crypto.randomBytes(3).toString('hex').toUpperCase());
  }
  return `${prefix}-${segments.join('-')}`;
}

module.exports = async (req, res) => {
  try {
    if (req.method !== 'POST') {
      return res.status(405).json({ error: 'Method not allowed' });
    }

    const adminSecret = req.body.adminSecret;
    if (!adminSecret || adminSecret !== ADMIN_SECRET) {
      return res.status(401).json({ error: 'Se requiere autorización' });
    }

    const { plan = 'essential', count = 1 } = req.body;
    const keys = [];
    const errors = [];

    for (let i = 0; i < count; i++) {
      const key = generateKey(plan);
      const r = await fetch(`${SUPABASE_URL}/rest/v1/license_keys`, {
        method: 'POST',
        headers: {
          'apikey': SUPABASE_KEY,
          'Authorization': `Bearer ${SUPABASE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal'
        },
        body: JSON.stringify({ key, plan, status: 'active', max_activations: 3, activated_devices: [] })
      });
      if (r.ok) {
        keys.push(key);
      } else {
        const errBody = await r.text();
        errors.push(errBody.substring(0, 100));
      }
    }

    const result = { created: keys.length, keys };
    if (errors.length > 0) result.error = errors.join(' | ');
    return res.status(keys.length > 0 ? 200 : 500).json(result);
  } catch (e) {
    return res.status(500).json({ error: e.message || 'Error interno' });
  }
};
