/**
 * Activity Tracking Service
 * Logs all user activities for analytics and personalization
 */

const { query } = require('../database');

class ActivityService {
  /**
   * Log a user activity
   * @param {number} userId - User ID
   * @param {string} activityType - Type of activity (VIEW_COURSE, START_LESSON, etc)
   * @param {string} resourceType - Type of resource being interacted with (course, lesson, quiz, etc)
   * @param {number} resourceId - ID of the resource
   * @param {object} metadata - Additional context data
   * @param {object} req - Express request object (for IP, user agent)
   */
  static async logActivity(userId, activityType, resourceType = null, resourceId = null, metadata = {}, req = null) {
    try {
      const sessionId = req?.sessionID || req?.headers?.['x-session-id'] || `session_${Date.now()}`;
      const ipAddress = req?.ip || req?.connection?.remoteAddress || null;
      const userAgent = req?.headers?.['user-agent'] || null;

      await query(
        `INSERT INTO user_activities (user_id, activity_type, resource_type, resource_id, metadata, session_id, ip_address, user_agent, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CURRENT_TIMESTAMP)`,
        [userId, activityType, resourceType, resourceId, JSON.stringify(metadata), sessionId, ipAddress, userAgent]
      );

      // Update user's last_active_at
      await this.updateUserLastActive(userId);

      return true;
    } catch (err) {
      console.error('Error logging activity:', err);
      return false;
    }
  }

  /**
   * Update last active timestamp for user
   */
  static async updateUserLastActive(userId) {
    try {
      const result = await query(
        `SELECT id FROM user_analytics WHERE user_id = $1`,
        [userId]
      );

      if (result.rows.length > 0) {
        await query(
          `UPDATE user_analytics SET last_active_at = CURRENT_TIMESTAMP WHERE user_id = $1`,
          [userId]
        );
      } else {
        // Create analytics record if doesn't exist
        await query(
          `INSERT INTO user_analytics (user_id, last_active_at) VALUES ($1, CURRENT_TIMESTAMP)`,
          [userId]
        );
      }
    } catch (err) {
      console.error('Error updating last active:', err);
    }
  }

  /**
   * Get user activity summary
   */
  static async getUserActivitySummary(userId, daysBack = 30) {
    try {
      const result = await query(
        `SELECT activity_type, COUNT(*) as count
         FROM user_activities
         WHERE user_id = $1 AND created_at >= NOW() - INTERVAL '${daysBack} days'
         GROUP BY activity_type
         ORDER BY count DESC`,
        [userId]
      );

      return result.rows;
    } catch (err) {
      console.error('Error getting activity summary:', err);
      return [];
    }
  }

  /**
   * Get all activities for a user
   */
  static async getUserActivities(userId, limit = 100, offset = 0) {
    try {
      const result = await query(
        `SELECT id, activity_type, resource_type, resource_id, metadata, created_at
         FROM user_activities
         WHERE user_id = $1
         ORDER BY created_at DESC
         LIMIT $2 OFFSET $3`,
        [userId, limit, offset]
      );

      return result.rows;
    } catch (err) {
      console.error('Error getting user activities:', err);
      return [];
    }
  }

  /**
   * Calculate user engagement metrics
   */
  static async calculateEngagementMetrics(userId) {
    try {
      // Get activity count
      const activityResult = await query(
        `SELECT COUNT(*) as activity_count
         FROM user_activities
         WHERE user_id = $1 AND created_at >= NOW() - INTERVAL '7 days'`,
        [userId]
      );

      const activityCount = parseInt(activityResult.rows[0]?.activity_count || 0);

      // Get unique days active (last 30 days)
      const daysResult = await query(
        `SELECT COUNT(DISTINCT DATE(created_at)) as days_active
         FROM user_activities
         WHERE user_id = $1 AND created_at >= NOW() - INTERVAL '30 days'`,
        [userId]
      );

      const daysActive = parseInt(daysResult.rows[0]?.days_active || 0);

      // Determine engagement level
      let engagementLevel = 'low';
      if (activityCount >= 20) engagementLevel = 'high';
      else if (activityCount >= 10) engagementLevel = 'medium';

      // Calculate churn risk (lower activity = higher risk)
      const churnRisk = Math.max(0, Math.min(1, (30 - daysActive) / 30));

      return {
        activityCount,
        daysActive,
        engagementLevel,
        churnRisk: parseFloat(churnRisk.toFixed(2))
      };
    } catch (err) {
      console.error('Error calculating engagement metrics:', err);
      return {
        activityCount: 0,
        daysActive: 0,
        engagementLevel: 'low',
        churnRisk: 1.0
      };
    }
  }

