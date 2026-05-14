const { createClient } = require('@supabase/supabase-js');

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
    } catch (e) {
      return res.status(500).json({ error: 'Error verificando autorización' });
    }
  } else if (adminSecret && adminSecret === (process.env.ADMIN_SECRET || 'n6PgGztTRf3ruweEicLB18Q0YyFAM5oh')) {
    // Admin secret accepted - skip JWT verification
  } else {
    return res.status(401).json({ error: 'Se requiere autorización (token JWT o adminSecret)' });
  }

  const { type = 'credits', value = 10, detail = '', count = 1, prefix = 'REGALO' } = req.body;

  function generateCode(pref) {
    const seg = () => Math.random().toString(36).substring(2, 6).toUpperCase();
    return (pref || 'REGALO') + '-' + seg() + '-' + seg();
  }

  const codes = [];
  const errors = [];
  for (let i = 0; i < count; i++) {
    const code = generateCode(prefix);
    const { error } = await supabase.from('coupons').insert({
      code,
      type,
      value: type === 'credits' ? value : 1,
      detail: type === 'license' ? detail : value.toString(),
      status: 'active',
      created_by: user.id
    });
    if (error) {
      errors.push(error.message);
    } else {
      codes.push(code);
    }
  }

  if (errors.length > 0) {
    return res.json({ created: codes.length, codes, error: errors.join(' | ') });
  }
  return res.json({ created: codes.length, codes });
};
