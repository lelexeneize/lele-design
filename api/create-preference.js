// ─── Mercado Pago — Create Payment Preference ────────────
// POST /api/create-preference
// Body: { plan: "essential"|"pro"|"elite" }
//
// REQUIERE: configurar MP_ACCESS_TOKEN en Vercel Environment Variables
// ─────────────────────────────────────────────────────────

const mercadopago = require('mercadopago');

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

  mercadopago.configurations.setAccessToken(accessToken);

  const { plan, email, name } = req.body;

  if (!plan || !PLANS[plan]) {
    return res.status(400).json({ error: 'Plan inválido. Opciones: essential, pro, elite' });
  }

  const planData = PLANS[plan];

  try {
    const preference = await mercadopago.preferences.create({
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
        success: 'https://leleoficial.com/pages/pago-exitoso.html',
        failure: 'https://leleoficial.com/pages/pago.html',
        pending: 'https://leleoficial.com/pages/pago.html'
      },
      auto_return: 'approved',
      notification_url: 'https://leleoficial.com/api/webhook.js'
    });

    return res.json({
      id: preference.body.id,
      init_point: preference.body.init_point,
      plan: plan
    });

  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};
