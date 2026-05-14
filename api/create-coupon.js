const SUPABASE_URL = process.env.SUPABASE_URL || 'https://qovtekqxruusqhscacqn.supabase.co';
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY;
const ADMIN_SECRET = process.env.ADMIN_SECRET || 'n6PgGztTRf3ruweEicLB18Q0YyFAM5oh';

function json(res, status, data) {
  res.status(status).json(data);
}

module.exports = async (req, res) => {
  try {
    // GET: return all coupons (admin stats)
    if (req.method === 'GET') {
      const r = await fetch(`${SUPABASE_URL}/rest/v1/coupons?select=*&order=created_at.desc`, {
        headers: { 'apikey': SUPABASE_KEY, 'Authorization': `Bearer ${SUPABASE_KEY}` }
      });
      const data = await r.json();
      return json(res, r.ok ? 200 : 500, data);
    }

    if (req.method !== 'POST') {
      return json(res, 405, { error: 'Method not allowed' });
    }

    // Verify admin
    const authHeader = req.headers.authorization;
    const adminSecret = req.body.adminSecret;

    if (adminSecret && adminSecret === ADMIN_SECRET) {
      // Admin secret accepted
    } else if (authHeader) {
      const token = authHeader.replace('Bearer ', '');
      const r = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
        headers: { 'apikey': SUPABASE_KEY, 'Authorization': `Bearer ${token}` }
      });
      if (!r.ok) return json(res, 401, { error: 'Token inválido o expirado' });
      const user = await r.json();
      const r2 = await fetch(`${SUPABASE_URL}/rest/v1/profiles?select=role&id=eq.${user.id}`, {
        headers: { 'apikey': SUPABASE_KEY, 'Authorization': `Bearer ${SUPABASE_KEY}` }
      });
      const profiles = await r2.json();
      if (!profiles?.[0] || profiles[0].role !== 'admin') {
        return json(res, 403, { error: 'Se requiere rol de administrador' });
      }
    } else {
      return json(res, 401, { error: 'Se requiere autorización' });
    }

    const { type = 'credits', value = 10, detail = '', count = 1, prefix = 'REGALO' } = req.body;
    const seg = () => Math.random().toString(36).substring(2, 6).toUpperCase();
    const codes = [];

    for (let i = 0; i < count; i++) {
      const code = (prefix + '-' + seg() + '-' + seg()).toUpperCase();
      const body = {
        code,
        type,
        value: type === 'credits' ? value : 1,
        detail: type === 'license' ? detail : String(value),
        status: 'active'
      };
      const r = await fetch(`${SUPABASE_URL}/rest/v1/coupons`, {
        method: 'POST',
        headers: {
          'apikey': SUPABASE_KEY,
          'Authorization': `Bearer ${SUPABASE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal'
        },
        body: JSON.stringify(body)
      });
      if (r.ok) codes.push(code);
    }

    return json(res, 200, { created: codes.length, codes });
  } catch (e) {
    return json(res, 500, { error: e.message || 'Error interno' });
  }
};
