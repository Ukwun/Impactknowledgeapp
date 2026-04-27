const express = require('express');
const { query } = require('../database');
const { verifyToken, requireRoles } = require('../middleware/auth');
const { validateBody, validateQuery } = require('../middleware/requestValidation');
const AuditService = require('../services/audit-service');

const router = express.Router();

const TAXONOMY = {
  activation: ['app_opened', 'onboarding_completed', 'first_course_enrolled'],
  attendance: ['live_session_joined', 'live_session_completed', 'attendance_marked'],
  assessment: ['quiz_started', 'quiz_submitted', 'assignment_submitted', 'project_submitted'],
  retention: ['weekly_active', 'streak_maintained', 'churn_risk_updated'],
  completion: ['course_completed', 'certificate_issued', 'badge_awarded'],
};

function classifyEvent(eventName) {
  for (const category of Object.keys(TAXONOMY)) {
    if (TAXONOMY[category].includes(eventName)) {
      return category;
    }
  }
  return null;
}

router.get('/taxonomy', verifyToken, (req, res) => {
  res.json({ success: true, data: TAXONOMY });
});

router.get(
  '/cohort-insights',
  verifyToken,
  requireRoles('facilitator', 'instructor', 'school_admin', 'admin'),
  validateQuery({
    daysBack: { type: 'number', integer: true, min: 7, max: 90 },
  }),
  async (req, res) => {
    try {
      const daysBack = Number(req.query.daysBack || 30);
      const isFacilitatorScope = ['facilitator', 'instructor'].includes(req.user.role);
      const scopeParams = isFacilitatorScope ? [req.user.id] : [];
      const learnerScopeSql = isFacilitatorScope
        ? `SELECT DISTINCT e.user_id
           FROM courses c
           JOIN enrollments e ON e.course_id = c.id
           WHERE c.instructor_id = $1`
        : `SELECT id AS user_id
           FROM users
           WHERE role IN ('student', 'learner')`;

      const insightsResult = await query(
        `WITH scoped_learners AS (
           ${learnerScopeSql}
         ), learner_analytics AS (
           SELECT
             sl.user_id,
             ua.engagement_level,
             ua.churn_risk_score,
             ua.last_active_at,
             COALESCE(ua.total_lessons_completed, 0) AS lessons_completed,
             COALESCE(ua.total_courses_completed, 0) AS courses_completed
           FROM scoped_learners sl
           LEFT JOIN user_analytics ua ON ua.user_id = sl.user_id
         ), learner_progress AS (
           SELECT
             e.user_id,
             AVG(COALESCE(e.progress_percentage, 0))::numeric(10,2) AS avg_progress,
             COUNT(*) FILTER (WHERE e.completion_status = 'completed')::int AS completed_enrollments
           FROM enrollments e
           WHERE e.user_id IN (SELECT user_id FROM scoped_learners)
           GROUP BY e.user_id
         )
         SELECT
           COUNT(*)::int AS total_learners,
           COUNT(*) FILTER (
             WHERE la.last_active_at >= NOW() - ($${scopeParams.length + 1} || ' days')::interval
           )::int AS retained_learners,
           COUNT(*) FILTER (
             WHERE COALESCE(la.engagement_level, 'low') IN ('medium', 'high')
           )::int AS engaged_learners,
           COUNT(*) FILTER (
             WHERE COALESCE(la.churn_risk_score, 0) >= 0.70
           )::int AS at_risk_learners,
           COALESCE(ROUND(AVG(lp.avg_progress)), 0)::int AS avg_progress,
           COALESCE(SUM(lp.completed_enrollments), 0)::int AS completed_enrollments
         FROM learner_analytics la
         LEFT JOIN learner_progress lp ON lp.user_id = la.user_id`,
        [...scopeParams, String(daysBack)]
      );

      const row = insightsResult.rows[0] || {};
      const totalLearners = Number(row.total_learners || 0);
      const retainedLearners = Number(row.retained_learners || 0);
      const engagedLearners = Number(row.engaged_learners || 0);
      const atRiskLearners = Number(row.at_risk_learners || 0);
      const cohortRetentionRate = totalLearners > 0
        ? Math.round((retainedLearners / totalLearners) * 100)
        : 0;
      const engagementRate = totalLearners > 0
        ? Math.round((engagedLearners / totalLearners) * 100)
        : 0;
      const interventionQueue = atRiskLearners + Math.max(totalLearners - engagedLearners, 0);

      return res.json({
        success: true,
        data: {
          summary: {
            totalLearners,
            retainedLearners,
            cohortRetentionRate,
            engagementRate,
            atRiskLearners,
            interventionQueue,
            avgProgress: Number(row.avg_progress || 0),
            completedEnrollments: Number(row.completed_enrollments || 0),
            daysBack,
          },
        },
      });
    } catch (err) {
      console.error('Cohort insights error:', err);
      return res.status(500).json({ success: false, error: 'Failed to compute cohort insights.' });
    }
  }
);

