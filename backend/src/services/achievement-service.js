const { query } = require('../database');
const ActivityService = require('./activity-service');

class AchievementService {
  /**
   * Get all active achievements
   */
  static async getAchievements(category = null) {
    try {
      let sql = `SELECT id, title, description, icon_url, points, category, 
                        unlock_condition, is_active
                 FROM achievements 
                 WHERE is_active = true`;
      const params = [];

      if (category) {
        sql += ' AND category = $1';
        params.push(category);
      }

      sql += ' ORDER BY points ASC';

      const result = await query(sql, params);
      return { success: true, data: result.rows };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get user's earned achievements
   */
  static async getUserAchievements(userId) {
    try {
      const result = await query(
        `SELECT a.*, aul.unlock_date, aul.trigger_event
         FROM user_achievements ua
         JOIN achievements a ON ua.achievement_id = a.id
         LEFT JOIN achievement_unlock_logs aul ON a.id = aul.achievement_id AND ua.user_id = aul.user_id
         WHERE ua.user_id = $1 AND a.is_active = true
         ORDER BY aul.unlock_date DESC NULLS LAST`,
        [userId]
      );

      return { success: true, data: result.rows };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Check unlocked achievements for a user
   */
  static async getUnlockedAchievements(userId) {
    try {
      const result = await query(
        `SELECT a.*, aul.unlock_date, aul.trigger_event
         FROM achievement_unlock_logs aul
         JOIN achievements a ON aul.achievement_id = a.id
         WHERE aul.user_id = $1
         ORDER BY aul.unlock_date DESC`,
        [userId]
      );

      return { success: true, data: result.rows };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Auto-unlock achievements based on criteria
   */
  static async checkAndUnlockAchievements(userId, triggerEvent, metadata, req) {
    try {
      const unlockedAchievements = [];

      // Get all active achievements
      const achievementsResult = await query(
        'SELECT * FROM achievements WHERE is_active = true'
      );

      for (const achievement of achievementsResult.rows) {
        const isEligible = await this._checkUnlockCriteria(
          userId,
          achievement.unlock_condition,
          triggerEvent
        );

        if (isEligible) {
          // Check if already unlocked
          const existingUnlock = await query(
            'SELECT id FROM user_achievements WHERE user_id = $1 AND achievement_id = $2',
            [userId, achievement.id]
          );

          if (existingUnlock.rows.length === 0) {
            // Unlock the achievement
            await query(
              'INSERT INTO user_achievements (user_id, achievement_id) VALUES ($1, $2)',
              [userId, achievement.id]
            );

            // Log the unlock
            await query(
              `INSERT INTO achievement_unlock_logs 
               (user_id, achievement_id, trigger_event, metadata)
               VALUES ($1, $2, $3, $4)`,
              [userId, achievement.id, triggerEvent, JSON.stringify(metadata)]
            );

            unlockedAchievements.push(achievement);

            await ActivityService.logActivity(
              userId,
              'ACHIEVEMENT_UNLOCKED',
              'achievement',
              achievement.id,
              { achievement: achievement.title, triggerEvent },
              req
            );
          }
        }
      }

      return { success: true, data: { unlockedAchievements, count: unlockedAchievements.length } };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Check if user meets unlock criteria
   */
  static async _checkUnlockCriteria(userId, unlockCondition, triggerEvent) {
    try {
      const condition = unlockCondition?.toLowerCase() || '';

      // Condition examples: "complete_1_course", "quiz_score_above_80", "5_quiz_attempts", etc.

      // Check enrollment count
      if (condition.includes('complete') && condition.includes('course')) {
        const numMatch = condition.match(/\d+/);
        const requiredCount = numMatch ? parseInt(numMatch[0]) : 1;

        const enrollmentResult = await query(
          `SELECT COUNT(DISTINCT e.course_id) as count 
           FROM enrollments e 
           WHERE e.user_id = $1 AND e.completion_status = 'completed'`,
          [userId]
        );

        const completedCount = parseInt(enrollmentResult.rows[0].count || 0);
        return completedCount >= requiredCount;
      }

      // Check quiz score
      if (condition.includes('quiz_score')) {
        const scoreMatch = condition.match(/\d+/);
        const requiredScore = scoreMatch ? parseInt(scoreMatch[0]) : 80;

        const quizResult = await query(
          `SELECT AVG(percentage) as avg_score 
           FROM quiz_attempts 
           WHERE user_id = $1`,
          [userId]
        );

        const avgScore = parseFloat(quizResult.rows[0]?.avg_score || 0);
        return avgScore >= requiredScore;
      }

      // Check quiz attempts
      if (condition.includes('quiz') && condition.includes('attempt')) {
        const numMatch = condition.match(/\d+/);
        const requiredAttempts = numMatch ? parseInt(numMatch[0]) : 5;

        const attemptsResult = await query(
          'SELECT COUNT(*) as count FROM quiz_attempts WHERE user_id = $1',
          [userId]
        );

        const attemptCount = parseInt(attemptsResult.rows[0].count || 0);
        return attemptCount >= requiredAttempts;
      }

      // Check passed quizzes
      if (condition.includes('pass') && condition.includes('quiz')) {
        const numMatch = condition.match(/\d+/);
        const requiredPasses = numMatch ? parseInt(numMatch[0]) : 3;

        const passResult = await query(
          `SELECT COUNT(*) as count 
           FROM quiz_attempts 
           WHERE user_id = $1 AND is_passed = true`,
          [userId]
        );

        const passCount = parseInt(passResult.rows[0].count || 0);
        return passCount >= requiredPasses;
      }

      // Check assignment submissions
      if (condition.includes('submit') && condition.includes('assignment')) {
        const numMatch = condition.match(/\d+/);
        const requiredSubmissions = numMatch ? parseInt(numMatch[0]) : 5;

        const submissionResult = await query(
          'SELECT COUNT(*) as count FROM submissions WHERE user_id = $1',
          [userId]
        );

        const submissionCount = parseInt(submissionResult.rows[0].count || 0);
        return submissionCount >= requiredSubmissions;
      }

      // Check assignment grades
      if (condition.includes('grade') && condition.includes('above')) {
        const gradeMatch = condition.match(/\d+/);
        const requiredGrade = gradeMatch ? parseInt(gradeMatch[0]) : 80;

        const gradeResult = await query(
          `SELECT AVG(CAST(score AS FLOAT) / total_points * 100) as avg_grade
           FROM submissions_grades 
           WHERE graded_user_id = $1`,
          [userId]
        );

        const avgGrade = parseFloat(gradeResult.rows[0]?.avg_grade || 0);
        return avgGrade >= requiredGrade;
      }

      // Check event attendance
      if (condition.includes('attend') && condition.includes('event')) {
        const numMatch = condition.match(/\d+/);
        const requiredAttendance = numMatch ? parseInt(numMatch[0]) : 1;

        const attendanceResult = await query(
          `SELECT COUNT(*) as count 
           FROM event_registrations 
           WHERE user_id = $1 AND attendance_status = 'attended'`,
          [userId]
        );

        const attendanceCount = parseInt(attendanceResult.rows[0].count || 0);
        return attendanceCount >= requiredAttendance;
      }

      // Trigger-event based unlocking (for specific events)
      if (condition.includes(triggerEvent?.toLowerCase() || '')) {
        return true;
      }

      return false;
    } catch (err) {
      console.error('Error checking unlock criteria:', err);
      return false;
    }
  }

  /**
   * Manually unlock an achievement (admin only)
   */
  static async manualUnlock(userId, achievementId, req) {
    try {
      // Check if achievement exists
      const achievementCheck = await query(
        'SELECT id FROM achievements WHERE id = $1 AND is_active = true',
        [achievementId]
      );

      if (achievementCheck.rows.length === 0) {
        throw new Error('Achievement not found');
      }

      // Check if already unlocked
      const existingUnlock = await query(
        'SELECT id FROM user_achievements WHERE user_id = $1 AND achievement_id = $2',
        [userId, achievementId]
      );

      if (existingUnlock.rows.length > 0) {
        throw new Error('User has already unlocked this achievement');
      }

      // Unlock it
      const result = await query(
        'INSERT INTO user_achievements (user_id, achievement_id) VALUES ($1, $2) RETURNING *',
        [userId, achievementId]
      );

      // Log the unlock
      await query(
        `INSERT INTO achievement_unlock_logs 
         (user_id, achievement_id, trigger_event)
         VALUES ($1, $2, 'MANUAL_UNLOCK')`,
        [userId, achievementId]
      );

      await ActivityService.logActivity(
        req.user?.id || userId,
        'ACHIEVEMENT_MANUALLY_UNLOCKED',
        'achievement',
        achievementId,
        { targetUser: userId },
        req
      );

      return { success: true, data: result.rows[0] };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Create new achievement (admin only)
   */
  static async createAchievement(achievementData, adminId, req) {
    try {
      const {
        title,
        description,
        iconUrl,
        points,
        category,
        unlockCondition,
      } = achievementData;

      if (!title || !points) {
        throw new Error('Title and points are required');
      }

      const result = await query(
        `INSERT INTO achievements 
         (title, description, icon_url, points, category, unlock_condition, is_active)
         VALUES ($1, $2, $3, $4, $5, $6, true)
         RETURNING *`,
        [
          title,
          description,
          iconUrl,
          points,
          category || 'general',
          unlockCondition || 'manual',
        ]
      );

      await ActivityService.logActivity(
        adminId,
        'ACHIEVEMENT_CREATED',
        'achievement',
        result.rows[0].id,
        { title, points },
        req
      );

      return { success: true, data: result.rows[0] };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Update achievement (admin only)
   */
  static async updateAchievement(achievementId, updates, adminId, req) {
    try {
      const fields = [];
      const values = [];
      let paramCount = 1;

      const allowedFields = [
        'title',
        'description',
        'icon_url',
        'points',
        'category',
        'unlock_condition',
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

      values.push(achievementId);

      const result = await query(
        `UPDATE achievements SET ${fields.join(', ')} WHERE id = $${paramCount} RETURNING *`,
        values
      );

      if (result.rows.length === 0) {
        throw new Error('Achievement not found');
      }

      await ActivityService.logActivity(
        adminId,
        'ACHIEVEMENT_UPDATED',
        'achievement',
        achievementId,
        { updates },
        req
      );

      return { success: true, data: result.rows[0] };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get achievement statistics
   */
  static async getStatistics() {
    try {
      // Total achievements
      const totalResult = await query(
        'SELECT COUNT(*) as count FROM achievements WHERE is_active = true'
      );

      // Most unlocked achievements
      const mostUnlockedResult = await query(
        `SELECT a.title, COUNT(DISTINCT aul.user_id) as unlock_count
         FROM achievements a
         LEFT JOIN achievement_unlock_logs aul ON a.id = aul.achievement_id
         WHERE a.is_active = true
         GROUP BY a.id, a.title
         ORDER BY unlock_count DESC
         LIMIT 10`
      );

      // Achievements by category
      const byCategory = await query(
        `SELECT category, COUNT(*) as count
         FROM achievements
         WHERE is_active = true
         GROUP BY category`
      );

      return {
        success: true,
        data: {
          total: parseInt(totalResult.rows[0].count),
          mostUnlocked: mostUnlockedResult.rows,
          byCategory: byCategory.rows,
        },
      };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }
}

module.exports = AchievementService;
