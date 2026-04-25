/**
 * Payment Routes - Card & Bank Transfers
 * Realistic payment processing with Paystack
 */

const express = require('express');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');
const StripeService = require('../services/stripe_service');
const NotificationTriggerService = require('../services/notification-trigger-service');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();
const stripe = new StripeService();
const DEFAULT_PAYMENT_CURRENCY = (process.env.DEFAULT_PAYMENT_CURRENCY || 'usd').toLowerCase();

function paymentMetadata(payment) {
  return payment && payment.metadata && typeof payment.metadata === 'object'
    ? payment.metadata
    : {};
}

async function grantPaymentAccess(payment) {
  if (payment.item_type === 'course') {
    await query(
      `INSERT INTO enrollments (user_id, course_id, enrollment_date)
       VALUES ($1, $2, NOW())
       ON CONFLICT (user_id, course_id) DO NOTHING`,
      [payment.user_id, payment.item_id]
    );
    return;
  }

  if (payment.item_type === 'membership') {
    await query(
      `UPDATE users
       SET membership_tier_id = $1, membership_expires_at = NOW() + INTERVAL '30 days'
       WHERE id = $2`,
      [payment.item_id, payment.user_id]
    );
  }
}

async function finalizePayment(payment, completion = {}) {
  if (payment.status === 'completed') {
    return payment;
  }

  const metadata = {
    ...paymentMetadata(payment),
    provider: 'stripe',
    providerSessionId:
      completion.sessionId || paymentMetadata(payment).providerSessionId || null,
    paymentIntentId:
      completion.paymentIntentId || paymentMetadata(payment).paymentIntentId || null,
    receiptUrl:
      completion.receiptUrl || paymentMetadata(payment).receiptUrl || null,
    completedAt: completion.paidAt || new Date().toISOString(),
  };

  await query(
    `UPDATE payments
     SET status = 'completed',
         payment_method = 'card',
         currency = COALESCE(currency, $1),
         updated_at = NOW(),
         metadata = $2::jsonb
     WHERE id = $3`,
    [DEFAULT_PAYMENT_CURRENCY, JSON.stringify(metadata), payment.id]
  );

  await grantPaymentAccess(payment);

  await query(
    `INSERT INTO user_activities (user_id, activity_type, metadata)
     VALUES ($1, 'PAYMENT_COMPLETED', $2::jsonb)`,
    [
      payment.user_id,
      JSON.stringify({
        reference: payment.reference,
        itemType: payment.item_type,
        itemId: payment.item_id,
        amount: payment.amount,
        currency: payment.currency || DEFAULT_PAYMENT_CURRENCY,
        paymentIntentId: metadata.paymentIntentId,
      }),
    ]
  );

  await NotificationTriggerService.notifyUser({
    userId: payment.user_id,
    title: 'Payment Successful',
    message:
      payment.item_type === 'course'
        ? 'Your payment was confirmed and course access is now active.'
        : 'Your payment was confirmed and your membership is now active.',
    type: 'payment',
    actionUrl: payment.item_type === 'course' ? '/courses' : '/profile',
    metadata: {
      action: 'payment_completed',
      resourceId: payment.id,
      reference: payment.reference,
      itemType: payment.item_type,
      itemId: payment.item_id,
      amount: payment.amount,
      receiptUrl: metadata.receiptUrl,
    },
    push: true,
  });

  return {
    ...payment,
    status: 'completed',
    metadata,
  };
}

// ============================================
// CARD PAYMENT ROUTES
// ============================================

/**
 * POST /api/payments/card/initialize
 * Initiate card payment for course/membership
 */
