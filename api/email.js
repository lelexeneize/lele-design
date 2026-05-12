const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL || 'https://qovtekqxruusqhscacqn.supabase.co',
  process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY
);

module.exports = async (req, res) => {
  if (req.method !== 'POST') return res.status(405).send('Method not allowed');

  const { key, plan, email } = req.body;
  if (!key || !email) return res.status(400).json({ error: 'Faltan datos' });

  const planLabels = { essential: 'Essential', pro: 'Pro', elite: 'Elite', starter: 'Starter', designpro: 'Pro', enterprise: 'Enterprise' };

  try {
    const RESEND_API_KEY = process.env.RESEND_API_KEY;
    if (!RESEND_API_KEY) {
      return res.status(200).json({ sent: false, note: 'RESEND_API_KEY no configurada' });
    }

    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        from: 'Lele Design <noreply@leledesign.com>',
        to: email,
        subject: `Tu license key para Sabina Optimizer ${planLabels[plan] || plan}`,
        html: `
          <div style="font-family: Inter, Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px; background: #0a0a0f; border-radius: 16px; border: 1px solid #2a2a3a;">
            <div style="text-align: center; margin-bottom: 24px;">
              <span style="font-size: 28px; font-weight: 900; background: linear-gradient(135deg, #a855f7, #d946ef, #22d3ee); -webkit-background-clip: text; -webkit-text-fill-color: transparent;">LELE</span>
              <span style="color: #888; font-weight: 300;">Design</span>
            </div>
            <h1 style="color: white; font-size: 20px; text-align: center; margin-bottom: 8px;">Gracias por tu compra</h1>
            <p style="color: #888; text-align: center; margin-bottom: 24px;">Tu license key para Sabina Optimizer ${planLabels[plan] || plan}</p>
            <div style="background: #1a1a2e; border: 1px solid #2a2a3a; border-radius: 12px; padding: 20px; text-align: center; margin-bottom: 24px;">
              <p style="color: #888; font-size: 12px; margin-bottom: 8px; text-transform: uppercase; letter-spacing: 1px;">License Key</p>
              <p style="color: #a855f7; font-size: 22px; font-weight: 700; font-family: monospace; letter-spacing: 2px; margin: 0;">${key}</p>
            </div>
            <a href="https://leledesign.vercel.app/pages/descargar.html" style="display: block; text-align: center; padding: 14px; background: linear-gradient(135deg, #7c3aed, #d946ef); color: white; border-radius: 9999px; text-decoration: none; font-weight: 600; font-size: 14px; margin-bottom: 20px;">Descargar Sabina Optimizer</a>
            <p style="color: #555; font-size: 12px; text-align: center;">Ejecutá el .exe como Administrador e ingresá tu license key para desbloquear todas las optimizaciones.</p>
          </div>
        `
      })
    });

    const result = await response.json();
    if (!response.ok) throw new Error(result.message || 'Error al enviar');

    await supabase.from('license_keys').update({ emailed_at: new Date().toISOString() }).eq('key', key);

    return res.json({ sent: true, id: result.id });
  } catch (err) {
    console.error('Email error:', err);
    return res.status(200).json({ sent: false, error: err.message });
  }
};
