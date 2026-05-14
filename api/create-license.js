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

  // Verify admin JWT
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return res.status(401).json({ error: 'Se requiere autorización' });
  }
  const token = authHeader.replace('Bearer ', '');

  const supabase = createClient(
    process.env.SUPABASE_URL || 'https://qovtekqxruusqhscacqn.supabase.co',
    process.env.SUPABASE_ANON_KEY
  );

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
  } catch (e) {
    return res.status(500).json({ error: 'Error verificando autorización' });
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
