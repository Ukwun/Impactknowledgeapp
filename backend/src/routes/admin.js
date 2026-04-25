const express = require('express');
const router = express.Router();
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');
const AdminService = require('../services/admin-service');
const NotificationTriggerService = require('../services/notification-trigger-service');

// Middleware to verify admin role
const adminOnly = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({
      success: false,
      error: 'Admin access required',
    });
  }
  next();
};

// ============================================
// USER MANAGEMENT
// ============================================

/**
 * GET /api/admin/users - List all users with filtering
 */
router.get('/users', verifyToken, adminOnly, async (req, res) => {
  try {
    const { role, status, search, page = 1, limit = 20 } = req.query;

    const result = await AdminService.listUsers({
      role,
      status,
      searchTerm: search,
      page: parseInt(page),
      limit: Math.min(parseInt(limit), 100),
    });

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

/**
 * GET /api/admin/users/:id - Get detailed user information
 */
router.get('/users/:id', verifyToken, adminOnly, async (req, res) => {
  try {
    const result = await AdminService.getUserDetail(parseInt(req.params.id));

    if (!result.success) {
      return res.status(404).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

/**
 * PUT /api/admin/users/:id/role - Change user role
 */
router.put('/users/:id/role', verifyToken, adminOnly, async (req, res) => {
  try {
    const { newRole } = req.body;

    if (!newRole) {
      return res.status(400).json({
        success: false,
        error: 'New role is required',
      });
    }

    const result = await AdminService.changeUserRole(
      parseInt(req.params.id),
      newRole,
      req.user.id,
      req
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    await NotificationTriggerService.notifyUser({
      userId: parseInt(req.params.id),
      title: 'Role Updated',
      message: `Your platform role is now ${newRole}.`,
      type: 'role_change',
      actionUrl: '/dashboard',
      metadata: {
        action: 'role_change',
        resourceId: parseInt(req.params.id),
        newRole,
      },
      push: true,
    });

    res.json(result);
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

/**
 * PUT /api/admin/users/:id/deactivate - Deactivate user (soft delete)
 */
router.put('/users/:id/deactivate', verifyToken, adminOnly, async (req, res) => {
  try {
    const result = await AdminService.deactivateUser(
      parseInt(req.params.id),
      req.user.id,
      req
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    await NotificationTriggerService.notifyUser({
      userId: parseInt(req.params.id),
      title: 'Account Access Updated',
      message: 'Your account has been deactivated. Contact support if this is unexpected.',
      type: 'account_status',
      actionUrl: '/support',
      metadata: {
        action: 'account_deactivated',
        resourceId: parseInt(req.params.id),
      },
      push: true,
    });

    res.json(result);
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

/**
 * PUT /api/admin/users/:id/reactivate - Reactivate user
 */
router.put('/users/:id/reactivate', verifyToken, adminOnly, async (req, res) => {
  try {
    const result = await AdminService.reactivateUser(
      parseInt(req.params.id),
      req.user.id,
      req
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    await NotificationTriggerService.notifyUser({
      userId: parseInt(req.params.id),
      title: 'Account Reactivated',
      message: 'Your account is active again. You can continue learning and collaborating.',
      type: 'account_status',
      actionUrl: '/dashboard',
      metadata: {
        action: 'account_reactivated',
        resourceId: parseInt(req.params.id),
      },
      push: true,
    });

    res.json(result);
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

// ============================================
// REPORTING & ANALYTICS
// ============================================

/**
 * GET /api/admin/reports/engagement - Get engagement report
 */
router.get('/reports/engagement', verifyToken, adminOnly, async (req, res) => {
  try {
    const { daysBack = 30 } = req.query;

    const result = await AdminService.getEngagementReport(parseInt(daysBack));

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

/**
 * GET /api/admin/reports/retention - Get retention report
 */
router.get('/reports/retention', verifyToken, adminOnly, async (req, res) => {
  try {
    const result = await AdminService.getRetentionReport();

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

/**
 * GET /api/admin/reports/revenue - Get revenue/payment report
 */
router.get('/reports/revenue', verifyToken, adminOnly, async (req, res) => {
  try {
    const result = await AdminService.getRevenueReport();

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

/**
 * GET /api/admin/reports/content - Get content performance report
 */
router.get('/reports/content', verifyToken, adminOnly, async (req, res) => {
  try {
    const result = await AdminService.getContentPerformanceReport();

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

/**
 * GET /api/admin/system-health - Get system health and statistics
 */
router.get('/system-health', verifyToken, adminOnly, async (req, res) => {
  try {
    const result = await AdminService.getSystemHealth();

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

// ============================================
// MEMBERSHIP TIER MANAGEMENT
// ============================================

/**
 * GET /api/admin/membership-tiers - Get all membership tiers
 */
router.get('/membership-tiers', verifyToken, adminOnly, async (req, res) => {
  try {
    const result = await AdminService.getMembershipTiers();

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

/**
 * POST /api/admin/membership-tiers - Create membership tier
 */
router.post('/membership-tiers', verifyToken, adminOnly, async (req, res) => {
  try {
    const { name, description, monthlyPrice, annualPrice, benefits } = req.body;

    if (!name || monthlyPrice == null) {
      return res.status(400).json({
        success: false,
        error: 'Name and monthlyPrice are required',
      });
    }

    const result = await AdminService.createMembershipTier(
      {
        name,
        description,
        monthlyPrice,
        annualPrice,
        benefits,
      },
      req.user.id,
      req
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.status(201).json(result);
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

/**
 * DELETE /api/admin/membership-tiers/:id - Delete membership tier
 */
router.delete('/membership-tiers/:id', verifyToken, adminOnly, async (req, res) => {
  try {
    const result = await AdminService.deleteMembershipTier(
      parseInt(req.params.id),
      req.user.id,
      req
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

// ============================================
// LANDING CONTENT MANAGEMENT
// ============================================

router.get('/partners', verifyToken, adminOnly, async (req, res) => {
  try {
    const result = await query(
      `SELECT id, name, website_url, logo_url, is_active, created_at
       FROM platform_partners
       ORDER BY created_at DESC`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.post('/partners', verifyToken, adminOnly, async (req, res) => {
  try {
    const { name, websiteUrl, logoUrl, isActive = true } = req.body;
    if (!name) {
      return res.status(400).json({ success: false, error: 'name is required' });
    }
    const result = await query(
      `INSERT INTO platform_partners (name, website_url, logo_url, is_active)
       VALUES ($1, $2, $3, $4)
       RETURNING id, name, website_url, logo_url, is_active, created_at`,
      [name, websiteUrl || null, logoUrl || null, isActive]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.put('/partners/:id', verifyToken, adminOnly, async (req, res) => {
  try {
    const id = parseInt(req.params.id);
    const { name, websiteUrl, logoUrl, isActive } = req.body;

    if (!name) {
      return res.status(400).json({ success: false, error: 'name is required' });
    }

    const result = await query(
      `UPDATE platform_partners
       SET name = $2,
           website_url = $3,
           logo_url = $4,
           is_active = COALESCE($5, is_active),
           updated_at = NOW()
       WHERE id = $1
       RETURNING id, name, website_url, logo_url, is_active, created_at, updated_at`,
      [id, name, websiteUrl || null, logoUrl || null, isActive]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Partner not found' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.delete('/partners/:id', verifyToken, adminOnly, async (req, res) => {
  try {
    await query('DELETE FROM platform_partners WHERE id = $1', [parseInt(req.params.id)]);
    res.json({ success: true, data: { id: parseInt(req.params.id) } });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.get('/testimonials', verifyToken, adminOnly, async (req, res) => {
  try {
    const result = await query(
      `SELECT id, quote, author_name, author_role, is_active, created_at
       FROM testimonials
       ORDER BY created_at DESC`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.post('/testimonials', verifyToken, adminOnly, async (req, res) => {
  try {
    const { quote, authorName, authorRole, isActive = true } = req.body;
    if (!quote || !authorName) {
      return res.status(400).json({ success: false, error: 'quote and authorName are required' });
    }
    const result = await query(
      `INSERT INTO testimonials (quote, author_name, author_role, is_active)
       VALUES ($1, $2, $3, $4)
       RETURNING id, quote, author_name, author_role, is_active, created_at`,
      [quote, authorName, authorRole || null, isActive]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.put('/testimonials/:id', verifyToken, adminOnly, async (req, res) => {
  try {
    const id = parseInt(req.params.id);
    const { quote, authorName, authorRole, isActive } = req.body;

    if (!quote || !authorName) {
      return res.status(400).json({ success: false, error: 'quote and authorName are required' });
    }

    const result = await query(
      `UPDATE testimonials
       SET quote = $2,
           author_name = $3,
           author_role = $4,
           is_active = COALESCE($5, is_active),
           updated_at = NOW()
       WHERE id = $1
       RETURNING id, quote, author_name, author_role, is_active, created_at, updated_at`,
      [id, quote, authorName, authorRole || null, isActive]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Testimonial not found' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.delete('/testimonials/:id', verifyToken, adminOnly, async (req, res) => {
  try {
    await query('DELETE FROM testimonials WHERE id = $1', [parseInt(req.params.id)]);
    res.json({ success: true, data: { id: parseInt(req.params.id) } });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * PUT /api/admin/membership-tiers/:id - Update membership tier
 */
router.put('/membership-tiers/:id', verifyToken, adminOnly, async (req, res) => {
  try {
    const result = await AdminService.updateMembershipTier(
      parseInt(req.params.id),
      req.body,
      req.user.id,
      req
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

// ============================================
// SETTINGS & CONFIGURATION
// ============================================

/**
 * GET /api/admin/settings - Get platform settings
 */
router.get('/settings', verifyToken, adminOnly, async (req, res) => {
  try {
    const result = await AdminService.getPlatformSettings();

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

// ============================================
// COMMUNICATIONS
// ============================================

/**
 * POST /api/admin/notifications/bulk - Send bulk notification
 */
router.post('/notifications/bulk', verifyToken, adminOnly, async (req, res) => {
  try {
    const { filters, message } = req.body;

    if (!message) {
      return res.status(400).json({
        success: false,
        error: 'Message is required',
      });
    }

    const result = await AdminService.sendBulkNotification(
      filters || {},
      message,
      req.user.id,
      req
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

// ============================================
// AUDIT LOG
// ============================================

/**
 * GET /api/admin/audit-log - Get audit log of activities
 */
router.get('/audit-log', verifyToken, adminOnly, async (req, res) => {
  try {
    const { actionType, userId, limit = 100, offset = 0 } = req.query;

    const result = await AdminService.getAuditLog({
      actionType,
      userId: userId ? parseInt(userId) : null,
      limit: Math.min(parseInt(limit), 500),
      offset: parseInt(offset),
    });

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

/**
 * GET /api/admin/reports/export/users?format=csv
 * Export core user/reporting dataset for admins.
 */
router.get('/reports/export/users', verifyToken, adminOnly, async (req, res) => {
  try {
    const format = (req.query.format || 'csv').toString().toLowerCase();
    const result = await query(
      `SELECT id, full_name, email, role, is_active, created_at
       FROM users
       ORDER BY created_at DESC
       LIMIT 5000`
    );

    if (format === 'json') {
      return res.json({ success: true, data: result.rows });
    }

    const headers = ['id', 'full_name', 'email', 'role', 'is_active', 'created_at'];
    const csvRows = [headers.join(',')];
    for (const row of result.rows) {
      csvRows.push(
        [
          row.id,
          `"${(row.full_name || '').replace(/"/g, '""')}"`,
          `"${(row.email || '').replace(/"/g, '""')}"`,
          row.role,
          row.is_active,
          row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
        ].join(',')
      );
    }

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="users-export-${new Date().toISOString().slice(0, 10)}.csv"`
    );
    return res.send(csvRows.join('\n'));
  } catch (err) {
    console.error('Export users report error:', err);
    return res.status(500).json({ success: false, error: 'Failed to export report' });
  }
});

/**
 * GET /api/admin/reports/export/payments?format=csv
 */
router.get('/reports/export/payments', verifyToken, adminOnly, async (req, res) => {
  try {
    const format = (req.query.format || 'csv').toString().toLowerCase();
    const result = await query(
      `SELECT p.id, p.reference, p.user_id, u.email, p.item_type, p.amount, p.status, p.payment_method, p.created_at
       FROM payments p
       LEFT JOIN users u ON u.id = p.user_id
       ORDER BY p.created_at DESC
       LIMIT 5000`
    );

    if (format === 'json') {
      return res.json({ success: true, data: result.rows });
    }

    const headers = ['id', 'reference', 'user_id', 'email', 'item_type', 'amount', 'status', 'payment_method', 'created_at'];
    const csvRows = [headers.join(',')];
    for (const row of result.rows) {
      csvRows.push([
        row.id,
        `"${(row.reference || '').replace(/"/g, '""')}"`,
        row.user_id,
        `"${(row.email || '').replace(/"/g, '""')}"`,
        row.item_type,
        row.amount,
        row.status,
        row.payment_method,
        row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
      ].join(','));
    }

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="payments-export-${new Date().toISOString().slice(0, 10)}.csv"`);
    return res.send(csvRows.join('\n'));
  } catch (err) {
    console.error('Export payments report error:', err);
    return res.status(500).json({ success: false, error: 'Failed to export report' });
  }
});

/**
 * GET /api/admin/reports/export/course-performance?format=csv
 */
router.get('/reports/export/course-performance', verifyToken, adminOnly, async (req, res) => {
  try {
    const format = (req.query.format || 'csv').toString().toLowerCase();
    const result = await query(
      `SELECT c.id as course_id, c.title,
              COUNT(DISTINCT e.user_id) as total_enrollments,
              COUNT(DISTINCT CASE WHEN e.completion_status = 'completed' THEN e.user_id END) as completed_enrollments,
              ROUND(
                CASE WHEN COUNT(DISTINCT e.user_id) = 0 THEN 0
                ELSE (COUNT(DISTINCT CASE WHEN e.completion_status = 'completed' THEN e.user_id END)::decimal / COUNT(DISTINCT e.user_id)::decimal) * 100
                END, 2
              ) as completion_rate_percent,
              ROUND(COALESCE(AVG(e.progress_percentage), 0), 2) as avg_progress_percent
       FROM courses c
       LEFT JOIN enrollments e ON e.course_id = c.id
       GROUP BY c.id, c.title
       ORDER BY total_enrollments DESC, c.title ASC`
    );

    if (format === 'json') {
      return res.json({ success: true, data: result.rows });
    }

    const headers = ['course_id', 'title', 'total_enrollments', 'completed_enrollments', 'completion_rate_percent', 'avg_progress_percent'];
    const csvRows = [headers.join(',')];
    for (const row of result.rows) {
      csvRows.push([
        row.course_id,
        `"${(row.title || '').replace(/"/g, '""')}"`,
        row.total_enrollments,
        row.completed_enrollments,
        row.completion_rate_percent,
        row.avg_progress_percent,
      ].join(','));
    }

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="course-performance-export-${new Date().toISOString().slice(0, 10)}.csv"`);
    return res.send(csvRows.join('\n'));
  } catch (err) {
    console.error('Export course performance error:', err);
    return res.status(500).json({ success: false, error: 'Failed to export report' });
  }
});

/**
 * GET /api/admin/reports/export/completion-cohorts?format=csv
 */
router.get('/reports/export/completion-cohorts', verifyToken, adminOnly, async (req, res) => {
  try {
    const format = (req.query.format || 'csv').toString().toLowerCase();
    const result = await query(
      `SELECT DATE_TRUNC('month', e.enrollment_date) as cohort_month,
              COUNT(*) as enrolled_count,
              COUNT(CASE WHEN e.completion_status = 'completed' THEN 1 END) as completed_count,
              ROUND(
                CASE WHEN COUNT(*) = 0 THEN 0
                ELSE (COUNT(CASE WHEN e.completion_status = 'completed' THEN 1 END)::decimal / COUNT(*)::decimal) * 100
                END, 2
              ) as completion_rate_percent
       FROM enrollments e
       GROUP BY DATE_TRUNC('month', e.enrollment_date)
       ORDER BY cohort_month DESC`
    );

    if (format === 'json') {
      return res.json({ success: true, data: result.rows });
    }

    const headers = ['cohort_month', 'enrolled_count', 'completed_count', 'completion_rate_percent'];
    const csvRows = [headers.join(',')];
    for (const row of result.rows) {
      const cohortMonth = row.cohort_month instanceof Date
        ? row.cohort_month.toISOString().slice(0, 7)
        : row.cohort_month;
      csvRows.push([
        cohortMonth,
        row.enrolled_count,
        row.completed_count,
        row.completion_rate_percent,
      ].join(','));
    }

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="completion-cohorts-export-${new Date().toISOString().slice(0, 10)}.csv"`);
    return res.send(csvRows.join('\n'));
  } catch (err) {
    console.error('Export completion cohorts error:', err);
    return res.status(500).json({ success: false, error: 'Failed to export report' });
  }
});

module.exports = router;
