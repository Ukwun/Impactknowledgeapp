const express = require('express');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

const LEARNING_LAYERS = [
  {
    key: 'learn',
    purpose: 'Introduce concepts clearly and in short structured units.',
    typicalComponents: [
      'Video lessons',
      'Story cards',
      'Explainers',
      'Readings',
      'Guided notes',
    ],
  },
  {
    key: 'apply',
    purpose: 'Turn ideas into action through tasks and templates.',
    typicalComponents: [
      'Worksheets',
      'Journals',
      'Mini assignments',
      'Business tasks',
      'Reflection prompts',
    ],
  },
  {
    key: 'engage',
    purpose: 'Deepen learning through human interaction and guided practice.',
    typicalComponents: [
      'Facilitator-led classes',
      'Q&A sessions',
      'Breakout sessions',
      'Simulations',
      'Clinics',
    ],
  },
  {
    key: 'show_progress',
    purpose: 'Make growth visible and motivating.',
    typicalComponents: [
      'Badges',
      'Attendance',
      'Scores',
      'Certificates',
      'Project showcases',
      'Learner portfolio',
    ],
  },
];

const BLUEPRINT_OBJECTIVES = [
  'Deliver subscription-based classroom experiences with predictable cadence and outcomes.',
  'Ensure every learner path uses Learn, Apply, Engage, and Show Progress layers.',
  'Operationalize facilitator-led live learning with evidence-backed progress tracking.',
  'Support role-specific learning pathways across ImpactSchool and ImpactUni programmes.',
];

const DELIVERY_MODEL = {
  cadence: 'Weekly blended delivery',
  format: [
    'Asynchronous guided content',
    'Facilitator-led live sessions',
    'Hands-on assignments and projects',
    'Progress checkpoints and recognitions',
  ],
  subscriptionTiers: [
    'Starter',
    'Pro',
    'Premium',
  ],
};

const ONLINE_CLASSROOM_STRUCTURE = {
  classroomUnits: [
    'Programme',
    'Level',
    'Cycle/Term',
    'Module',
    'Lesson',
    'Activity',
    'Live Session',
    'Assessment',
    'Project/Showcase',
    'Badge/Certificate',
  ],
  facilitation: {
    liveSupport: true,
    officeHours: true,
    breakoutLearning: true,
  },
};

const CURRICULUM_ARCHITECTURE = {
  principles: [
    'Competency-driven sequencing',
    'Short modular units',
    'Applied task-based learning',
    'Evidence and mastery checkpoints',
  ],
};

const LIVE_FACILITATOR_FRAMEWORK = {
  sessionTypes: [
    'Core class',
    'Workshop',
    'Q&A clinic',
    'Simulation',
    'Project review',
  ],
  expectedOutcomes: [
    'Higher completion rates',
    'Stronger learner engagement',
    'Faster concept mastery',
    'Visible learner progression',
  ],
};

function isClassroomManager(role) {
  return ['admin', 'school_admin', 'instructor', 'facilitator'].includes(role);
}

