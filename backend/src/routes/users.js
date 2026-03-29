const express = require('express');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

// Get user achievements
router.get('/achievements', verifyToken, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const pageSize = parseInt(req.query.pageSize) || 20;
    const offset = (page - 1) * pageSize;

    const result = await query(
      `SELECT ua.id, ua.user_id, a.id as achievement_id, a.name, a.description, a.icon_url, 
              a.points_reward, ua.earned_at
       FROM user_achievements ua
       JOIN achievements a ON ua.achievement_id = a.id
       WHERE ua.user_id = $1
       ORDER BY ua.earned_at DESC
       LIMIT $2 OFFSET $3`,
      [req.user.id, pageSize, offset]
    );

    // Get total count
    const countResult = await query(
      'SELECT COUNT(*) as count FROM user_achievements WHERE user_id = $1',
      [req.user.id]
    );
    const total = parseInt(countResult.rows[0].count);

    res.json({
      data: result.rows,
      pagination: {
        page,
        pageSize,
        total,
        pages: Math.ceil(total / pageSize)
      }
    });
  } catch (err) {
    console.error('Get user achievements error:', err);
    res.status(500).json({ error: 'Failed to fetch achievements' });
  }
});

// Get user points
router.get('/points', verifyToken, async (req, res) => {
  try {
    const result = await query(
      'SELECT total_points, month_points, week_points FROM user_points WHERE user_id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User points not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Get user points error:', err);
    res.status(500).json({ error: 'Failed to fetch points' });
  }
});

// Get user profile
router.get('/me', verifyToken, async (req, res) => {
  try {
    const result = await query(
      'SELECT id, email, full_name, role, profile_picture_url, bio, phone_number, location, created_at FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Get user profile error:', err);
    res.status(500).json({ error: 'Failed to fetch user profile' });
  }
});

// Update user profile
router.put('/me', verifyToken, async (req, res) => {
  try {
    const { full_name, bio, phone_number, location, profile_picture_url } = req.body;

    const result = await query(
      `UPDATE users SET full_name = COALESCE($1, full_name), 
                       bio = COALESCE($2, bio),
                       phone_number = COALESCE($3, phone_number),
                       location = COALESCE($4, location),
                       profile_picture_url = COALESCE($5, profile_picture_url),
                       updated_at = CURRENT_TIMESTAMP
      WHERE id = $6
      RETURNING id, email, full_name, role, bio, phone_number, location, profile_picture_url`,
      [full_name, bio, phone_number, location, profile_picture_url, req.user.id]
    );

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Update user profile error:', err);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

module.exports = router;
