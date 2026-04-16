const { query } = require('../database');
const ActivityService = require('./activity-service');

class QuizService {
  /**
   * Create a new quiz
   */
  static async createQuiz(quizData, instructorId, req) {
    try {
      const {
        courseId,
        moduleId,
        title,
        description,
        passingScore,
        timeLimitMinutes,
        maxAttempts,
        showAnswers,
        shuffleQuestions,
      } = quizData;

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
        `INSERT INTO quizzes 
        (course_id, module_id, title, description, passing_score, 
         time_limit_minutes, max_attempts, show_answers, shuffle_questions, created_by) 
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) 
        RETURNING *`,
        [
          courseId,
          moduleId || null,
          title,
          description,
          passingScore || 70,
          timeLimitMinutes || null,
          maxAttempts || 3,
          showAnswers || false,
          shuffleQuestions || false,
          instructorId,
        ]
      );

      await ActivityService.logActivity(
        instructorId,
        'QUIZ_CREATED',
        'quiz',
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
   * Get quiz by ID with questions
   */
  static async getQuiz(quizId) {
    try {
      const quizResult = await query(
        'SELECT * FROM quizzes WHERE id = $1',
        [quizId]
      );

      if (quizResult.rows.length === 0) {
        throw new Error('Quiz not found');
      }

      const quiz = quizResult.rows[0];

      // Get questions
      const questionsResult = await query(
        `SELECT qq.*, 
                COALESCE(json_agg(json_build_object('id', qa.id, 'answer_text', qa.answer_text, 
                                                      'order_index', qa.order_index) 
                          ORDER BY qa.order_index ASC) 
                  FILTER (WHERE qa.id IS NOT NULL), '[]'::json) as answers
         FROM quiz_questions qq
         LEFT JOIN quiz_answers qa ON qq.id = qa.question_id
         WHERE qq.quiz_id = $1
         GROUP BY qq.id
         ORDER BY qq.order_index ASC`,
        [quizId]
      );

      quiz.questions = questionsResult.rows;

      return { success: true, data: quiz };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Update quiz
   */
  static async updateQuiz(quizId, updates, instructorId, req) {
    try {
      const quiz = await query(
        'SELECT created_by FROM quizzes WHERE id = $1',
        [quizId]
      );

      if (quiz.rows.length === 0) {
        throw new Error('Quiz not found');
      }

      if (quiz.rows[0].created_by !== instructorId) {
        throw new Error('Unauthorized: You did not create this quiz');
      }

      const fields = [];
      const values = [];
      let paramCount = 1;

      Object.keys(updates).forEach((key) => {
        if (
          [
            'title',
            'description',
            'passing_score',
            'time_limit_minutes',
            'max_attempts',
            'show_answers',
            'shuffle_questions',
            'is_published',
          ].includes(key)
        ) {
          fields.push(`${key} = $${paramCount}`);
          values.push(updates[key]);
          paramCount++;
        }
      });

      values.push(quizId);
      fields.push('updated_at = CURRENT_TIMESTAMP');

      const result = await query(
        `UPDATE quizzes SET ${fields.join(', ')} WHERE id = $${paramCount} RETURNING *`,
        values
      );

      await ActivityService.logActivity(
        instructorId,
        'QUIZ_UPDATED',
        'quiz',
        quizId,
        { updates },
        req
      );

      return { success: true, data: result.rows[0] };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Delete quiz
   */
  static async deleteQuiz(quizId, instructorId, req) {
    try {
      const quiz = await query(
        'SELECT created_by FROM quizzes WHERE id = $1',
        [quizId]
      );

      if (quiz.rows.length === 0) {
        throw new Error('Quiz not found');
      }

      if (quiz.rows[0].created_by !== instructorId) {
        throw new Error('Unauthorized: You did not create this quiz');
      }

      await query('DELETE FROM quizzes WHERE id = $1', [quizId]);

      await ActivityService.logActivity(
        instructorId,
        'QUIZ_DELETED',
        'quiz',
        quizId,
        {},
        req
      );

      return { success: true, data: { id: quizId } };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Add question to quiz
   */
  static async addQuestion(quizId, questionData, instructorId, req) {
    try {
      const quiz = await query(
        'SELECT created_by FROM quizzes WHERE id = $1',
        [quizId]
      );

      if (quiz.rows.length === 0) {
        throw new Error('Quiz not found');
      }

      if (quiz.rows[0].created_by !== instructorId) {
        throw new Error('Unauthorized');
      }

      const { questionText, questionType, explanation, points, orderIndex } =
        questionData;

      const result = await query(
        `INSERT INTO quiz_questions 
        (quiz_id, question_text, question_type, explanation, points, order_index)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *`,
        [
          quizId,
          questionText,
          questionType,
          explanation,
          points || 1,
          orderIndex,
        ]
      );

      await ActivityService.logActivity(
        instructorId,
        'QUIZ_QUESTION_ADDED',
        'quiz_question',
        result.rows[0].id,
        { questionText, quizId },
        req
      );

      return { success: true, data: result.rows[0] };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Add answer option to question
   */
  static async addAnswer(questionId, answerData, instructorId, req) {
    try {
      const { answerText, isCorrect, orderIndex } = answerData;

      // Verify authorization
      const questionCheck = await query(
        `SELECT qq.quiz_id FROM quiz_questions qq WHERE qq.id = $1`,
        [questionId]
      );

      if (questionCheck.rows.length === 0) {
        throw new Error('Question not found');
      }

      const quizCheck = await query(
        'SELECT created_by FROM quizzes WHERE id = $1',
        [questionCheck.rows[0].quiz_id]
      );

      if (quizCheck.rows[0].created_by !== instructorId) {
        throw new Error('Unauthorized');
      }

      const result = await query(
        `INSERT INTO quiz_answers (question_id, answer_text, is_correct, order_index)
        VALUES ($1, $2, $3, $4)
        RETURNING *`,
        [questionId, answerText, isCorrect || false, orderIndex]
      );

      return { success: true, data: result.rows[0] };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Submit quiz attempt (student takes quiz)
   */
  static async submitQuizAttempt(quizId, userId, answers, timeSpenMinutes, req) {
    try {
      // Get quiz info including passing score
      const quizResult = await query(
        'SELECT * FROM quizzes WHERE id = $1',
        [quizId]
      );

      if (quizResult.rows.length === 0) {
        throw new Error('Quiz not found');
      }

      const quiz = quizResult.rows[0];

      // Check enrollment
      const enrollmentCheck = await query(
        'SELECT id FROM enrollments WHERE user_id = $1 AND course_id = $2',
        [userId, quiz.course_id]
      );

      if (enrollmentCheck.rows.length === 0) {
        throw new Error('User not enrolled in this course');
      }

      // Calculate score
      let totalPoints = 0;
      let earnedPoints = 0;

      // Get all questions with correct answers
      const questionsResult = await query(
        `SELECT qq.id, qq.points,
                (SELECT id FROM quiz_answers WHERE question_id = qq.id AND is_correct = true LIMIT 1) as correct_answer_id
         FROM quiz_questions WHERE quiz_id = $1`,
        [quizId]
      );

      const questions = questionsResult.rows;

      // Check each answer
      for (const answer of answers) {
        const question = questions.find((q) => q.id === answer.questionId);
        if (question) {
          totalPoints += question.points || 1;

          if (answer.selectedAnswerId === question.correct_answer_id) {
            earnedPoints += question.points || 1;
          }
        }
      }

      const percentageScore =
        totalPoints > 0 ? (earnedPoints / totalPoints) * 100 : 0;
      const passed = percentageScore >= quiz.passing_score;

      // Create attempt record
      const attemptResult = await query(
        `INSERT INTO quiz_attempts 
        (quiz_id, user_id, score, percentage_score, passed, time_spent_minutes, completed_at)
        VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)
        RETURNING *`,
        [quizId, userId, earnedPoints, percentageScore, passed, timeSpenMinutes]
      );

      const attemptId = attemptResult.rows[0].id;

      // Record individual question answers
      for (const answer of answers) {
        await query(
          `INSERT INTO quiz_user_answers 
          (attempt_id, question_id, selected_answer_id, is_correct, points_earned)
          VALUES ($1, $2, $3, $4, $5)`,
          [
            attemptId,
            answer.questionId,
            answer.selectedAnswerId || null,
            answer.selectedAnswerId ===
              questions.find((q) => q.id === answer.questionId)?.correct_answer_id,
            answers.selectedAnswerId ===
              questions.find((q) => q.id === answer.questionId)?.correct_answer_id
              ? questions.find((q) => q.id === answer.questionId).points
              : 0,
          ]
        );
      }

      // Update user analytics
      await ActivityService.logActivity(
        userId,
        'QUIZ_COMPLETED',
        'quiz',
        quizId,
        {
          score: earnedPoints,
          totalPoints,
          percentage: percentageScore,
          passed,
        },
        req
      );

      // Update analytics table
      await query(
        `UPDATE user_analytics 
         SET total_quiz_attempts = total_quiz_attempts + 1,
             average_quiz_score = (
               SELECT AVG(percentage_score) FROM quiz_attempts WHERE user_id = $1
             )
         WHERE user_id = $1`,
        [userId]
      );

      return {
        success: true,
        data: {
          attempt: attemptResult.rows[0],
          score: earnedPoints,
          totalPoints,
          percentage: parseFloat(percentageScore.toFixed(2)),
          passed,
        },
      };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get user's quiz attempts
   */
  static async getUserAttempts(quizId, userId) {
    try {
      const result = await query(
        `SELECT * FROM quiz_attempts 
         WHERE quiz_id = $1 AND user_id = $2
         ORDER BY completed_at DESC`,
        [quizId, userId]
      );

      return { success: true, data: result.rows };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get quiz results/analytics
   */
  static async getQuizResults(quizId) {
    try {
      const result = await query(
        `SELECT 
           COUNT(DISTINCT user_id) as total_attempts,
           AVG(percentage_score) as average_score,
           COUNT(CASE WHEN passed = true THEN 1 END) as passed_count,
           COUNT(CASE WHEN passed = false THEN 1 END) as failed_count
         FROM quiz_attempts 
         WHERE quiz_id = $1`,
        [quizId]
      );

      // Get performance by question
      const questionStats = await query(
        `SELECT 
           qq.id,
           qq.question_text,
           COUNT(qua.selected_answer_id) as total_responses,
           COUNT(CASE WHEN qua.is_correct = true THEN 1 END) as correct_count,
           ROUND(100.0 * COUNT(CASE WHEN qua.is_correct = true THEN 1 END) / 
                  NULLIF(COUNT(qua.selected_answer_id), 0), 2) as correct_percentage
         FROM quiz_questions qq
         LEFT JOIN quiz_user_answers qua ON qq.id = qua.question_id
         WHERE qq.quiz_id = $1
         GROUP BY qq.id, qq.question_text
         ORDER BY qq.id`,
        [quizId]
      );

      return {
        success: true,
        data: {
          summary: result.rows[0],
          questionStats: questionStats.rows,
        },
      };
    } catch (err) {
      return { success: false, error: err.message };
    }
  }
}

module.exports = QuizService;
