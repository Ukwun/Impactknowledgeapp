const express = require('express');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

// Get all courses with pagination and search
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const pageSize = parseInt(req.query.pageSize) || 20;
    const category = req.query.category;
    const search = req.query.search;

    const offset = (page - 1) * pageSize;
    let whereClause = 'WHERE is_published = true';
    let params = [];

    if (category) {
      whereClause += ' AND category = $' + (params.length + 1);
      params.push(category);
    }

    if (search) {
      whereClause += ' AND (title ILIKE $' + (params.length + 1) + ' OR description ILIKE $' + (params.length + 2) + ')';
      params.push(`%${search}%`, `%${search}%`);
    }

    // Get total count
    const countResult = await query(`SELECT COUNT(*) as count FROM courses ${whereClause}`, params);
    const total = parseInt(countResult.rows[0].count);

    // Get paginated courses
    const paramsWithPagination = [...params, pageSize, offset];
    const coursesResult = await query(
      `SELECT id, title, description, category, thumbnail_url, price, level, duration_hours, instructor_id
       FROM courses ${whereClause} ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
      paramsWithPagination
    );

    res.json({
      data: coursesResult.rows,
      pagination: {
        page,
        pageSize,
        total,
        pages: Math.ceil(total / pageSize)
      }
    });
  } catch (err) {
    console.error('Get courses error:', err);
    res.status(500).json({ error: 'Failed to fetch courses' });
  }
});

// Get course by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await query(
      'SELECT id, title, description, category, thumbnail_url, price, level, duration_hours, instructor_id FROM courses WHERE id = $1 AND is_published = true',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Course not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Get course error:', err);
    res.status(500).json({ error: 'Failed to fetch course' });
  }
});

// Get course modules
router.get('/:courseId/modules', async (req, res) => {
  try {
    const { courseId } = req.params;
    const result = await query(
      'SELECT id, course_id, title, description, order_index FROM modules WHERE course_id = $1 ORDER BY order_index ASC',
      [courseId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Get modules error:', err);
    res.status(500).json({ error: 'Failed to fetch modules' });
  }
});

// Get module lessons
router.get('/modules/:moduleId/lessons', async (req, res) => {
  try {
    const { moduleId } = req.params;
    const result = await query(
      'SELECT id, module_id, title, description, content_type, content_url, order_index, duration_minutes FROM lessons WHERE module_id = $1 ORDER BY order_index ASC',
      [moduleId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Get lessons error:', err);
    res.status(500).json({ error: 'Failed to fetch lessons' });
  }
});

module.exports = router;
