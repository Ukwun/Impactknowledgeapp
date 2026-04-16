const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const EventService = require('../services/event-service');

/**
 * POST /api/events - Create a new event (instructor/admin)
 */
router.post('/', verifyToken, async (req, res) => {
  try {
    const { title, description, eventType, startDate, endDate, location, capacity, thumbnailUrl } = req.body;

    // Validate required fields
    if (!title || !startDate) {
      return res.status(400).json({
        success: false,
        error: 'Title and start date are required',
      });
    }

    // Only instructors and admins can create events
    if (req.user.role !== 'instructor' && req.user.role !== 'admin' && req.user.role !== 'facilitator') {
      return res.status(403).json({
        success: false,
        error: 'Only instructors can create events',
      });
    }

    const result = await EventService.createEvent(
      {
        title,
        description,
        eventType,
        startDate,
        endDate,
        location,
        capacity,
        thumbnailUrl,
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
 * GET /api/events - List all published events
 */
router.get('/', async (req, res) => {
  try {
    const { eventType, status = 'scheduled', upcomingOnly = 'false', page = 1, limit = 20 } = req.query;

    const result = await EventService.listEvents({
      eventType,
      status,
      upcomingOnly: upcomingOnly === 'true',
      page: parseInt(page),
      limit: Math.min(parseInt(limit), 100), // Cap at 100
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
 * GET /api/events/:id - Get event details
 */
router.get('/:id', async (req, res) => {
  try {
    const userId = req.user?.id || null;
    const result = await EventService.getEvent(parseInt(req.params.id), userId);

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
 * PUT /api/events/:id - Update event (creator only)
 */
router.put('/:id', verifyToken, async (req, res) => {
  try {
    // Only instructors and admins can update events
    if (req.user.role !== 'instructor' && req.user.role !== 'admin' && req.user.role !== 'facilitator') {
      return res.status(403).json({
        success: false,
        error: 'Only instructors can update events',
      });
    }

    const result = await EventService.updateEvent(
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
 * DELETE /api/events/:id - Delete event (creator only)
 */
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    // Only instructors and admins can delete events
    if (req.user.role !== 'instructor' && req.user.role !== 'admin' && req.user.role !== 'facilitator') {
      return res.status(403).json({
        success: false,
        error: 'Only instructors can delete events',
      });
    }

    const result = await EventService.deleteEvent(
      parseInt(req.params.id),
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
 * POST /api/events/:id/register - Register for an event
 */
router.post('/:id/register', verifyToken, async (req, res) => {
  try {
    const result = await EventService.registerForEvent(
      parseInt(req.params.id),
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
 * DELETE /api/events/:id/register - Unregister from an event
 */
router.delete('/:id/register', verifyToken, async (req, res) => {
  try {
    const result = await EventService.unregisterFromEvent(
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
 * GET /api/events/:id/attendees - Get event attendees (event creator only)
 */
router.get('/:id/attendees', verifyToken, async (req, res) => {
  try {
    const result = await EventService.getEventAttendees(
      parseInt(req.params.id),
      req.user.id
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
 * GET /api/events/user/my-events - Get current user's registered events
 */
router.get('/user/my-events', verifyToken, async (req, res) => {
  try {
    const result = await EventService.getUserEvents(req.user.id);

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
 * PUT /api/events/:id/mark-attendance - Mark attendance for event
 */
router.put('/:id/mark-attendance/:userId', verifyToken, async (req, res) => {
  try {
    // Only event creator or admin can mark attendance
    const { attendanceStatus } = req.body;

    if (!attendanceStatus) {
      return res.status(400).json({
        success: false,
        error: 'Attendance status is required',
      });
    }

    // Verify user is event creator (would need to check event.created_by)
    // For now, can be improved with proper authorization check
    const result = await EventService.markAttendance(
      parseInt(req.params.id),
      parseInt(req.params.userId),
      attendanceStatus,
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
