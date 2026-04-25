const express = require('express');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');
const ActivityService = require('../services/activity-service');
const NotificationTriggerService = require('../services/notification-trigger-service');

const router = express.Router();

// Helper: Check if user can manage course content.
async function canManageCourses(userId) {
  const result = await query('SELECT role FROM users WHERE id = $1', [userId]);
  return (
    result.rows.length > 0 &&
    ['instructor', 'facilitator', 'admin', 'school_admin'].includes(result.rows[0].role)
  );
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

// Get course analytics (owner/admin)
router.get('/:id/analytics', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;

    const ownership = await query(
      'SELECT instructor_id FROM courses WHERE id = $1',
      [id]
    );

    if (ownership.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Course not found' });
    }

    const canAccess =
      ownership.rows[0].instructor_id === req.user.id ||
      ['admin', 'school_admin'].includes(req.user.role);

    if (!canAccess) {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    const [enrollmentResult, completionResult, modulesResult, lessonsResult] = await Promise.all([
      query('SELECT COUNT(*) as count FROM enrollments WHERE course_id = $1', [id]),
      query(
        `SELECT COUNT(*) as count
         FROM enrollments
         WHERE course_id = $1 AND completion_status = 'completed'`,
        [id]
      ),
      query('SELECT COUNT(*) as count FROM modules WHERE course_id = $1', [id]),
      query(
        `SELECT COUNT(*) as count
         FROM lessons l
         JOIN modules m ON m.id = l.module_id
         WHERE m.course_id = $1`,
        [id]
      ),
    ]);

    const totalEnrollments = parseInt(enrollmentResult.rows[0]?.count || 0);
    const completed = parseInt(completionResult.rows[0]?.count || 0);

    res.json({
      success: true,
      data: {
        courseId: id,
        totalEnrollments,
        completedEnrollments: completed,
        completionRate: totalEnrollments > 0 ? Number(((completed / totalEnrollments) * 100).toFixed(1)) : 0,
        moduleCount: parseInt(modulesResult.rows[0]?.count || 0),
        lessonCount: parseInt(lessonsResult.rows[0]?.count || 0),
      }
    });
  } catch (err) {
    console.error('Get course analytics error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch course analytics' });
  }
});

// Get course reports (owner/admin)
router.get('/:id/reports', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;

    const ownership = await query(
      'SELECT instructor_id, title FROM courses WHERE id = $1',
      [id]
    );

    if (ownership.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Course not found' });
    }

    const canAccess =
      ownership.rows[0].instructor_id === req.user.id ||
      ['admin', 'school_admin'].includes(req.user.role);

    if (!canAccess) {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    const [progressSummary, recentEnrollments] = await Promise.all([
      query(
        `SELECT
           COUNT(*) as total_learners,
           AVG(progress_percentage)::numeric(5,2) as avg_progress,
           COUNT(*) FILTER (WHERE completion_status = 'completed') as completed_learners,
           COUNT(*) FILTER (WHERE completion_status = 'in_progress') as active_learners
         FROM enrollments
         WHERE course_id = $1`,
        [id]
      ),
      query(
        `SELECT e.user_id, e.progress_percentage, e.completion_status, e.enrollment_date
         FROM enrollments e
         WHERE e.course_id = $1
         ORDER BY e.enrollment_date DESC
         LIMIT 20`,
        [id]
      )
    ]);

    res.json({
      success: true,
      data: {
        courseId: id,
        courseTitle: ownership.rows[0].title,
        summary: {
          totalLearners: parseInt(progressSummary.rows[0]?.total_learners || 0),
          avgProgress: Number(progressSummary.rows[0]?.avg_progress || 0),
          completedLearners: parseInt(progressSummary.rows[0]?.completed_learners || 0),
          activeLearners: parseInt(progressSummary.rows[0]?.active_learners || 0),
        },
        recentEnrollments: recentEnrollments.rows,
      }
    });
  } catch (err) {
    console.error('Get course reports error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch reports' });
  }
});

