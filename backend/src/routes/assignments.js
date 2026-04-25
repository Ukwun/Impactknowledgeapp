const express = require('express');
const jwt = require('jsonwebtoken');
const path = require('path');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');
const AssignmentService = require('../services/assignment-service');
const NotificationTriggerService = require('../services/notification-trigger-service');

const router = express.Router();
const FILE_DOWNLOAD_SECRET =
  process.env.FILE_DOWNLOAD_SECRET ||
  process.env.JWT_SECRET ||
  'impactknowledge-file-download-secret';

/**
 * GET /api/assignments
 * List assignments, optional filter: ?courseId=<id>
 */
router.get('/', verifyToken, async (req, res) => {
  try {
    const { courseId } = req.query;
    const result = await AssignmentService.listAssignments({
      courseId,
      userId: req.user.id,
    });

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/assignments/submissions/:submissionId
 * Get submission detail (owner or assignment creator)
 */
router.get('/submissions/:submissionId', verifyToken, async (req, res) => {
  try {
    const result = await AssignmentService.getSubmissionById(
      req.params.submissionId,
      req.user.id
    );

    if (!result.success) {
      const status = result.error === 'Unauthorized' ? 403 : 404;
      return res.status(status).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/assignments/submissions/:submissionId/file
 * Get authorized file URL for a submission
 */
router.get('/submissions/:submissionId/file', verifyToken, async (req, res) => {
  try {
    const result = await AssignmentService.getSubmissionFile(
      req.params.submissionId,
      req.user.id
    );

    if (!result.success) {
      const status = result.error === 'Unauthorized' ? 403 : 404;
      return res.status(status).json(result);
    }

    const token = jwt.sign(
      {
        submissionId: req.params.submissionId,
        requesterId: req.user.id,
      },
      FILE_DOWNLOAD_SECRET,
      { expiresIn: '10m' }
    );

    const baseUrl = `${req.protocol}://${req.get('host')}`;
    const downloadUrl =
      `${baseUrl}/api/assignments/submissions/${req.params.submissionId}` +
      `/file/download?token=${encodeURIComponent(token)}`;

    res.json({
      success: true,
      data: {
        submissionId: req.params.submissionId,
        fileUrl: downloadUrl,
        expiresInSeconds: 600,
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/assignments/submissions/:submissionId/file/download?token=...
 * Stream a short-lived authorized submission file without exposing raw storage URLs.
 */
router.get('/submissions/:submissionId/file/download', async (req, res) => {
  try {
    const { token } = req.query;
    if (!token) {
      return res.status(401).json({ success: false, error: 'Download token is required' });
    }

    let payload;
    try {
      payload = jwt.verify(token, FILE_DOWNLOAD_SECRET);
    } catch (_) {
      return res.status(401).json({ success: false, error: 'Invalid or expired download token' });
    }

    if (
      payload.submissionId?.toString() !== req.params.submissionId.toString()
    ) {
      return res.status(403).json({ success: false, error: 'Token does not match submission' });
    }

    const result = await AssignmentService.getSubmissionFile(
      req.params.submissionId,
      payload.requesterId
    );

    if (!result.success) {
      const status = result.error === 'Unauthorized' ? 403 : 404;
      return res.status(status).json(result);
    }

    const fileUrl = result.data?.fileUrl;
    if (!fileUrl) {
      return res.status(404).json({ success: false, error: 'File not available' });
    }

    const upstream = await fetch(fileUrl);
    if (!upstream.ok || !upstream.body) {
      return res.status(502).json({
        success: false,
        error: 'Unable to stream the requested file',
      });
    }

    const url = new URL(fileUrl);
    const ext = path.extname(url.pathname) || '';
    const filename = `submission-${req.params.submissionId}${ext}`;

    res.setHeader(
      'Content-Type',
      upstream.headers.get('content-type') || 'application/octet-stream'
    );
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="${filename}"`
    );

    upstream.body.pipe(res);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * DELETE /api/assignments/submissions/:submissionId/file
 * Delete submission file (owner or assignment creator)
 */
router.delete('/submissions/:submissionId/file', verifyToken, async (req, res) => {
  try {
    const result = await AssignmentService.deleteSubmissionFile(
      req.params.submissionId,
      req.user.id,
      req
    );

    if (!result.success) {
      const status = result.error === 'Unauthorized' ? 403 : 404;
      return res.status(status).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

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

    const enrolledUsers = await query(
      'SELECT user_id FROM enrollments WHERE course_id = $1',
      [result.data.course_id]
    );

    const recipientIds = enrolledUsers.rows
      .map((row) => parseInt(row.user_id, 10))
      .filter((value) => Number.isFinite(value));

    if (recipientIds.length > 0) {
      await NotificationTriggerService.notifyMany({
        userIds: recipientIds,
        title: 'New Assignment Available',
        message: `${result.data.title} has been assigned. Review requirements and due date.`,
        type: 'assignment',
        actionUrl: `/assignments/${result.data.id}`,
        metadata: {
          action: 'assignment_created',
          resourceId: result.data.id,
          courseId: result.data.course_id,
        },
        push: true,
      });
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

      const submissionResult = await query(
        `SELECT s.user_id, s.assignment_id, a.title
         FROM submissions s
         JOIN assignments a ON a.id = s.assignment_id
         WHERE s.id = $1`,
        [req.params.submissionId]
      );

      const submission = submissionResult.rows[0];
      if (submission?.user_id) {
        await NotificationTriggerService.notifyUser({
          userId: submission.user_id,
          title: 'Assignment Graded',
          message: `${submission.title} has been graded. Check your feedback and score.`,
          type: 'assignment',
          actionUrl: `/assignments/${submission.assignment_id}`,
          metadata: {
            action: 'assignment_graded',
            resourceId: submission.assignment_id,
            submissionId: parseInt(req.params.submissionId, 10),
          },
          push: true,
        });
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
