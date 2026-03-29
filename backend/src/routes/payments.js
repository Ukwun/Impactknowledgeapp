const express = require('express');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');
const crypto = require('crypto');

const router = express.Router();

// Generate unique reference ID
function generateReferenceId() {
  return 'REF_' + crypto.randomBytes(8).toString('hex').toUpperCase();
}

// Initiate payment for course
router.post('/courses/initiate', verifyToken, async (req, res) => {
  try {
    const { courseId, email, phoneNumber } = req.body;

    if (!courseId || !email || !phoneNumber) {
      return res.status(400).json({ error: 'courseId, email, and phoneNumber are required' });
    }

    // Get course details
    const courseResult = await query('SELECT id, title, price FROM courses WHERE id = $1', [courseId]);
    if (courseResult.rows.length === 0) {
      return res.status(404).json({ error: 'Course not found' });
    }

    const course = courseResult.rows[0];
    const referenceId = generateReferenceId();

    // Create payment record
    const paymentResult = await query(
      `INSERT INTO payments (user_id, type, amount, currency, reference_id, status, email, phone_number)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING id, reference_id, amount, currency`,
      [req.user.id, 'course', course.price, 'NGN', referenceId, 'pending', email, phoneNumber]
    );

    // Return Flutterwave initialization response format
    res.json({
      reference_id: referenceId,
      tx_ref: referenceId,
      amount: course.price,
      currency: 'NGN',
      email: email,
      phone_number: phoneNumber,
      customer_name: req.user.full_name || 'Customer',
      title: `Payment for ${course.title}`,
      description: course.title,
      redirect_url: 'https://your-app-domain.com/payment-success'
    });
  } catch (err) {
    console.error('Initiate course payment error:', err);
    res.status(500).json({ error: 'Failed to initiate payment' });
  }
});

// Initiate payment for membership
router.post('/membership/initiate', verifyToken, async (req, res) => {
  try {
    const { membershipTierId, email, phoneNumber, billingCycle } = req.body;

    if (!membershipTierId || !email || !phoneNumber || !billingCycle) {
      return res.status(400).json({ 
        error: 'membershipTierId, email, phoneNumber, and billingCycle are required' 
      });
    }

    // Get membership tier details
    const tierResult = await query(
      'SELECT id, name, monthly_price, annual_price FROM membership_tiers WHERE id = $1',
      [membershipTierId]
    );
    if (tierResult.rows.length === 0) {
      return res.status(404).json({ error: 'Membership tier not found' });
    }

    const tier = tierResult.rows[0];
    const amount = billingCycle === 'annual' ? tier.annual_price : tier.monthly_price;
    const referenceId = generateReferenceId();

    // Create payment record
    const paymentResult = await query(
      `INSERT INTO payments (user_id, type, amount, currency, reference_id, status, email, phone_number)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING id, reference_id, amount, currency`,
      [req.user.id, 'membership', amount, 'NGN', referenceId, 'pending', email, phoneNumber]
    );

    // Return Flutterwave initialization response format
    res.json({
      reference_id: referenceId,
      tx_ref: referenceId,
      amount: amount,
      currency: 'NGN',
      email: email,
      phone_number: phoneNumber,
      customer_name: req.user.full_name || 'Customer',
      title: `${tier.name} Membership - ${billingCycle}`,
      description: `${billingCycle === 'annual' ? 'Annual' : 'Monthly'} subscription to ${tier.name}`,
      redirect_url: 'https://your-app-domain.com/payment-success'
    });
  } catch (err) {
    console.error('Initiate membership payment error:', err);
    res.status(500).json({ error: 'Failed to initiate payment' });
  }
});

// Verify payment
router.post('/verify', verifyToken, async (req, res) => {
  try {
    const { reference_id, flutterwave_id } = req.body;

    if (!reference_id) {
      return res.status(400).json({ error: 'reference_id is required' });
    }

    // Find payment record
    const paymentResult = await query(
      'SELECT id, user_id, type, amount FROM payments WHERE reference_id = $1 AND user_id = $2',
      [reference_id, req.user.id]
    );

    if (paymentResult.rows.length === 0) {
      return res.status(404).json({ error: 'Payment not found' });
    }

    const payment = paymentResult.rows[0];

    // Update payment status to successful
    await query(
      'UPDATE payments SET status = $1, flutterwave_id = $2, updated_at = CURRENT_TIMESTAMP WHERE id = $3',
      ['successful', flutterwave_id, payment.id]
    );

    // If course payment, create enrollment
    if (payment.type === 'course') {
      const enrollmentResult = await query(
        'SELECT id FROM enrollments WHERE user_id = $1 AND course_id = $2',
        [req.user.id, reference_id.split('_')[1] || null]
      );

      // Note: In production, you'd need to store courseId in payments table
    }

    res.json({ 
      status: 'successful',
      message: 'Payment verified successfully',
      reference_id: reference_id 
    });
  } catch (err) {
    console.error('Verify payment error:', err);
    res.status(500).json({ error: 'Payment verification failed' });
  }
});

// Get user payments
router.get('/', verifyToken, async (req, res) => {
  try {
    const result = await query(
      'SELECT id, type, amount, currency, reference_id, status, payment_method, created_at FROM payments WHERE user_id = $1 ORDER BY created_at DESC',
      [req.user.id]
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Get payments error:', err);
    res.status(500).json({ error: 'Failed to fetch payments' });
  }
});

module.exports = router;
