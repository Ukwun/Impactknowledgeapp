const express = require('express');
const { query, pool } = require('../database');
const { verifyToken, requireRoles } = require('../middleware/auth');

const router = express.Router();

router.get('/ops-health', verifyToken, requireRoles('admin', 'school_admin'), async (req, res) => {
  const started = Date.now();
  try {
    await query('SELECT 1');
    const dbLatencyMs = Date.now() - started;

    const [payments, liveSessions, attendanceSignals] = await Promise.all([
      query(`SELECT COUNT(*)::int AS count FROM payments WHERE created_at >= NOW() - INTERVAL '30 days'`),
      query(`SELECT COUNT(*)::int AS count FROM classroom_live_sessions WHERE starts_at >= NOW() - INTERVAL '30 days'`),
      query(`SELECT COUNT(*)::int AS count FROM user_activities WHERE activity_type LIKE 'attendance:%' AND created_at >= NOW() - INTERVAL '30 days'`),
    ]);

    res.json({
      success: true,
      data: {
        uptimeSeconds: process.uptime(),
        dbLatencyMs,
        paymentEvents30d: payments.rows[0]?.count || 0,
        liveSessions30d: liveSessions.rows[0]?.count || 0,
        attendanceSignals30d: attendanceSignals.rows[0]?.count || 0,
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to compute ops health.' });
  }
});

router.get('/playstore-readiness', verifyToken, requireRoles('admin', 'school_admin'), async (req, res) => {
  res.json({
    success: true,
    data: {
      checklist: [
        { key: 'android_app_bundle', label: 'Android App Bundle signing and release track setup', status: 'pending' },
        { key: 'data_safety', label: 'Play Console Data Safety form', status: 'pending' },
        { key: 'privacy_terms', label: 'Privacy policy and terms endpoints', status: 'implemented' },
        { key: 'content_rating', label: 'Content rating and target audience declarations', status: 'pending' },
        { key: 'crash_anr', label: 'Crash/ANR thresholds and pre-launch report fixes', status: 'in_progress' },
      ],
      releaseGuidance: 'Use internal testing track first, then closed testing cohorts before production rollout.',
    },
  });
});

router.get('/incident-runbook', verifyToken, requireRoles('admin', 'school_admin'), async (req, res) => {
  res.json({
    success: true,
    data: {
      backupRestore: [
        'Run nightly PostgreSQL backups with retention >= 14 days',
        'Test restore process weekly in staging environment',
        'Keep migration rollback scripts for latest release',
      ],
      alerting: [
        'Alert on API 5xx error rate > 2% for 5 minutes',
        'Alert on payment verification failures spike',
        'Alert on queue/notification delivery failures',
      ],
      incidentWorkflow: [
        'Declare incident severity and owner',
        'Communicate user impact within 15 minutes',
        'Mitigate, verify, and publish postmortem with actions',
      ],
    },
  });
});

module.exports = router;