async function ensureManagerAccess(req, res, next) {
  try {
    if (!req.user || !req.user.id) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    const result = await query('SELECT role FROM users WHERE id = $1', [req.user.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    if (!isClassroomManager(result.rows[0].role)) {
      return res.status(403).json({ success: false, error: 'Forbidden: classroom manager access required' });
    }

    next();
  } catch (err) {
    console.error('Classroom manager access check failed:', err);
    return res.status(500).json({ success: false, error: 'Access check failed' });
  }
}

async function getFallbackHierarchyFromCourses() {
  const coursesResult = await query(
    `SELECT id, title, description, level, category, is_published
     FROM courses
     WHERE is_published = true
     ORDER BY id ASC`
  );

  const modulesResult = await query(
    `SELECT id, course_id, title, description, order_index
     FROM modules
     ORDER BY course_id ASC, order_index ASC NULLS LAST, id ASC`
  );

  const lessonsResult = await query(
    `SELECT id, module_id, title, description, content_type, content_url, learning_layer, order_index, duration_minutes
     FROM lessons
     ORDER BY module_id ASC, order_index ASC NULLS LAST, id ASC`
  );

  const lessonsByModule = new Map();
  for (const lesson of lessonsResult.rows) {
    const list = lessonsByModule.get(lesson.module_id) || [];
    list.push({
      ...lesson,
      layer: lesson.learning_layer || 'learn',
      activities: [],
    });
    lessonsByModule.set(lesson.module_id, list);
  }

  const modulesByCourse = new Map();
  for (const module of modulesResult.rows) {
    const list = modulesByCourse.get(module.course_id) || [];
    list.push({
      ...module,
      lessons: lessonsByModule.get(module.id) || [],
    });
    modulesByCourse.set(module.course_id, list);
  }

  const levelGroups = new Map();
  for (const course of coursesResult.rows) {
    const levelName = course.level || 'General';
    const group = levelGroups.get(levelName) || [];
    group.push(course);
    levelGroups.set(levelName, group);
  }

  let levelCounter = 1;
  const levels = [];
  for (const [levelName, levelCourses] of levelGroups.entries()) {
    const cycleId = levelCounter;
    levels.push({
      id: levelCounter,
      programme_id: 1,
      name: levelName,
      level_order: levelCounter,
      description: `Auto-generated from published courses for ${levelName}.`,
      cycles: [
        {
          id: cycleId,
          level_id: levelCounter,
          name: 'Current Cycle',
          cycle_type: 'term',
          status: 'active',
          description: 'Auto-generated default cycle.',
          modules: levelCourses.flatMap((course) => modulesByCourse.get(course.id) || []),
          liveSessions: [],
          assessments: [],
          showcases: [],
        },
      ],
    });
    levelCounter += 1;
  }

  return [
    {
      id: 1,
      code: 'impactschool',
      name: 'ImpactSchool',
      description: 'Default classroom hierarchy generated from published courses.',
      delivery_model: 'Blended subscription classroom model',
      objectives: BLUEPRINT_OBJECTIVES,
      online_classroom_structure: ONLINE_CLASSROOM_STRUCTURE,
      curriculum_architecture: CURRICULUM_ARCHITECTURE,
      live_facilitator_framework: LIVE_FACILITATOR_FRAMEWORK,
      is_active: true,
      levels,
    },
  ];
}

async function getNestedHierarchy() {
  const programmesResult = await query(
    `SELECT id, code, name, description, delivery_model, objectives, online_classroom_structure,
            curriculum_architecture, live_facilitator_framework, is_active
     FROM classroom_programmes
     WHERE is_active = true
     ORDER BY id ASC`
  );

  const levelsResult = await query(
    `SELECT id, programme_id, name, level_order, description, is_active
     FROM classroom_levels
     WHERE is_active = true
     ORDER BY programme_id ASC, level_order ASC, id ASC`
  );

  const cyclesResult = await query(
    `SELECT id, level_id, name, cycle_type, start_date, end_date, status, description
     FROM classroom_cycles
     ORDER BY level_id ASC, id ASC`
  );

  const modulesResult = await query(
    `SELECT id, course_id, cycle_id, title, description, order_index
     FROM modules
     ORDER BY cycle_id ASC NULLS LAST, order_index ASC NULLS LAST, id ASC`
  );

  const lessonsResult = await query(
    `SELECT id, module_id, title, description, content_type, content_url, learning_layer, order_index, duration_minutes
     FROM lessons
     ORDER BY module_id ASC, order_index ASC NULLS LAST, id ASC`
  );

  const activitiesResult = await query(
    `SELECT id, lesson_id, activity_type, title, instructions, resource_url, metadata, order_index, is_required
     FROM classroom_activities
     ORDER BY lesson_id ASC, order_index ASC, id ASC`
  );

  const liveSessionsResult = await query(
    `SELECT id, cycle_id, module_id, title, session_type, facilitator_id, starts_at, ends_at, join_url, capacity, status, notes
     FROM classroom_live_sessions
     ORDER BY cycle_id ASC, starts_at ASC`
  );

  const assessmentsResult = await query(
    `SELECT id, cycle_id, module_id, assessment_type, title, description, scoring_method, max_score, pass_threshold, due_at, metadata
     FROM classroom_assessments
     ORDER BY cycle_id ASC, due_at ASC NULLS LAST, id ASC`
  );

  const showcasesResult = await query(
    `SELECT id, cycle_id, title, description, submission_type, visibility
     FROM classroom_showcases
     ORDER BY cycle_id ASC, id ASC`
  );

  const badgesResult = await query(
    `SELECT id, assessment_id, showcase_id, title, badge_type, criteria, certificate_template_url, points_reward, is_active
     FROM classroom_badges
     WHERE is_active = true
     ORDER BY id ASC`
  );

  const activitiesByLesson = new Map();
  for (const row of activitiesResult.rows) {
    const list = activitiesByLesson.get(row.lesson_id) || [];
    list.push(row);
    activitiesByLesson.set(row.lesson_id, list);
  }

  const lessonsByModule = new Map();
  for (const row of lessonsResult.rows) {
    const list = lessonsByModule.get(row.module_id) || [];
    list.push({
      ...row,
      layer: row.learning_layer || 'learn',
      activities: activitiesByLesson.get(row.id) || [],
    });
    lessonsByModule.set(row.module_id, list);
  }

  const modulesByCycle = new Map();
  for (const row of modulesResult.rows) {
    const list = modulesByCycle.get(row.cycle_id) || [];
    list.push({
      ...row,
      lessons: lessonsByModule.get(row.id) || [],
    });
    modulesByCycle.set(row.cycle_id, list);
  }

  const liveByCycle = new Map();
  for (const row of liveSessionsResult.rows) {
    const list = liveByCycle.get(row.cycle_id) || [];
    list.push(row);
    liveByCycle.set(row.cycle_id, list);
  }

  const badgesByAssessment = new Map();
  const badgesByShowcase = new Map();
  for (const row of badgesResult.rows) {
    if (row.assessment_id) {
      const list = badgesByAssessment.get(row.assessment_id) || [];
      list.push(row);
      badgesByAssessment.set(row.assessment_id, list);
    }
    if (row.showcase_id) {
      const list = badgesByShowcase.get(row.showcase_id) || [];
      list.push(row);
      badgesByShowcase.set(row.showcase_id, list);
    }
  }

  const assessmentsByCycle = new Map();
  for (const row of assessmentsResult.rows) {
    const list = assessmentsByCycle.get(row.cycle_id) || [];
    list.push({
      ...row,
      badges: badgesByAssessment.get(row.id) || [],
    });
    assessmentsByCycle.set(row.cycle_id, list);
  }

  const showcasesByCycle = new Map();
  for (const row of showcasesResult.rows) {
    const list = showcasesByCycle.get(row.cycle_id) || [];
    list.push({
      ...row,
      badges: badgesByShowcase.get(row.id) || [],
    });
    showcasesByCycle.set(row.cycle_id, list);
  }

  const cyclesByLevel = new Map();
  for (const row of cyclesResult.rows) {
    const list = cyclesByLevel.get(row.level_id) || [];
    list.push({
      ...row,
      modules: modulesByCycle.get(row.id) || [],
      liveSessions: liveByCycle.get(row.id) || [],
      assessments: assessmentsByCycle.get(row.id) || [],
      showcases: showcasesByCycle.get(row.id) || [],
    });
    cyclesByLevel.set(row.level_id, list);
  }

  const levelsByProgramme = new Map();
  for (const row of levelsResult.rows) {
    const list = levelsByProgramme.get(row.programme_id) || [];
    list.push({
      ...row,
      cycles: cyclesByLevel.get(row.id) || [],
    });
    levelsByProgramme.set(row.programme_id, list);
  }

  return programmesResult.rows.map((programme) => ({
    ...programme,
    levels: levelsByProgramme.get(programme.id) || [],
  }));
}

router.get('/blueprint', async (req, res) => {
  try {
    res.json({
      success: true,
      data: {
        objectives: BLUEPRINT_OBJECTIVES,
        deliveryModel: DELIVERY_MODEL,
        onlineClassroomStructure: ONLINE_CLASSROOM_STRUCTURE,
        curriculumArchitecture: CURRICULUM_ARCHITECTURE,
        liveFacilitatorFramework: LIVE_FACILITATOR_FRAMEWORK,
        learningArchitecture: LEARNING_LAYERS,
      },
    });
  } catch (err) {
    console.error('Blueprint fetch error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch classroom blueprint' });
  }
});

router.get('/hierarchy', async (req, res) => {
  try {
    let hierarchy = await getNestedHierarchy();
    if (hierarchy.length === 0) {
      hierarchy = await getFallbackHierarchyFromCourses();
    }
    res.json({ success: true, data: hierarchy });
  } catch (err) {
    console.error('Hierarchy fetch error:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch classroom hierarchy' });
  }
});

