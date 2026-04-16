/**
 * User Support System Endpoints
 * Handles support tickets and customer communication
 */

const express = require('express');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');
const router = express.Router();

// ============================================
// USER ENDPOINTS - Support Tickets
// ============================================

/**
 * POST /api/support/tickets
 * Create a new support ticket
 */
router.post('/tickets', verifyToken, async (req, res) => {
  try {
    const { category, subject, description } = req.body;
    const user_id = req.user.id;

    if (!category || !subject || !description) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: category, subject, description'
      });
    }

    const validCategories = ['technical', 'billing', 'content', 'other'];
    if (!validCategories.includes(category)) {
      return res.status(400).json({
        success: false,
        error: `Invalid category. Must be one of: ${validCategories.join(', ')}`
      });
    }

    // Create ticket
    const result = await query(
      `INSERT INTO support_tickets 
       (user_id, category, subject, description, status, priority, created_at, updated_at)
       VALUES ($1, $2, $3, $4, 'open', 'normal', NOW(), NOW())
       RETURNING id, created_at, status`,
      [user_id, category, subject, description]
    );

    const ticketId = result.rows[0].id;

    // Create initial message from user
    await query(
      `INSERT INTO support_messages (ticket_id, sender_id, message, created_at)
       VALUES ($1, $2, $3, NOW())`,
      [ticketId, user_id, description]
    );

    res.status(201).json({
      success: true,
      message: 'Support ticket created successfully',
      ticket_id: ticketId,
      created_at: result.rows[0].created_at
    });
  } catch (err) {
    console.error('Create ticket error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/support/tickets
 * Get user's support tickets
 */
router.get('/tickets', verifyToken, async (req, res) => {
  try {
    const user_id = req.user.id;
    const { limit = 20, offset = 0 } = req.query;

    const result = await query(
      `SELECT id, category, subject, status, priority, created_at, updated_at
       FROM support_tickets
       WHERE user_id = $1
       ORDER BY updated_at DESC
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
    console.error('Get tickets error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/support/tickets/:ticketId
 * Get specific ticket with messages
 */
router.get('/tickets/:ticketId', verifyToken, async (req, res) => {
  try {
    const { ticketId } = req.params;
    const user_id = req.user.id;

    // Get ticket
    const ticketResult = await query(
      `SELECT * FROM support_tickets WHERE id = $1`,
      [ticketId]
    );

    if (ticketResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Ticket not found'
      });
    }

    const ticket = ticketResult.rows[0];

    // Check authorization (only owner or admin)
    if (ticket.user_id !== user_id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Not authorized to view this ticket'
      });
    }

    // Get messages
    const messagesResult = await query(
      `SELECT sm.id, sm.sender_id, sm.message, sm.created_at,
              u.full_name, u.role
       FROM support_messages sm
       LEFT JOIN users u ON sm.sender_id = u.id
       WHERE sm.ticket_id = $1
       ORDER BY sm.created_at ASC`,
      [ticketId]
    );

    res.json({
      success: true,
      ticket,
      messages: messagesResult.rows
    });
  } catch (err) {
    console.error('Get ticket error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/support/tickets/:ticketId/messages
 * Add message to ticket
 */
router.post('/tickets/:ticketId/messages', verifyToken, async (req, res) => {
  try {
    const { ticketId } = req.params;
    const { message } = req.body;
    const user_id = req.user.id;

    if (!message) {
      return res.status(400).json({
        success: false,
        error: 'Message is required'
      });
    }

    // Get ticket and verify ownership
    const ticketResult = await query(
      `SELECT user_id FROM support_tickets WHERE id = $1`,
      [ticketId]
    );

    if (ticketResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Ticket not found'
      });
    }

    const ticket = ticketResult.rows[0];
    if (ticket.user_id !== user_id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Not authorized to message this ticket'
      });
    }

    // Add message
    const result = await query(
      `INSERT INTO support_messages (ticket_id, sender_id, message, created_at)
       VALUES ($1, $2, $3, NOW())
       RETURNING id, created_at`,
      [ticketId, user_id, message]
    );

    // Update ticket's updated_at
    await query(
      `UPDATE support_tickets SET updated_at = NOW() WHERE id = $1`,
      [ticketId]
    );

    res.status(201).json({
      success: true,
      message_id: result.rows[0].id,
      created_at: result.rows[0].created_at
    });
  } catch (err) {
    console.error('Add message error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * PUT /api/support/tickets/:ticketId
 * Update ticket status
 */
router.put('/tickets/:ticketId', verifyToken, async (req, res) => {
  try {
    const { ticketId } = req.params;
    const { status } = req.body;
    const user_id = req.user.id;

    const validStatuses = ['open', 'in-progress', 'resolved', 'closed'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        error: `Invalid status. Must be one of: ${validStatuses.join(', ')}`
      });
    }

    // Get ticket
    const ticketResult = await query(
      `SELECT user_id FROM support_tickets WHERE id = $1`,
      [ticketId]
    );

    if (ticketResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Ticket not found'
      });
    }

    const ticket = ticketResult.rows[0];

    // Only admin or owner can update
    if (ticket.user_id !== user_id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Not authorized to update this ticket'
      });
    }

    // Update status
    await query(
      `UPDATE support_tickets SET status = $1, updated_at = NOW() WHERE id = $2`,
      [status, ticketId]
    );

    res.json({
      success: true,
      message: 'Ticket status updated',
      status
    });
  } catch (err) {
    console.error('Update ticket error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ============================================
// ADMIN ENDPOINTS
// ============================================

/**
 * GET /api/admin/support/tickets
 * Get all support tickets (admin only)
 */
router.get('/admin/tickets', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Only admins can access support dashboard'
      });
    }

    const { status = 'open', limit = 20, offset = 0 } = req.query;

    let query_str = `SELECT 
      st.id, st.user_id, st.category, st.subject, st.status, st.priority, st.created_at,
      u.full_name, u.email,
      (SELECT COUNT(*) FROM support_messages WHERE ticket_id = st.id) as message_count
      FROM support_tickets st
      LEFT JOIN users u ON st.user_id = u.id
      WHERE 1=1`;
    const params = [];

    if (status && status !== 'all') {
      query_str += ` AND st.status = $${params.length + 1}`;
      params.push(status);
    }

    query_str += ` ORDER BY st.updated_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(parseInt(limit), parseInt(offset));

    const result = await query(query_str, params);

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        limit: parseInt(limit),
        offset: parseInt(offset)
      }
    });
  } catch (err) {
    console.error('Get admin tickets error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/admin/support/stats
 * Get support statistics
 */
router.get('/admin/stats', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Only admins can access support statistics'
      });
    }

    const stats = await query(`
      SELECT 
        COUNT(*) as total_tickets,
        SUM(CASE WHEN status = 'open' THEN 1 ELSE 0 END) as open_tickets,
        SUM(CASE WHEN status = 'in-progress' THEN 1 ELSE 0 END) as in_progress_tickets,
        SUM(CASE WHEN status = 'resolved' THEN 1 ELSE 0 END) as resolved_tickets,
        SUM(CASE WHEN status = 'closed' THEN 1 ELSE 0 END) as closed_tickets
      FROM support_tickets
    `);

    const byCategory = await query(`
      SELECT category, COUNT(*) as count
      FROM support_tickets
      GROUP BY category
      ORDER BY count DESC
    `);

    res.json({
      success: true,
      stats: stats.rows[0],
      by_category: byCategory.rows
    });
  } catch (err) {
    console.error('Get support stats error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
