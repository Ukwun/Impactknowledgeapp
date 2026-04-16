const express = require('express');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');
const ActivityService = require('../services/activity-service');

const router = express.Router();

// Helper: Check if user is instructor or admin
async function isInstructor(userId) {
  const result = await query('SELECT role FROM users WHERE id = $1', [userId]);
  return result.rows.length > 0 && (result.rows[0].role === 'instructor' || result.rows[0].role === 'admin');
}

// ============================================
// GET ENDPOINTS (Public & Protected)
// ============================================

// Get all courses with filtering and search
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const pageSize = parseInt(req.query.pageSize) || 20;
    const category = req.query.category;
    const search = req.query.search;
    const level = req.query.level;
    const sortBy = req.query.sortBy || 'created_at';

    const offset = (page - 1) * pageSize;
    let whereClause = 'WHERE is_published = true';
    let params = [];

    if (category) {
      whereClause += ' AND category = $' + (params.length + 1);
      params.push(category);
    }

    if (level) {
      whereClause += ' AND level = $' + (params.length + 1);
      params.push(level);
    }

    if (search) {
      whereClause += ' AND (title ILIKE $' + (params.length + 1) + ' OR description ILIKE $' + (params.length + 2) + ')';
      params.push(`%${search}%`, `%${search}%`);
    }

    // Get total count
    const countResult = await query(
      `SELECT COUNT(*) as count FROM courses ${whereClause}`,
      params
    );
    const total = parseInt(countResult.rows[0].count);

    // Get paginated courses
    const paramsWithPagination = [...params, pageSize, offset];
    const coursesResult = await query(
      `SELECT id, title, description, category, thumbnail_url, price, level, duration_hours, instructor_id, created_at
       FROM courses 
       ${whereClause} 
       ORDER BY ${sortBy} DESC 
       LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
      paramsWithPagination
    );

    // Get enrollment counts for each course
    const coursesWithCounts = await Promise.all(
      coursesResult.rows.map(async (course) => {
        const enrollResult = await query(
          'SELECT COUNT(*) as count FROM enrollments WHERE course_id = $1',
          [course.id]
        );
        return {
          ...course,
          enrollmentCount: parseInt(enrollResult.rows[0]?.count || 0)
        };
      })
    );

    res.json({
      success: true,
      data: coursesWithCounts,
      pagination: {
        page,
        pageSize,
        total,
        pages: Math.ceil(total / pageSize)
      }
    });
  } catch (err) {
    console.error('Get courses error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch courses' });
  }
});

// Get course by ID (with modules and lessons)
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Get course
    const courseResult = await query(
      'SELECT id, title, description, category, thumbnail_url, price, level, duration_hours, instructor_id, is_published, created_at, updated_at FROM courses WHERE id = $1',
      [id]
    );

    if (courseResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Course not found' });
    }

    const course = courseResult.rows[0];

    // Get modules
    const modulesResult = await query(
      'SELECT id, course_id, title, description, order_index FROM modules WHERE course_id = $1 ORDER BY order_index ASC',
      [id]
    );

    // Get enrollment count
    const enrollResult = await query(
      'SELECT COUNT(*) as count FROM enrollments WHERE course_id = $1',
      [id]
    );

    res.json({
      success: true,
      data: {
        ...course,
        modules: modulesResult.rows,
        enrollmentCount: parseInt(enrollResult.rows[0]?.count || 0)
      }
    });
  } catch (err) {
    console.error('Get course error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch course' });
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

    res.json({
      success: true,
      data: result.rows
    });
  } catch (err) {
    console.error('Get modules error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch modules' });
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

    res.json({
      success: true,
      data: result.rows
    });
  } catch (err) {
    console.error('Get lessons error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch lessons' });
  }
});

// Get instructor's courses
router.get('/instructor/:instructorId/courses', async (req, res) => {
  try {
    const { instructorId } = req.params;
    const result = await query(
      'SELECT id, title, description, category, thumbnail_url, price, level, duration_hours, is_published, created_at FROM courses WHERE instructor_id = $1 ORDER BY created_at DESC',
      [instructorId]
    );

    res.json({
      success: true,
      data: result.rows
    });
  } catch (err) {
    console.error('Get instructor courses error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch courses' });
  }
});

// ============================================
// POST ENDPOINTS (Create)
// ============================================

// Create new course
router.post('/', verifyToken, async (req, res) => {
  try {
    // Check if user is instructor or admin
    const isInstr = await isInstructor(req.user.id);
    if (!isInstr) {
      return res.status(403).json({ success: false, error: 'Only instructors can create courses' });
    }

    const { title, description, category, price = 0, level, duration_hours, thumbnail_url } = req.body;

    // Validation
    if (!title || !category || level === undefined) {
      return res.status(400).json({ success: false, error: 'Title, category, and level are required' });
    }

    const result = await query(
      `INSERT INTO courses (title, description, category, instructor_id, price, level, duration_hours, thumbnail_url, is_published, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
       RETURNING id, title, description, category, price, level, duration_hours, created_at`,
      [title, description, category, req.user.id, price, level, duration_hours, thumbnail_url]
    );

    // Log activity
    await ActivityService.logActivity(req.user.id, 'CREATE_COURSE', 'course', result.rows[0].id, { title }, req);

    res.status(201).json({
      success: true,
      message: 'Course created successfully',
      data: result.rows[0]
    });
  } catch (err) {
    console.error('Create course error:', err);
    res.status(500).json({ success: false, error: 'Failed to create course' });
  }
});

// Create module for course
router.post('/:courseId/modules', verifyToken, async (req, res) => {
  try {
    const { courseId } = req.params;
    const { title, description, order_index } = req.body;

    // Verify ownership
    const courseResult = await query(
      'SELECT instructor_id FROM courses WHERE id = $1',
      [courseId]
    );

    if (courseResult.rows.length === 0 || (courseResult.rows[0].instructor_id !== req.user.id && req.user.role !== 'admin')) {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    const result = await query(
      `INSERT INTO modules (course_id, title, description, order_index, created_at, updated_at)
       VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
       RETURNING id, course_id, title, description, order_index`,
      [courseId, title, description, order_index || 1]
    );

    res.status(201).json({
      success: true,
      message: 'Module created successfully',
      data: result.rows[0]
    });
  } catch (err) {
    console.error('Create module error:', err);
    res.status(500).json({ success: false, error: 'Failed to create module' });
  }
});

// Create lesson for module
router.post('/:courseId/lessons', verifyToken, async (req, res) => {
  try {
    const { courseId } = req.params;
    const { moduleId, title, description, content_type, content_url, order_index, duration_minutes } = req.body;

    // Verify ownership
    const courseResult = await query(
      'SELECT instructor_id FROM courses WHERE id = $1',
      [courseId]
    );

    if (courseResult.rows.length === 0 || (courseResult.rows[0].instructor_id !== req.user.id && req.user.role !== 'admin')) {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    const result = await query(
      `INSERT INTO lessons (module_id, title, description, content_type, content_url, order_index, duration_minutes, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
       RETURNING id, module_id, title, description, content_type, content_url, order_index, duration_minutes`,
      [moduleId, title, description, content_type, content_url, order_index || 1, duration_minutes]
    );

    res.status(201).json({
      success: true,
      message: 'Lesson created successfully',
      data: result.rows[0]
    });
  } catch (err) {
    console.error('Create lesson error:', err);
    res.status(500).json({ success: false, error: 'Failed to create lesson' });
  }
});

// ============================================
// PUT ENDPOINTS (Update)
// ============================================

// Update course
router.put('/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, category, price, level, duration_hours, thumbnail_url, is_published } = req.body;

    // Verify ownership
    const courseResult = await query(
      'SELECT instructor_id FROM courses WHERE id = $1',
      [id]
    );

    if (courseResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Course not found' });
    }

    if (courseResult.rows[0].instructor_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    const result = await query(
      `UPDATE courses SET
        title = COALESCE($2, title),
        description = COALESCE($3, description),
        category = COALESCE($4, category),
        price = COALESCE($5, price),
        level = COALESCE($6, level),
        duration_hours = COALESCE($7, duration_hours),
        thumbnail_url = COALESCE($8, thumbnail_url),
        is_published = COALESCE($9, is_published),
        updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING id, title, description, category, price, level, duration_hours, is_published, updated_at`,
      [id, title, description, category, price, level, duration_hours, thumbnail_url, is_published]
    );

    // Log activity
    await ActivityService.logActivity(req.user.id, 'UPDATE_COURSE', 'course', id, { title: result.rows[0].title }, req);

    res.json({
      success: true,
      message: 'Course updated successfully',
      data: result.rows[0]
    });
  } catch (err) {
    console.error('Update course error:', err);
    res.status(500).json({ success: false, error: 'Failed to update course' });
  }
});

// Update module
router.put('/modules/:moduleId', verifyToken, async (req, res) => {
  try {
    const { moduleId } = req.params;
    const { title, description, order_index } = req.body;

    // Verify ownership through course
    const moduleResult = await query(
      'SELECT m.course_id FROM modules m JOIN courses c ON m.course_id = c.id WHERE m.id = $1',
      [moduleId]
    );

    if (moduleResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Module not found' });
    }

    const result = await query(
      `UPDATE modules SET
        title = COALESCE($2, title),
        description = COALESCE($3, description),
        order_index = COALESCE($4, order_index),
        updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING id, course_id, title, description, order_index`,
      [moduleId, title, description, order_index]
    );

    res.json({
      success: true,
      message: 'Module updated successfully',
      data: result.rows[0]
    });
  } catch (err) {
    console.error('Update module error:', err);
    res.status(500).json({ success: false, error: 'Failed to update module' });
  }
});

// Update lesson
router.put('/lessons/:lessonId', verifyToken, async (req, res) => {
  try {
    const { lessonId } = req.params;
    const { title, description, content_type, content_url, order_index, duration_minutes } = req.body;

    const result = await query(
      `UPDATE lessons SET
        title = COALESCE($2, title),
        description = COALESCE($3, description),
        content_type = COALESCE($4, content_type),
        content_url = COALESCE($5, content_url),
        order_index = COALESCE($6, order_index),
        duration_minutes = COALESCE($7, duration_minutes),
        updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING id, module_id, title, description, content_type, content_url, order_index, duration_minutes`,
      [lessonId, title, description, content_type, content_url, order_index, duration_minutes]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Lesson not found' });
    }

    res.json({
      success: true,
      message: 'Lesson updated successfully',
      data: result.rows[0]
    });
  } catch (err) {
    console.error('Update lesson error:', err);
    res.status(500).json({ success: false, error: 'Failed to update lesson' });
  }
});

// ============================================
// DELETE ENDPOINTS
// ============================================

// Delete course
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;

    // Verify ownership
    const courseResult = await query(
      'SELECT instructor_id, title FROM courses WHERE id = $1',
      [id]
    );

    if (courseResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Course not found' });
    }

    if (courseResult.rows[0].instructor_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    await query('DELETE FROM courses WHERE id = $1', [id]);

    // Log activity
    await ActivityService.logActivity(req.user.id, 'DELETE_COURSE', 'course', id, { title: courseResult.rows[0].title }, req);

    res.json({
      success: true,
      message: 'Course deleted successfully'
    });
  } catch (err) {
    console.error('Delete course error:', err);
    res.status(500).json({ success: false, error: 'Failed to delete course' });
  }
});

// Delete module
router.delete('/modules/:moduleId', verifyToken, async (req, res) => {
  try {
    const { moduleId } = req.params;

    await query('DELETE FROM modules WHERE id = $1', [moduleId]);

    res.json({
      success: true,
      message: 'Module deleted successfully'
    });
  } catch (err) {
    console.error('Delete module error:', err);
    res.status(500).json({ success: false, error: 'Failed to delete module' });
  }
});

// Delete lesson
router.delete('/lessons/:lessonId', verifyToken, async (req, res) => {
  try {
    const { lessonId } = req.params;

    await query('DELETE FROM lessons WHERE id = $1', [lessonId]);

    res.json({
      success: true,
      message: 'Lesson deleted successfully'
    });
  } catch (err) {
    console.error('Delete lesson error:', err);
    res.status(500).json({ success: false, error: 'Failed to delete lesson' });
  }
});

module.exports = router;
