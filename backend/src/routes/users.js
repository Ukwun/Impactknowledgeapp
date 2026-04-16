const express = require('express');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');
const ActivityService = require('../services/activity-service');

const router = express.Router();

/**
 * GET /api/users/me
 * Get current user profile
 */
router.get('/me', verifyToken, async (req, res) => {
  try {
    const result = await query(
      'SELECT id, email, full_name, role, profile_picture_url, bio, phone_number, location, created_at FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * PUT /api/users/me
 * Update current user profile
 */
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

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
  try {
    if (req.user.role !== 'admin' && req.user.role !== 'facilitator') {
      return res.status(403).json({
        success: false,
        error: 'Only admins can list all users',
      });
    }

    const { role, search, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    let whereConditions = ['is_active = true'];
    const params = [];
    let paramCount = 1;

    if (role) {
      whereConditions.push(`role = $${paramCount}`);
      params.push(role);
      paramCount++;
    }

    if (search) {
      whereConditions.push(
        `(full_name ILIKE $${paramCount} OR email ILIKE $${paramCount})`
      );
      params.push(`%${search}%`);
      params.push(`%${search}%`);
      paramCount += 2;
    }

    params.push(parseInt(limit));
    params.push(offset);

    const countResult = await query(
      `SELECT COUNT(*) as total FROM users WHERE ${whereConditions.join(' AND ')}`
    );

    const result = await query(
      `SELECT id, email, full_name, role, profile_picture_url, phone_number, 
              location, created_at, updated_at
       FROM users 
       WHERE ${whereConditions.join(' AND ')}
       ORDER BY created_at DESC
       LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
      [...params.slice(0, paramCount - 2), limit, offset]
    );

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: parseInt(countResult.rows[0].total),
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/users/:id
 * Get user details
 */
router.get('/:id', verifyToken, async (req, res) => {
  try {
    // Users can only view their own profile unless admin/facilitator
    if (
      req.user.id !== parseInt(req.params.id) &&
      req.user.role !== 'admin' &&
      req.user.role !== 'facilitator'
    ) {
      return res.status(403).json({
        success: false,
        error: 'Unauthorized',
      });
    }

    const userResult = await query(
      `SELECT id, email, full_name, role, profile_picture_url, bio, 
              phone_number, location, created_at, updated_at
       FROM users WHERE id = $1`,
      [req.params.id]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
      });
    }

    // Get user stats
    const analyticsResult = await query(
      `SELECT * FROM user_analytics WHERE user_id = $1`,
      [req.params.id]
    );

    const user = userResult.rows[0];
    user.analytics = analyticsResult.rows[0] || null;

    res.json({ success: true, data: user });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/users/filter/:role
 * Filter users by role (admin only)
 * Query: ?page=1&limit=20
 */
router.get('/filter/:role', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin' && req.user.role !== 'facilitator') {
      return res.status(403).json({
        success: false,
        error: 'Unauthorized',
      });
    }

    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    const countResult = await query(
      `SELECT COUNT(*) as total FROM users WHERE role = $1 AND is_active = true`,
      [req.params.role]
    );

    const result = await query(
      `SELECT id, email, full_name, role, profile_picture_url, created_at
       FROM users 
       WHERE role = $1 AND is_active = true
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [req.params.role, parseInt(limit), offset]
    );

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: parseInt(countResult.rows[0].total),
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * PUT /api/users/:id/role
 * Change user role (admin only)
 * Body: { newRole }
 */
router.put('/:id/role', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Only admins can change user roles',
      });
    }

    const { newRole } = req.body;
    const validRoles = ['student', 'instructor', 'admin', 'mentor', 'facilitator', 'parent'];

    if (!validRoles.includes(newRole)) {
      return res.status(400).json({
        success: false,
        error: `Invalid role. Must be one of: ${validRoles.join(', ')}`,
      });
    }

    const userCheck = await query(
      'SELECT role FROM users WHERE id = $1',
      [req.params.id]
    );

    if (userCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
      });
    }

    const oldRole = userCheck.rows[0].role;

    const result = await query(
      `UPDATE users SET role = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *`,
      [newRole, req.params.id]
    );

    await ActivityService.logActivity(
      req.user.id,
      'USER_ROLE_CHANGED',
      'user',
      parseInt(req.params.id),
      { oldRole, newRole },
      req
    );

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * DELETE /api/users/:id
 * Deactivate user (soft delete) - admin only
 */
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Only admins can deactivate users',
      });
    }

    // Prevent self-deletion
    if (req.user.id === parseInt(req.params.id)) {
      return res.status(400).json({
        success: false,
        error: 'Cannot deactivate your own account',
      });
    }

    const result = await query(
      `UPDATE users SET is_active = false, deactivated_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP 
       WHERE id = $1 RETURNING *`,
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
      });
    }

    await ActivityService.logActivity(
      req.user.id,
      'USER_DEACTIVATED',
      'user',
      parseInt(req.params.id),
      { email: result.rows[0].email },
      req
    );

    res.json({ success: true, data: { message: 'User deactivated successfully' } });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/users/:id/analytics
 * Get detailed user analytics
 */
