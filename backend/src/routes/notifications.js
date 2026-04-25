const express = require('express');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

const canManageNotifications = (role) =>
  ['admin', 'facilitator', 'instructor'].includes(role);

/**
 * GET /api/notifications
 * Current user's notifications (latest first).
 */
router.get('/', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const limit = Math.min(parseInt(req.query.limit || '25', 10), 100);
    const unreadOnly = req.query.unreadOnly === 'true';

    const params = [userId, limit];
    const unreadClause = unreadOnly ? 'AND is_read = false' : '';

    const result = await query(
      `SELECT id, title, message, type, action_url, metadata, is_read, created_at, read_at
       FROM notifications
       WHERE user_id = $1 ${unreadClause}
       ORDER BY created_at DESC
       LIMIT $2`,
      params
    );

    const unreadCountResult = await query(
      `SELECT COUNT(*)::int AS unread_count
       FROM notifications
       WHERE user_id = $1 AND is_read = false`,
      [userId]
    );

    res.json({
      success: true,
      data: result.rows,
      unreadCount: unreadCountResult.rows[0]?.unread_count ?? 0,
    });
  } catch (err) {
    console.error('Get notifications error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch notifications' });
  }
});

/**
 * POST /api/notifications
 * Create a notification for a user (admin/facilitator/instructor only).
 */
router.post('/', verifyToken, async (req, res) => {
  try {
    if (!canManageNotifications(req.user.role)) {
      return res.status(403).json({ success: false, error: 'Insufficient permissions' });
    }

    const {
      userId,
      title,
      message,
      type = 'info',
      actionUrl = null,
      metadata = {},
    } = req.body;

    if (!userId || !title || !message) {
      return res.status(400).json({
        success: false,
        error: 'userId, title, and message are required',
      });
    }

    const created = await query(
      `INSERT INTO notifications (user_id, title, message, type, action_url, metadata)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, user_id, title, message, type, action_url, metadata, is_read, created_at`,
      [userId, title, message, type, actionUrl, JSON.stringify(metadata)]
    );

    res.status(201).json({ success: true, data: created.rows[0] });
  } catch (err) {
    console.error('Create notification error:', err);
    res.status(500).json({ success: false, error: 'Failed to create notification' });
  }
});

/**
 * PUT /api/notifications/:id/read
 * Mark one notification as read.
 */
router.put('/:id/read', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const id = parseInt(req.params.id, 10);

    const updated = await query(
      `UPDATE notifications
       SET is_read = true, read_at = NOW()
       WHERE id = $1 AND user_id = $2
       RETURNING id, is_read, read_at`,
      [id, userId]
    );

    if (updated.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Notification not found' });
    }

    res.json({ success: true, data: updated.rows[0] });
  } catch (err) {
    console.error('Mark notification read error:', err);
    res.status(500).json({ success: false, error: 'Failed to update notification' });
  }
});

/**
 * PUT /api/notifications/read-all
 * Mark all current user's notifications as read.
 */
router.put('/read-all', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const result = await query(
      `UPDATE notifications
       SET is_read = true, read_at = NOW()
       WHERE user_id = $1 AND is_read = false`,
      [userId]
    );

    res.json({ success: true, updatedCount: result.rowCount });
  } catch (err) {
    console.error('Mark all notifications read error:', err);
    res.status(500).json({ success: false, error: 'Failed to update notifications' });
  }
});

/**
 * DELETE /api/notifications/:id
 * Delete one notification (owner only).
 */
router.delete('/:id(\\d+)', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const id = parseInt(req.params.id, 10);

    const result = await query(
      'DELETE FROM notifications WHERE id = $1 AND user_id = $2',
      [id, userId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, error: 'Notification not found' });
    }

    res.json({ success: true, message: 'Notification deleted' });
  } catch (err) {
    console.error('Delete notification error:', err);
    res.status(500).json({ success: false, error: 'Failed to delete notification' });
  }
});

/**
 * PUT /api/notifications/device-token
 * Register/update the caller's device token for FCM push delivery.
 */
router.put('/device-token', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { token } = req.body;

    if (!token || !token.toString().trim()) {
      return res.status(400).json({ success: false, error: 'token is required' });
    }

    await query(
      `UPDATE users
       SET fcm_token = $2, updated_at = NOW()
       WHERE id = $1`,
      [userId, token.toString().trim()]
    );

    res.json({ success: true, message: 'Device token updated' });
  } catch (err) {
    console.error('Update device token error:', err);
    res.status(500).json({ success: false, error: 'Failed to update device token' });
  }
});

/**
 * DELETE /api/notifications/device-token
 * Clear the caller's device token.
 */
router.delete('/device-token', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    await query(
      `UPDATE users
       SET fcm_token = NULL, updated_at = NOW()
       WHERE id = $1`,
      [userId]
    );

    res.json({ success: true, message: 'Device token cleared' });
  } catch (err) {
    console.error('Clear device token error:', err);
    res.status(500).json({ success: false, error: 'Failed to clear device token' });
  }
});

module.exports = router;
