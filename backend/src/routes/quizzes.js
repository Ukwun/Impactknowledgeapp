const express = require('express');
const { verifyToken } = require('../middleware/auth');
const QuizService = require('../services/quiz-service');

const router = express.Router();

/**
 * POST /api/quizzes
 * Create a new quiz (instructor only)
 */
router.post('/', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'instructor' && req.user.role !== 'facilitator') {
      return res.status(403).json({
        success: false,
        error: 'Only instructors can create quizzes',
      });
    }

    const result = await QuizService.createQuiz(req.body, req.user.id, req);

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.status(201).json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/quizzes/:id
 * Get quiz details with questions and answers
 */
router.get('/:id', verifyToken, async (req, res) => {
  try {
    const result = await QuizService.getQuiz(req.params.id);

    if (!result.success) {
      return res.status(404).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * PUT /api/quizzes/:id
 * Update quiz (instructor only)
 */
router.put('/:id', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'instructor' && req.user.role !== 'facilitator') {
      return res.status(403).json({
        success: false,
        error: 'Only instructors can update quizzes',
      });
    }

    const result = await QuizService.updateQuiz(
      req.params.id,
      req.body,
      req.user.id,
      req
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * DELETE /api/quizzes/:id
 * Delete quiz (instructor only)
 */
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'instructor' && req.user.role !== 'facilitator') {
      return res.status(403).json({
        success: false,
        error: 'Only instructors can delete quizzes',
      });
    }

    const result = await QuizService.deleteQuiz(
      req.params.id,
      req.user.id,
      req
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/quizzes/:id/questions
 * Add question to quiz (instructor only)
 */
router.post('/:id/questions', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'instructor' && req.user.role !== 'facilitator') {
      return res.status(403).json({
        success: false,
        error: 'Only instructors can add questions',
      });
    }

    const result = await QuizService.addQuestion(
      req.params.id,
      req.body,
      req.user.id,
      req
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.status(201).json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/quizzes/:quizId/questions/:questionId/answers
 * Add answer option to question (instructor only)
 */
router.post('/:quizId/questions/:questionId/answers', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'instructor' && req.user.role !== 'facilitator') {
      return res.status(403).json({
        success: false,
        error: 'Only instructors can add answers',
      });
    }

    const result = await QuizService.addAnswer(
      req.params.questionId,
      req.body,
      req.user.id,
      req
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.status(201).json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * POST /api/quizzes/:id/attempts
 * Submit quiz attempt (student)
 * Body: { answers: [{questionId, selectedAnswerId}], timeSpentMinutes }
 */
router.post('/:id/attempts', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'student') {
      return res.status(403).json({
        success: false,
        error: 'Only students can submit quiz attempts',
      });
    }

    const { answers, timeSpentMinutes } = req.body;

    if (!answers || !Array.isArray(answers)) {
      return res.status(400).json({
        success: false,
        error: 'Answers array required',
      });
    }

    const result = await QuizService.submitQuizAttempt(
      req.params.id,
      req.user.id,
      answers,
      timeSpentMinutes || 0,
      req
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.status(201).json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/quizzes/:id/attempts
 * Get user's quiz attempts
 */
router.get('/:id/attempts', verifyToken, async (req, res) => {
  try {
    const result = await QuizService.getUserAttempts(req.params.id, req.user.id);

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/quizzes/:id/results
 * Get quiz results and analytics (instructor view)
 */
router.get('/:id/results', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'instructor' && req.user.role !== 'facilitator' && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Unauthorized',
      });
    }

    const result = await QuizService.getQuizResults(req.params.id);

    if (!result.success) {
      return res.status(400).json(result);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
