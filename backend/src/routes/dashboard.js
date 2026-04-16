const express = require('express');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');
const ActivityService = require('../services/activity-service');

const router = express.Router();

// Authorization middleware - Admin only
const adminOnly = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ success: false, error: 'Admin access required' });
  }
  next();
};

// Facilitator check middleware
const facilitatorOrAdmin = (req, res, next) => {
  if (!['instructor', 'facilitator', 'admin'].includes(req.user.role)) {
    return res.status(403).json({ success: false, error: 'Facilitator access required' });
  }
  next();
};

// ============================================
// ANALYTICS ENDPOINTS
// ============================================

// Get platform-wide analytics (Admin only)
router.get('/admin/analytics', verifyToken, adminOnly, async (req, res) => {
  try {
    const analytics = await ActivityService.getPlatformAnalytics();
    res.json({
      success: true,
      data: analytics
    });
  } catch (err) {
    console.error('Analytics error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch analytics' });
  }
});

// Get user activity summary
router.get('/user/:userId/activity', verifyToken, async (req, res) => {
  try {
    const { userId } = req.params;
    const daysBack = req.query.daysBack || 30;

    // Check authorization
    if (parseInt(userId) !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    const activitySummary = await ActivityService.getUserActivitySummary(userId, daysBack);
    const engagement = await ActivityService.calculateEngagementMetrics(userId);
    const activities = await ActivityService.getUserActivities(userId, 50);

    res.json({
      success: true,
      data: {
        summary: activitySummary,
        engagement,
        recentActivities: activities
      }
    });
  } catch (err) {
    console.error('User activity error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch activity' });
  }
});

// Get personalized recommendations
router.get('/user/:userId/recommendations', verifyToken, async (req, res) => {
  try {
    const { userId } = req.params;

    // Check authorization
    if (parseInt(userId) !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    const recommendations = await ActivityService.getRecommendedCourses(userId);

    res.json({
      success: true,
      data: recommendations
    });
  } catch (err) {
    console.error('Recommendations error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch recommendations' });
  }
});

// ============================================
// STUDENT DASHBOARD
// ============================================

router.get('/student', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;

    // Execute all queries in parallel for better performance
    const [enrollmentsResult, analyticsResult, achievementsResult, activitySummary] = 
      await Promise.all([
        query(
          `SELECT e.id, c.id as course_id, c.title, c.description, c.thumbnail_url, c.category, 
                  e.progress_percentage, e.completion_status, e.enrollment_date
           FROM enrollments e
           JOIN courses c ON e.course_id = c.id
           WHERE e.user_id = $1 AND c.is_published = true
           ORDER BY e.enrollment_date DESC
           LIMIT 10`,
          [userId]
        ),
        query(
          'SELECT total_lessons_completed, total_courses_completed, engagement_level, churn_risk_score FROM user_analytics WHERE user_id = $1',
          [userId]
        ),
        query(
          'SELECT COUNT(*) as count FROM user_achievements WHERE user_id = $1 AND unlocked_at IS NOT NULL',
          [userId]
        ),
        ActivityService.getUserActivitySummary(userId, 7)
      ]);

    const userAnalytics = analyticsResult.rows[0] || {
      total_lessons_completed: 0,
      total_courses_completed: 0,
      engagement_level: 'low',
      churn_risk_score: 0
    };

    res.json({
      success: true,
      data: {
        enrolledCourses: enrollmentsResult.rows,
        enrollmentCount: enrollmentsResult.rows.length,
        lessonsCompleted: userAnalytics.total_lessons_completed,
        coursesCompleted: userAnalytics.total_courses_completed,
        engagementLevel: userAnalytics.engagement_level,
        churnRiskScore: parseFloat(userAnalytics.churn_risk_score || 0).toFixed(2),
        achievementCount: parseInt(achievementsResult.rows[0]?.count || 0),
        recentActivity: activitySummary
      }
    });
  } catch (err) {
    console.error('Student dashboard error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch student dashboard' });
  }
});

// ============================================
// FACILITATOR DASHBOARD
// ============================================

router.get('/facilitator', verifyToken, facilitatorOrAdmin, async (req, res) => {
  try {
    const userId = req.user.id;

    // Get instructor's courses
    const coursesResult = await query(
      'SELECT id, title, description, is_published, created_at FROM courses WHERE instructor_id = $1 ORDER BY created_at DESC',
      [userId]
    );

    const courses = coursesResult.rows;

    if (courses.length === 0) {
      return res.json({
        success: true,
        data: {
          courses: [],
          totalStudents: 0,
          avgProgress: '0.00',
          pendingGrading: 0,
          courseCount: 0
        }
      });
    }

    // Get all stats in one optimized query
    const courseIds = courses.map(c => c.id);
    const [statsResult, performanceResult] = await Promise.all([
      query(
        `SELECT 
           course_id,
           COUNT(*) as enrollment_count
         FROM enrollments
         WHERE course_id = ANY($1)
         GROUP BY course_id`,
        [courseIds]
      ),
      query(
        `SELECT 
           AVG(e.progress_percentage) as avg_progress,
           COUNT(e.id) as total_enrollments,
           (SELECT COUNT(*) FROM assignments a JOIN submissions s ON a.id = s.assignment_id 
            WHERE a.course_id = ANY($1) AND s.grade IS NULL) as pending_grades
         FROM enrollments e
         WHERE e.course_id = ANY($1)`,
        [courseIds]
      )
    ]);

    // Map enrollment counts to courses
    const enrollmentMap = {};
    statsResult.rows.forEach(row => {
      enrollmentMap[row.course_id] = row.enrollment_count;
    });

    const courseStats = courses.map(course => ({
      ...course,
      enrollmentCount: enrollmentMap[course.id] || 0
    }));

    const performance = performanceResult.rows[0] || {
      avg_progress: 0,
      total_enrollments: 0,
      pending_grades: 0
    };

    res.json({
      success: true,
      data: {
        courses: courseStats,
        totalStudents: parseInt(performance.total_enrollments || 0),
        avgProgress: parseFloat(performance.avg_progress || 0).toFixed(2),
        pendingGrading: parseInt(performance.pending_grades || 0),
        courseCount: courses.length
      }
    });
  } catch (err) {
    console.error('Facilitator dashboard error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch facilitator dashboard' });
  }
});

