const express = require('express');
const { query } = require('../database');

const router = express.Router();

// Get leaderboard
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const pageSize = parseInt(req.query.pageSize) || 50;
    const timeframe = req.query.timeframe || 'all'; // 'all', 'monthly', 'weekly'
    const offset = (page - 1) * pageSize;

    let orderColumn = 'total_points';
    if (timeframe === 'monthly') {
      orderColumn = 'month_points';
    } else if (timeframe === 'weekly') {
      orderColumn = 'week_points';
    }

    const result = await query(
      `SELECT up.user_id, u.full_name, u.profile_picture_url, 
              up.total_points, up.month_points, up.week_points,
              ROW_NUMBER() OVER (ORDER BY up.${orderColumn} DESC) as rank
       FROM user_points up
       JOIN users u ON up.user_id = u.id
       ORDER BY up.${orderColumn} DESC
       LIMIT $1 OFFSET $2`,
      [pageSize, offset]
    );

    // Get total count
    const countResult = await query('SELECT COUNT(*) as count FROM user_points');
    const total = parseInt(countResult.rows[0].count);

    res.json({
      data: result.rows,
      pagination: {
        page,
        pageSize,
        total,
        timeframe,
        pages: Math.ceil(total / pageSize)
      }
    });
  } catch (err) {
    console.error('Get leaderboard error:', err);
    res.status(500).json({ error: 'Failed to fetch leaderboard' });
  }
});

module.exports = router;
