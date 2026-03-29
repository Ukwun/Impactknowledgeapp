const express = require('express');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

// Generic dashboard data generator
function generateDashboardData() {
  return {
    totalStudents: 245,
    totalFacilitators: 18,
    totalCoursesActive: 12,
    totalEnrollments: 1250,
    completionRate: 68,
    openAlerts: 5,
    averageScore: 78.5,
    topPerformers: [
      { name: 'John Doe', score: 95 },
      { name: 'Jane Smith', score: 92 },
      { name: 'Bob Johnson', score: 88 },
    ],
    recentActivity: [
      { action: 'Course completed', user: 'John Doe', time: new Date(Date.now() - 3600000).toISOString() },
      { action: 'New enrollment', user: 'Jane Smith', time: new Date(Date.now() - 7200000).toISOString() },
      { action: 'Assessment passed', user: 'Bob Johnson', time: new Date(Date.now() - 10800000).toISOString() },
    ],
    metrics: {
      engagementRate: 82,
      courseCompletionRate: 68,
      studentSatisfaction: 4.5,
      facilitatorEffectiveness: 4.3,
    },
  };
}

// Student/Learner Dashboard
router.get('/student', verifyToken, (req, res) => {
  try {
    res.json(generateDashboardData());
  } catch (err) {
    console.error('Student dashboard error:', err);
    res.status(500).json({ error: 'Failed to fetch student dashboard' });
  }
});

// Parent Dashboard
router.get('/parent', verifyToken, (req, res) => {
  try {
    res.json({
      ...generateDashboardData(),
      childrenBeingMonitored: 3,
      overallProgress: 72,
      upcomingAssignments: 5,
    });
  } catch (err) {
    console.error('Parent dashboard error:', err);
    res.status(500).json({ error: 'Failed to fetch parent dashboard' });
  }
});

// Facilitator Dashboard
router.get('/facilitator', verifyToken, (req, res) => {
  try {
    res.json({
      ...generateDashboardData(),
      classesTeaching: 4,
      totalStudentsUnderCare: 125,
      pendingGrading: 23,
      attendanceRate: 88,
    });
  } catch (err) {
    console.error('Facilitator dashboard error:', err);
    res.status(500).json({ error: 'Failed to fetch facilitator dashboard' });
  }
});

// School Admin Dashboard
router.get('/school-admin', verifyToken, (req, res) => {
  try {
    res.json({
      ...generateDashboardData(),
      totalStudents: 450,
      totalFacilitators: 28,
      schoolId: 'SCH-001',
      schoolName: 'Demo School',
    });
  } catch (err) {
    console.error('School admin dashboard error:', err);
    res.status(500).json({ error: 'Failed to fetch school admin dashboard' });
  }
});

// Mentor Dashboard
router.get('/mentor', verifyToken, (req, res) => {
  try {
    res.json({
      ...generateDashboardData(),
      menteeCount: 15,
      activeMentorships: 12,
      completedSessions: 48,
    });
  } catch (err) {
    console.error('Mentor dashboard error:', err);
    res.status(500).json({ error: 'Failed to fetch mentor dashboard' });
  }
});

// Circle Member Dashboard
router.get('/circle-member', verifyToken, (req, res) => {
  try {
    res.json({
      ...generateDashboardData(),
      circleName: 'Demo Circle',
      memberCount: 50,
      eventCount: 8,
    });
  } catch (err) {
    console.error('Circle member dashboard error:', err);
    res.status(500).json({ error: 'Failed to fetch circle member dashboard' });
  }
});

// University Member Dashboard
router.get('/uni-member', verifyToken, (req, res) => {
  try {
    res.json({
      ...generateDashboardData(),
      universityName: 'Demo University',
      departmentCount: 12,
      facultyCount: 85,
    });
  } catch (err) {
    console.error('University member dashboard error:', err);
    res.status(500).json({ error: 'Failed to fetch uni member dashboard' });
  }
});

// Admin Dashboard
router.get('/admin', verifyToken, (req, res) => {
  try {
    res.json({
      ...generateDashboardData(),
      totalUsers: 5000,
      activeUsers: 2300,
      totalOrganizations: 250,
      systemHealth: 99.5,
    });
  } catch (err) {
    console.error('Admin dashboard error:', err);
    res.status(500).json({ error: 'Failed to fetch admin dashboard' });
  }
});

module.exports = router;
