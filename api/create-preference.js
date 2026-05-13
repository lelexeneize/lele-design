// ─── Mercado Pago — Create Payment Preference ────────────
// POST /api/create-preference
// Body: { plan: "essential"|"pro"|"elite" }
// ─────────────────────────────────────────────────────────

const PLANS = {
  essential:  { title: 'Sabina Optimizer - Essential', price: 45000,  currency: 'ARS' },
  pro:        { title: 'Sabina Optimizer - Pro',       price: 65000,  currency: 'ARS' },
  elite:      { title: 'Sabina Optimizer - Elite',     price: 85000,  currency: 'ARS' },
  starter:    { title: 'Diseño - Starter',             price: 35000,  currency: 'ARS' },
  designpro:  { title: 'Diseño - Pro',                 price: 95000,  currency: 'ARS' },
  enterprise: { title: 'Diseño - Enterprise',          price: 239000, currency: 'ARS' }
};

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const accessToken = process.env.MP_ACCESS_TOKEN;
  if (!accessToken) {
    return res.status(500).json({ error: 'MP_ACCESS_TOKEN no configurado en Vercel' });
  }

  const { plan, email, name } = req.body;

  if (!plan || !PLANS[plan]) {
    return res.status(400).json({ error: 'Plan inválido. Opciones: essential, pro, elite' });
  }

  const planData = PLANS[plan];

  try {
    const preference = await fetch('https://api.mercadopago.com/checkout/preferences', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        items: [{
          title: planData.title,
          unit_price: planData.price,
          quantity: 1,
          currency_id: planData.currency
        }],
        payer: {
          name: name || 'Comprador',
          email: email || 'comprador@email.com'
        },
        back_urls: {
          success: 'https://leleoficial.vercel.app/pages/pago-exitoso.html',
          failure: 'https://leleoficial.vercel.app/pages/pago.html',
          pending: 'https://leleoficial.vercel.app/pages/pago.html'
        },
        auto_return: 'approved',
        notification_url: 'https://leleoficial.vercel.app/api/webhook',
        metadata: {
          plan: plan,
          email: email || 'comprador@email.com'
        }
      })
    });

    const data = await preference.json();

    if (data.id && data.init_point) {
      return res.json({
        id: data.id,
        init_point: data.init_point,
        plan: plan
      });
    } else {
      return res.status(500).json({ error: 'MP response inválido', detail: data });
    }

  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};
