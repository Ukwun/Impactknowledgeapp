const express = require('express');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

// Enroll in a course
router.post('/', verifyToken, async (req, res) => {
  try {
    const { courseId } = req.body;

    if (!courseId) {
      return res.status(400).json({ error: 'courseId is required' });
    }

    // Check if course exists
    const courseResult = await query('SELECT id FROM courses WHERE id = $1', [courseId]);
    if (courseResult.rows.length === 0) {
      return res.status(404).json({ error: 'Course not found' });
    }

    // Check if already enrolled
    const enrollmentCheck = await query(
      'SELECT id FROM enrollments WHERE user_id = $1 AND course_id = $2',
      [req.user.id, courseId]
    );

    if (enrollmentCheck.rows.length > 0) {
      return res.status(409).json({ error: 'Already enrolled in this course' });
    }

    // Create enrollment
    const result = await query(
      'INSERT INTO enrollments (user_id, course_id, enrollment_date) VALUES ($1, $2, CURRENT_TIMESTAMP) RETURNING *',
      [req.user.id, courseId]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Enroll error:', err);
    res.status(500).json({ error: 'Enrollment failed' });
  }
});

// Get user enrollments
router.get('/', verifyToken, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const pageSize = parseInt(req.query.pageSize) || 20;
    const offset = (page - 1) * pageSize;

    const result = await query(
      `SELECT e.id, e.user_id, e.course_id, e.enrollment_date, e.completion_status, e.progress_percentage,
              c.title, c.description, c.thumbnail_url, c.price
       FROM enrollments e
       JOIN courses c ON e.course_id = c.id
       WHERE e.user_id = $1
       ORDER BY e.enrollment_date DESC
       LIMIT $2 OFFSET $3`,
      [req.user.id, pageSize, offset]
    );

    // Get total count
    const countResult = await query(
      'SELECT COUNT(*) as count FROM enrollments WHERE user_id = $1',
      [req.user.id]
    );
    const total = parseInt(countResult.rows[0].count);

    res.json({
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
    res.status(500).json({ error: 'Failed to fetch enrollments' });
  }
});

// Get enrollment by ID
router.get('/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await query(
      'SELECT * FROM enrollments WHERE id = $1 AND user_id = $2',
      [id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Enrollment not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Get enrollment error:', err);
    res.status(500).json({ error: 'Failed to fetch enrollment' });
  }
});

// Update enrollment progress
router.put('/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { completion_status, progress_percentage } = req.body;

    const result = await query(
      `UPDATE enrollments 
       SET completion_status = COALESCE($1, completion_status),
           progress_percentage = COALESCE($2, progress_percentage)
       WHERE id = $3 AND user_id = $4
       RETURNING *`,
      [completion_status, progress_percentage, id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Enrollment not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Update enrollment error:', err);
    res.status(500).json({ error: 'Failed to update enrollment' });
  }
});

module.exports = router;
