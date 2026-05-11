// ─── Mercado Pago Webhook ────────────────────────────────
// Cuando un pago se aprueba, genera automáticamente la license key
// ─────────────────────────────────────────────────────────

const { createClient } = require('@supabase/supabase-js');
const crypto = require('crypto');

const supabase = createClient(
  process.env.SUPABASE_URL || 'https://qovtekqxruusqhscacqn.supabase.co',
  process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY
);

function generateLicenseKey(plan) {
  const prefix = plan.substring(0, 2).toUpperCase();
  const segments = [];
  for (let i = 0; i < 4; i++) {
    segments.push(crypto.randomBytes(3).toString('hex').toUpperCase());
  }
  return `${prefix}-${segments.join('-')}`;
}

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).send('Method not allowed');
  }

  const { action, data } = req.body;

  // Solo procesar pagos aprobados
  if (action !== 'payment.updated' && action !== 'payment.created') {
    return res.status(200).send('OK');
  }

  try {
    const paymentId = data?.id;
    if (!paymentId) return res.status(200).send('OK');

    // Obtener datos del pago (necesitarías el SDK)
    // Por ahora, creamos un placeholder
    const plan = 'essential'; // Esto vendría del payment metadata
    const key = generateLicenseKey(plan);

    const { error } = await supabase.from('license_keys').insert({
      key: key,
      plan: plan,
      status: 'active',
      created_at: new Date().toISOString()
    });

    if (error) {
      console.error('Error inserting license:', error);
      return res.status(500).send('Error');
    }

    // Enviar email con la key al comprador
    // (integrar con Resend/SendGrid si se desea)

    console.log(`✅ License generated: ${key} (${plan})`);
    return res.status(200).send('OK');

  } catch (err) {
    console.error('Webhook error:', err);
    return res.status(500).send('Error');
  }
};
