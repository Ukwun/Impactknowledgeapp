const express = require('express');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');
const NotificationTriggerService = require('../services/notification-trigger-service');

const router = express.Router();

const adminRoles = new Set(['admin', 'school_admin']);
const mentorCoordinatorRoles = new Set(['admin', 'school_admin', 'facilitator']);

const isAdminRole = (role) => adminRoles.has(role);
const canCoordinateMentors = (role) => mentorCoordinatorRoles.has(role);

router.get('/parent/children', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'parent' && !isAdminRole(req.user.role)) {
      return res.status(403).json({ success: false, error: 'Parent access required' });
    }

    const requestedParentId = parseInt(req.query.parentUserId || req.user.id, 10);
    const parentUserId = isAdminRole(req.user.role) ? requestedParentId : req.user.id;

    const result = await query(
      `SELECT
         pcl.id,
         pcl.relationship,
         pcl.is_active,
         pcl.created_at,
         u.id AS child_user_id,
         u.full_name AS child_name,
         u.email AS child_email,
         COALESCE(ROUND(AVG(e.progress_percentage)), 0)::int AS avg_progress,
         COUNT(e.id)::int AS enrollments,
         COUNT(*) FILTER (WHERE e.completion_status = 'completed')::int AS completed_courses
       FROM parent_child_links pcl
       JOIN users u ON u.id = pcl.child_user_id
       LEFT JOIN enrollments e ON e.user_id = pcl.child_user_id
       WHERE pcl.parent_user_id = $1
       GROUP BY pcl.id, u.id, u.full_name, u.email
       ORDER BY pcl.created_at DESC`,
      [parentUserId]
    );

    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('Get parent children links error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

router.post('/parent/children/link', verifyToken, async (req, res) => {
  try {
    if (!isAdminRole(req.user.role)) {
      return res.status(403).json({ success: false, error: 'Admin access required' });
    }

    const { parentUserId, childUserId, relationship = 'guardian' } = req.body;
    if (!parentUserId || !childUserId) {
      return res.status(400).json({ success: false, error: 'parentUserId and childUserId are required' });
    }

    const created = await query(
      `INSERT INTO parent_child_links
        (parent_user_id, child_user_id, relationship, is_active, created_by, updated_at)
       VALUES ($1, $2, $3, true, $4, NOW())
       ON CONFLICT (parent_user_id, child_user_id)
       DO UPDATE SET
         relationship = EXCLUDED.relationship,
         is_active = true,
         created_by = EXCLUDED.created_by,
         updated_at = NOW()
       RETURNING *`,
      [parentUserId, childUserId, relationship, req.user.id]
    );

    await NotificationTriggerService.notifyMany({
      userIds: [parseInt(parentUserId, 10), parseInt(childUserId, 10)],
      title: 'Family Link Activated',
      message: 'A parent-child learning link has been activated on your account.',
      type: 'account',
      actionUrl: '/dashboard',
      metadata: {
        action: 'parent_child_linked',
        resourceId: created.rows[0].id,
      },
      push: true,
    });

    res.status(201).json({ success: true, data: created.rows[0] });
  } catch (err) {
    console.error('Create parent child link error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

router.delete('/parent/children/:childUserId(\\d+)', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'parent' && !isAdminRole(req.user.role)) {
      return res.status(403).json({ success: false, error: 'Parent access required' });
    }

    const parentUserId = isAdminRole(req.user.role)
      ? parseInt(req.query.parentUserId, 10)
      : req.user.id;
    const childUserId = parseInt(req.params.childUserId, 10);

    if (!parentUserId) {
      return res.status(400).json({ success: false, error: 'parentUserId is required for admin unlink' });
    }

    const result = await query(
      `UPDATE parent_child_links
       SET is_active = false, updated_at = NOW()
       WHERE parent_user_id = $1 AND child_user_id = $2
       RETURNING id`,
      [parentUserId, childUserId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Relationship not found' });
    }

    res.json({ success: true, message: 'Link deactivated' });
  } catch (err) {
    console.error('Deactivate parent child link error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

router.get('/mentor/mentees', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'mentor' && !canCoordinateMentors(req.user.role)) {
      return res.status(403).json({ success: false, error: 'Mentor access required' });
    }

    const requestedMentorId = parseInt(req.query.mentorUserId || req.user.id, 10);
    const mentorUserId = canCoordinateMentors(req.user.role) ? requestedMentorId : req.user.id;

    const result = await query(
      `SELECT
         mml.id,
         mml.status,
         mml.goals,
         mml.notes,
         mml.next_session_at,
         mml.last_session_at,
         mml.is_active,
         mml.created_at,
         u.id AS mentee_user_id,
         u.full_name AS mentee_name,
         u.email AS mentee_email,
         COALESCE(ROUND(AVG(e.progress_percentage)), 0)::int AS avg_progress,
         COUNT(e.id)::int AS enrollment_count
       FROM mentor_mentee_links mml
       JOIN users u ON u.id = mml.mentee_user_id
       LEFT JOIN enrollments e ON e.user_id = mml.mentee_user_id
       WHERE mml.mentor_user_id = $1 AND mml.is_active = true
       GROUP BY mml.id, u.id, u.full_name, u.email
       ORDER BY COALESCE(mml.next_session_at, mml.updated_at) ASC`,
      [mentorUserId]
    );

    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('Get mentor mentee links error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

router.post('/mentor/mentees/link', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'mentor' && !canCoordinateMentors(req.user.role)) {
      return res.status(403).json({ success: false, error: 'Mentor coordinator access required' });
    }

    const { mentorUserId, menteeUserId, goals = null, notes = null, nextSessionAt = null } = req.body;
    if (!mentorUserId || !menteeUserId) {
      return res.status(400).json({ success: false, error: 'mentorUserId and menteeUserId are required' });
    }

    const effectiveMentorId = req.user.role === 'mentor' ? req.user.id : parseInt(mentorUserId, 10);
    if (req.user.role === 'mentor' && effectiveMentorId !== parseInt(mentorUserId, 10)) {
      return res.status(403).json({ success: false, error: 'Mentors can only manage their own roster' });
    }

    const created = await query(
      `INSERT INTO mentor_mentee_links
        (mentor_user_id, mentee_user_id, status, goals, notes, next_session_at, is_active, created_by, updated_at)
       VALUES ($1, $2, 'active', $3, $4, $5, true, $6, NOW())
       ON CONFLICT (mentor_user_id, mentee_user_id)
       DO UPDATE SET
         status = 'active',
         goals = COALESCE(EXCLUDED.goals, mentor_mentee_links.goals),
         notes = COALESCE(EXCLUDED.notes, mentor_mentee_links.notes),
         next_session_at = COALESCE(EXCLUDED.next_session_at, mentor_mentee_links.next_session_at),
         is_active = true,
         updated_at = NOW()
       RETURNING *`,
      [effectiveMentorId, menteeUserId, goals, notes, nextSessionAt, req.user.id]
    );

    await NotificationTriggerService.notifyMany({
      userIds: [parseInt(effectiveMentorId, 10), parseInt(menteeUserId, 10)],
      title: 'Mentorship Link Active',
      message: 'A mentor-mentee relationship is now active for your account.',
      type: 'mentor',
      actionUrl: '/dashboard',
      metadata: {
        action: 'mentor_mentee_linked',
        resourceId: created.rows[0].id,
      },
      push: true,
    });

    res.status(201).json({ success: true, data: created.rows[0] });
  } catch (err) {
    console.error('Create mentor mentee link error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

router.put('/mentor/mentees/:menteeUserId(\\d+)/session', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'mentor' && !canCoordinateMentors(req.user.role)) {
      return res.status(403).json({ success: false, error: 'Mentor access required' });
    }

    const menteeUserId = parseInt(req.params.menteeUserId, 10);
    const mentorUserId = req.user.role === 'mentor'
      ? req.user.id
      : parseInt(req.body.mentorUserId || req.query.mentorUserId, 10);

    if (!mentorUserId) {
      return res.status(400).json({ success: false, error: 'mentorUserId is required' });
    }

    const { status = null, notes = null, nextSessionAt = null, lastSessionAt = null } = req.body;

    const updated = await query(
      `UPDATE mentor_mentee_links
       SET
         status = COALESCE($3, status),
         notes = COALESCE($4, notes),
         next_session_at = COALESCE($5, next_session_at),
         last_session_at = COALESCE($6, last_session_at),
         updated_at = NOW()
       WHERE mentor_user_id = $1 AND mentee_user_id = $2 AND is_active = true
       RETURNING *`,
      [mentorUserId, menteeUserId, status, notes, nextSessionAt, lastSessionAt]
    );

    if (updated.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Mentorship relationship not found' });
    }

    await NotificationTriggerService.notifyUser({
      userId: menteeUserId,
      title: 'Mentorship Session Updated',
      message: 'Your mentorship plan has new updates and scheduling details.',
      type: 'mentor',
      actionUrl: '/dashboard',
      metadata: {
        action: 'mentor_session_updated',
        resourceId: updated.rows[0].id,
      },
      push: true,
    });

    res.json({ success: true, data: updated.rows[0] });
  } catch (err) {
    console.error('Update mentor session error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;