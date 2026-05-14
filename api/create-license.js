const { createClient } = require('@supabase/supabase-js');
const crypto = require('crypto');

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

  // Use service key (bypass RLS) when available, fallback to anon key
  const supabase = createClient(
    process.env.SUPABASE_URL || 'https://qovtekqxruusqhscacqn.supabase.co',
    process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY
  );

  // Verify admin: JWT from header OR admin secret from body
  const authHeader = req.headers.authorization;
  const adminSecret = req.body.adminSecret;
  let adminUserId = null;

  if (authHeader) {
    const token = authHeader.replace('Bearer ', '');
    try {
      const { data: { user }, error: authError } = await supabase.auth.getUser(token);
      if (authError || !user) {
        return res.status(401).json({ error: 'Token inválido o expirado' });
      }
      const { data: profile } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();
      if (!profile || profile.role !== 'admin') {
        return res.status(403).json({ error: 'Se requiere rol de administrador' });
      }
      adminUserId = user.id;
    } catch (e) {
      return res.status(500).json({ error: 'Error verificando autorización' });
    }
  } else if (adminSecret && adminSecret === (process.env.ADMIN_SECRET || 'n6PgGztTRf3ruweEicLB18Q0YyFAM5oh')) {
    // Admin secret accepted - skip JWT verification
  } else {
    return res.status(401).json({ error: 'Se requiere autorización (token JWT o adminSecret)' });
  }

  const { plan = 'essential', count = 1 } = req.body;

  const keys = [];
  const errors = [];
  for (let i = 0; i < count; i++) {
    const key = generateKey(plan);
    const maxAct = req.body.max_activations || 3;
    const { error } = await supabase.from('license_keys').insert({
      key: key,
      plan: plan,
      status: 'active',
      max_activations: maxAct,
      activated_devices: []
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
