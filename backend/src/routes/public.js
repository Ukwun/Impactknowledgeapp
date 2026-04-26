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

/**
 * GET /api/public/legal/privacy-policy
 * Public privacy policy endpoint for mobile app and store compliance.
 */
router.get('/legal/privacy-policy', async (req, res) => {
  res.json({
    success: true,
    data: {
      version: '2026-04-26',
      title: 'ImpactKnowledge Privacy Policy',
      summary:
        'We collect account, learning activity, and device notification data to deliver personalized learning, progress tracking, and classroom operations.',
      keyPoints: [
        'Learner activity data is used for progression, recommendations, and retention interventions.',
        'Parent and school-linked access is role-scoped and permission-gated.',
        'Safety and moderation logs are retained for safeguarding and compliance.',
        'Users can request data export and deletion through support channels.',
      ],
    },
  });
});

/**
 * GET /api/public/legal/terms
 * Public terms endpoint for mobile app and store compliance.
 */
router.get('/legal/terms', async (req, res) => {
  res.json({
    success: true,
    data: {
      version: '2026-04-26',
      title: 'ImpactKnowledge Terms of Service',
      summary:
        'Use of the platform requires adherence to learning conduct, payment terms, and child-safety policies.',
      keyPoints: [
        'Accounts are role-based and access is restricted by assigned permissions.',
        'Course progress, attendance, and assessment integrity are monitored.',
        'Abuse, harassment, and policy violations trigger moderation actions.',
        'Payments, refunds, and subscriptions follow posted billing terms.',
      ],
    },
  });
});

module.exports = router;
