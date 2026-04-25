const Stripe = require('stripe');

class StripeService {
  constructor() {
    this.secretKey = process.env.STRIPE_SECRET_KEY;
    this.webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
    this.publishableKey = process.env.STRIPE_PUBLISHABLE_KEY;
    this.client = this.secretKey ? new Stripe(this.secretKey) : null;
  }

  ensureConfigured() {
    if (!this.client) {
      throw new Error('Stripe is not configured. Set STRIPE_SECRET_KEY.');
    }
  }

  async createCheckoutSession({
    email,
    amount,
    currency = 'usd',
    reference,
    description,
    metadata = {},
    successUrl,
    cancelUrl,
  }) {
    this.ensureConfigured();

    const session = await this.client.checkout.sessions.create({
      mode: 'payment',
      customer_email: email,
      success_url: successUrl,
      cancel_url: cancelUrl,
      payment_method_types: ['card'],
      metadata: {
        paymentReference: reference,
        ...Object.fromEntries(
          Object.entries(metadata).map(([key, value]) => [key, String(value)])
        ),
      },
      line_items: [
        {
          quantity: 1,
          price_data: {
            currency,
            unit_amount: Math.round(Number(amount) * 100),
            product_data: {
              name: description || 'ImpactKnowledge payment',
            },
          },
        },
      ],
    });

    return {
      success: true,
      sessionId: session.id,
      paymentUrl: session.url,
      accessCode: session.id,
      status: session.payment_status,
    };
  }

  async retrieveCheckoutSession(sessionId) {
    this.ensureConfigured();

    return this.client.checkout.sessions.retrieve(sessionId, {
      expand: ['payment_intent.latest_charge'],
    });
  }

  async verifyCheckoutSession(sessionId) {
    const session = await this.retrieveCheckoutSession(sessionId);
    const latestCharge = session.payment_intent?.latest_charge;

    return {
      success: session.payment_status === 'paid',
      status: session.payment_status,
      sessionId: session.id,
      paymentIntentId:
        typeof session.payment_intent === 'string'
          ? session.payment_intent
          : session.payment_intent?.id,
      receiptUrl: latestCharge?.receipt_url || null,
      paidAt: session.payment_status === 'paid' ? new Date().toISOString() : null,
      metadata: session.metadata || {},
    };
  }

  verifyWebhookSignature(signature, payload) {
    this.ensureConfigured();

    if (!this.webhookSecret) {
      throw new Error(
        'Stripe webhook verification is not configured. Set STRIPE_WEBHOOK_SECRET.'
      );
    }

    return this.client.webhooks.constructEvent(
      payload,
      signature,
      this.webhookSecret
    );
  }

  async createRefund({ paymentIntentId, amount, metadata = {}, reason }) {
    this.ensureConfigured();

    return this.client.refunds.create({
      payment_intent: paymentIntentId,
      amount: Math.round(Number(amount) * 100),
      reason: reason || undefined,
      metadata: Object.fromEntries(
        Object.entries(metadata).map(([key, value]) => [key, String(value)])
      ),
    });
  }
}

module.exports = StripeService;