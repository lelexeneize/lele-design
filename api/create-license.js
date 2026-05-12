// ─── Admin: Create License Keys ──────────────────────────
// POST /api/create-license
// Body: { plan: "essential"|"pro"|"elite", count: 1 }
// ─────────────────────────────────────────────────────────

const { createClient } = require('@supabase/supabase-js');
const crypto = require('crypto');

const supabase = createClient(
  process.env.SUPABASE_URL || 'https://qovtekqxruusqhscacqn.supabase.co',
  process.env.SUPABASE_ANON_KEY
);

function generateKey(plan) {
  const prefix = plan.substring(0, 2).toUpperCase();
  const segments = [];
  for (let i = 0; i < 4; i++) {
    segments.push(crypto.randomBytes(3).toString('hex').toUpperCase());
  }
  return `${prefix}-${segments.join('-')}`;
}

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { plan = 'essential', count = 1 } = req.body;

  const keys = [];
  const errors = [];
  for (let i = 0; i < count; i++) {
    const key = generateKey(plan);
    const { error } = await supabase.from('license_keys').insert({
      key: key,
      plan: plan,
      status: 'active'
    });
    if (error) {
      errors.push(error.message);
    } else {
      keys.push(key);
    }
  }

  if (errors.length > 0) {
    return res.json({ created: keys.length, keys, error: errors.join(' | ') });
  }
  return res.json({ created: keys.length, keys });
};