// ============================================
// ADMIN DASHBOARD
// ============================================

router.get('/admin', verifyToken, adminOnly, async (req, res) => {
  try {
    // Execute all admin dashboard queries in parallel for better performance
    const [statsResult, activitiesResult, instructorsResult, atRiskResult, userCountsResult] = 
      await Promise.all([
        ActivityService.getPlatformAnalytics(),
        query(
          `SELECT action_type, COUNT(*) as count
           FROM user_activities
           WHERE created_at >= NOW() - INTERVAL '24 hours'
           GROUP BY action_type
           ORDER BY count DESC`,
          []
        ),
        query(
          `SELECT u.id, u.full_name, COUNT(c.id) as course_count, COUNT(DISTINCT e.id) as total_enrollments
           FROM users u
           LEFT JOIN courses c ON u.id = c.instructor_id
           LEFT JOIN enrollments e ON c.id = e.course_id
           WHERE u.role IN ('instructor', 'facilitator')
           GROUP BY u.id, u.full_name
           ORDER BY total_enrollments DESC
           LIMIT 10`,
          []
        ),
        query(
          `SELECT u.id, u.full_name, u.email, ua.engagement_level, ua.churn_risk_score
           FROM users u
           LEFT JOIN user_analytics ua ON u.id = ua.user_id
           WHERE u.role = 'student' AND ua.churn_risk_score > 0.7
           ORDER BY ua.churn_risk_score DESC
           LIMIT 10`,
          []
        ),
        query(
          `SELECT 
             (SELECT COUNT(*) FROM users WHERE role = 'student') as student_count,
             (SELECT COUNT(*) FROM users WHERE role IN ('instructor', 'facilitator')) as instructor_count,
             (SELECT COUNT(*) FROM users WHERE role = 'admin') as admin_count,
             (SELECT COUNT(DISTINCT course_id) FROM enrollments) as total_courses,
             (SELECT COUNT(*) FROM enrollments) as total_enrollments`,
          []
        )
      ]);

    const userCounts = userCountsResult.rows[0];

    res.json({
      success: true,
      data: {
        platformStats: statsResult,
        userRoles: {
          students: parseInt(userCounts.student_count || 0),
          instructors: parseInt(userCounts.instructor_count || 0),
          admins: parseInt(userCounts.admin_count || 0)
        },
        recentActivity: activitiesResult.rows,
        topInstructors: instructorsResult.rows,
        atRiskStudents: atRiskResult.rows,
        enrollmentStats: {
          totalCourses: parseInt(userCounts.total_courses || 0),
          totalEnrollments: parseInt(userCounts.total_enrollments || 0)
        }
      }
    });
  } catch (err) {
    console.error('Admin dashboard error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch admin dashboard' });
  }
});

// ============================================
// PARENT/GUARDIAN DASHBOARD
// ============================================

router.get('/parent', verifyToken, async (req, res) => {
  try {
    // Parent dashboard requires parent-child relationship table
    // This is a placeholder for future implementation
    res.json({
      success: true,
      data: {
        message: 'Parent dashboard requires future implementation (parent-child mapping table needed)',
        status: 'coming_soon',
        childrenBeingMonitored: 0,
        overallProgress: 0
      }
    });
  } catch (err) {
    console.error('Parent dashboard error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch dashboard' });
  }
});

// ============================================
// MENTOR DASHBOARD
// ============================================

router.get('/mentor', verifyToken, facilitatorOrAdmin, async (req, res) => {
  try {
    const userId = req.user.id;

    const [menteeCountResult, sessionsResult, feedbackResult] = await Promise.all([
      query(
        'SELECT COUNT(*) as count FROM mentorships WHERE mentor_id = $1 AND status = $2',
        [userId, 'active']
      ),
      query(
        `SELECT COUNT(*) as count FROM mentorship_sessions 
         WHERE mentor_id = $1 AND session_date >= NOW() - INTERVAL '7 days'`,
        [userId]
      ),
      query(
        'SELECT AVG(rating) as avg_rating FROM mentorship_feedback WHERE mentor_id = $1',
        [userId]
      )
    ]);

    res.json({
      success: true,
      data: {
        activeMentees: parseInt(menteeCountResult.rows[0]?.count || 0),
        recentSessions: parseInt(sessionsResult.rows[0]?.count || 0),
        averageRating: parseFloat(feedbackResult.rows[0]?.avg_rating || 0).toFixed(2),
        mentorStatus: 'active'
      }
    });
  } catch (err) {
    console.error('Mentor dashboard error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch mentor dashboard' });
  }
});

module.exports = router;
