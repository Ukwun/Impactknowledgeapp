const express = require('express');
const { query } = require('../database');

const router = express.Router();

/**
 * GET /api/public/landing-content
 * Public landing page content and real platform counters
 */
router.get('/landing-content', async (req, res) => {
  try {
    const [statsResult, partnersResult, testimonialsResult] = await Promise.all([
      query(
        `SELECT
           (SELECT COUNT(*) FROM users WHERE role = 'student') as learners,
           (SELECT COUNT(*) FROM courses WHERE is_published = true) as courses,
           (SELECT COUNT(*) FROM users WHERE role IN ('instructor', 'facilitator')) as institutions`
      ),
      query(
        `SELECT id, name, website_url, logo_url
         FROM platform_partners
         WHERE is_active = true
         ORDER BY created_at DESC
         LIMIT 12`
      ),
      query(
        `SELECT id, quote, author_name, author_role
         FROM testimonials
         WHERE is_active = true
         ORDER BY created_at DESC
         LIMIT 12`
      ),
    ]);

    res.json({
      success: true,
      data: {
        impactNumbers: {
          learners: parseInt(statsResult.rows[0]?.learners || 0),
          courses: parseInt(statsResult.rows[0]?.courses || 0),
          institutions: parseInt(statsResult.rows[0]?.institutions || 0),
        },
        partners: partnersResult.rows,
        testimonials: testimonialsResult.rows,
      },
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

module.exports = router;