  /**
   * Get user learning style prediction based on activities
   */
  static async predictLearningStyle(userId) {
    try {
      const result = await query(
        `SELECT resource_type, COUNT(*) as count
         FROM user_activities
         WHERE user_id = $1 AND activity_type IN ('START_LESSON', 'COMPLETE_LESSON', 'COMPLETED_LESSON')
         GROUP BY resource_type`,
        [userId]
      );

      let learningStyle = 'mixed';
      if (result.rows.length > 0) {
        const topResource = result.rows[0];
        if (topResource.resource_type === 'video') learningStyle = 'visual';
        else if (topResource.resource_type === 'quiz') learningStyle = 'kinesthetic';
        else if (topResource.resource_type === 'text') learningStyle = 'reading';
      }

      return learningStyle;
    } catch (err) {
      console.error('Error predicting learning style:', err);
      return 'mixed';
    }
  }

  /**
   * Get recommended courses based on user activities
   */
  static async getRecommendedCourses(userId, limit = 5) {
    try {
      // Get user's preferred categories
      const categoryResult = await query(
        `SELECT DISTINCT c.category
         FROM user_activities ua
         JOIN courses c ON ua.resource_id = c.id AND ua.resource_type = 'course'
         WHERE ua.user_id = $1
         LIMIT 3`,
        [userId]
      );

      const categories = categoryResult.rows.map(r => r.category).filter(Boolean);

      // Get user's enrolled courses
      const enrolledResult = await query(
        `SELECT course_id FROM enrollments WHERE user_id = $1`,
        [userId]
      );

      const enrolledCourseIds = enrolledResult.rows.map(r => r.course_id);

      // Recommend similar courses
      let whereClause = 'WHERE is_published = true';
      const params = [limit];

      if (categories.length > 0) {
        whereClause += ` AND category = ANY($${params.length + 1}::text[])`;
        params.push(categories);
      }

      if (enrolledCourseIds.length > 0) {
        whereClause += ` AND id NOT IN (${enrolledCourseIds.join(',')})`;
      }

      const recommendResult = await query(
        `SELECT id, title, description, category, thumbnail_url, price, level
         FROM courses
         ${whereClause}
         ORDER BY created_at DESC
         LIMIT $${params.length}`,
        params
      );

      return recommendResult.rows;
    } catch (err) {
      console.error('Error getting recommendations:', err);
      return [];
    }
  }

