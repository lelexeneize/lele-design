// ─── Sabina Optimizer — License Key Validation ───────────
// Vercel Serverless Function
// GET /api/validate-license?key=XXXX-XXXX-XXXX
// ─────────────────────────────────────────────────────────

const { createClient } = require('@supabase/supabase-js');

const supabaseAnon = createClient(
  process.env.SUPABASE_URL || 'https://qovtekqxruusqhscacqn.supabase.co',
  process.env.SUPABASE_ANON_KEY
);
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL || 'https://qovtekqxruusqhscacqn.supabase.co',
  process.env.SUPABASE_SERVICE_KEY
);

module.exports = async (req, res) => {
  const { key, device_id } = req.query;

  if (!key) {
    return res.status(400).json({ valid: false, error: 'Key requerida' });
  }

  try {
    const { data, error } = await supabaseAnon
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

    const maxAct = data.max_activations || 3;
    const devices = data.activated_devices || [];

    // Verificar límite de activaciones si se envía device_id
    if (device_id) {
      if (devices.includes(device_id)) {
        // Este dispositivo ya está registrado — permitir
      } else if (devices.length >= maxAct) {
        return res.status(403).json({
          valid: false,
          error: `Límite de activaciones alcanzado (${maxAct}/${maxAct}). Desactivá otro dispositivo desde el panel o contactá a soporte.`
        });
      }
    }

    // Actualizar last_validated_at y registrar device_id
    if (process.env.SUPABASE_SERVICE_KEY) {
      const updatePayload = { last_validated_at: new Date().toISOString() };
      if (device_id && !devices.includes(device_id)) {
        updatePayload.activated_devices = [...devices, device_id];
      }
      await supabaseAdmin
        .from('license_keys')
        .update(updatePayload)
        .eq('key', data.key);
    }

    return res.json({
      valid: true,
      plan: data.plan,
      expires: data.expires_at,
      activations: device_id ? (devices.includes(device_id) ? devices.length : devices.length + 1) : devices.length,
      max_activations: maxAct
    });

  } catch (err) {
    return res.status(500).json({ valid: false, error: err.message });
  }
};
