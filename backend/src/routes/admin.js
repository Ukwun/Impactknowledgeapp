const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const AdminService = require('../services/admin-service');

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
    const { name, description, price, features, duration_months } = req.body;

    if (!name || !price) {
      return res.status(400).json({
        success: false,
        error: 'Name and price are required',
      });
    }

    const result = await AdminService.createMembershipTier(
      {
        name,
        description,
        price,
        features,
        duration_months,
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

module.exports = router;