  /**
   * Update user analytics from activities
   */
  static async updateUserAnalytics(userId) {
    try {
      // Get completion counts
      const completionResult = await query(
        `SELECT
          (SELECT COUNT(*) FROM user_activities WHERE user_id = $1 AND activity_type IN ('COMPLETE_COURSE', 'COURSE_COMPLETED')) as completed_courses,
          (SELECT COUNT(*) FROM user_activities WHERE user_id = $1 AND activity_type IN ('COMPLETE_LESSON', 'COMPLETED_LESSON')) as completed_lessons,
          (SELECT COUNT(*) FROM user_activities WHERE user_id = $1 AND activity_type IN ('COMPLETE_QUIZ', 'QUIZ_COMPLETED')) as quiz_attempts
         FROM user_activities LIMIT 1`,
        [userId]
      );

      const metrics = completionResult.rows[0] || {};

      // Get user's learning style
      const learningStyle = await this.predictLearningStyle(userId);

      // Get engagement metrics
      const engagement = await this.calculateEngagementMetrics(userId);

      // Update analytics
      const existsResult = await query(
        `SELECT id FROM user_analytics WHERE user_id = $1`,
        [userId]
      );

      if (existsResult.rows.length > 0) {
        await query(
          `UPDATE user_analytics SET
            total_lessons_completed = $2,
            total_courses_completed = $3,
            total_quiz_attempts = $4,
            learning_style = $5,
            engagement_level = $6,
            churn_risk_score = $7,
            updated_at = CURRENT_TIMESTAMP
          WHERE user_id = $1`,
          [userId, metrics.completed_lessons || 0, metrics.completed_courses || 0, metrics.quiz_attempts || 0, learningStyle, engagement.engagementLevel, engagement.churnRisk]
        );
      } else {
        await query(
          `INSERT INTO user_analytics (user_id, total_lessons_completed, total_courses_completed, total_quiz_attempts, learning_style, engagement_level, churn_risk_score)
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [userId, metrics.completed_lessons || 0, metrics.completed_courses || 0, metrics.quiz_attempts || 0, learningStyle, engagement.engagementLevel, engagement.churnRisk]
        );
      }

      return true;
    } catch (err) {
      console.error('Error updating user analytics:', err);
      return false;
    }
  }

  /**
   * Track lesson progress
   */
  static async updateLessonProgress(userId, lessonId, status, timeSpent = 0, completionPercentage = 0) {
    try {
      const existsResult = await query(
        `SELECT id FROM lesson_progress WHERE user_id = $1 AND lesson_id = $2`,
        [userId, lessonId]
      );

      if (existsResult.rows.length > 0) {
        await query(
          `UPDATE lesson_progress SET
            status = $3,
            time_spent_minutes = time_spent_minutes + $4,
            completion_percentage = $5,
            last_accessed_at = CURRENT_TIMESTAMP,
            completed_at = CASE WHEN $3 = 'completed' THEN CURRENT_TIMESTAMP ELSE completed_at END
          WHERE user_id = $1 AND lesson_id = $2`,
          [userId, lessonId, status, timeSpent, completionPercentage]
        );
      } else {
        await query(
          `INSERT INTO lesson_progress (user_id, lesson_id, status, time_spent_minutes, completion_percentage, last_accessed_at)
           VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)`,
          [userId, lessonId, status, timeSpent, completionPercentage]
        );
      }

      // Log the activity
      await this.logActivity(userId, `${status.toUpperCase()}_LESSON`, 'lesson', lessonId, { timeSpent, completionPercentage });

      return true;
    } catch (err) {
      console.error('Error updating lesson progress:', err);
      return false;
    }
  }

  /**
   * Get platform-wide analytics
   */
  static async getPlatformAnalytics() {
    try {
      const totalUsersResult = await query(
        `SELECT COUNT(*) as count FROM users`
      );

      const activeTodayResult = await query(
        `SELECT COUNT(DISTINCT user_id) as count FROM user_activities WHERE DATE(created_at) = CURRENT_DATE`
      );

      const totalCoursesResult = await query(
        `SELECT COUNT(*) as count FROM courses WHERE is_published = true`
      );

      const totalEnrollmentsResult = await query(
        `SELECT COUNT(*) as count FROM enrollments`
      );

      const avgCompletionResult = await query(
        `SELECT AVG(progress_percentage) as avg_progress FROM enrollments`
      );

      const topCoursesResult = await query(
        `SELECT c.id, c.title, COUNT(e.id) as enrollment_count
         FROM courses c
         LEFT JOIN enrollments e ON c.id = e.course_id
         WHERE c.is_published = true
         GROUP BY c.id, c.title
         ORDER BY enrollment_count DESC
         LIMIT 5`
      );

      return {
        totalUsers: parseInt(totalUsersResult.rows[0]?.count || 0),
        activeToday: parseInt(activeTodayResult.rows[0]?.count || 0),
        totalCourses: parseInt(totalCoursesResult.rows[0]?.count || 0),
        totalEnrollments: parseInt(totalEnrollmentsResult.rows[0]?.count || 0),
        avgCompletionRate: parseFloat(avgCompletionResult.rows[0]?.avg_progress || 0),
        topCourses: topCoursesResult.rows
      };
    } catch (err) {
      console.error('Error getting platform analytics:', err);
      return {
        totalUsers: 0,
        activeToday: 0,
        totalCourses: 0,
        totalEnrollments: 0,
        avgCompletionRate: 0,
        topCourses: []
      };
    }
  }
}

module.exports = ActivityService;
