// ─── Sabina Optimizer — License Key Validation ───────────
// Vercel Serverless Function
// GET /api/validate-license?key=XXXX-XXXX-XXXX
// ─────────────────────────────────────────────────────────

const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL || 'https://qovtekqxruusqhscacqn.supabase.co',
  process.env.SUPABASE_ANON_KEY || 'sb_publishable_iZ9oKQoxTU0ui2kAUhCcLg_CrXpI1S2'
);

module.exports = async (req, res) => {
  const { key } = req.query;

  if (!key) {
    return res.status(400).json({ valid: false, error: 'Key requerida' });
  }

  try {
    const { data, error } = await supabase
      .from('license_keys')
      .select('*')
      .eq('key', key)
      .single();

    if (error || !data) {
      return res.status(404).json({ valid: false, error: 'Licencia no encontrada' });
    }

    if (data.status !== 'active') {
      return res.status(403).json({ valid: false, error: 'Licencia ' + data.status });
    }

    // Marcar como usada
    await supabase
      .from('license_keys')
      .update({ status: 'used', used_at: new Date().toISOString() })
      .eq('key', data.key);

    return res.json({
      valid: true,
      plan: data.plan,
      expires: data.expires_at
    });

  } catch (err) {
    return res.status(500).json({ valid: false, error: err.message });
  }
};
