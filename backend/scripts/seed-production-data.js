/* eslint-disable no-console */
const bcrypt = require('bcryptjs');
const { initializeDatabase, query } = require('../src/database');

const SEED_PASSWORD = process.env.SEED_USER_PASSWORD || 'ImpactKnowledge2026!';

async function upsertUser({ email, fullName, role, bio, location }) {
  const passwordHash = await bcrypt.hash(SEED_PASSWORD, 10);
  const existing = await query('SELECT id FROM users WHERE email = $1', [email.toLowerCase()]);

  if (existing.rows.length > 0) {
    const result = await query(
      `UPDATE users
       SET full_name = $2,
           role = $3,
           bio = $4,
           location = $5,
           password_hash = $6,
           updated_at = CURRENT_TIMESTAMP
       WHERE email = $1
       RETURNING *`,
      [email.toLowerCase(), fullName, role, bio || null, location || null, passwordHash]
    );
    return result.rows[0];
  }

  const result = await query(
    `INSERT INTO users (email, password_hash, full_name, role, bio, location, created_at, updated_at)
     VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
     RETURNING *`,
    [email.toLowerCase(), passwordHash, fullName, role, bio || null, location || null]
  );
  return result.rows[0];
}

async function upsertMembershipTier({ name, description, monthlyPrice, annualPrice, benefits }) {
  const existing = await query(
    'SELECT id FROM membership_tiers WHERE LOWER(name) = LOWER($1) LIMIT 1',
    [name]
  );

  if (existing.rows.length > 0) {
    const result = await query(
      `UPDATE membership_tiers
       SET description = $2,
           monthly_price = $3,
           annual_price = $4,
           benefits = $5
       WHERE id = $1
       RETURNING *`,
      [existing.rows[0].id, description, monthlyPrice, annualPrice, benefits.join('\n')]
    );
    return result.rows[0];
  }

  const result = await query(
    `INSERT INTO membership_tiers (name, description, monthly_price, annual_price, benefits)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [name, description, monthlyPrice, annualPrice, benefits.join('\n')]
  );
  return result.rows[0];
}

async function upsertAchievement({ name, description, pointsReward, criteria, category, unlockCondition }) {
  const existing = await query(
    'SELECT id FROM achievements WHERE LOWER(name) = LOWER($1) LIMIT 1',
    [name]
  );

  if (existing.rows.length > 0) {
    const result = await query(
      `UPDATE achievements
       SET description = $2,
           points_reward = $3,
           criteria = $4,
           category = $5,
           unlock_condition = $6,
           is_active = true
       WHERE id = $1
       RETURNING *`,
      [existing.rows[0].id, description, pointsReward, criteria, category, unlockCondition]
    );
    return result.rows[0];
  }

  const result = await query(
    `INSERT INTO achievements (name, description, points_reward, criteria, category, unlock_condition, is_active)
     VALUES ($1, $2, $3, $4, $5, $6, true)
     RETURNING *`,
    [name, description, pointsReward, criteria, category, unlockCondition]
  );
  return result.rows[0];
}

async function upsertCourse({ title, description, category, instructorId, price, level, durationHours, thumbnailUrl }) {
  const existing = await query('SELECT id FROM courses WHERE title = $1 LIMIT 1', [title]);

  if (existing.rows.length > 0) {
    const result = await query(
      `UPDATE courses
       SET description = $2,
           category = $3,
           instructor_id = $4,
           price = $5,
           level = $6,
           duration_hours = $7,
           thumbnail_url = $8,
           is_published = true,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING *`,
      [existing.rows[0].id, description, category, instructorId, price, level, durationHours, thumbnailUrl || null]
    );
    return result.rows[0];
  }

  const result = await query(
    `INSERT INTO courses (title, description, category, instructor_id, price, level, duration_hours, thumbnail_url, is_published, created_at, updated_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
     RETURNING *`,
    [title, description, category, instructorId, price, level, durationHours, thumbnailUrl || null]
  );
  return result.rows[0];
}

async function upsertModule({ courseId, title, description, orderIndex }) {
  const existing = await query(
    'SELECT id FROM modules WHERE course_id = $1 AND title = $2 LIMIT 1',
    [courseId, title]
  );

  if (existing.rows.length > 0) {
    const result = await query(
      `UPDATE modules
       SET description = $2,
           order_index = $3,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING *`,
      [existing.rows[0].id, description, orderIndex]
    );
    return result.rows[0];
  }

  const result = await query(
    `INSERT INTO modules (course_id, title, description, order_index, created_at, updated_at)
     VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
     RETURNING *`,
    [courseId, title, description, orderIndex]
  );
  return result.rows[0];
}

async function upsertLesson({ moduleId, title, description, contentType, contentBody, contentUrl, orderIndex, durationMinutes }) {
  const existing = await query(
    'SELECT id FROM lessons WHERE module_id = $1 AND title = $2 LIMIT 1',
    [moduleId, title]
  );

  if (existing.rows.length > 0) {
    const result = await query(
      `UPDATE lessons
       SET description = $2,
           content_type = $3,
           content_body = $4,
           content_url = $5,
           order_index = $6,
           duration_minutes = $7,
           is_published = true,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING *`,
      [existing.rows[0].id, description, contentType, contentBody, contentUrl || null, orderIndex, durationMinutes]
    );
    return result.rows[0];
  }

  const result = await query(
    `INSERT INTO lessons (module_id, title, description, content_type, content_body, content_url, order_index, duration_minutes, is_published, created_at, updated_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
     RETURNING *`,
    [moduleId, title, description, contentType, contentBody, contentUrl || null, orderIndex, durationMinutes]
  );
  return result.rows[0];
}

async function upsertQuiz({ courseId, moduleId, title, description, passingScore, timeLimitMinutes, createdBy }) {
  const existing = await query('SELECT id FROM quizzes WHERE course_id = $1 AND title = $2 LIMIT 1', [courseId, title]);

  if (existing.rows.length > 0) {
    const result = await query(
      `UPDATE quizzes
       SET module_id = $2,
           description = $3,
           passing_score = $4,
           time_limit_minutes = $5,
           is_published = true,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING *`,
      [existing.rows[0].id, moduleId, description, passingScore, timeLimitMinutes]
    );
    return result.rows[0];
  }

  const result = await query(
    `INSERT INTO quizzes (course_id, module_id, title, description, passing_score, time_limit_minutes, is_published, created_by, created_at, updated_at)
     VALUES ($1, $2, $3, $4, $5, $6, true, $7, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
     RETURNING *`,
    [courseId, moduleId, title, description, passingScore, timeLimitMinutes, createdBy]
  );
  return result.rows[0];
}

async function upsertQuizQuestion({ quizId, questionText, explanation, points, orderIndex, answers }) {
  const existing = await query(
    'SELECT id FROM quiz_questions WHERE quiz_id = $1 AND question_text = $2 LIMIT 1',
    [quizId, questionText]
  );

  let questionId;
  if (existing.rows.length > 0) {
    questionId = existing.rows[0].id;
    await query(
      `UPDATE quiz_questions
       SET question_type = 'multiple_choice',
           explanation = $2,
           points = $3,
           order_index = $4,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1`,
      [questionId, explanation, points, orderIndex]
    );
  } else {
    const result = await query(
      `INSERT INTO quiz_questions (quiz_id, question_text, question_type, explanation, points, order_index, created_at, updated_at)
       VALUES ($1, $2, 'multiple_choice', $3, $4, $5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
       RETURNING id`,
      [quizId, questionText, explanation, points, orderIndex]
    );
    questionId = result.rows[0].id;
  }

  for (const [index, answer] of answers.entries()) {
    const answerResult = await query(
      'SELECT id FROM quiz_answers WHERE question_id = $1 AND answer_text = $2 LIMIT 1',
      [questionId, answer.answerText]
    );
    if (answerResult.rows.length > 0) {
      await query(
        'UPDATE quiz_answers SET is_correct = $2, order_index = $3 WHERE id = $1',
        [answerResult.rows[0].id, answer.isCorrect, index + 1]
      );
    } else {
      await query(
        `INSERT INTO quiz_answers (question_id, answer_text, is_correct, order_index)
         VALUES ($1, $2, $3, $4)`,
        [questionId, answer.answerText, answer.isCorrect, index + 1]
      );
    }
  }
}

async function upsertAssignment({ courseId, moduleId, title, description, instructions, totalPoints, createdBy, dueDate }) {
  const existing = await query(
    'SELECT id FROM assignments WHERE course_id = $1 AND title = $2 LIMIT 1',
    [courseId, title]
  );

  if (existing.rows.length > 0) {
    const result = await query(
      `UPDATE assignments
       SET module_id = $2,
           description = $3,
           instructions = $4,
           total_points = $5,
           due_date = $6,
           is_published = true,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING *`,
      [existing.rows[0].id, moduleId, description, instructions, totalPoints, dueDate]
    );
    return result.rows[0];
  }

  const result = await query(
    `INSERT INTO assignments (course_id, module_id, title, description, instructions, total_points, due_date, created_by, is_published, created_at, updated_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
     RETURNING *`,
    [courseId, moduleId, title, description, instructions, totalPoints, dueDate, createdBy]
  );
  return result.rows[0];
}

async function ensureEnrollment(userId, courseId, progressPercentage, completionStatus) {
  const existing = await query(
    'SELECT id FROM enrollments WHERE user_id = $1 AND course_id = $2 LIMIT 1',
    [userId, courseId]
  );

  if (existing.rows.length > 0) {
    await query(
      `UPDATE enrollments
       SET progress_percentage = $2,
           completion_status = $3
       WHERE id = $1`,
      [existing.rows[0].id, progressPercentage, completionStatus]
    );
    return;
  }

  await query(
    `INSERT INTO enrollments (user_id, course_id, enrollment_date, completion_status, progress_percentage)
     VALUES ($1, $2, CURRENT_TIMESTAMP, $3, $4)`,
    [userId, courseId, completionStatus, progressPercentage]
  );
}

async function upsertAnalytics(userId, values) {
  await query(
    `INSERT INTO user_analytics (
       user_id,
       total_lessons_completed,
       total_courses_completed,
       total_quiz_attempts,
       average_quiz_score,
       total_engagement_minutes,
       total_points_earned,
       membership_status,
       last_active_at,
       learning_style,
       preferred_category,
       estimated_difficulty_level,
       churn_risk_score,
       engagement_level,
       updated_at
     )
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CURRENT_TIMESTAMP, $9, $10, $11, $12, $13, CURRENT_TIMESTAMP)
     ON CONFLICT (user_id) DO UPDATE SET
       total_lessons_completed = EXCLUDED.total_lessons_completed,
       total_courses_completed = EXCLUDED.total_courses_completed,
       total_quiz_attempts = EXCLUDED.total_quiz_attempts,
       average_quiz_score = EXCLUDED.average_quiz_score,
       total_engagement_minutes = EXCLUDED.total_engagement_minutes,
       total_points_earned = EXCLUDED.total_points_earned,
       membership_status = EXCLUDED.membership_status,
       last_active_at = EXCLUDED.last_active_at,
       learning_style = EXCLUDED.learning_style,
       preferred_category = EXCLUDED.preferred_category,
       estimated_difficulty_level = EXCLUDED.estimated_difficulty_level,
       churn_risk_score = EXCLUDED.churn_risk_score,
       engagement_level = EXCLUDED.engagement_level,
       updated_at = CURRENT_TIMESTAMP`,
    [
      userId,
      values.totalLessonsCompleted,
      values.totalCoursesCompleted,
      values.totalQuizAttempts,
      values.averageQuizScore,
      values.totalEngagementMinutes,
      values.totalPointsEarned,
      values.membershipStatus,
      values.learningStyle,
      values.preferredCategory,
      values.estimatedDifficultyLevel,
      values.churnRiskScore,
      values.engagementLevel,
    ]
  );
}

async function upsertPoints(userId, totalPoints, monthPoints, weekPoints) {
  await query(
    `INSERT INTO user_points (user_id, total_points, month_points, week_points, last_updated)
     VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
     ON CONFLICT (user_id) DO UPDATE SET
       total_points = EXCLUDED.total_points,
       month_points = EXCLUDED.month_points,
       week_points = EXCLUDED.week_points,
       last_updated = CURRENT_TIMESTAMP`,
    [userId, totalPoints, monthPoints, weekPoints]
  );
}

async function upsertSupportTicket({ userId, category, subject, description, status, priority }) {
  const existing = await query(
    'SELECT id FROM support_tickets WHERE user_id = $1 AND subject = $2 LIMIT 1',
    [userId, subject]
  );

  if (existing.rows.length > 0) {
    const result = await query(
      `UPDATE support_tickets
       SET category = $2,
           description = $3,
           status = $4,
           priority = $5,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING *`,
      [existing.rows[0].id, category, description, status, priority]
    );
    return result.rows[0];
  }

  const result = await query(
    `INSERT INTO support_tickets (user_id, category, subject, description, status, priority, created_at, updated_at)
     VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
     RETURNING *`,
    [userId, category, subject, description, status, priority]
  );
  return result.rows[0];
}

async function ensureSupportMessage(ticketId, senderId, message) {
  const existing = await query(
    'SELECT id FROM support_messages WHERE ticket_id = $1 AND sender_id = $2 AND message = $3 LIMIT 1',
    [ticketId, senderId, message]
  );
  if (existing.rows.length === 0) {
    await query(
      `INSERT INTO support_messages (ticket_id, sender_id, message, created_at)
       VALUES ($1, $2, $3, CURRENT_TIMESTAMP)`,
      [ticketId, senderId, message]
    );
  }
}

async function upsertNotification({ userId, title, message, type, actionUrl, metadata }) {
  const existing = await query(
    'SELECT id FROM notifications WHERE user_id = $1 AND title = $2 LIMIT 1',
    [userId, title]
  );
  if (existing.rows.length > 0) {
    await query(
      `UPDATE notifications
       SET message = $2,
           type = $3,
           action_url = $4,
           metadata = $5::jsonb
       WHERE id = $1`,
      [existing.rows[0].id, message, type, actionUrl || null, JSON.stringify(metadata || {})]
    );
    return;
  }

  await query(
    `INSERT INTO notifications (user_id, title, message, type, action_url, metadata)
     VALUES ($1, $2, $3, $4, $5, $6::jsonb)`,
    [userId, title, message, type, actionUrl || null, JSON.stringify(metadata || {})]
  );
}

async function ensureParentChildLink(parentUserId, childUserId, relationship, createdBy) {
  const existing = await query(
    'SELECT id FROM parent_child_links WHERE parent_user_id = $1 AND child_user_id = $2 LIMIT 1',
    [parentUserId, childUserId]
  );

  if (existing.rows.length > 0) {
    await query(
      `UPDATE parent_child_links
       SET relationship = $2,
           is_active = true,
           created_by = $3,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1`,
      [existing.rows[0].id, relationship, createdBy]
    );
    return;
  }

  await query(
    `INSERT INTO parent_child_links (parent_user_id, child_user_id, relationship, is_active, created_by, created_at, updated_at)
     VALUES ($1, $2, $3, true, $4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
    [parentUserId, childUserId, relationship, createdBy]
  );
}

async function ensureMentorMenteeLink(mentorUserId, menteeUserId, goals, createdBy) {
  const existing = await query(
    'SELECT id FROM mentor_mentee_links WHERE mentor_user_id = $1 AND mentee_user_id = $2 LIMIT 1',
    [mentorUserId, menteeUserId]
  );

  if (existing.rows.length > 0) {
    await query(
      `UPDATE mentor_mentee_links
       SET goals = $2,
           status = 'active',
           is_active = true,
           created_by = $3,
           next_session_at = CURRENT_TIMESTAMP + INTERVAL '7 days',
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1`,
      [existing.rows[0].id, goals, createdBy]
    );
    return;
  }

  await query(
    `INSERT INTO mentor_mentee_links (mentor_user_id, mentee_user_id, status, goals, next_session_at, is_active, created_by, created_at, updated_at)
     VALUES ($1, $2, 'active', $3, CURRENT_TIMESTAMP + INTERVAL '7 days', true, $4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
    [mentorUserId, menteeUserId, goals, createdBy]
  );
}

async function upsertRoleResource({ namespace, ownerUserId, title, description, metadata }) {
  const existing = await query(
    'SELECT id FROM role_resources WHERE namespace = $1 AND owner_user_id = $2 AND title = $3 LIMIT 1',
    [namespace, ownerUserId, title]
  );

  if (existing.rows.length > 0) {
    await query(
      `UPDATE role_resources
       SET description = $2,
           status = 'active',
           metadata = $3::jsonb,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1`,
      [existing.rows[0].id, description, JSON.stringify(metadata || {})]
    );
    return;
  }

  await query(
    `INSERT INTO role_resources (namespace, owner_user_id, title, description, status, metadata, created_at, updated_at)
     VALUES ($1, $2, $3, $4, 'active', $5::jsonb, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
    [namespace, ownerUserId, title, description, JSON.stringify(metadata || {})]
  );
}

async function upsertPartner(name, websiteUrl) {
  const existing = await query(
    'SELECT id FROM platform_partners WHERE LOWER(name) = LOWER($1) LIMIT 1',
    [name]
  );
  if (existing.rows.length > 0) {
    await query(
      `UPDATE platform_partners
       SET website_url = $2,
           is_active = true,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1`,
      [existing.rows[0].id, websiteUrl || null]
    );
    return;
  }

  await query(
    `INSERT INTO platform_partners (name, website_url, is_active, created_at, updated_at)
     VALUES ($1, $2, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
    [name, websiteUrl || null]
  );
}

async function upsertTestimonial(quote, authorName, authorRole) {
  const existing = await query('SELECT id FROM testimonials WHERE quote = $1 LIMIT 1', [quote]);
  if (existing.rows.length > 0) {
    await query(
      `UPDATE testimonials
       SET author_name = $2,
           author_role = $3,
           is_active = true,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1`,
      [existing.rows[0].id, authorName, authorRole || null]
    );
    return;
  }

  await query(
    `INSERT INTO testimonials (quote, author_name, author_role, is_active, created_at, updated_at)
     VALUES ($1, $2, $3, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
    [quote, authorName, authorRole || null]
  );
}

async function main() {
  await initializeDatabase();

  const users = {
    admin: await upsertUser({ email: 'admin@impactknowledge.app', fullName: 'ImpactKnowledge Admin', role: 'admin', bio: 'Owns platform quality, launches, and operations.', location: 'London, UK' }),
    instructor: await upsertUser({ email: 'instructor@impactknowledge.app', fullName: 'Rachel Morgan', role: 'instructor', bio: 'Leads practical digital-skills and growth programs.', location: 'Manchester, UK' }),
    facilitator: await upsertUser({ email: 'facilitator@impactknowledge.app', fullName: 'Daniel Brooks', role: 'facilitator', bio: 'Supports cohort delivery and learner engagement.', location: 'Birmingham, UK' }),
    parent: await upsertUser({ email: 'parent@impactknowledge.app', fullName: 'Angela Carter', role: 'parent', bio: 'Tracks progress across her child’s learning plan.', location: 'Leeds, UK' }),
    mentor: await upsertUser({ email: 'mentor@impactknowledge.app', fullName: 'Marcus Reed', role: 'mentor', bio: 'Mentors students on portfolio, confidence, and career direction.', location: 'New York, US' }),
    schoolAdmin: await upsertUser({ email: 'schooladmin@impactknowledge.app', fullName: 'Olivia Bennett', role: 'school_admin', bio: 'Monitors school-wide adoption and intervention needs.', location: 'Chicago, US' }),
    circleMember: await upsertUser({ email: 'circle@impactknowledge.app', fullName: 'Chloe Sanders', role: 'circle_member', bio: 'Community member building collaboration and thought leadership.', location: 'Austin, US' }),
    uniMember: await upsertUser({ email: 'university@impactknowledge.app', fullName: 'Ibrahim Yusuf', role: 'uni_member', bio: 'University member focused on venture readiness and impact.', location: 'Boston, US' }),
    learnerOne: await upsertUser({ email: 'student.one@impactknowledge.app', fullName: 'Mia Thompson', role: 'student', bio: 'Learner focused on digital fluency and career mobility.', location: 'London, UK' }),
    learnerTwo: await upsertUser({ email: 'student.two@impactknowledge.app', fullName: 'Noah Johnson', role: 'student', bio: 'Learner working on entrepreneurship and community leadership.', location: 'Atlanta, US' }),
  };

  const tiers = {
    free: await upsertMembershipTier({ name: 'Free', description: 'Explore introductory learning experiences and community events.', monthlyPrice: 0, annualPrice: 0, benefits: ['Starter learning path', 'Community announcements', 'Basic progress tracking'] }),
    starter: await upsertMembershipTier({ name: 'Starter', description: 'For motivated learners building consistent weekly momentum.', monthlyPrice: 19, annualPrice: 190, benefits: ['All Free features', 'Full access to starter courses', 'Assignments and quizzes', 'Email support'] }),
    pro: await upsertMembershipTier({ name: 'Pro', description: 'For learners and professionals who want coaching signals and advanced content.', monthlyPrice: 49, annualPrice: 490, benefits: ['All Starter features', 'Advanced learning paths', 'Role-based dashboards', 'Priority support', 'Performance insights'] }),
    premium: await upsertMembershipTier({ name: 'Premium', description: 'For institutions and high-touch growth journeys.', monthlyPrice: 99, annualPrice: 990, benefits: ['All Pro features', 'Mentor access', 'Institution oversight', 'Operational analytics', 'Priority launch support'] }),
  };

  await upsertAchievement({ name: 'First Step', description: 'Complete your first lesson and begin your ImpactKnowledge journey.', pointsReward: 50, criteria: 'lesson_completion', category: 'learning', unlockCondition: 'complete_1_lesson' });
  await upsertAchievement({ name: 'Momentum Builder', description: 'Maintain a strong learning streak for seven consecutive days.', pointsReward: 120, criteria: 'streak', category: 'engagement', unlockCondition: '7_day_streak' });
  await upsertAchievement({ name: 'Quiz Finisher', description: 'Pass your first assessment with confidence.', pointsReward: 80, criteria: 'quiz_pass', category: 'assessment', unlockCondition: 'pass_1_quiz' });
  await upsertAchievement({ name: 'Course Closer', description: 'Complete an end-to-end course experience.', pointsReward: 200, criteria: 'course_completion', category: 'learning', unlockCondition: 'complete_1_course' });

  const courseOne = await upsertCourse({ title: 'Digital Skills for Community Impact', description: 'Build practical communication, research, and collaboration skills for real-world impact projects.', category: 'Digital Literacy', instructorId: users.instructor.id, price: 79, level: 'Beginner', durationHours: 12, thumbnailUrl: 'https://images.unsplash.com/photo-1516321497487-e288fb19713f' });
  const courseTwo = await upsertCourse({ title: 'Career Readiness and Leadership', description: 'A structured path for confidence, leadership communication, and employability readiness.', category: 'Career Growth', instructorId: users.instructor.id, price: 99, level: 'Intermediate', durationHours: 16, thumbnailUrl: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f' });
  const courseThree = await upsertCourse({ title: 'Foundations of AI and Data Thinking', description: 'Understand core AI concepts, responsible data use, and practical decision-making with technology.', category: 'AI & Data', instructorId: users.instructor.id, price: 129, level: 'Intermediate', durationHours: 20, thumbnailUrl: 'https://images.unsplash.com/photo-1485827404703-89b55fcc595e' });

  const moduleOneA = await upsertModule({ courseId: courseOne.id, title: 'Digital Confidence', description: 'Build the habits and tools needed for online learning success.', orderIndex: 1 });
  const moduleOneB = await upsertModule({ courseId: courseOne.id, title: 'Practical Collaboration', description: 'Apply digital collaboration to group work and community impact.', orderIndex: 2 });
  const moduleTwoA = await upsertModule({ courseId: courseTwo.id, title: 'Leadership Presence', description: 'Develop confidence, communication, and career clarity.', orderIndex: 1 });
  const moduleThreeA = await upsertModule({ courseId: courseThree.id, title: 'AI Fundamentals', description: 'Learn the language and logic behind modern AI systems.', orderIndex: 1 });

  await upsertLesson({ moduleId: moduleOneA.id, title: 'Getting Comfortable with Learning Tools', description: 'Set up your digital workspace and build your weekly routine.', contentType: 'text', contentBody: 'Learners explore how to organize study time, navigate the app, and use digital tools confidently.', contentUrl: null, orderIndex: 1, durationMinutes: 18 });
  await upsertLesson({ moduleId: moduleOneA.id, title: 'Finding Reliable Information Online', description: 'Evaluate sources and recognize trustworthy evidence.', contentType: 'video', contentBody: 'This lesson walks through basic source evaluation and fact-checking patterns.', contentUrl: 'https://www.example.com/video/reliable-information', orderIndex: 2, durationMinutes: 22 });
  await upsertLesson({ moduleId: moduleOneB.id, title: 'Working in Distributed Teams', description: 'Practice communication rules for collaborative delivery.', contentType: 'text', contentBody: 'Team agreements, communication cadence, and role clarity are introduced through practical scenarios.', contentUrl: null, orderIndex: 1, durationMinutes: 20 });
  await upsertLesson({ moduleId: moduleTwoA.id, title: 'Leading with Clarity', description: 'Use concise communication to influence outcomes.', contentType: 'video', contentBody: 'A leadership lesson on structuring communication for meetings, updates, and feedback.', contentUrl: 'https://www.example.com/video/leading-with-clarity', orderIndex: 1, durationMinutes: 25 });
  await upsertLesson({ moduleId: moduleThreeA.id, title: 'What AI Can and Cannot Do', description: 'Separate hype from practical capability.', contentType: 'text', contentBody: 'Learners examine what current AI systems are good at, where they fail, and how to use them responsibly.', contentUrl: null, orderIndex: 1, durationMinutes: 24 });

  const quizOne = await upsertQuiz({ courseId: courseOne.id, moduleId: moduleOneA.id, title: 'Digital Confidence Checkpoint', description: 'Measure understanding of the digital confidence foundations.', passingScore: 70, timeLimitMinutes: 15, createdBy: users.instructor.id });
  const quizTwo = await upsertQuiz({ courseId: courseThree.id, moduleId: moduleThreeA.id, title: 'AI Fundamentals Checkpoint', description: 'Confirm understanding of AI fundamentals and responsible use.', passingScore: 70, timeLimitMinutes: 20, createdBy: users.instructor.id });

  await upsertQuizQuestion({ quizId: quizOne.id, questionText: 'Which habit most improves consistency in an online learning program?', explanation: 'Consistency comes from a repeatable weekly rhythm, not motivation alone.', points: 1, orderIndex: 1, answers: [
    { answerText: 'Waiting until you feel inspired', isCorrect: false },
    { answerText: 'Setting a fixed learning routine', isCorrect: true },
    { answerText: 'Studying only on assessment days', isCorrect: false },
    { answerText: 'Skipping reflection time', isCorrect: false },
  ] });
  await upsertQuizQuestion({ quizId: quizTwo.id, questionText: 'What is the most accurate definition of responsible AI use?', explanation: 'Responsible AI combines effectiveness, transparency, and human judgment.', points: 1, orderIndex: 1, answers: [
    { answerText: 'Using AI without checking outputs', isCorrect: false },
    { answerText: 'Combining AI assistance with human review and accountability', isCorrect: true },
    { answerText: 'Treating AI answers as automatically true', isCorrect: false },
    { answerText: 'Avoiding AI in every situation', isCorrect: false },
  ] });

  await upsertAssignment({ courseId: courseOne.id, moduleId: moduleOneB.id, title: 'Community Impact Collaboration Plan', description: 'Create a simple collaboration plan for a community learning challenge.', instructions: 'Submit a one-page plan that covers goals, roles, communication cadence, and delivery risks.', totalPoints: 100, createdBy: users.instructor.id, dueDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000) });
  await upsertAssignment({ courseId: courseTwo.id, moduleId: moduleTwoA.id, title: 'Career Pitch Reflection', description: 'Record and reflect on a 90-second professional pitch.', instructions: 'Upload a reflection summary describing your target audience, message clarity, and next iteration.', totalPoints: 100, createdBy: users.instructor.id, dueDate: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000) });

  await ensureEnrollment(users.learnerOne.id, courseOne.id, 65, 'in_progress');
  await ensureEnrollment(users.learnerOne.id, courseTwo.id, 30, 'in_progress');
  await ensureEnrollment(users.learnerTwo.id, courseOne.id, 92, 'completed');
  await ensureEnrollment(users.learnerTwo.id, courseThree.id, 48, 'in_progress');

  await upsertAnalytics(users.learnerOne.id, { totalLessonsCompleted: 8, totalCoursesCompleted: 0, totalQuizAttempts: 3, averageQuizScore: 78, totalEngagementMinutes: 320, totalPointsEarned: 240, membershipStatus: tiers.starter.name, learningStyle: 'guided', preferredCategory: 'Digital Literacy', estimatedDifficultyLevel: 'beginner', churnRiskScore: 0.25, engagementLevel: 'high' });
  await upsertAnalytics(users.learnerTwo.id, { totalLessonsCompleted: 15, totalCoursesCompleted: 1, totalQuizAttempts: 5, averageQuizScore: 88, totalEngagementMinutes: 540, totalPointsEarned: 520, membershipStatus: tiers.pro.name, learningStyle: 'exploratory', preferredCategory: 'AI & Data', estimatedDifficultyLevel: 'intermediate', churnRiskScore: 0.1, engagementLevel: 'high' });
  await upsertPoints(users.learnerOne.id, 240, 180, 60);
  await upsertPoints(users.learnerTwo.id, 520, 240, 85);

  await ensureParentChildLink(users.parent.id, users.learnerOne.id, 'guardian', users.admin.id);
  await ensureMentorMenteeLink(users.mentor.id, users.learnerTwo.id, 'Improve leadership confidence and ship one portfolio-ready project this quarter.', users.admin.id);

  await upsertRoleResource({ namespace: 'mentor', ownerUserId: users.mentor.id, title: 'Weekly Mentee Growth Plan', description: 'Action plan covering skills, confidence, and accountability checkpoints.', metadata: { activeMentees: 1, nextReviewWindow: '7d' } });
  await upsertRoleResource({ namespace: 'circle_member', ownerUserId: users.circleMember.id, title: 'Founder Roundtable Brief', description: 'Discussion brief for the next community founder roundtable.', metadata: { roundtableDate: 'next-month', focus: 'fundraising-readiness' } });
  await upsertRoleResource({ namespace: 'uni_member', ownerUserId: users.uniMember.id, title: 'Campus Venture Milestones', description: 'Operational milestone tracker for student founders.', metadata: { opportunitiesOpen: 4, activeMentors: 2 } });

  const ticket = await upsertSupportTicket({ userId: users.parent.id, category: 'billing', subject: 'Need invoice for school reimbursement', description: 'Please share the receipt format accepted for reimbursement and whether membership invoices can be exported monthly.', status: 'open', priority: 'normal' });
  await ensureSupportMessage(ticket.id, users.parent.id, 'I need a VAT-style receipt and a clear payment breakdown for reimbursement.');
  await ensureSupportMessage(ticket.id, users.admin.id, 'We can export a receipt summary after payment confirmation. We are also finalizing automated receipt delivery.');

  await upsertNotification({ userId: users.learnerOne.id, title: 'Assignment due soon', message: 'Your Community Impact Collaboration Plan is due in less than two weeks.', type: 'assignment', actionUrl: '/assignments', metadata: { courseId: courseOne.id } });
  await upsertNotification({ userId: users.parent.id, title: 'New learner progress snapshot', message: 'Mia has completed 65% of Digital Skills for Community Impact.', type: 'progress', actionUrl: '/dashboard', metadata: { childUserId: users.learnerOne.id } });
  await upsertNotification({ userId: users.admin.id, title: 'Open support ticket requires review', message: 'A billing-related support ticket is waiting for operational follow-up.', type: 'support', actionUrl: '/admin-support', metadata: { ticketId: ticket.id } });

  await upsertPartner('ImpactHub London', 'https://impacthub.net');
  await upsertPartner('Digital Promise', 'https://digitalpromise.org');
  await upsertTestimonial('ImpactKnowledge gave our learners a product experience that felt structured, credible, and motivating from week one.', 'Sarah K.', 'Program Director');
  await upsertTestimonial('The dashboards made it easier to understand who needed support before they disengaged.', 'James T.', 'School Operations Lead');

  console.log('Seed complete.');
  console.log(`Seed user password: ${SEED_PASSWORD}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Seed failed:', error);
    process.exit(1);
  });
