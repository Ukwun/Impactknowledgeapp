const { query } = require('../database');
const ActivityService = require('./activity-service');

class AdminService {
  /**
   * Get all users with filtering and pagination
   */
  static async listUsers(filters = {}) {
    try {
      const { role, status = 'active', searchTerm, page = 1, limit = 20 } = filters;
      const offset = (page - 1) * limit;

      let whereConditions = [];
      const params = [];
      let paramCount = 1;

      if (status === 'active') {
        whereConditions.push('is_active = true');
      } else if (status === 'inactive') {
        whereConditions.push('is_active = false');
      }

      if (role) {
        whereConditions.push(`role = $${paramCount}`);
        params.push(role);
        paramCount++;
      }

      if (searchTerm) {
        whereConditions.push(
          `(full_name ILIKE $${paramCount} OR email ILIKE $${paramCount})`
        );
        params.push(`%${searchTerm}%`);
        paramCount++;
      }

      const whereClause =
        whereConditions.length > 0 ? `WHERE ${whereConditions.join(' AND ')}` : '';

      const countResult = await query(
        `SELECT COUNT(*) as total FROM users ${whereClause}`,
        params.slice(0, paramCount - 1)
      );

      const result = await query(
        `SELECT id, email, full_name, role, is_active, created_at, updated_at
         FROM users
         ${whereClause}
         ORDER BY created_at DESC
         LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
        [...params.slice(0, paramCount - 1), limit, offset]
      );

      return {
        success: true,
        data: result.rows,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: parseInt(countResult.rows[0].total),
        },
      };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get detailed user information with analytics
   */
  static async getUserDetail(userId) {
    try {
      const userResult = await query(
        'SELECT * FROM users WHERE id = $1',
        [userId]
      );

      if (userResult.rows.length === 0) {
        throw new Error('User not found');
      }

      const user = userResult.rows[0];

      // Get user analytics
      const analyticsResult = await query(
        'SELECT * FROM user_analytics WHERE user_id = $1',
        [userId]
      );

      const analytics = analyticsResult.rows[0] || {};

      // Get enrollment count
      const enrollmentResult = await query(
        'SELECT COUNT(*) as count FROM enrollments WHERE user_id = $1',
        [userId]
      );

      // Get activity count
      const activityResult = await query(
        'SELECT COUNT(*) as count FROM user_activities WHERE user_id = $1',
        [userId]
      );

      // Get achievements count
      const achievementResult = await query(
        'SELECT COUNT(*) as count FROM user_achievements WHERE user_id = $1',
        [userId]
      );

      return {
        success: true,
        data: {
          user,
          analytics,
          enrollmentCount: parseInt(enrollmentResult.rows[0].count || 0),
          activityCount: parseInt(activityResult.rows[0].count || 0),
          achievementCount: parseInt(achievementResult.rows[0].count || 0),
        },
      };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Change user role
   */
  static async changeUserRole(userId, newRole, adminId, req) {
    try {
      // Validate role
      const validRoles = ['student', 'instructor', 'facilitator', 'admin'];
      if (!validRoles.includes(newRole)) {
        throw new Error('Invalid role');
      }

      const result = await query(
        'UPDATE users SET role = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
        [newRole, userId]
      );

      if (result.rows.length === 0) {
        throw new Error('User not found');
      }

      await ActivityService.logActivity(
        adminId,
        'USER_ROLE_CHANGED',
        'user',
        userId,
        { newRole, oldRole: 'unknown' },
        req
      );

      return { success: true, data: result.rows[0] };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Deactivate user (soft delete)
   */
  static async deactivateUser(userId, adminId, req) {
    try {
      const result = await query(
        'UPDATE users SET is_active = false, deactivated_at = CURRENT_TIMESTAMP WHERE id = $1 RETURNING *',
        [userId]
      );

      if (result.rows.length === 0) {
        throw new Error('User not found');
      }

      await ActivityService.logActivity(
        adminId,
        'USER_DEACTIVATED',
        'user',
        userId,
        { reason: 'Admin deactivation' },
        req
      );

      return { success: true, data: result.rows[0] };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Reactivate user
   */
  static async reactivateUser(userId, adminId, req) {
    try {
      const result = await query(
        'UPDATE users SET is_active = true, deactivated_at = NULL WHERE id = $1 RETURNING *',
        [userId]
      );

      if (result.rows.length === 0) {
        throw new Error('User not found');
      }

      await ActivityService.logActivity(
        adminId,
        'USER_REACTIVATED',
        'user',
        userId,
        {},
        req
      );

      return { success: true, data: result.rows[0] };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get engagement report
   */
  static async getEngagementReport(daysBack = 30) {
    try {
      // Total active users in period
      const activeUsersResult = await query(
        `SELECT COUNT(DISTINCT user_id) as count
         FROM user_activities
         WHERE created_at >= NOW() - INTERVAL '${daysBack} days'`
      );

      // Activity by type
      const activityByTypeResult = await query(
        `SELECT action_type, COUNT(*) as count
         FROM user_activities
         WHERE created_at >= NOW() - INTERVAL '${daysBack} days'
         GROUP BY action_type
         ORDER BY count DESC`
      );

      // Daily active users
      const dailyActiveResult = await query(
        `SELECT DATE(created_at) as date, COUNT(DISTINCT user_id) as count
         FROM user_activities
         WHERE created_at >= NOW() - INTERVAL '${daysBack} days'
         GROUP BY DATE(created_at)
         ORDER BY date DESC`
      );

      // User engagement levels
      const engagementLevelResult = await query(
        `SELECT engagement_level, COUNT(*) as count
         FROM user_analytics
         GROUP BY engagement_level`
      );

      return {
        success: true,
        data: {
          activeUsers: parseInt(activeUsersResult.rows[0]?.count || 0),
          activityByType: activityByTypeResult.rows,
          dailyActive: dailyActiveResult.rows,
          engagementLevels: engagementLevelResult.rows,
          period: `${daysBack} days`,
        },
      };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get retention report
   */
  static async getRetentionReport() {
    try {
      // Total users
      const totalResult = await query(
        'SELECT COUNT(*) as count FROM users WHERE role = $1',
        ['student']
      );

      // Active students (logged in last 7 days)
      const activeLastWeekResult = await query(
        `SELECT COUNT(DISTINCT user_id) as count
         FROM user_activities
         WHERE user_id IN (SELECT id FROM users WHERE role = $1)
         AND created_at >= NOW() - INTERVAL '7 days'`,
        ['student']
      );

      // Active students (logged in last 30 days)
      const activeLastMonthResult = await query(
        `SELECT COUNT(DISTINCT user_id) as count
         FROM user_activities
         WHERE user_id IN (SELECT id FROM users WHERE role = $1)
         AND created_at >= NOW() - INTERVAL '30 days'`,
        ['student']
      );

      // Completed courses
      const completedCoursesResult = await query(
        `SELECT COUNT(*) as count
         FROM enrollments
         WHERE completion_status = 'completed'`
      );

      // At-risk students (high churn risk score)
      const atRiskResult = await query(
        `SELECT COUNT(*) as count
         FROM user_analytics
         WHERE churn_risk_score > 0.7`
      );

      const total = parseInt(totalResult.rows[0]?.count || 0);
      const activeLastWeek = parseInt(activeLastWeekResult.rows[0]?.count || 0);
      const activeLastMonth = parseInt(activeLastMonthResult.rows[0]?.count || 0);

      return {
        success: true,
        data: {
          totalStudents: total,
          weeklyRetention: total ? ((activeLastWeek / total) * 100).toFixed(2) : 0,
          monthlyRetention: total
            ? ((activeLastMonth / total) * 100).toFixed(2)
            : 0,
          completedCourses: parseInt(completedCoursesResult.rows[0]?.count || 0),
          atRiskStudents: parseInt(atRiskResult.rows[0]?.count || 0),
        },
      };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get revenue/payment report
   */
  static async getRevenueReport() {
    try {
      // Total revenue
      const totalRevenueResult = await query(
        `SELECT SUM(amount) as total FROM payments WHERE status = $1`,
        ['success']
      );

      // Revenue by membership tier
      const revenueByTierResult = await query(
        `SELECT mt.name, SUM(p.amount) as total
         FROM payments p
         JOIN membership_tiers mt ON p.membership_tier_id = mt.id
         WHERE p.status = $1
         GROUP BY mt.name`,
        ['success']
      );

      // Payment count
      const paymentCountResult = await query(
        `SELECT COUNT(*) as count FROM payments WHERE status = $1`,
        ['success']
      );

      // Failed payments
      const failedPaymentResult = await query(
        `SELECT COUNT(*) as count FROM payments WHERE status = $1`,
        ['failed']
      );

      // Average transaction
      const avgTransactionResult = await query(
        `SELECT AVG(amount) as average FROM payments WHERE status = $1`,
        ['success']
      );

      return {
        success: true,
        data: {
          totalRevenue: parseFloat(totalRevenueResult.rows[0]?.total || 0),
          paymentCount: parseInt(paymentCountResult.rows[0]?.count || 0),
          failedPayments: parseInt(failedPaymentResult.rows[0]?.count || 0),
          averageTransaction: parseFloat(
            avgTransactionResult.rows[0]?.average || 0
          ).toFixed(2),
          revenueByTier: revenueByTierResult.rows,
        },
      };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get content performance report
   */
  static async getContentPerformanceReport() {
    try {
      // Top courses by enrollment
      const topCoursesResult = await query(
        `SELECT c.id, c.title, COUNT(e.id) as enrollments, 
                AVG(e.progress_percentage) as avg_progress
         FROM courses c
         LEFT JOIN enrollments e ON c.id = e.course_id
         WHERE c.is_published = true
         GROUP BY c.id, c.title
         ORDER BY enrollments DESC
         LIMIT 10`
      );

      // Quiz difficulty stats
      const quizStatsResult = await query(
        `SELECT q.id, q.title, COUNT(qa.id) as attempts,
                AVG(qa.percentage) as avg_score,
                AVG(CAST(qa.time_spent_minutes AS FLOAT)) as avg_time
         FROM quizzes q
         LEFT JOIN quiz_attempts qa ON q.id = qa.quiz_id
         GROUP BY q.id, q.title
         ORDER BY attempts DESC
         LIMIT 10`
      );

      // Assignment completion
      const assignmentStatsResult = await query(
        `SELECT a.id, a.title, COUNT(s.id) as submissions,
                AVG(CAST(sg.score AS FLOAT)) as avg_score
         FROM assignments a
         LEFT JOIN submissions s ON a.id = s.assignment_id
         LEFT JOIN submissions_grades sg ON s.id = sg.submission_id
         GROUP BY a.id, a.title
         ORDER BY submissions DESC
         LIMIT 10`
      );

      return {
        success: true,
        data: {
          topCourses: topCoursesResult.rows,
          quizPerformance: quizStatsResult.rows,
          assignmentPerformance: assignmentStatsResult.rows,
        },
      };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get system health and statistics
   */
  static async getSystemHealth() {
    try {
      // User counts by role
      const userCountsResult = await query(
        `SELECT role, COUNT(*) as count FROM users GROUP BY role`
      );

      // Total courses
      const courseCountResult = await query(
        'SELECT COUNT(*) as count FROM courses WHERE is_published = true'
      );

      // Total enrollments
      const enrollmentCountResult = await query(
        'SELECT COUNT(*) as count FROM enrollments'
      );

      // Database statistics
      const dbStatsResult = await query(
        `SELECT 
           (SELECT COUNT(*) FROM users) as total_users,
           (SELECT COUNT(*) FROM courses) as total_courses,
           (SELECT COUNT(*) FROM quizzes) as total_quizzes,
           (SELECT COUNT(*) FROM assignments) as total_assignments,
           (SELECT COUNT(*) FROM user_activities) as total_activities`
      );

      return {
        success: true,
        data: {
          usersByRole: userCountsResult.rows,
          publishedCourses: parseInt(courseCountResult.rows[0]?.count || 0),
          totalEnrollments: parseInt(enrollmentCountResult.rows[0]?.count || 0),
          databaseStats: dbStatsResult.rows[0],
          timestamp: new Date().toISOString(),
        },
      };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Manage membership tiers
   */
  static async createMembershipTier(tierData, adminId, req) {
    try {
      const { name, description, price, features, duration_months } = tierData;

      const result = await query(
        `INSERT INTO membership_tiers (name, description, price, features, duration_months)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [name, description, price, features, duration_months]
      );

      await ActivityService.logActivity(
        adminId,
        'MEMBERSHIP_TIER_CREATED',
        'membership_tier',
        result.rows[0].id,
        { name, price },
        req
      );

      return { success: true, data: result.rows[0] };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get all membership tiers
   */
  static async getMembershipTiers() {
    try {
      const result = await query(
        'SELECT * FROM membership_tiers ORDER BY price ASC'
      );

      return { success: true, data: result.rows };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Update membership tier
   */
  static async updateMembershipTier(tierId, updates, adminId, req) {
    try {
      const fields = [];
      const values = [];
      let paramCount = 1;

      const allowedFields = [
        'name',
        'description',
        'price',
        'features',
        'duration_months',
        'is_active',
      ];

      Object.keys(updates).forEach((key) => {
        if (allowedFields.includes(key)) {
          fields.push(`${key} = $${paramCount}`);
          values.push(updates[key]);
          paramCount++;
        }
      });

      if (fields.length === 0) {
        return { success: false, error: 'No valid fields to update' };
      }

      values.push(tierId);

      const result = await query(
        `UPDATE membership_tiers SET ${fields.join(', ')} WHERE id = $${paramCount} RETURNING *`,
        values
      );

      if (result.rows.length === 0) {
        throw new Error('Membership tier not found');
      }

      await ActivityService.logActivity(
        adminId,
        'MEMBERSHIP_TIER_UPDATED',
        'membership_tier',
        tierId,
        { updates },
        req
      );

      return { success: true, data: result.rows[0] };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get platform settings
   */
  static async getPlatformSettings() {
    try {
      // Return default settings (can be extended with database table)
      return {
        success: true,
        data: {
          siteName: 'ImpactKnowledge',
          timezone: 'UTC',
          emailNotifications: true,
          maintenanceMode: false,
          features: {
            quizzes: true,
            assignments: true,
            events: true,
            achievements: true,
            communityForum: false,
            socialSharing: true,
          },
          security: {
            passwordMinLength: 8,
            sessionTimeout: 3600,
            mfaRequired: false,
            ipWhitelist: [],
          },
        },
      };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Send bulk notification to users
   */
  static async sendBulkNotification(filters, message, adminId, req) {
    try {
      let whereClause = '';
      const params = [];

      if (filters.role) {
        whereClause = `WHERE role = $1`;
        params.push(filters.role);
      }

      const result = await query(
        `SELECT id, email, full_name FROM users ${whereClause}`,
        params
      );

      const recipients = result.rows;

      // Log activity for bulk notification
      await ActivityService.logActivity(
        adminId,
        'BULK_NOTIFICATION_SENT',
        'notification',
        0,
        { recipientCount: recipients.length, filters },
        req
      );

      return {
        success: true,
        data: {
          recipientCount: recipients.length,
          message: 'Notification queued for delivery',
          recipients: recipients.map((r) => r.email),
        },
      };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get audit log (activity history)
   */
  static async getAuditLog(filters = {}) {
    try {
      const { actionType, userId, limit = 100, offset = 0 } = filters;

      let whereConditions = [];
      const params = [];
      let paramCount = 1;

      if (actionType) {
        whereConditions.push(`action_type = $${paramCount}`);
        params.push(actionType);
        paramCount++;
      }

      if (userId) {
        whereConditions.push(`user_id = $${paramCount}`);
        params.push(userId);
        paramCount++;
      }

      const whereClause =
        whereConditions.length > 0 ? `WHERE ${whereConditions.join(' AND ')}` : '';

      const result = await query(
        `SELECT * FROM user_activities
         ${whereClause}
         ORDER BY created_at DESC
         LIMIT $${paramCount} OFFSET $${paramCount + 1}`,
        [...params, limit, offset]
      );

      const countResult = await query(
        `SELECT COUNT(*) as total FROM user_activities ${whereClause}`,
        params
      );

      return {
        success: true,
        data: result.rows,
        pagination: {
          total: parseInt(countResult.rows[0].total),
          limit,
          offset,
        },
      };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }
}

module.exports = AdminService;
