/**
 * Content Moderation Routes
 * Handles flagging, reporting, and resolution of flagged content
 */

const express = require('express');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');
const router = express.Router();

// ============================================
// USER ENDPOINTS - Report/Flag Content
// ============================================

/**
 * POST /api/moderation/flag
 * User reports flagged content
 * Body: { content_type, content_id, reason, description }
 */
router.post('/flag', verifyToken, async (req, res) => {
  try {
    const { content_type, content_id, reason, description } = req.body;
    const user_id = req.user.id;

    // Validate input
    if (!content_type || !content_id || !reason) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: content_type, content_id, reason'
      });
    }

    const validTypes = ['course', 'lesson', 'comment', 'user', 'assignment'];
    if (!validTypes.includes(content_type)) {
      return res.status(400).json({
        success: false,
        error: `Invalid content_type. Must be one of: ${validTypes.join(', ')}`
      });
    }

    const validReasons = ['spam', 'inappropriate', 'misleading', 'copyright', 'other'];
    if (!validReasons.includes(reason)) {
      return res.status(400).json({
        success: false,
        error: `Invalid reason. Must be one of: ${validReasons.join(', ')}`
      });
    }

    // Check if user already flagged this content
    const existingFlag = await query(
      `SELECT id FROM content_flags 
       WHERE reported_by = $1 AND content_type = $2 AND content_id = $3 AND status = 'pending'`,
      [user_id, content_type, content_id]
    );

    if (existingFlag.rows.length > 0) {
      return res.status(400).json({
        success: false,
        error: 'You have already reported this content. We are reviewing it.'
      });
    }

    // Create flag
    const result = await query(
      `INSERT INTO content_flags 
       (reported_by, content_type, content_id, reason, description, status, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, 'pending', NOW(), NOW())
       RETURNING id, created_at, status`,
      [user_id, content_type, content_id, reason, description || null]
    );

    res.status(201).json({
      success: true,
      message: 'Thank you for reporting this content. Our moderation team will review it.',
      flag_id: result.rows[0].id,
      created_at: result.rows[0].created_at
    });
  } catch (err) {
    console.error('Flag content error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/moderation/my-flags
 * User views their reported content
 */
router.get('/my-flags', verifyToken, async (req, res) => {
  try {
    const user_id = req.user.id;
    const { limit = 20, offset = 0 } = req.query;

    const result = await query(
      `SELECT id, content_type, content_id, reason, status, created_at, updated_at
       FROM content_flags
       WHERE reported_by = $1
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [user_id, parseInt(limit), parseInt(offset)]
    );

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        limit: parseInt(limit),
        offset: parseInt(offset)
      }
    });
  } catch (err) {
    console.error('Get my flags error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ============================================
// ADMIN ENDPOINTS - Moderation Dashboard
// ============================================

/**
 * GET /api/admin/moderation/flags
 * Get all flagged content (admin only)
 */
router.get('/admin/flags', verifyToken, async (req, res) => {
  try {
    // Verify user is admin or moderator
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Only admins can access moderation dashboard'
      });
    }

    const { status = 'pending', limit = 20, offset = 0 } = req.query;

    let query_str = `SELECT 
      cf.id, cf.reported_by, cf.content_type, cf.content_id, 
      cf.reason, cf.description, cf.status, cf.created_at,
      u.full_name, u.email
      FROM content_flags cf
      LEFT JOIN users u ON cf.reported_by = u.id
      WHERE 1=1`;
    const params = [];

    if (status && status !== 'all') {
      query_str += ` AND cf.status = $${params.length + 1}`;
      params.push(status);
    }

    query_str += ` ORDER BY cf.created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(parseInt(limit), parseInt(offset));

    const result = await query(query_str, params);

    // Get total count
    let count_query = `SELECT COUNT(*) as total FROM content_flags WHERE 1=1`;
    const count_params = [];
    if (status && status !== 'all') {
      count_query += ` AND status = $${count_params.length + 1}`;
      count_params.push(status);
    }

    const countResult = await query(count_query, count_params);

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        total: parseInt(countResult.rows[0].total),
        limit: parseInt(limit),
        offset: parseInt(offset)
      }
    });
  } catch (err) {
    console.error('Get moderation flags error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * PUT /api/admin/moderation/flags/:flagId
 * Resolve a flag (approve/reject)
 */
router.put('/admin/flags/:flagId', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Only admins can resolve flags'
      });
    }

    const { flagId } = req.params;
    const { action, resolution_note } = req.body; // action: 'approved' or 'rejected'

    if (!['approved', 'rejected'].includes(action)) {
      return res.status(400).json({
        success: false,
        error: 'Action must be "approved" or "rejected"'
      });
    }

    // Update flag
    const result = await query(
      `UPDATE content_flags 
       SET status = $1, resolved_by = $2, resolution_note = $3, resolved_at = NOW(), updated_at = NOW()
       WHERE id = $4
       RETURNING id, status, content_type, content_id`,
      [action, req.user.id, resolution_note || null, flagId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Flag not found'
      });
    }

    // Log the moderation action
    await query(
      `INSERT INTO moderation_actions (flag_id, admin_id, action, details)
       VALUES ($1, $2, $3, $4)`,
      [flagId, req.user.id, action, resolution_note || null]
    );

    // If approved, potentially take action (e.g., hide content)
    if (action === 'approved') {
      const { content_type, content_id } = result.rows[0];
      
      // Mark content as flagged/hidden
      switch (content_type) {
        case 'course':
          await query(`UPDATE courses SET is_published = false WHERE id = $1`, [content_id]);
          break;
        case 'lesson':
          await query(`UPDATE lessons SET is_published = false WHERE id = $1`, [content_id]);
          break;
        case 'user':
          // Could disable user account
          await query(`UPDATE users SET is_active = false WHERE id = $1`, [content_id]);
          break;
      }
    }

    res.json({
      success: true,
      message: `Flag ${action} successfully`,
      flag_id: result.rows[0].id,
      status: action
    });
  } catch (err) {
    console.error('Resolve flag error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/admin/moderation/stats
 * Get moderation statistics
 */
router.get('/admin/stats', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Only admins can view moderation stats'
      });
    }

    const stats = await query(`
      SELECT 
        COUNT(*) as total_flags,
        SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_flags,
        SUM(CASE WHEN status = 'approved' THEN 1 ELSE 0 END) as approved_flags,
        SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END) as rejected_flags
      FROM content_flags
    `);

    const byType = await query(`
      SELECT content_type, COUNT(*) as count, status
      FROM content_flags
      GROUP BY content_type, status
      ORDER BY content_type, status
    `);

    res.json({
      success: true,
      stats: stats.rows[0],
      by_type: byType.rows
    });
  } catch (err) {
    console.error('Get moderation stats error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