router.post('/programmes', verifyToken, ensureManagerAccess, async (req, res) => {
  try {
    const {
      code,
      name,
      description,
      deliveryModel,
      objectives,
      onlineClassroomStructure,
      curriculumArchitecture,
      liveFacilitatorFramework,
    } = req.body;

    if (!code || !name) {
      return res.status(400).json({ success: false, error: 'code and name are required' });
    }

    const result = await query(
      `INSERT INTO classroom_programmes
        (code, name, description, delivery_model, objectives, online_classroom_structure,
         curriculum_architecture, live_facilitator_framework, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       ON CONFLICT (code) DO UPDATE SET
         name = EXCLUDED.name,
         description = EXCLUDED.description,
         delivery_model = EXCLUDED.delivery_model,
         objectives = EXCLUDED.objectives,
         online_classroom_structure = EXCLUDED.online_classroom_structure,
         curriculum_architecture = EXCLUDED.curriculum_architecture,
         live_facilitator_framework = EXCLUDED.live_facilitator_framework,
         updated_at = CURRENT_TIMESTAMP
       RETURNING *`,
      [
        String(code).trim().toLowerCase(),
        name,
        description || null,
        deliveryModel || null,
        objectives || null,
        onlineClassroomStructure || null,
        curriculumArchitecture || null,
        liveFacilitatorFramework || null,
        req.user.id,
      ]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('Create programme error:', err);
    res.status(500).json({ success: false, error: 'Failed to save classroom programme' });
  }
});

router.post('/programmes/:programmeId/levels', verifyToken, ensureManagerAccess, async (req, res) => {
  try {
    const { programmeId } = req.params;
    const { name, levelOrder = 1, description } = req.body;

    if (!name) {
      return res.status(400).json({ success: false, error: 'name is required' });
    }

    const result = await query(
      `INSERT INTO classroom_levels (programme_id, name, level_order, description)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (programme_id, name) DO UPDATE SET
         level_order = EXCLUDED.level_order,
         description = EXCLUDED.description,
         updated_at = CURRENT_TIMESTAMP
       RETURNING *`,
      [programmeId, name, levelOrder, description || null]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('Create level error:', err);
    res.status(500).json({ success: false, error: 'Failed to save classroom level' });
  }
});

router.post('/levels/:levelId/cycles', verifyToken, ensureManagerAccess, async (req, res) => {
  try {
    const { levelId } = req.params;
    const { name, cycleType = 'term', startDate, endDate, status = 'planned', description } = req.body;

    if (!name) {
      return res.status(400).json({ success: false, error: 'name is required' });
    }

    const result = await query(
      `INSERT INTO classroom_cycles
        (level_id, name, cycle_type, start_date, end_date, status, description)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (level_id, name) DO UPDATE SET
         cycle_type = EXCLUDED.cycle_type,
         start_date = EXCLUDED.start_date,
         end_date = EXCLUDED.end_date,
         status = EXCLUDED.status,
         description = EXCLUDED.description,
         updated_at = CURRENT_TIMESTAMP
       RETURNING *`,
      [levelId, name, cycleType, startDate || null, endDate || null, status, description || null]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('Create cycle error:', err);
    res.status(500).json({ success: false, error: 'Failed to save classroom cycle' });
  }
});

router.post('/cycles/:cycleId/modules/:moduleId/link', verifyToken, ensureManagerAccess, async (req, res) => {
  try {
    const { cycleId, moduleId } = req.params;
    const result = await query(
      `UPDATE modules
       SET cycle_id = $1, updated_at = CURRENT_TIMESTAMP
       WHERE id = $2
       RETURNING id, cycle_id, course_id, title`,
      [cycleId, moduleId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Module not found' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('Link module error:', err);
    res.status(500).json({ success: false, error: 'Failed to link module to cycle' });
  }
});

router.post('/lessons/:lessonId/activities', verifyToken, ensureManagerAccess, async (req, res) => {
  try {
    const { lessonId } = req.params;
    const {
      activityType,
      title,
      instructions,
      resourceUrl,
      metadata,
      orderIndex = 1,
      isRequired = true,
      learningLayer,
    } = req.body;

    if (!activityType || !title) {
      return res.status(400).json({ success: false, error: 'activityType and title are required' });
    }

    const allowedLayers = ['learn', 'apply', 'engage', 'show_progress'];
    if (learningLayer && !allowedLayers.includes(learningLayer)) {
      return res.status(400).json({ success: false, error: 'Invalid learningLayer value' });
    }

    if (learningLayer) {
      await query(
        `UPDATE lessons
         SET learning_layer = $1, updated_at = CURRENT_TIMESTAMP
         WHERE id = $2`,
        [learningLayer, lessonId]
      );
    }

    const result = await query(
      `INSERT INTO classroom_activities
        (lesson_id, activity_type, title, instructions, resource_url, metadata, order_index, is_required, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [
        lessonId,
        activityType,
        title,
        instructions || null,
        resourceUrl || null,
        metadata || null,
        orderIndex,
        Boolean(isRequired),
        req.user.id,
      ]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('Create activity error:', err);
    res.status(500).json({ success: false, error: 'Failed to save classroom activity' });
  }
});

router.post('/cycles/:cycleId/live-sessions', verifyToken, ensureManagerAccess, async (req, res) => {
  try {
    const { cycleId } = req.params;
    const {
      moduleId,
      title,
      sessionType = 'facilitator_class',
      facilitatorId,
      startsAt,
      endsAt,
      joinUrl,
      capacity,
      status = 'scheduled',
      notes,
    } = req.body;

    if (!title || !startsAt) {
      return res.status(400).json({ success: false, error: 'title and startsAt are required' });
    }

    const result = await query(
      `INSERT INTO classroom_live_sessions
        (cycle_id, module_id, title, session_type, facilitator_id, starts_at, ends_at, join_url, capacity, status, notes, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
       RETURNING *`,
      [
        cycleId,
        moduleId || null,
        title,
        sessionType,
        facilitatorId || null,
        startsAt,
        endsAt || null,
        joinUrl || null,
        capacity || null,
        status,
        notes || null,
        req.user.id,
      ]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('Create live session error:', err);
    res.status(500).json({ success: false, error: 'Failed to save live session' });
  }
});

router.post('/cycles/:cycleId/assessments', verifyToken, ensureManagerAccess, async (req, res) => {
  try {
    const { cycleId } = req.params;
    const {
      moduleId,
      assessmentType,
      title,
      description,
      scoringMethod = 'points',
      maxScore,
      passThreshold,
      dueAt,
      metadata,
    } = req.body;

    if (!assessmentType || !title) {
      return res.status(400).json({ success: false, error: 'assessmentType and title are required' });
    }

    const result = await query(
      `INSERT INTO classroom_assessments
        (cycle_id, module_id, assessment_type, title, description, scoring_method, max_score, pass_threshold, due_at, metadata, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
       RETURNING *`,
      [
        cycleId,
        moduleId || null,
        assessmentType,
        title,
        description || null,
        scoringMethod,
        maxScore || null,
        passThreshold || null,
        dueAt || null,
        metadata || null,
        req.user.id,
      ]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('Create assessment error:', err);
    res.status(500).json({ success: false, error: 'Failed to save assessment' });
  }
});

router.post('/cycles/:cycleId/showcases', verifyToken, ensureManagerAccess, async (req, res) => {
  try {
    const { cycleId } = req.params;
    const { title, description, submissionType = 'project', visibility = 'private' } = req.body;

    if (!title) {
      return res.status(400).json({ success: false, error: 'title is required' });
    }

    const result = await query(
      `INSERT INTO classroom_showcases
        (cycle_id, title, description, submission_type, visibility, created_by)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [cycleId, title, description || null, submissionType, visibility, req.user.id]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('Create showcase error:', err);
    res.status(500).json({ success: false, error: 'Failed to save showcase' });
  }
});

router.post('/badges', verifyToken, ensureManagerAccess, async (req, res) => {
  try {
    const {
      assessmentId,
      showcaseId,
      title,
      badgeType,
      criteria,
      certificateTemplateUrl,
      pointsReward = 0,
    } = req.body;

    if (!title || !badgeType) {
      return res.status(400).json({ success: false, error: 'title and badgeType are required' });
    }

    if (!assessmentId && !showcaseId) {
      return res.status(400).json({ success: false, error: 'assessmentId or showcaseId is required' });
    }

    const result = await query(
      `INSERT INTO classroom_badges
        (assessment_id, showcase_id, title, badge_type, criteria, certificate_template_url, points_reward, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        assessmentId || null,
        showcaseId || null,
        title,
        badgeType,
        criteria || null,
        certificateTemplateUrl || null,
        pointsReward,
        req.user.id,
      ]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('Create badge error:', err);
    res.status(500).json({ success: false, error: 'Failed to save badge/certificate' });
  }
});

module.exports = router;
