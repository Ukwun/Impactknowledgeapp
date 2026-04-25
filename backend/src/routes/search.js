const express = require('express');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

/**
 * GET /api/search/global?q=term&type=all&limit=10
 * Unified search across courses, lessons, assignments, quizzes, and events.
 */
router.get('/global', verifyToken, async (req, res) => {
  try {
    const q = (req.query.q || '').toString().trim();
    const type = (req.query.type || 'all').toString();
    const limit = Math.min(parseInt(req.query.limit || '8', 10), 25);

    if (!q) {
      return res.status(400).json({
        success: false,
        error: 'Search query parameter q is required',
      });
    }

    const pattern = `%${q}%`;
    const out = {
      courses: [],
      lessons: [],
      assignments: [],
      quizzes: [],
      events: [],
      users: [],
    };

    if (type === 'all' || type === 'courses') {
      const courses = await query(
        `SELECT id, title, description, category, 'course' as content_type
         FROM courses
         WHERE is_published = true
           AND (title ILIKE $1 OR description ILIKE $1 OR category ILIKE $1)
         ORDER BY updated_at DESC
         LIMIT $2`,
        [pattern, limit]
      );
      out.courses = courses.rows;
    }

    if (type === 'all' || type === 'lessons') {
      const lessons = await query(
        `SELECT l.id, l.title, l.description, m.course_id, c.title as course_title, 'lesson' as content_type
         FROM lessons l
         JOIN modules m ON l.module_id = m.id
         JOIN courses c ON m.course_id = c.id
         WHERE c.is_published = true
           AND (l.title ILIKE $1 OR l.description ILIKE $1)
         ORDER BY l.updated_at DESC
         LIMIT $2`,
        [pattern, limit]
      );
      out.lessons = lessons.rows;
    }

    if (type === 'all' || type === 'assignments') {
      const assignments = await query(
        `SELECT a.id, a.title, a.description, a.due_date, c.id as course_id, c.title as course_title, 'assignment' as content_type
         FROM assignments a
         JOIN courses c ON a.course_id = c.id
         WHERE c.is_published = true
           AND (a.title ILIKE $1 OR a.description ILIKE $1)
         ORDER BY a.updated_at DESC
         LIMIT $2`,
        [pattern, limit]
      );
      out.assignments = assignments.rows;
    }

    if (type === 'all' || type === 'quizzes') {
      const quizzes = await query(
        `SELECT q.id, q.title, q.description, q.time_limit_minutes, c.id as course_id, c.title as course_title, 'quiz' as content_type
         FROM quizzes q
         JOIN courses c ON q.course_id = c.id
         WHERE c.is_published = true
           AND (q.title ILIKE $1 OR q.description ILIKE $1)
         ORDER BY q.updated_at DESC
         LIMIT $2`,
        [pattern, limit]
      );
      out.quizzes = quizzes.rows;
    }

    if (type === 'all' || type === 'events') {
      const events = await query(
        `SELECT id, title, description, event_type, start_date, location, 'event' as content_type
         FROM events
         WHERE (title ILIKE $1 OR description ILIKE $1 OR event_type ILIKE $1)
         ORDER BY start_date DESC
         LIMIT $2`,
        [pattern, limit]
      );
      out.events = events.rows;
    }

    if ((type === 'all' || type === 'users') && req.user.role === 'admin') {
      const users = await query(
        `SELECT id, full_name as title, email as description, role, 'user' as content_type
         FROM users
         WHERE is_active = true
           AND (full_name ILIKE $1 OR email ILIKE $1 OR role ILIKE $1)
         ORDER BY updated_at DESC NULLS LAST, created_at DESC
         LIMIT $2`,
        [pattern, limit]
      );
      out.users = users.rows;
    }

    const total =
      out.courses.length +
      out.lessons.length +
      out.assignments.length +
      out.quizzes.length +
      out.events.length +
      out.users.length;

    res.json({
      success: true,
      query: q,
      type,
      total,
      data: out,
    });
  } catch (err) {
    console.error('Global search error:', err);
    res.status(500).json({ success: false, error: 'Failed to search content' });
  }
});

module.exports = router;
