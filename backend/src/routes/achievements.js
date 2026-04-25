const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const { query } = require('../database');
const AchievementService = require('../services/achievement-service');

/**
 * GET /api/achievements - Get all achievements
 */
router.get('/', async (req, res) => {
  try {
    const { category } = req.query;
    const result = await AchievementService.getAchievements(category);

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
 * GET /api/achievements/stats - Get achievement statistics
 */
router.get('/stats', async (req, res) => {
  try {
    const result = await AchievementService.getStatistics();

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
 * GET /api/achievements/user/:userId - Get user's achievements
 */
router.get('/user/:userId', async (req, res) => {
  try {
    const result = await AchievementService.getUserAchievements(
      parseInt(req.params.userId)
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
 * GET /api/achievements/user/:userId/unlocked - Get user's unlocked achievements
 */
router.get('/user/:userId/unlocked', async (req, res) => {
  try {
    const result = await AchievementService.getUnlockedAchievements(
      parseInt(req.params.userId)
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
 * GET /api/achievements/me - Get current user's achievements
 */
router.get('/me/all', verifyToken, async (req, res) => {
  try {
    const result = await AchievementService.getUserAchievements(req.user.id);

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
 * POST /api/achievements - Create new achievement (admin only)
 */
router.post('/', verifyToken, async (req, res) => {
  try {
    // Only admins can create achievements
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Only admins can create achievements',
      });
    }

    const { title, description, iconUrl, points, category, unlockCondition } =
      req.body;

    if (!title || !points) {
      return res.status(400).json({
        success: false,
        error: 'Title and points are required',
      });
    }

    const result = await AchievementService.createAchievement(
      {
        title,
        description,
        iconUrl,
        points,
        category,
        unlockCondition,
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
 * PUT /api/achievements/:id - Update achievement (admin only)
 */
router.put('/:id', verifyToken, async (req, res) => {
  try {
    // Only admins can update achievements
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Only admins can update achievements',
      });
    }

    const result = await AchievementService.updateAchievement(
      parseInt(req.params.id),
      req.body,
      req.user.id,
      req
    );

    if (!result.success) {
      return res.status(403).json(result);
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
 * DELETE /api/achievements/:id - Delete achievement (admin only)
 */
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Only admins can delete achievements',
      });
    }

    const achievementId = parseInt(req.params.id);

    const deleted = await query(
      'DELETE FROM achievements WHERE id = $1 RETURNING id, title',
      [achievementId]
    );

    if (deleted.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Achievement not found',
      });
    }

    res.json({
      success: true,
      message: 'Achievement deleted successfully',
      data: deleted.rows[0],
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

/**
 * POST /api/achievements/:id/unlock - Manually unlock achievement (admin only)
 */
router.post('/:id/unlock', verifyToken, async (req, res) => {
  try {
    // Only admins can manually unlock achievements
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Only admins can manually unlock achievements',
      });
    }

    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        error: 'User ID is required',
      });
    }

    const result = await AchievementService.manualUnlock(
      userId,
      parseInt(req.params.id),
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
 * POST /api/achievements/check - Check and auto-unlock achievements
 * Used internally after quiz completion, course completion, etc.
 */
router.post('/check/auto-unlock', verifyToken, async (req, res) => {
  try {
    const { triggerEvent, metadata = {} } = req.body;

    if (!triggerEvent) {
      return res.status(400).json({
        success: false,
        error: 'Trigger event is required',
      });
    }

    const result = await AchievementService.checkAndUnlockAchievements(
      req.user.id,
      triggerEvent,
      metadata,
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

module.exports = router;
