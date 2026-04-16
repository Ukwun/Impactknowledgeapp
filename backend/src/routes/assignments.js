const express = require('express');
const { verifyToken } = require('../middleware/auth');
const AssignmentService = require('../services/assignment-service');

const router = express.Router();

/**
 * POST /api/assignments
 * Create a new assignment (instructor only)
 */
router.post('/', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'instructor' && req.user.role !== 'facilitator') {
      return res.status(403).json({
        success: false,
        error: 'Only instructors can create assignments',
      });
    }

    const result = await AssignmentService.createAssignment(
      req.body,
      req.user.id,
      req
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.status(201).json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/assignments/:id
 * Get assignment details (with student's submission if they're a student)
 */
router.get('/:id', verifyToken, async (req, res) => {
  try {
    const userId = req.user.role === 'student' ? req.user.id : null;
    const result = await AssignmentService.getAssignment(req.params.id, userId);

    if (!result.success) {
      return res.status(404).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * PUT /api/assignments/:id
 * Update assignment (instructor only)
 */
router.put('/:id', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'instructor' && req.user.role !== 'facilitator') {
      return res.status(403).json({
        success: false,
        error: 'Only instructors can update assignments',
      });
    }

    const result = await AssignmentService.updateAssignment(
      req.params.id,
      req.body,
      req.user.id,
      req
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * DELETE /api/assignments/:id
 * Delete assignment (instructor only)
 */
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'instructor' && req.user.role !== 'facilitator') {
      return res.status(403).json({
        success: false,
        error: 'Only instructors can delete assignments',
      });
    }

    const result = await AssignmentService.deleteAssignment(
      req.params.id,
      req.user.id,
      req
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/assignments/:id/submit
 * Submit assignment (student)
 * Body: { submissionText, fileUrl (optional) }
 */
router.post('/:id/submit', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'student') {
      return res.status(403).json({
        success: false,
        error: 'Only students can submit assignments',
      });
    }

    const result = await AssignmentService.submitAssignment(
      req.params.id,
      req.user.id,
      req.body,
      req
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.status(201).json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/assignments/:id/submissions
 * Get all submissions for an assignment (instructor view)
 */
router.get('/:id/submissions', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'instructor' && req.user.role !== 'facilitator' && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Unauthorized',
      });
    }

    const result = await AssignmentService.getAssignmentSubmissions(
      req.params.id,
      req.user.id
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * PUT /api/assignments/:assignmentId/submissions/:submissionId/grade
 * Grade a submission (instructor only)
 * Body: { pointsEarned, feedback }
 */
router.put(
  '/:assignmentId/submissions/:submissionId/grade',
  verifyToken,
  async (req, res) => {
    try {
      if (
        req.user.role !== 'instructor' &&
        req.user.role !== 'facilitator' &&
        req.user.role !== 'admin'
      ) {
        return res.status(403).json({
          success: false,
          error: 'Unauthorized',
        });
      }

      const result = await AssignmentService.gradeSubmission(
        req.params.submissionId,
        req.body,
        req.user.id,
        req
      );

      if (!result.success) {
        return res.status(400).json(result);
      }

      res.json(result);
    } catch (err) {
      res.status(500).json({ success: false, error: err.message });
    }
  }
);

/**
 * GET /api/assignments/:id/stats
 * Get assignment statistics
 */
router.get('/:id/stats', verifyToken, async (req, res) => {
  try {
    const result = await AssignmentService.getAssignmentStats(req.params.id);

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
