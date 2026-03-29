const express = require('express');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

// Get all achievements
router.get('/', async (req, res) => {
  try {
    const result = await query(
      'SELECT id, name, description, icon_url, points_reward, criteria FROM achievements ORDER BY points_reward DESC'
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Get achievements error:', err);
    res.status(500).json({ error: 'Failed to fetch achievements' });
  }
});

// Get achievement by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await query(
      'SELECT id, name, description, icon_url, points_reward, criteria FROM achievements WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Achievement not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Get achievement error:', err);
    res.status(500).json({ error: 'Failed to fetch achievement' });
  }
});

module.exports = router;