router.post('/card/initialize', verifyToken, async (req, res) => {
  try {
    const { itemType, itemId, amount, description } = req.body;
    const userId = req.user.id;

    if (!['course', 'membership'].includes(itemType)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid itemType. Must be "course" or "membership"',
      });
    }

    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Invalid amount',
      });
    }

    // Get user email
    const userResult = await query('SELECT email FROM users WHERE id = $1', [userId]);
    if (userResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    const userEmail = userResult.rows[0].email;
    const frontendBaseUrl = process.env.FRONTEND_URL || process.env.APP_URL || 'https://impactknowledge.app';

    // Create payment record
    const paymentReference = `PKG_${uuidv4().substring(0, 12).toUpperCase()}`;
    const paymentResult = await query(
      `INSERT INTO payments 
       (user_id, item_type, item_id, amount, currency, reference, status, payment_method, metadata, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, 'pending', 'card', $7, NOW())
       RETURNING id, reference`,
      [
        userId,
        itemType,
        itemId,
        amount,
        DEFAULT_PAYMENT_CURRENCY,
        paymentReference,
        JSON.stringify({
          description,
          provider: 'stripe',
          initiatedAt: new Date().toISOString(),
        }),
      ]
    );

    const stripeResponse = await stripe.createCheckoutSession({
      email: userEmail,
      amount,
      currency: DEFAULT_PAYMENT_CURRENCY,
      reference: paymentReference,
      description: description || `${itemType} purchase`,
      metadata: {
        itemType,
        itemId,
        userId,
      },
      successUrl: `${frontendBaseUrl}/payments/success?reference=${paymentReference}`,
      cancelUrl: `${frontendBaseUrl}/payments/cancel?reference=${paymentReference}`,
    });

    await query(
      `UPDATE payments
       SET metadata = jsonb_set(
         COALESCE(metadata, '{}'::jsonb),
         '{providerSessionId}',
         to_jsonb($1::text),
         true
       )
       WHERE id = $2`,
      [stripeResponse.sessionId, paymentResult.rows[0].id]
    );

    res.json({
      success: true,
      reference: paymentReference,
      paymentUrl: stripeResponse.paymentUrl,
      accessCode: stripeResponse.accessCode,
      amount,
    });
  } catch (err) {
    console.error('Initialize card payment error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/payments/card/verify
 * Verify card payment was successful
 */
router.post('/card/verify', verifyToken, async (req, res) => {
  try {
    const { reference } = req.body;
    const userId = req.user.id;

    if (!reference) {
      return res.status(400).json({
        success: false,
        error: 'Payment reference is required',
      });
    }

    // Get payment from DB
    const paymentResult = await query(
      `SELECT * FROM payments WHERE reference = $1 AND user_id = $2`,
      [reference, userId]
    );

    if (paymentResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Payment not found',
      });
    }

    const payment = paymentResult.rows[0];

    // Idempotency: if already completed, return success without re-granting.
    if (payment.status === 'completed') {
      return res.json({
        success: true,
        message: 'Payment already verified',
        status: 'completed',
        reference,
        amount: payment.amount,
      });
    }

    const metadata = paymentMetadata(payment);
    if (!metadata.providerSessionId) {
      return res.status(400).json({
        success: false,
        error: 'Payment is missing a Stripe checkout session reference',
      });
    }

    const verification = await stripe.verifyCheckoutSession(metadata.providerSessionId);

    if (!verification.success) {
      return res.json({
        success: false,
        error: 'Payment is not completed yet',
        status: verification.status || 'pending',
      });
    }

    await finalizePayment(payment, verification);

    res.json({
      success: true,
      message: 'Payment verified successfully',
      status: 'completed',
      reference,
      amount: payment.amount,
    });
  } catch (err) {
    console.error('Verify card payment error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ============================================
// BANK TRANSFER ROUTES
// ============================================

/**
 * POST /api/payments/bank-transfer/initialize
 * Initiate bank transfer (provides account details)
 */
router.post('/bank-transfer/initialize', verifyToken, async (req, res) => {
  try {
    const { itemType, itemId, amount, description } = req.body;
    const userId = req.user.id;

    if (!['course', 'membership'].includes(itemType)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid itemType',
      });
    }

    // Create payment record
    const paymentReference = `BT_${uuidv4().substring(0, 12).toUpperCase()}`;
    const paymentResult = await query(
      `INSERT INTO payments 
       (user_id, item_type, item_id, amount, reference, status, payment_method, metadata, created_at)
       VALUES ($1, $2, $3, $4, $5, 'pending', 'bank_transfer', $6, NOW())
       RETURNING id`,
      [
        userId,
        itemType,
        itemId,
        amount,
        paymentReference,
        JSON.stringify({
          description,
          initiatedAt: new Date().toISOString(),
          transferDeadline: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
        }),
      ]
    );

    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
    const bankDetails = {
      accountName: process.env.BUSINESS_BANK_ACCOUNT_NAME || 'ImpactKnowledge',
      accountNumber: process.env.BUSINESS_BANK_ACCOUNT_NUMBER || '0000000000',
      bankCode: process.env.BUSINESS_BANK_CODE || '',
      bankName: process.env.BUSINESS_BANK_NAME || 'Business Bank',
      amount,
      transferReference:
        `${process.env.BUSINESS_ACCOUNT_REFERENCE_PREFIX || 'IK'}_${paymentReference}`,
      description: description || 'ImpactKnowledge transfer payment',
    };

    res.json({
      success: true,
      reference: paymentReference,
      method: 'bank_transfer',
      bankDetails,
      expiresAt,
      instructions: [
        `Transfer exactly ${amount} to the account below`,
        `Use this reference in the transfer description: ${paymentReference}`,
        `Transfer must be completed within 24 hours`,
        `Payment will be automatically confirmed when we receive your transfer`,
      ],
    });
  } catch (err) {
    console.error('Initialize bank transfer error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/payments/bank-transfer/:reference/status
 * Check status of bank transfer
 */
router.get('/bank-transfer/:reference/status', verifyToken, async (req, res) => {
  try {
    const { reference } = req.params;
    const userId = req.user.id;

    const paymentResult = await query(
      `SELECT * FROM payments WHERE reference = $1 AND user_id = $2 AND payment_method = 'bank_transfer'`,
      [reference, userId]
    );

    if (paymentResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Transfer not found',
      });
    }

    const payment = paymentResult.rows[0];

    res.json({
      success: true,
      reference: payment.reference,
      status: payment.status,
      amount: payment.amount,
      message:
        payment.status === 'pending'
          ? 'Waiting for transfer confirmation'
          : `Transfer ${payment.status}`,
    });
  } catch (err) {
    console.error('Get transfer status error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ============================================
// PAYMENT HISTORY
// ============================================

/**
 * GET /api/payments/history
 * Get user's payment history
 */
router.get('/history', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { limit = 20, offset = 0 } = req.query;

    const result = await query(
      `SELECT id, reference, item_type, amount, status, payment_method, created_at
       FROM payments
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, parseInt(limit), parseInt(offset)]
    );

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        limit: parseInt(limit),
        offset: parseInt(offset),
      },
    });
  } catch (err) {
    console.error('Get payment history error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/payments/details/:reference
 * Get payment details
 */
router.get('/details/:reference', verifyToken, async (req, res) => {
  try {
    const { reference } = req.params;
    const userId = req.user.id;

    const result = await query(
      `SELECT * FROM payments WHERE reference = $1 AND user_id = $2`,
      [reference, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Payment not found',
      });
    }

    res.json({
      success: true,
      payment: result.rows[0],
    });
  } catch (err) {
    console.error('Get payment error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/payments/:reference/refund
 * Refund a completed payment (admin only)
 */
router.post('/:reference/refund', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Only admins can issue refunds',
      });
    }

    const { reference } = req.params;
    const { amount, reason } = req.body;

    const paymentResult = await query(
      `SELECT * FROM payments WHERE reference = $1`,
      [reference]
    );

    if (paymentResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Payment not found' });
    }

    const payment = paymentResult.rows[0];
    if (payment.status !== 'completed') {
      return res.status(400).json({
        success: false,
        error: 'Only completed payments can be refunded',
      });
    }

    const refundAmount = amount ? Number(amount) : Number(payment.amount);
    if (!refundAmount || refundAmount <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Invalid refund amount',
      });
    }

    const metadata = paymentMetadata(payment);
    let providerRefundId = null;
    if (metadata.paymentIntentId) {
      const refund = await stripe.createRefund({
        paymentIntentId: metadata.paymentIntentId,
        amount: refundAmount,
        reason,
        metadata: {
          reference,
          refundedBy: req.user.id,
        },
      });
      providerRefundId = refund.id;
    }

    await query(
      `UPDATE payments
       SET status = 'refunded',
           updated_at = NOW(),
           metadata = jsonb_set(
             COALESCE(metadata, '{}'::jsonb),
             '{refund}',
             to_jsonb($1::json),
             true
           )
       WHERE id = $2`,
      [
        JSON.stringify({
          refundedAt: new Date().toISOString(),
          refundedBy: req.user.id,
          amount: refundAmount,
          reason: reason || null,
          providerRefundId,
        }),
        payment.id,
      ]
    );

    await query(
      `INSERT INTO payment_refunds (payment_id, requested_by, amount, reason, status)
       VALUES ($1, $2, $3, $4, 'approved')`,
      [payment.id, req.user.id, refundAmount, reason || null]
    );

    await NotificationTriggerService.notifyUser({
      userId: payment.user_id,
      title: 'Payment Refunded',
      message:
        `Your payment ${reference} has been refunded.` +
        (reason ? ` Reason: ${reason}` : ''),
      type: 'payment',
      actionUrl: '/payments',
      metadata: {
        action: 'payment_refund',
        resourceId: payment.id,
        reference,
        amount: refundAmount,
        reason: reason || null,
      },
      push: true,
    });

    res.json({
      success: true,
      message: 'Refund approved and recorded',
      data: {
        reference,
        amount: refundAmount,
      },
    });
  } catch (err) {
    console.error('Refund payment error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/payments/webhook
 * Stripe webhook for payment confirmations
 */
router.post('/webhook', async (req, res) => {
  try {
    const signature = req.headers['stripe-signature'];
    const body = req.rawBody || JSON.stringify(req.body);
    const event = stripe.verifyWebhookSignature(signature, body);

    if (event.type === 'checkout.session.completed') {
      const session = event.data.object;
      const reference = session.metadata?.paymentReference;

      if (!reference) {
        return res.status(400).json({ success: false, error: 'Missing payment reference' });
      }

      const paymentResult = await query(`SELECT * FROM payments WHERE reference = $1`, [reference]);
      if (paymentResult.rows.length > 0) {
        await finalizePayment(paymentResult.rows[0], {
          sessionId: session.id,
          paymentIntentId:
            typeof session.payment_intent === 'string'
              ? session.payment_intent
              : session.payment_intent?.id,
          paidAt: new Date().toISOString(),
        });
        console.log(`Payment ${reference} confirmed via webhook`);
      }
    }

    res.json({ success: true });
  } catch (err) {
    console.error('Webhook error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