// Send course announcement to enrolled learners (owner/admin)
router.post('/:id/announcements', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { subject, message } = req.body;

    if (!subject || !message) {
      return res.status(400).json({ success: false, error: 'Subject and message are required' });
    }

    const ownership = await query(
      'SELECT instructor_id, title FROM courses WHERE id = $1',
      [id]
    );

    if (ownership.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Course not found' });
    }

    const canAccess =
      ownership.rows[0].instructor_id === req.user.id ||
      ['admin', 'school_admin'].includes(req.user.role);

    if (!canAccess) {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    const recipients = await query(
      'SELECT user_id FROM enrollments WHERE course_id = $1',
      [id]
    );

    const recipientIds = recipients.rows
      .map((row) => parseInt(row.user_id, 10))
      .filter((value) => Number.isFinite(value));

    if (recipientIds.length > 0) {
      await NotificationTriggerService.notifyMany({
        userIds: recipientIds,
        title: `Course Update: ${subject}`,
        message,
        type: 'course',
        actionUrl: `/courses/${id}`,
        metadata: {
          action: 'course_announcement',
          resourceId: parseInt(id, 10),
        },
        push: true,
      });
    }

    await ActivityService.logActivity(
      req.user.id,
      'COURSE_ANNOUNCEMENT',
      'course',
      id,
      {
        subject,
        message,
        courseTitle: ownership.rows[0].title,
        recipients: recipientIds.length,
      },
      req
    );

    res.status(201).json({
      success: true,
      message: 'Announcement sent',
      data: {
        courseId: id,
        recipients: recipientIds.length,
      }
    });
  } catch (err) {
    console.error('Create announcement error:', err);
    res.status(500).json({ success: false, error: 'Failed to send announcement' });
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
      'SELECT id, module_id, title, description, content_body, content_type, content_url, order_index, duration_minutes FROM lessons WHERE module_id = $1 ORDER BY order_index ASC',
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
    // Check if user can manage course content.
    const allowed = await canManageCourses(req.user.id);
    if (!allowed) {
      return res.status(403).json({ success: false, error: 'Only facilitators/instructors/admins can create courses' });
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
    const { moduleId, title, description, content_body, content_type, content_url, order_index, duration_minutes } = req.body;

    // Verify ownership
    const courseResult = await query(
      'SELECT instructor_id FROM courses WHERE id = $1',
      [courseId]
    );

    if (courseResult.rows.length === 0 || (courseResult.rows[0].instructor_id !== req.user.id && req.user.role !== 'admin')) {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    const result = await query(
      `INSERT INTO lessons (module_id, title, description, content_body, content_type, content_url, order_index, duration_minutes, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
       RETURNING id, module_id, title, description, content_body, content_type, content_url, order_index, duration_minutes`,
      [moduleId, title, description, content_body, content_type, content_url, order_index || 1, duration_minutes]
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
      'SELECT instructor_id, is_published, title FROM courses WHERE id = $1',
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

    const wasPublished = !!courseResult.rows[0].is_published;
    const nowPublished = !!result.rows[0].is_published;
    const courseTitle = result.rows[0].title;

    if (!wasPublished && nowPublished) {
      await NotificationTriggerService.notifyAllActiveUsers({
        title: 'New Course Published',
        message: `${courseTitle} is now live and open for enrollment.`,
        type: 'course',
        actionUrl: `/courses/${id}`,
        metadata: {
          action: 'course_published',
          resourceId: parseInt(id, 10),
        },
        push: true,
      });
    }

    if (wasPublished && !nowPublished) {
      const enrolledUsers = await query(
        'SELECT user_id FROM enrollments WHERE course_id = $1',
        [id]
      );

      const enrolledIds = enrolledUsers.rows
        .map((row) => parseInt(row.user_id, 10))
        .filter((value) => Number.isFinite(value));

      if (enrolledIds.length > 0) {
        await NotificationTriggerService.notifyMany({
          userIds: enrolledIds,
          title: 'Course Availability Update',
          message: `${courseTitle} is temporarily unavailable while updates are made.`,
          type: 'course',
          actionUrl: '/courses',
          metadata: {
            action: 'course_unpublished',
            resourceId: parseInt(id, 10),
          },
          push: false,
        });
      }
    }

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
    const { title, description, content_body, content_type, content_url, order_index, duration_minutes } = req.body;

    const result = await query(
      `UPDATE lessons SET
        title = COALESCE($2, title),
        description = COALESCE($3, description),
        content_body = COALESCE($4, content_body),
        content_type = COALESCE($5, content_type),
        content_url = COALESCE($6, content_url),
        order_index = COALESCE($7, order_index),
        duration_minutes = COALESCE($8, duration_minutes),
        updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING id, module_id, title, description, content_body, content_type, content_url, order_index, duration_minutes`,
      [lessonId, title, description, content_body, content_type, content_url, order_index, duration_minutes]
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