router.get('/:id/analytics', verifyToken, async (req, res) => {
  try {
    if (
      req.user.id !== parseInt(req.params.id) &&
      req.user.role !== 'admin' &&
      req.user.role !== 'facilitator'
    ) {
      return res.status(403).json({
        success: false,
        error: 'Unauthorized',
      });
    }

    // Get user analytics
    const analyticsResult = await query(
      `SELECT * FROM user_analytics WHERE user_id = $1`,
      [req.params.id]
    );

    // Get recent activities
    const activitiesResult = await query(
      `SELECT * FROM user_activities WHERE user_id = $1 ORDER BY created_at DESC LIMIT 20`,
      [req.params.id]
    );

    // Get enrollment stats
    const enrollmentStats = await query(
      `SELECT 
         COUNT(*) as total_enrollments,
         COUNT(CASE WHEN completion_status = 'completed' THEN 1 END) as completed_courses,
         AVG(progress_percentage) as average_progress
       FROM enrollments WHERE user_id = $1`,
      [req.params.id]
    );

    // Get quiz stats
    const quizStats = await query(
      `SELECT 
         COUNT(*) as total_attempts,
         AVG(percentage_score) as average_score,
         COUNT(CASE WHEN passed = true THEN 1 END) as passed_count
       FROM quiz_attempts WHERE user_id = $1`,
      [req.params.id]
    );

    res.json({
      success: true,
      data: {
        analytics: analyticsResult.rows[0],
        recentActivities: activitiesResult.rows,
        enrollmentStats: enrollmentStats.rows[0],
        quizStats: quizStats.rows[0],
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/users/:id/send-notification
 * Send notification to user (admin only)
 * Body: { title, message, type (email|push|both) }
 */
router.post('/:id/send-notification', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin' && req.user.role !== 'facilitator') {
      return res.status(403).json({
        success: false,
        error: 'Unauthorized',
      });
    }

    const { title, message, type = 'both' } = req.body;

    // Validate user exists
    const userResult = await query('SELECT email FROM users WHERE id = $1', [
      req.params.id,
    ]);

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
      });
    }

    // Log the notification activity
    await ActivityService.logActivity(
      req.user.id,
      'NOTIFICATION_SENT',
      'notification',
      parseInt(req.params.id),
      { title, message, type },
      req
    );

    // TODO: Integrate with actual notification service (email/push)

    res.json({
      success: true,
      data: {
        message: 'Notification queued for delivery',
        userId: parseInt(req.params.id),
        type,
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/users/:id/achievements
 * Get user achievements
 */
router.get('/:id/achievements', verifyToken, async (req, res) => {
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
      [req.params.id, pageSize, offset]
    );

    const countResult = await query(
      'SELECT COUNT(*) as count FROM user_achievements WHERE user_id = $1',
      [req.params.id]
    );
    const total = parseInt(countResult.rows[0].count);

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        page,
        pageSize,
        total,
        pages: Math.ceil(total / pageSize),
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/users/:id/points
 * Get user points
 */
router.get('/:id/points', verifyToken, async (req, res) => {
  try {
    const result = await query(
      'SELECT total_points, month_points, week_points FROM user_points WHERE user_id = $1',
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'User points not found' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
