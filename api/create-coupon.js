const SUPABASE_URL = process.env.SUPABASE_URL || 'https://qovtekqxruusqhscacqn.supabase.co';
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY || 'sb_publishable_iZ9oKQoxTU0ui2kAUhCcLg_CrXpI1S2';
const ADMIN_SECRET = process.env.ADMIN_SECRET || 'n6PgGztTRf3ruweEicLB18Q0YyFAM5oh';

module.exports = async (req, res) => {
  try {
    if (req.method === 'GET') {
      const r = await fetch(`${SUPABASE_URL}/rest/v1/coupons?select=*&order=created_at.desc`, {
        headers: { 'apikey': SUPABASE_KEY, 'Authorization': `Bearer ${SUPABASE_KEY}` }
      });
      return res.status(r.ok ? 200 : 500).json(r.ok ? await r.json() : { error: 'Error al obtener cupones' });
    }

    if (req.method !== 'POST') {
      return res.status(405).json({ error: 'Method not allowed' });
    }

    const adminSecret = req.body.adminSecret;
    if (!adminSecret || adminSecret !== ADMIN_SECRET) {
      return res.status(401).json({ error: 'Se requiere autorización' });
    }

    const { type = 'credits', value = 10, detail = '', count = 1, prefix = 'REGALO' } = req.body;
    const seg = () => Math.random().toString(36).substring(2, 6).toUpperCase();
    const codes = [];
    const errors = [];

    for (let i = 0; i < count; i++) {
      const code = (prefix + '-' + seg() + '-' + seg()).toUpperCase();
      const r = await fetch(`${SUPABASE_URL}/rest/v1/rpc/admin_insert_coupon`, {
        method: 'POST',
        headers: { 'apikey': SUPABASE_KEY, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          p_code: code,
          p_type: type,
          p_value: type === 'credits' ? value : 1,
          p_detail: type === 'license' ? detail : String(value)
        })
      });
      if (r.ok) {
        codes.push(code);
      } else {
        const errBody = await r.text();
        errors.push(errBody.substring(0, 200));
      }
    }

    const result = { created: codes.length, codes };
    if (errors.length > 0) result.error = errors.join(' | ');
    return res.status(codes.length > 0 ? 200 : 500).json(result);
  } catch (e) {
    return res.status(500).json({ error: e.message || 'Error interno' });
  }
};