router.post(
  '/events',
  verifyToken,
  validateBody({
    eventName: { type: 'string', required: true, maxLength: 80 },
    resourceType: { type: 'string', maxLength: 80 },
    resourceId: { type: 'number', integer: true, min: 1 },
    metadata: { type: 'object' },
  }),
  async (req, res) => {
  try {
    const { eventName, resourceType = null, resourceId = null, metadata = {} } = req.body || {};

    if (!eventName) {
      return res.status(400).json({ success: false, error: 'eventName is required.' });
    }

    const category = classifyEvent(String(eventName));
    if (!category) {
      return res.status(400).json({ success: false, error: 'Event is not in approved taxonomy.' });
    }

    await query(
      `INSERT INTO user_activities (
        user_id,
        activity_type,
        resource_type,
        resource_id,
        metadata,
        session_id,
        ip_address,
        user_agent,
        created_at
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,NOW())`,
      [
        req.user.id,
        `${category}:${eventName}`,
        resourceType,
        resourceId,
        JSON.stringify({ ...metadata, category, eventName }),
        metadata.sessionId || null,
        req.ip || null,
        req.headers['user-agent'] || null,
      ]
    );

    await query(
      `INSERT INTO user_analytics (user_id, last_active_at, engagement_level, updated_at)
       VALUES ($1, NOW(), 'medium', NOW())
       ON CONFLICT (user_id)
       DO UPDATE SET
         last_active_at = NOW(),
         engagement_level = CASE
           WHEN user_analytics.total_engagement_minutes >= 600 THEN 'high'
           WHEN user_analytics.total_engagement_minutes >= 180 THEN 'medium'
           ELSE user_analytics.engagement_level
         END,
         updated_at = NOW()`,
      [req.user.id]
    );

    await AuditService.log({
      actorId: req.user.id,
      actorRole: req.user.role,
      action: 'ANALYTICS_EVENT_RECORDED',
      entityType: 'user_activity',
      entityId: String(req.user.id),
      metadata: { category, eventName },
      req,
    });

    return res.status(201).json({ success: true, data: { category, eventName } });
  } catch (err) {
    console.error('Analytics event error:', err);
    return res.status(500).json({ success: false, error: 'Failed to record analytics event.' });
  }
});

router.get('/recommendations/me', verifyToken, async (req, res) => {
  try {
    const userAnalyticsResult = await query(
      `SELECT user_id, engagement_level, churn_risk_score, preferred_category, total_lessons_completed, total_courses_completed
       FROM user_analytics WHERE user_id = $1 LIMIT 1`,
      [req.user.id]
    );

    const analytics = userAnalyticsResult.rows[0] || {};
    const churnRisk = Number(analytics.churn_risk_score || 0);

    const recommendations = [];
    const interventions = [];

    if (req.user.role === 'student' || req.user.role === 'learner') {
      recommendations.push('Continue with your current learning path and complete one practical task this week.');
      if (analytics.preferred_category) {
        recommendations.push(`Explore more content in ${analytics.preferred_category}.`);
      }
      if (churnRisk >= 0.7) {
        interventions.push('Send engagement nudge with next best lesson and live class reminder.');
      }
    }

    if (req.user.role === 'parent') {
      recommendations.push('Review linked learner attendance and completion summary this week.');
      interventions.push('Send parent digest when learner misses 2 live sessions.');
    }

    if (['facilitator', 'instructor', 'school_admin', 'admin'].includes(req.user.role)) {
      recommendations.push('Prioritize low-engagement learners for follow-up and live participation coaching.');
      interventions.push('Trigger cohort-level nudges for users below completion threshold.');
    }

    res.json({
      success: true,
      data: {
        analytics,
        recommendations,
        interventions,
      },
    });
  } catch (err) {
    console.error('Recommendation error:', err);
    res.status(500).json({ success: false, error: 'Failed to compute recommendations.' });
  }
});

router.post(
  '/interventions/run',
  verifyToken,
  requireRoles('admin', 'facilitator', 'school_admin'),
  validateBody({
    cohortUserIds: { type: 'array', required: true, minItems: 1, items: 'int' },
    reason: { type: 'string', maxLength: 80 },
  }),
  async (req, res) => {
  try {
    const { cohortUserIds = [], reason = 'at_risk' } = req.body || {};
    const ids = Array.isArray(cohortUserIds)
      ? cohortUserIds.map((id) => Number(id)).filter((id) => Number.isFinite(id))
      : [];

    if (!ids.length) {
      return res.status(400).json({ success: false, error: 'cohortUserIds is required.' });
    }

    const sendResult = await query(
      `INSERT INTO notifications (user_id, title, message, type, metadata)
       SELECT id, $1, $2, 'nudge', $3::jsonb
       FROM users
       WHERE id = ANY($4::int[])
       RETURNING id`,
      [
        'Learning Support Nudge',
        'You are close to your next milestone. Complete your pending activity and attend the next live session.',
        JSON.stringify({ reason, triggeredBy: req.user.id }),
        ids,
      ]
    );

    await AuditService.log({
      actorId: req.user.id,
      actorRole: req.user.role,
      action: 'INTERVENTION_TRIGGERED',
      entityType: 'notification',
      entityId: String(sendResult.rowCount),
      metadata: { reason, recipients: ids.length },
      req,
    });

    res.json({ success: true, data: { nudgesSent: sendResult.rowCount } });
  } catch (err) {
    console.error('Intervention dispatch error:', err);
    res.status(500).json({ success: false, error: 'Failed to dispatch interventions.' });
  }
});

module.exports = router;
