const { query } = require('../database');
const ActivityService = require('./activity-service');

class AssignmentService {
  /**
   * List assignments, optionally filtered by course
   */
  static async listAssignments({ courseId, userId = null } = {}) {
    try {
      const params = [];
      const conditions = [];

      if (courseId) {
        params.push(courseId);
        conditions.push(`a.course_id = $${params.length}`);
      }

      const whereClause = conditions.length
        ? `WHERE ${conditions.join(' AND ')}`
        : '';

      const result = await query(
        `SELECT a.*, c.title as course_title
         FROM assignments a
         JOIN courses c ON c.id = a.course_id
         ${whereClause}
         ORDER BY a.created_at DESC`,
        params
      );

      // Optionally annotate whether current user has submitted.
      if (userId) {
        const assignmentIds = result.rows.map((row) => row.id);
        if (assignmentIds.length > 0) {
          const submissionResult = await query(
            `SELECT assignment_id, status
             FROM submissions
             WHERE user_id = $1 AND assignment_id = ANY($2)`,
            [userId, assignmentIds]
          );
          const submissionMap = new Map(
            submissionResult.rows.map((row) => [row.assignment_id, row.status])
          );

          result.rows.forEach((row) => {
            row.submission_status = submissionMap.get(row.id) || 'not_submitted';
          });
        }
      }

      return { success: true, data: result.rows };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Create a new assignment
   */
  static async createAssignment(assignmentData, instructorId, req) {
    try {
      const {
        courseId,
        moduleId,
        title,
        description,
        instructions,
        totalPoints,
        dueDate,
        allowLateSubmission,
        latePenaltyPercent,
      } = assignmentData;

      // Verify instructor owns the course
      const courseCheck = await query(
        'SELECT instructor_id FROM courses WHERE id = $1',
        [courseId]
      );

      if (courseCheck.rows.length === 0) {
        throw new Error('Course not found');
      }

      if (courseCheck.rows[0].instructor_id !== instructorId) {
        throw new Error('Unauthorized: You do not own this course');
      }

      const result = await query(
        `INSERT INTO assignments 
        (course_id, module_id, title, description, instructions, total_points, 
         due_date, allow_late_submission, late_penalty_percent, created_by) 
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) 
        RETURNING *`,
        [
          courseId,
          moduleId || null,
          title,
          description,
          instructions,
          totalPoints || 100,
          dueDate || null,
          allowLateSubmission || false,
          latePenaltyPercent || 0,
          instructorId,
        ]
      );

      await ActivityService.logActivity(
        instructorId,
        'ASSIGNMENT_CREATED',
        'assignment',
        result.rows[0].id,
        { title, courseId },
        req
      );

      return { success: true, data: result.rows[0] };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get assignment by ID with submission info
   */
  static async getAssignment(assignmentId, userId = null) {
    try {
      const assignmentResult = await query(
        'SELECT * FROM assignments WHERE id = $1',
        [assignmentId]
      );

      if (assignmentResult.rows.length === 0) {
        throw new Error('Assignment not found');
      }

      const assignment = assignmentResult.rows[0];

      // If user is specified and is a student, get their submission
      if (userId) {
        const submissionResult = await query(
          `SELECT s.*, sg.points_earned, sg.feedback, sg.graded_at, u.full_name as graded_by_name
           FROM submissions s
           LEFT JOIN submissions_grades sg ON s.id = sg.submission_id
           LEFT JOIN users u ON sg.graded_by = u.id
           WHERE s.assignment_id = $1 AND s.user_id = $2`,
          [assignmentId, userId]
        );

        assignment.submission = submissionResult.rows[0] || null;
      }

      return { success: true, data: assignment };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get a submission by ID
   */
  static async getSubmissionById(submissionId, requesterId) {
    try {
      const result = await query(
        `SELECT s.*, sg.points_earned, sg.feedback, sg.graded_at
         FROM submissions s
         LEFT JOIN submissions_grades sg ON sg.submission_id = s.id
         WHERE s.id = $1`,
        [submissionId]
      );

      if (result.rows.length === 0) {
        throw new Error('Submission not found');
      }

      const submission = result.rows[0];

      const accessResult = await query(
        `SELECT a.created_by
         FROM assignments a
         WHERE a.id = $1`,
        [submission.assignment_id]
      );

      const createdBy = accessResult.rows[0]?.created_by;
      if (submission.user_id !== requesterId && createdBy !== requesterId) {
        throw new Error('Unauthorized');
      }

      return { success: true, data: submission };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get submission file URL with authorization checks
   */
  static async getSubmissionFile(submissionId, requesterId) {
    try {
      const submissionResult = await query(
        `SELECT s.id, s.user_id, s.file_url, s.assignment_id, a.created_by
         FROM submissions s
         JOIN assignments a ON a.id = s.assignment_id
         WHERE s.id = $1`,
        [submissionId]
      );

      if (submissionResult.rows.length === 0) {
        throw new Error('Submission not found');
      }

      const submission = submissionResult.rows[0];
      const authorized =
        submission.user_id === requesterId || submission.created_by === requesterId;

      if (!authorized) {
        throw new Error('Unauthorized');
      }

      if (!submission.file_url) {
        throw new Error('No file attached to this submission');
      }

      return {
        success: true,
        data: {
          submissionId,
          fileUrl: submission.file_url,
        },
      };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Delete submission file with authorization checks
   */
  static async deleteSubmissionFile(submissionId, requesterId, req) {
    try {
      const submissionResult = await query(
        `SELECT s.id, s.user_id, s.file_url, s.assignment_id, a.created_by
         FROM submissions s
         JOIN assignments a ON a.id = s.assignment_id
         WHERE s.id = $1`,
        [submissionId]
      );

      if (submissionResult.rows.length === 0) {
        throw new Error('Submission not found');
      }

      const submission = submissionResult.rows[0];
      const authorized =
        submission.user_id === requesterId || submission.created_by === requesterId;

      if (!authorized) {
        throw new Error('Unauthorized');
      }

      if (!submission.file_url) {
        return { success: true, data: { message: 'No file to delete' } };
      }

      await query(
        `UPDATE submissions
         SET file_url = NULL,
             submission_date = CURRENT_TIMESTAMP,
             status = CASE WHEN submission_text IS NULL OR submission_text = '' THEN 'draft' ELSE status END
         WHERE id = $1`,
        [submissionId]
      );

      await ActivityService.logActivity(
        requesterId,
        'ASSIGNMENT_FILE_DELETED',
        'submission',
        submissionId,
        { assignmentId: submission.assignment_id },
        req
      );

      return {
        success: true,
        data: {
          submissionId,
          deleted: true,
        },
      };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get all submissions for an assignment (instructor view)
   */
  static async getAssignmentSubmissions(assignmentId, instructorId) {
    try {
      // Verify instructor owns the course
      const assignmentCheck = await query(
        `SELECT a.created_by, a.course_id FROM assignments a WHERE a.id = $1`,
        [assignmentId]
      );

      if (assignmentCheck.rows.length === 0) {
        throw new Error('Assignment not found');
      }

      if (assignmentCheck.rows[0].created_by !== instructorId) {
        throw new Error('Unauthorized');
      }

      const result = await query(
        `SELECT s.*, u.full_name, u.email,
                sg.points_earned, sg.feedback, sg.graded_at
         FROM submissions s
         JOIN users u ON s.user_id = u.id
         LEFT JOIN submissions_grades sg ON s.id = sg.submission_id
         WHERE s.assignment_id = $1
         ORDER BY s.submission_date DESC`,
        [assignmentId]
      );

      return { success: true, data: result.rows };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Update assignment
   */
  static async updateAssignment(assignmentId, updates, instructorId, req) {
    try {
      const assignment = await query(
        'SELECT created_by FROM assignments WHERE id = $1',
        [assignmentId]
      );

      if (assignment.rows.length === 0) {
        throw new Error('Assignment not found');
      }

      if (assignment.rows[0].created_by !== instructorId) {
        throw new Error('Unauthorized: You did not create this assignment');
      }

      const fields = [];
      const values = [];
      let paramCount = 1;

      const allowedFields = [
        'title',
        'description',
        'instructions',
        'total_points',
        'due_date',
        'allow_late_submission',
        'late_penalty_percent',
        'is_published',
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

      values.push(assignmentId);
      fields.push('updated_at = CURRENT_TIMESTAMP');

      const result = await query(
        `UPDATE assignments SET ${fields.join(', ')} WHERE id = $${paramCount} RETURNING *`,
        values
      );

      await ActivityService.logActivity(
        instructorId,
        'ASSIGNMENT_UPDATED',
        'assignment',
        assignmentId,
        { updates },
        req
      );

      return { success: true, data: result.rows[0] };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Delete assignment
   */
  static async deleteAssignment(assignmentId, instructorId, req) {
    try {
      const assignment = await query(
        'SELECT created_by FROM assignments WHERE id = $1',
        [assignmentId]
      );

      if (assignment.rows.length === 0) {
        throw new Error('Assignment not found');
      }

      if (assignment.rows[0].created_by !== instructorId) {
        throw new Error('Unauthorized: You did not create this assignment');
      }

      await query('DELETE FROM assignments WHERE id = $1', [assignmentId]);

      await ActivityService.logActivity(
        instructorId,
        'ASSIGNMENT_DELETED',
        'assignment',
        assignmentId,
        {},
        req
      );

      return { success: true, data: { id: assignmentId } };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Submit assignment (student)
   */
  static async submitAssignment(assignmentId, userId, submissionData, req) {
    try {
      // Get assignment details
      const assignmentResult = await query(
        'SELECT * FROM assignments WHERE id = $1',
        [assignmentId]
      );

      if (assignmentResult.rows.length === 0) {
        throw new Error('Assignment not found');
      }

      const assignment = assignmentResult.rows[0];

      // Check enrollment
      const enrollmentCheck = await query(
        'SELECT id FROM enrollments WHERE user_id = $1 AND course_id = $2',
        [userId, assignment.course_id]
      );

      if (enrollmentCheck.rows.length === 0) {
        throw new Error('User not enrolled in this course');
      }

      // Check if already submitted
      const existingSubmission = await query(
        'SELECT id FROM submissions WHERE assignment_id = $1 AND user_id = $2',
        [assignmentId, userId]
      );

      let result;
      const isLate =
        assignment.due_date && new Date() > new Date(assignment.due_date);

      if (existingSubmission.rows.length > 0) {
        // Update existing submission
        result = await query(
          `UPDATE submissions 
           SET submission_text = $1, file_url = $2, submission_date = CURRENT_TIMESTAMP, is_late = $3, status = 'submitted'
           WHERE assignment_id = $4 AND user_id = $5
           RETURNING *`,
          [
            submissionData.submissionText || null,
            submissionData.fileUrl || null,
            isLate,
            assignmentId,
            userId,
          ]
        );
      } else {
        // Create new submission
        result = await query(
          `INSERT INTO submissions 
          (assignment_id, user_id, submission_text, file_url, is_late, status)
          VALUES ($1, $2, $3, $4, $5, 'submitted')
          RETURNING *`,
          [
            assignmentId,
            userId,
            submissionData.submissionText || null,
            submissionData.fileUrl || null,
            isLate,
          ]
        );
      }

      await ActivityService.logActivity(
        userId,
        'ASSIGNMENT_SUBMITTED',
        'assignment',
        assignmentId,
        { late: isLate },
        req
      );

      return { success: true, data: result.rows[0] };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Grade submission
   */
  static async gradeSubmission(submissionId, gradeData, instructorId, req) {
    try {
      const { pointsEarned, feedback } = gradeData;

      // Get submission and verify instructor is course creator
      const submissionResult = await query(
        `SELECT s.*, a.created_by FROM submissions s
         JOIN assignments a ON s.assignment_id = a.id
         WHERE s.id = $1`,
        [submissionId]
      );

      if (submissionResult.rows.length === 0) {
        throw new Error('Submission not found');
      }

      if (submissionResult.rows[0].created_by !== instructorId) {
        throw new Error('Unauthorized');
      }

      // Check if grade already exists
      const existingGrade = await query(
        'SELECT id FROM submissions_grades WHERE submission_id = $1',
        [submissionId]
      );

      let result;
      if (existingGrade.rows.length > 0) {
        // Update existing grade
        result = await query(
          `UPDATE submissions_grades 
           SET points_earned = $1, feedback = $2, graded_at = CURRENT_TIMESTAMP
           WHERE submission_id = $3
           RETURNING *`,
          [pointsEarned, feedback, submissionId]
        );
      } else {
        // Create new grade
        result = await query(
          `INSERT INTO submissions_grades (submission_id, graded_by, points_earned, feedback)
          VALUES ($1, $2, $3, $4)
          RETURNING *`,
          [submissionId, instructorId, pointsEarned, feedback]
        );
      }

      // Update submission status to graded
      await query(
        `UPDATE submissions SET status = 'graded' WHERE id = $1`,
        [submissionId]
      );

      const submission = submissionResult.rows[0];

      await ActivityService.logActivity(
        instructorId,
        'SUBMISSION_GRADED',
        'submission',
        submissionId,
        { pointsEarned, feedback },
        req
      );

      return { success: true, data: result.rows[0] };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get assignment statistics
   */
  static async getAssignmentStats(assignmentId) {
    try {
      const result = await query(
        `SELECT 
           COUNT(DISTINCT user_id) as total_students,
           COUNT(CASE WHEN status = 'submitted' OR status = 'graded' THEN 1 END) as submitted_count,
           COUNT(CASE WHEN status = 'graded' THEN 1 END) as graded_count,
           AVG(CAST(sg.points_earned AS FLOAT)) as average_score,
           COUNT(CASE WHEN is_late = true THEN 1 END) as late_submissions
         FROM submissions s
         LEFT JOIN submissions_grades sg ON s.id = sg.submission_id
         WHERE s.assignment_id = $1`,
        [assignmentId]
      );

      return { success: true, data: result.rows[0] };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }
}

module.exports = AssignmentService;
