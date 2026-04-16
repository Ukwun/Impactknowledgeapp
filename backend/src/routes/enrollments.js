const express = require('express');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');
const ActivityService = require('../services/activity-service');

const router = express.Router();

// ============================================
// POST ENDPOINTS (Create)
// ============================================

// Enroll in a course
router.post('/', verifyToken, async (req, res) => {
  try {
    const { courseId } = req.body;

    if (!courseId) {
      return res.status(400).json({ success: false, error: 'courseId is required' });
    }

    // Check if course exists
    const courseResult = await query(
      'SELECT id, title, price FROM courses WHERE id = $1',
      [courseId]
    );

    if (courseResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Course not found' });
    }

    const course = courseResult.rows[0];

    // Check if already enrolled
    const enrollmentCheck = await query(
      'SELECT id FROM enrollments WHERE user_id = $1 AND course_id = $2',
      [req.user.id, courseId]
    );

    if (enrollmentCheck.rows.length > 0) {
      return res.status(409).json({ success: false, error: 'Already enrolled in this course' });
    }

    // If course has a price, check if payment is required
    if (parseFloat(course.price) > 0) {
      return res.status(400).json({ 
        success: false, 
        error: 'This course requires payment. Start payment flow first.',
        requiresPayment: true
      });
    }

    // Create enrollment
    const result = await query(
      `INSERT INTO enrollments (user_id, course_id, enrollment_date, completion_status, progress_percentage)
       VALUES ($1, $2, CURRENT_TIMESTAMP, 'in_progress', 0)
       RETURNING id, user_id, course_id, enrollment_date, completion_status, progress_percentage`,
      [req.user.id, courseId]
    );

    // Log activity
    await ActivityService.logActivity(req.user.id, 'ENROLL_COURSE', 'course', courseId, { courseTitle: course.title }, req);

    res.status(201).json({
      success: true,
      message: 'Enrolled in course successfully',
      data: result.rows[0]
    });
  } catch (err) {
    console.error('Enroll error:', err);
    res.status(500).json({ success: false, error: 'Enrollment failed' });
  }
});

// ============================================
// GET ENDPOINTS
// ============================================

// Get user enrollments
router.get('/', verifyToken, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const pageSize = parseInt(req.query.pageSize) || 20;
    const status = req.query.status;
    const offset = (page - 1) * pageSize;

    let whereClause = 'WHERE e.user_id = $1';
    const params = [req.user.id];

    if (status) {
      whereClause += ` AND e.completion_status = $${params.length + 1}`;
      params.push(status);
    }

    // Get total count
    const countResult = await query(
      `SELECT COUNT(*) as count FROM enrollments e ${whereClause}`,
      params
    );
    const total = parseInt(countResult.rows[0].count);

    // Get paginated enrollments with course details
    const paramsWithPagination = [...params, pageSize, offset];
    const result = await query(
      `SELECT e.id, e.user_id, e.course_id, e.enrollment_date, e.completion_status, e.progress_percentage,
              c.title, c.description, c.thumbnail_url, c.price, c.category, c.level, c.duration_hours
       FROM enrollments e
       JOIN courses c ON e.course_id = c.id
       ${whereClause}
       ORDER BY e.enrollment_date DESC
       LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
      paramsWithPagination
    );

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        page,
        pageSize,
        total,
        pages: Math.ceil(total / pageSize)
      }
    });
  } catch (err) {
    console.error('Get enrollments error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch enrollments' });
  }
});

// Get enrollment by ID
router.get('/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await query(
      `SELECT e.*, c.title, c.description, c.category, c.level, c.duration_hours, c.thumbnail_url
       FROM enrollments e
       JOIN courses c ON e.course_id = c.id
       WHERE e.id = $1 AND e.user_id = $2`,
      [id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Enrollment not found' });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (err) {
    console.error('Get enrollment error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch enrollment' });
  }
});

// Get course enrollments (instructor/admin only)
router.get('/course/:courseId/enrollments', verifyToken, async (req, res) => {
  try {
    const { courseId } = req.params;

    // Verify instructor owns course or user is admin
    const courseResult = await query(
      'SELECT instructor_id FROM courses WHERE id = $1',
      [courseId]
    );

    if (courseResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Course not found' });
    }

    if (courseResult.rows[0].instructor_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    // Get enrollments
    const enrollmentsResult = await query(
      `SELECT e.id, e.user_id, e.completion_status, e.progress_percentage, e.enrollment_date,
              u.full_name, u.email
       FROM enrollments e
       JOIN users u ON e.user_id = u.id
       WHERE e.course_id = $1
       ORDER BY e.enrollment_date DESC`,
      [courseId]
    );

    res.json({
      success: true,
      data: enrollmentsResult.rows,
      totalEnrollments: enrollmentsResult.rows.length
    });
  } catch (err) {
    console.error('Get course enrollments error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch enrollments' });
  }
});

// ============================================
// PUT ENDPOINTS (Update)
// ============================================

// Update enrollment progress
router.put('/:id/progress', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { progress_percentage, completion_status } = req.body;

    // Verify ownership
    const enrollmentResult = await query(
      'SELECT user_id, course_id FROM enrollments WHERE id = $1',
      [id]
    );

    if (enrollmentResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Enrollment not found' });
    }

    if (enrollmentResult.rows[0].user_id !== req.user.id) {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    const result = await query(
      `UPDATE enrollments SET
        progress_percentage = COALESCE($2, progress_percentage),
        completion_status = COALESCE($3, completion_status),
        updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING id, progress_percentage, completion_status`,
      [id, progress_percentage, completion_status]
    );

    // Log activity if completed
    if (completion_status === 'completed') {
      await ActivityService.logActivity(
        req.user.id,
        'COMPLETE_COURSE',
        'course',
        enrollmentResult.rows[0].course_id,
        { enrollmentId: id },
        req
      );
    }

    res.json({
      success: true,
      message: 'Enrollment updated successfully',
      data: result.rows[0]
    });
  } catch (err) {
    console.error('Update enrollment error:', err);
    res.status(500).json({ success: false, error: 'Failed to update enrollment' });
  }
});

// ============================================
// DELETE ENDPOINTS
// ============================================

// Unenroll from course
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;

    // Verify ownership
    const enrollmentResult = await query(
      'SELECT user_id, course_id FROM enrollments WHERE id = $1',
      [id]
    );

    if (enrollmentResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Enrollment not found' });
    }

    if (enrollmentResult.rows[0].user_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    await query('DELETE FROM enrollments WHERE id = $1', [id]);

    // Log activity
    await ActivityService.logActivity(
      req.user.id,
      'UNENROLL_COURSE',
      'course',
      enrollmentResult.rows[0].course_id,
      { enrollmentId: id },
      req
    );

    res.json({
      success: true,
      message: 'Unenrolled successfully'
    });
  } catch (err) {
    console.error('Unenroll error:', err);
    res.status(500).json({ success: false, error: 'Failed to unenroll' });
  }
});

module.exports = router;
