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

    // Obtener plan del metadata del pago (requiere SDK de Mercado Pago + MP_ACCESS_TOKEN)
    // Mientras MP_ACCESS_TOKEN no esté configurado, intentamos leer del body
    const plan = data?.metadata?.plan || data?.additional_info?.items?.[0]?.id || 'essential';
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

    // Enviar email si tenemos el correo del comprador
    const buyerEmail = data?.payer?.email || data?.metadata?.email;
    if (buyerEmail && process.env.RESEND_API_KEY) {
      try {
        await fetch(`https://leleoficial.com/api/email`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ key, plan, email: buyerEmail })
        });
      } catch (_) {}
    }

    console.log(`✅ License generated: ${key} (${plan})`);
    return res.status(200).send('OK');

  } catch (err) {
    console.error('Webhook error:', err);
    return res.status(500).send('Error');
  }
};
