const express = require('express');
const { query } = require('../database');

const router = express.Router();

// Get all membership tiers
router.get('/', async (req, res) => {
  try {
    const result = await query(
      'SELECT id, name, description, monthly_price, annual_price, benefits FROM membership_tiers ORDER BY monthly_price ASC'
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Get membership tiers error:', err);
    res.status(500).json({ error: 'Failed to fetch membership tiers' });
  }
});

// Get membership tier by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await query(
      'SELECT id, name, description, monthly_price, annual_price, benefits FROM membership_tiers WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Membership tier not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Get membership tier error:', err);
    res.status(500).json({ error: 'Failed to fetch membership tier' });
  }
});

module.exports = router;
