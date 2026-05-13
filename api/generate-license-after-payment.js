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

async function verifyMPPayment(paymentId) {
  const accessToken = process.env.MP_ACCESS_TOKEN;
  if (!accessToken) return { verified: false, reason: 'MP_ACCESS_TOKEN no configurado' };
  try {
    const res = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, {
      headers: { 'Authorization': `Bearer ${accessToken}` }
    });
    if (!res.ok) return { verified: false, reason: 'Error al verificar pago en MP' };
    const payment = await res.json();
    if (payment.status === 'approved') {
      return { verified: true, plan: payment.metadata?.plan || 'essential', email: payment.payer?.email || '' };
    }
    return { verified: false, reason: `Pago ${payment.status}` };
  } catch (e) {
    return { verified: false, reason: e.message };
  }
}

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { payment_id, plan: fallbackPlan } = req.body;

  let verified = false;
  let plan = fallbackPlan || 'essential';
  let buyerEmail = '';

  if (payment_id) {
    const result = await verifyMPPayment(payment_id);
    if (result.verified) {
      verified = true;
      plan = result.plan || fallbackPlan || 'essential';
      buyerEmail = result.email || '';
    } else {
      return res.json({ verified: false, key: null, error: result.reason || 'Pago no verificado' });
    }
  } else {
    return res.json({ verified: false, key: null, error: 'No se recibió ID de pago' });
  }

  const supabase = createClient(
    process.env.SUPABASE_URL || 'https://qovtekqxruusqhscacqn.supabase.co',
    process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY
  );

  const key = generateKey(plan);
  const { error: insertError } = await supabase.from('license_keys').insert({
    key, plan, status: 'active',
    created_at: new Date().toISOString(),
    source: 'post-payment'
  });

  if (insertError) {
    return res.status(500).json({ verified: true, key: null, error: insertError.message });
  }

  if (buyerEmail && process.env.SENDGRID_API_KEY) {
    try {
      await fetch(`${req.headers.origin || 'https://leleoficial.vercel.app'}/api/email`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ key, plan, email: buyerEmail })
      });
    } catch (_) {}
  }

  return res.json({ verified: true, key, plan });
};
