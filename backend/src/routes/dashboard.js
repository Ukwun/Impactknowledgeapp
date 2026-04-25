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
    const [
      enrollmentsResult,
      analyticsResult,
      achievementsResult,
      activitySummary,
      pendingAssignmentsResult,
      availableQuizzesResult,
    ] = await Promise.all([
      query(
        `SELECT e.id, c.id as course_id, c.title, c.description, c.thumbnail_url, c.category,
                e.progress_percentage, e.completion_status, e.enrollment_date
         FROM enrollments e
         JOIN courses c ON e.course_id = c.id
         WHERE e.user_id = $1 AND c.is_published = true
         ORDER BY e.progress_percentage ASC, e.enrollment_date DESC
         LIMIT 10`,
        [userId]
      ),
      query(
        'SELECT total_lessons_completed, total_courses_completed, engagement_level, churn_risk_score FROM user_analytics WHERE user_id = $1',
        [userId]
      ),
      query(
        'SELECT COUNT(*) as count FROM user_achievements WHERE user_id = $1 AND earned_at IS NOT NULL',
        [userId]
      ),
      ActivityService.getUserActivitySummary(userId, 7),
      // Pending assignments across all enrolled courses (due within next 14 days or slightly overdue)
      query(
        `SELECT a.id, a.title, a.description, a.due_date, a.total_points,
                c.title as course_title, c.id as course_id,
                s.id as submission_id, s.status as submission_status,
                CASE WHEN a.due_date < NOW() THEN true ELSE false END as is_overdue
         FROM assignments a
         JOIN courses c ON a.course_id = c.id
         JOIN enrollments e ON e.course_id = c.id AND e.user_id = $1
         LEFT JOIN submissions s ON s.assignment_id = a.id AND s.user_id = $1
         WHERE a.due_date >= NOW() - INTERVAL '3 days'
           AND a.due_date <= NOW() + INTERVAL '14 days'
           AND (s.id IS NULL OR s.status NOT IN ('submitted', 'graded'))
         ORDER BY a.due_date ASC
         LIMIT 5`,
        [userId]
      ),
      // Available quizzes from enrolled courses (not yet passed)
      query(
        `SELECT q.id, q.title, q.description, q.time_limit, q.passing_score,
                c.title as course_title, c.id as course_id,
                (SELECT COUNT(*) FROM quiz_questions WHERE quiz_id = q.id) as question_count,
                (SELECT COUNT(*) FROM quiz_attempts qa WHERE qa.quiz_id = q.id AND qa.user_id = $1 AND qa.passed = true) as times_passed
         FROM quizzes q
         JOIN courses c ON q.course_id = c.id
         JOIN enrollments e ON e.course_id = c.id AND e.user_id = $1
         WHERE c.is_published = true
         ORDER BY e.enrollment_date DESC, q.created_at DESC
         LIMIT 5`,
        [userId]
      ),
    ]);

    const userAnalytics = analyticsResult.rows[0] || {
      total_lessons_completed: 0,
      total_courses_completed: 0,
      engagement_level: 'low',
      churn_risk_score: 0,
    };

    // Calculate average progress across enrolled courses
    const progressValues = enrollmentsResult.rows.map(r =>
      parseFloat(r.progress_percentage || 0)
    );
    const avgProgress = progressValues.length > 0
      ? Math.round(progressValues.reduce((a, b) => a + b, 0) / progressValues.length)
      : 0;

    res.json({
      success: true,
      data: {
        enrolledCourses: enrollmentsResult.rows,
        enrollmentCount: enrollmentsResult.rows.length,
        avgProgress,
        lessonsCompleted: userAnalytics.total_lessons_completed,
        coursesCompleted: userAnalytics.total_courses_completed,
        engagementLevel: userAnalytics.engagement_level,
        churnRiskScore: parseFloat(userAnalytics.churn_risk_score || 0).toFixed(2),
        achievementCount: parseInt(achievementsResult.rows[0]?.count || 0),
        recentActivity: activitySummary,
        pendingAssignments: pendingAssignmentsResult.rows,
        availableQuizzes: availableQuizzesResult.rows,
      },
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
           (SELECT COUNT(*)
            FROM assignments a
            JOIN submissions s ON a.id = s.assignment_id
            LEFT JOIN submissions_grades sg ON sg.submission_id = s.id
            WHERE a.course_id = ANY($1) AND sg.id IS NULL) as pending_grades
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
    const [statsResult, activitiesResult, instructorsResult, atRiskResult, userCountsResult, openTicketsResult, failedPaymentsResult] = 
      await Promise.all([
        ActivityService.getPlatformAnalytics(),
        query(
          `SELECT activity_type, COUNT(*) as count
           FROM user_activities
           WHERE created_at >= NOW() - INTERVAL '24 hours'
           GROUP BY activity_type
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
        ),
        query(
          `SELECT COUNT(*) as count
           FROM support_tickets
           WHERE status IN ('open', 'in-progress')`,
          []
        ),
        query(
          `SELECT COUNT(*) as count
           FROM payments
           WHERE status = 'failed'
             AND created_at >= NOW() - INTERVAL '7 days'`,
          []
        )
      ]);

    const userCounts = userCountsResult.rows[0];
    const openSupportTickets = parseInt(openTicketsResult.rows[0]?.count || 0);
    const failedPayments = parseInt(failedPaymentsResult.rows[0]?.count || 0);
    const atRiskLearners = atRiskResult.rows.length;
    const openAlerts = openSupportTickets + failedPayments + atRiskLearners;
    const completionRate = statsResult.totalEnrollments > 0
      ? Math.round(statsResult.avgCompletionRate || 0)
      : 0;

    const systemAlerts = [
      {
        type: 'support',
        severity: openSupportTickets > 20 ? 'high' : 'medium',
        title: 'Open Support Tickets',
        count: openSupportTickets,
      },
      {
        type: 'payments',
        severity: failedPayments > 10 ? 'high' : 'medium',
        title: 'Failed Payments (7d)',
        count: failedPayments,
      },
      {
        type: 'retention',
        severity: atRiskLearners > 25 ? 'high' : 'medium',
        title: 'At-Risk Learners',
        count: atRiskLearners,
      },
    ].filter((a) => a.count > 0);

    res.json({
      success: true,
      data: {
        summary: {
          totalUsers: statsResult.totalUsers,
          activeCourses: statsResult.totalCourses,
          completionRate,
          openAlerts,
        },
        platformStats: statsResult,
        userRoles: {
          students: parseInt(userCounts.student_count || 0),
          instructors: parseInt(userCounts.instructor_count || 0),
          admins: parseInt(userCounts.admin_count || 0)
        },
        institutionStats: {
          totalInstitutions: parseInt(userCounts.instructor_count || 0),
          totalStudents: parseInt(userCounts.student_count || 0),
          totalEnrollments: parseInt(userCounts.total_enrollments || 0),
        },
        alerts: systemAlerts,
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
    if (!['parent', 'admin'].includes(req.user.role)) {
      return res.status(403).json({ success: false, error: 'Parent access required' });
    }

    const userId = req.user.id;
    const [childrenSummaryResult, unreadNotificationsResult, recentTicketsResult, upcomingEventsResult] = await Promise.all([
      query(
        `SELECT
           COUNT(DISTINCT pcl.child_user_id)::int AS children_linked,
           COALESCE(ROUND(AVG(e.progress_percentage)), 0)::int AS avg_progress,
           COALESCE(
             ROUND(
               100.0 *
               SUM(
                 CASE
                   WHEN e.completion_status = 'completed' THEN 1
                   WHEN e.completion_status = 'in_progress' THEN 0.5
                   ELSE 0
                 END
               ) / NULLIF(COUNT(e.id), 0)
             ),
             0
           )::int AS attendance_rate
         FROM parent_child_links pcl
         LEFT JOIN enrollments e ON e.user_id = pcl.child_user_id
         WHERE pcl.parent_user_id = $1 AND pcl.is_active = true`,
        [userId]
      ),
      query(
        `SELECT COUNT(*)::int AS unread_count
         FROM notifications
         WHERE user_id = $1 AND is_read = false`,
        [userId]
      ),
      query(
        `SELECT COUNT(*)::int AS open_tickets
         FROM support_tickets
         WHERE user_id = $1 AND status IN ('open', 'in-progress')`,
        [userId]
      ),
      query(
        `SELECT COUNT(*)::int AS upcoming_events
         FROM event_registrations er
         JOIN events e ON e.id = er.event_id
         WHERE er.user_id = $1 AND e.start_date >= NOW()`,
        [userId]
      ),
    ]);

    const childrenSummary = childrenSummaryResult.rows[0] || {};
    const recentTickets = recentTicketsResult.rows[0]?.open_tickets || 0;
    const upcomingEvents = upcomingEventsResult.rows[0]?.upcoming_events || 0;

    res.json({
      success: true,
      data: {
        summary: {
          childrenLinked: parseInt(childrenSummary.children_linked || 0),
          avgProgress: parseInt(childrenSummary.avg_progress || 0),
          attendanceRate: parseInt(childrenSummary.attendance_rate || 0),
          unreadMessages: parseInt(unreadNotificationsResult.rows[0]?.unread_count || 0),
        },
        oversight: {
          openTickets: parseInt(recentTickets || 0),
          upcomingEvents: parseInt(upcomingEvents || 0),
        },
      }
    });
  } catch (err) {
    console.error('Parent dashboard error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch dashboard' });
  }
});

// ============================================
// SCHOOL ADMIN DASHBOARD
// ============================================

router.get('/school-admin', verifyToken, async (req, res) => {
  try {
    if (!['school_admin', 'admin'].includes(req.user.role)) {
      return res.status(403).json({ success: false, error: 'School admin access required' });
    }

    const [userCountsResult, progressResult, alertsResult] = await Promise.all([
      query(
        `SELECT
           COUNT(*) FILTER (WHERE role = 'student' AND COALESCE(is_active, true) = true)::int AS total_students,
           COUNT(*) FILTER (WHERE role IN ('facilitator', 'instructor') AND COALESCE(is_active, true) = true)::int AS total_facilitators
         FROM users`,
        []
      ),
      query(
        `SELECT COALESCE(ROUND(AVG(progress_percentage)), 0)::int AS completion_rate
         FROM enrollments`,
        []
      ),
      query(
        `SELECT (
            (SELECT COUNT(*) FROM support_tickets WHERE status IN ('open', 'in-progress')) +
            (SELECT COUNT(*) FROM content_flags WHERE status = 'pending') +
            (SELECT COUNT(*) FROM payments WHERE status = 'failed' AND created_at >= NOW() - INTERVAL '7 days')
          )::int AS open_alerts`,
        []
      ),
    ]);

    const userCounts = userCountsResult.rows[0] || {};

    res.json({
      success: true,
      data: {
        summary: {
          totalStudents: parseInt(userCounts.total_students || 0),
          totalFacilitators: parseInt(userCounts.total_facilitators || 0),
          completionRate: parseInt(progressResult.rows[0]?.completion_rate || 0),
          openAlerts: parseInt(alertsResult.rows[0]?.open_alerts || 0),
        },
      }
    });
  } catch (err) {
    console.error('School admin dashboard error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch school admin dashboard' });
  }
});

// ============================================
// MENTOR DASHBOARD
// ============================================

router.get('/mentor', verifyToken, async (req, res) => {
  try {
    if (!['mentor', 'admin'].includes(req.user.role)) {
      return res.status(403).json({ success: false, error: 'Mentor access required' });
    }

    const userId = req.user.id;
    const [menteeSummaryResult, eventsSummaryResult, courseGrowthResult] = await Promise.all([
      query(
        `SELECT
           COUNT(*) FILTER (WHERE is_active = true AND status = 'active')::int AS total_mentees,
           COUNT(*) FILTER (WHERE is_active = true AND next_session_at >= NOW())::int AS scheduled_sessions,
           COUNT(*) FILTER (WHERE is_active = true AND last_session_at >= NOW() - INTERVAL '30 days')::int AS completed_sessions,
           COALESCE(
             ROUND(AVG(e.progress_percentage)),
             0
           )::int AS resource_growth
         FROM mentor_mentee_links mml
         LEFT JOIN enrollments e ON e.user_id = mml.mentee_user_id
         WHERE mml.mentor_user_id = $1`,
        [userId]
      ),
      query(
        `SELECT
           COUNT(*) FILTER (WHERE start_date >= NOW())::int AS upcoming_sessions,
           COUNT(*) FILTER (WHERE start_date < NOW())::int AS completed_sessions
         FROM events
         WHERE created_by = $1`,
        [userId]
      ),
      query(
        `SELECT COALESCE(ROUND(AVG(e.progress_percentage)), 0)::int AS avg_growth
         FROM courses c
         JOIN enrollments e ON e.course_id = c.id
         WHERE c.instructor_id = $1`,
        [userId]
      ),
    ]);

    const menteeSummary = menteeSummaryResult.rows[0] || {};

    res.json({
      success: true,
      data: {
        summary: {
          totalMentees: parseInt(menteeSummary.total_mentees || 0),
          upcomingSessions: parseInt(
            menteeSummary.scheduled_sessions || eventsSummaryResult.rows[0]?.upcoming_sessions || 0
          ),
          completedSessions: parseInt(
            menteeSummary.completed_sessions || eventsSummaryResult.rows[0]?.completed_sessions || 0
          ),
          avgMenteeGrowth: parseInt(
            menteeSummary.resource_growth || courseGrowthResult.rows[0]?.avg_growth || 0
          ),
        },
      }
    });
  } catch (err) {
    console.error('Mentor dashboard error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch mentor dashboard' });
  }
});

// ============================================
// CIRCLE MEMBER DASHBOARD
// ============================================

router.get('/circle-member', verifyToken, async (req, res) => {
  try {
    if (!['circle_member', 'admin'].includes(req.user.role)) {
      return res.status(403).json({ success: false, error: 'Circle member access required' });
    }

    const userId = req.user.id;
    const [communityResult, roundtableResult, reachResult] = await Promise.all([
      query(
        `SELECT
           COUNT(DISTINCT owner_user_id) FILTER (
             WHERE owner_user_id <> $1 AND status = 'active'
           )::int AS connections,
           COUNT(*) FILTER (
             WHERE owner_user_id = $1 AND created_at >= DATE_TRUNC('month', NOW())
           )::int AS posts_this_month
         FROM role_resources
         WHERE namespace = 'circle_member'`,
        [userId]
      ),
      query(
        `SELECT COUNT(*)::int AS roundtables
         FROM events
         WHERE start_date >= NOW()
           AND LOWER(COALESCE(event_type, '')) IN ('roundtable', 'community', 'networking')`,
        []
      ),
      query(
        `SELECT COUNT(*)::int AS profile_reach
         FROM notifications
         WHERE user_id = $1 AND created_at >= NOW() - INTERVAL '30 days'`,
        [userId]
      ),
    ]);

    const community = communityResult.rows[0] || {};

    res.json({
      success: true,
      data: {
        summary: {
          connections: parseInt(community.connections || 0),
          postsThisMonth: parseInt(community.posts_this_month || 0),
          roundtables: parseInt(roundtableResult.rows[0]?.roundtables || 0),
          profileReach: parseInt(reachResult.rows[0]?.profile_reach || 0),
        },
      }
    });
  } catch (err) {
    console.error('Circle member dashboard error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch circle member dashboard' });
  }
});

// ============================================
// UNIVERSITY MEMBER DASHBOARD
// ============================================

router.get('/uni-member', verifyToken, async (req, res) => {
  try {
    if (!['uni_member', 'admin'].includes(req.user.role)) {
      return res.status(403).json({ success: false, error: 'University member access required' });
    }

    const userId = req.user.id;
    const [learningResult, teamResult, mentorSessionsResult, opportunitiesResult] = await Promise.all([
      query(
        `SELECT
           COUNT(*) FILTER (WHERE completion_status = 'completed')::int AS completed_courses,
           COUNT(*)::int AS enrolled_courses
         FROM enrollments
         WHERE user_id = $1`,
        [userId]
      ),
      query(
        `SELECT COUNT(*)::int AS team_members
         FROM event_registrations er
         JOIN events e ON e.id = er.event_id
         WHERE e.created_by = $1 AND er.user_id <> $1`,
        [userId]
      ),
      query(
        `SELECT COUNT(*)::int AS mentor_sessions
         FROM event_registrations er
         JOIN events e ON e.id = er.event_id
         WHERE er.user_id = $1
           AND LOWER(COALESCE(e.event_type, '')) IN ('mentorship', 'mentor_session', 'coaching', 'workshop')`,
        [userId]
      ),
      query(
        `SELECT COUNT(*)::int AS open_opportunities
         FROM events
         WHERE start_date >= NOW()
           AND LOWER(COALESCE(event_type, '')) IN ('hackathon', 'incubator', 'networking', 'opportunity', 'roundtable', 'workshop')`,
        []
      ),
    ]);

    const learning = learningResult.rows[0] || {};
    const completedCourses = parseInt(learning.completed_courses || 0);
    const enrolledCourses = parseInt(learning.enrolled_courses || 0);
    let ventureStage = 'Exploration';
    if (completedCourses >= 5) {
      ventureStage = 'Growth';
    } else if (completedCourses >= 2) {
      ventureStage = 'Validation';
    } else if (enrolledCourses > 0) {
      ventureStage = 'Idea';
    }

    res.json({
      success: true,
      data: {
        summary: {
          ventureStage,
          teamMembers: parseInt(teamResult.rows[0]?.team_members || 0),
          mentorSessions: parseInt(mentorSessionsResult.rows[0]?.mentor_sessions || 0),
          openOpportunities: parseInt(opportunitiesResult.rows[0]?.open_opportunities || 0),
        },
      }
    });
  } catch (err) {
    console.error('University member dashboard error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch university member dashboard' });
  }
});

module.exports = router;
