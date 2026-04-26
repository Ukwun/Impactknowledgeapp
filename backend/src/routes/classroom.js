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
  roles: [
    {
      role: 'Lead Facilitator',
      responsibility: 'Delivers the lesson, guides discussion, and drives learning outcomes.',
      icon: 'school',
    },
    {
      role: 'Classroom Moderator',
      responsibility: 'Manages attendance, chat, questions, breakout groups, and learning flow.',
      icon: 'manage_accounts',
    },
    {
      role: 'Mentor / Guest Expert',
      responsibility: 'Provides specialist perspective, especially in Senior Secondary and ImpactUni.',
      icon: 'person_pin',
    },
    {
      role: 'Programme Coordinator',
      responsibility: 'Monitors quality, replay publishing, timetable flow, and escalations.',
      icon: 'dashboard_customize',
    },
  ],
  standardSessionSequence: [
    { step: 9, label: 'Welcome and Recap', description: 'Open session, greet learners, recap previous lesson key points.' },
    { step: 10, label: 'Key Concept Teaching', description: 'Deliver the core content for this session clearly and concisely.' },
    { step: 11, label: 'Scenario, Case, or Activity', description: 'Run a scenario, case study, or hands-on practical activity.' },
    { step: 12, label: 'Learner Participation and Questions', description: 'Open floor for questions, poll responses, and learner contributions.' },
    { step: 13, label: 'Reflection and Challenge Prompt', description: 'Guide learners through a brief reflection and issue the week challenge.' },
    { step: 14, label: 'Assignment Briefing', description: 'Clearly brief the assignment: task, deadline, submission method, and rubric.' },
    { step: 15, label: 'Attendance Confirmation and Close', description: 'Confirm attendance, share replay link timeline, and close session.' },
  ],
  toolRequirements: [
    { tool: 'Attendance Tracker', description: 'Mark present, late, or absent for each enrolled learner per session.', icon: 'how_to_reg' },
    { tool: 'Lesson Plan and Facilitator Notes Panel', description: 'In-session view of lesson objectives, script notes, and stage cues.', icon: 'notes' },
    { tool: 'Live Polls and Quizzes', description: 'Launch quick polls or knowledge checks during the session.', icon: 'poll' },
    { tool: 'Breakout Room Controls', description: 'Create, assign, and close breakout groups for collaborative tasks.', icon: 'meeting_room' },
    { tool: 'Whiteboard / Annotation Support', description: 'Annotate, draw, or highlight in real time during lesson delivery.', icon: 'draw' },
    { tool: 'Assignment Reminder and Follow-up Prompts', description: 'Trigger assignment reminder notifications to learners post-session.', icon: 'assignment_late' },
    { tool: 'Replay Publishing Workflow', description: 'Mark session as complete, upload or link replay, and publish to learner feeds.', icon: 'video_library' },
    { tool: 'Participation Score / Engagement Indicator', description: 'Track and display each learner\'s engagement level per session.', icon: 'bar_chart' },
    { tool: 'Incident / Safeguarding Note Field', description: 'Log any safeguarding concern, incident, or escalation note with timestamp.', icon: 'shield' },
  ],
};

const FOUR_LEVEL_CURRICULUM_FRAMEWORK = [
  {
    key: 'primary',
    level: 'Primary',
    ageGroup: '7-11',
    purpose: 'Build habits, values, awareness, and confidence.',
    primaryOutcome: 'Habit formation',
    signatureShift: 'From awareness to healthy daily money, behaviour, and teamwork habits.',
    coreOutcomes: [
      'Distinguish needs from wants.',
      'Understand saving before spending.',
      'Recognise simple buying and selling ideas.',
      'Show honesty, responsibility, respect, and fairness.',
      'Work with others and take simple initiative.',
    ],
    curriculumStrands: [
      'My Money Habits',
      'My Ideas and Small Business Thinking',
      'My Leadership Habits',
      'My Values and Community',
    ],
    suggestedTermStructure: [
      {
        term: 'Term 1',
        focus: 'Money and Choices',
        illustrativeTopics: [
          'Needs vs wants',
          'What money is',
          'Saving before spending',
          'Delayed gratification',
          'Planning small spending choices',
        ],
      },
      {
        term: 'Term 2',
        focus: 'Ideas, Work, and Value',
        illustrativeTopics: [
          'What a business is',
          'Goods and services',
          'Solving simple problems',
          'Customer basics',
          'Honesty in selling',
        ],
      },
      {
        term: 'Term 3',
        focus: 'Leadership and Civil Values',
        illustrativeTopics: [
          'Confidence',
          'Respect',
          'Kindness',
          'Responsibility',
          'Doing the right thing',
          'Community helper project',
        ],
      },
    ],
    signatureExperiences: [
      'Class savings challenge',
      'Mini market day',
      'Story-based ethics circle',
      'Young leader recognition',
      'Family discussion prompt',
    ],
    liveClassroomFormat: {
      frequency: 'One live class per week',
      durationMinutes: 45,
      format: 'Visual and highly interactive',
      methods: [
        'Polls',
        'Role play',
        'Guided discussion',
        'Simple practical prompts',
      ],
    },
    aliases: ['primary', 'primary school'],
  },
  {
    key: 'junior_secondary',
    level: 'Junior Secondary',
    ageGroup: '12-14',
    purpose: 'Build practical financial and enterprise habits.',
    primaryOutcome: 'Practical application',
    signatureShift: 'From understanding to budgeting, recording, and simple enterprise practice.',
    coreOutcomes: [
      'Create a simple budget.',
      'Keep basic spending and sales records.',
      'Estimate cost and understand price.',
      'Recognise the difference between revenue, cost, and profit.',
      'Practice responsibility, teamwork, and ethical decision making.',
    ],
    curriculumStrands: [
      'Personal Money Management',
      'Enterprise Practice',
      'Leadership in Action',
      'Civic Responsibility and Ethics',
    ],
    suggestedTermStructure: [
      {
        term: 'Term 1',
        focus: 'Budgeting and Financial Discipline',
        illustrativeTopics: [
          'Income and allowance',
          'Budget basics',
          'Savings goals',
          'Record keeping',
          'Digital money awareness',
          'Avoiding waste',
        ],
      },
      {
        term: 'Term 2',
        focus: 'Enterprise Basics',
        illustrativeTopics: [
          'Problem identification',
          'Creating an offer',
          'Cost estimation',
          'Pricing basics',
          'Customer service',
          'Profit awareness',
        ],
      },
      {
        term: 'Term 3',
        focus: 'Leadership and Community Action',
        illustrativeTopics: [
          'Team roles',
          'Accountability',
          'Ethical choices',
          'Conflict resolution',
          'Group micro-enterprise challenge',
        ],
      },
    ],
    signatureExperiences: [
      'Weekly budget journal',
      'Sales and cost record sheet',
      'Cost-and-price challenge',
      'School micro-business simulation',
      'Community problem-solving task',
    ],
    liveClassroomFormat: {
      frequency: 'One live class per week',
      durationMinutes: 60,
      format: 'Moderator-supported and highly practical',
      methods: [
        'Chat engagement',
        'Scenario work',
        'Guided practice reviews',
        'Monthly simulation session',
      ],
    },
    aliases: ['junior secondary', 'jss', 'junior'],
  },
  {
    key: 'senior_secondary',
    level: 'Senior Secondary',
    ageGroup: '15-18',
    primaryOutcome: 'Enterprise readiness',
    signatureShift: 'From business ideas to planning, projections, pitching, and investment awareness.',
    purpose: 'Build enterprise readiness, financial confidence, and presentation ability.',
    coreOutcomes: [
      'Write a basic business plan',
      'Prepare simple financial projections',
      'Understand startup cost, pricing, margin, and cash flow logic',
      'Participate in investment simulations',
      'Present a business or project pitch with confidence',
    ],
    curriculumStrands: [
      'Venture Design',
      'Financial Planning and Projections',
      'Leadership, Governance, and Influence',
      'Investment and Pitch Readiness',
    ],
    suggestedTermStructure: [
      {
        term: 'Term 1',
        focus: 'Business Design',
        illustrativeTopics: [
          'Opportunity identification',
          'Market problem',
          'Value proposition',
          'Customer understanding',
          'Business model basics',
          'Operations',
        ],
      },
      {
        term: 'Term 2',
        focus: 'Financial and Execution Readiness',
        illustrativeTopics: [
          'Startup cost planning',
          'Pricing',
          'Record keeping',
          'Cash flow basics',
          'Simple projections',
          'Performance tracking',
        ],
      },
      {
        term: 'Term 3',
        focus: 'Investment Simulation and Pitch',
        illustrativeTopics: [
          'Types of capital',
          'Risk and return',
          'Investment simulation',
          'Pitch deck structure',
          'Presentation skills',
          'Demo day',
        ],
      },
    ],
    signatureExperiences: [
      'Business plan builder',
      'Projection worksheet',
      'Investor simulation game',
      'Peer pitch review',
      'Quarterly virtual demo day',
    ],
    liveClassroomFormat: {
      frequency: 'One live class per week',
      durationMinutes: 75,
      format: 'Enterprise coaching class with realistic venture scenarios',
      methods: [
        'Case-based venture review',
        'Financial model walkthrough',
        'Pitch practice and rebuttal',
        'Monthly venture lab',
        'Quarterly showcase with feedback rubrics',
      ],
      support: [
        'Monthly venture lab',
        'Quarterly showcase or pitch day',
        'Structured feedback rubrics',
      ],
    },
    aliases: ['senior secondary', 'sss', 'senior'],
  },
  {
    key: 'impactuni',
    level: 'ImpactUni',
    ageGroup: '18+',
    primaryOutcome: 'Execution and capital awareness',
    signatureShift: 'From readiness to venture building, employability, and institutional engagement.',
    purpose: 'Move learners from knowledge to execution, employability, venture building, and capital awareness.',
    coreOutcomes: [
      'Manage personal finance and career capital with greater maturity',
      'Design and validate a venture, initiative, or innovation project',
      'Build execution plans and basic financial models',
      'Understand funding pathways including grants, debt, equity, and bootstrapping',
      'Lead teams, present ideas, and engage institutions or investors more credibly',
    ],
    curriculumStrands: [
      'Personal Finance and Career Capital',
      'Venture Building and Innovation',
      'Leadership, Governance, and Public Purpose',
      'Capital, Investment, and Opportunity Readiness',
    ],
    suggestedTermStructure: [
      {
        term: 'Term 1',
        focus: 'Personal and Professional Capital',
        illustrativeTopics: [
          'Budgeting',
          'Debt awareness',
          'Income planning',
          'Productivity',
          'Digital professionalism',
          'Career positioning',
        ],
      },
      {
        term: 'Term 2',
        focus: 'Venture and Project Execution',
        illustrativeTopics: [
          'Problem validation',
          'Product or service design',
          'Market research',
          'Operations',
          'Partnerships',
          'Execution roadmap',
        ],
      },
      {
        term: 'Term 3',
        focus: 'Capital and Institutional Readiness',
        illustrativeTopics: [
          'Financial modelling',
          'Fundraising basics',
          'Grants, debt, equity',
          'Governance',
          'Investor materials',
          'Formal presentations',
        ],
      },
      {
        term: 'Term 4',
        focus: 'Applied Studio',
        illustrativeTopics: [
          'Startup studio',
          'Consulting challenge',
          'Civic innovation lab',
          'Internship-linked project',
          'Capstone showcase',
        ],
      },
    ],
    signatureExperiences: [
      'Career capital dashboard',
      'Founder studio',
      'Venture sprint',
      'Investment committee simulation',
      'Civic innovation challenge',
      'Capstone pitch',
    ],
    liveClassroomFormat: {
      frequency: 'One 90-minute masterclass per week',
      durationMinutes: 90,
      format: 'Advanced venture and leadership development with institutional engagement',
      methods: [
        'Masterclass and case study analysis',
        'Peer feedback and pitch rounds',
        'Mentor and investor office hours',
        'Studio project work',
        'Civic challenge challenges',
      ],
      support: [
        'One studio or clinic every two weeks',
        'Monthly mentor office hours',
        'Quarterly showcase or challenge events',
      ],
    },
    aliases: ['impactuni', 'university', 'uni', 'campus'],
  },
];

const CONTENT_OBJECT_FIELDS = [
  { key: 'title', label: 'Title', description: 'Main content title used across CMS and classroom views.' },
  { key: 'shortDescription', label: 'Short Description', description: 'Short summary shown in cards and release notices.' },
  { key: 'programme', label: 'Programme and Level', description: 'Programme, level, and cohort context for the content.' },
  { key: 'ageBand', label: 'Age Band', description: 'Target learner age band or maturity segment.' },
  { key: 'subjectStrand', label: 'Subject Strand', description: 'Topic strand or competency area.' },
  { key: 'termCycleModule', label: 'Term / Cycle and Module Number', description: 'Delivery timing and module sequencing reference.' },
  { key: 'lessonType', label: 'Lesson Type', description: 'Lesson format such as explainer, worksheet, clinic, or simulation.' },
  { key: 'learningObjectives', label: 'Learning Objectives', description: 'Observable outcomes learners should achieve.' },
  { key: 'coreContentBody', label: 'Core Content Body', description: 'Primary instructional content body.' },
  { key: 'facilitatorNotes', label: 'Facilitator Notes', description: 'Delivery guidance, prompts, and moderation notes.' },
  { key: 'learnerInstructions', label: 'Learner Instructions', description: 'Actionable learner-facing instructions.' },
  { key: 'downloadableResources', label: 'Downloadable Resources / Worksheets', description: 'Attached templates, worksheets, or supporting resources.' },
  { key: 'quizItems', label: 'Quiz Items and Answer Rules', description: 'Assessment items and answer logic for quick checks.' },
  { key: 'assignmentSubmissionType', label: 'Assignment Submission Type', description: 'Expected submission mode such as text, upload, or project link.' },
  { key: 'liveSessionReference', label: 'Live Session Reference and Replay Link', description: 'Linked facilitator session and replay asset.' },
  { key: 'assessmentWeighting', label: 'Assessment Weighting', description: 'Contribution to progress, score, or mastery calculation.' },
  { key: 'badgeTrigger', label: 'Badge Trigger and Certificate Rule', description: 'Recognition criteria and certificate release rule.' },
  { key: 'prerequisiteContent', label: 'Prerequisite Content', description: 'Required earlier content or dependency chain.' },
  { key: 'completionStatus', label: 'Completion Status', description: 'Publication and learner completion lifecycle state.' },
];

const SUBSCRIPTION_DELIVERY_MODEL = {
  pathways: [
    {
      mode: 'Individual Subscription',
      primaryUser: 'Parent / learner',
      requiredFeatures: [
        'Personal dashboard',
        'Level access',
        'Live class booking',
        'Progress tracking',
        'Certificates',
      ],
    },
    {
      mode: 'School Subscription',
      primaryUser: 'School admin / teachers / students',
      requiredFeatures: [
        'Cohort management',
        'Attendance',
        'Reporting',
        'School dashboard',
        'Facilitator scheduling',
      ],
    },
    {
      mode: 'Institutional / University Subscription',
      primaryUser: 'Campus, department, student network, partner institution',
      requiredFeatures: [
        'Cohort enrolment',
        'Advanced live sessions',
        'ImpactUni studio delivery',
        'Exportable reporting',
      ],
    },
  ],
  recommendedBlend: {
    selfPacedStructuredContent: 60,
    liveClassroomMentoringFacilitation: 25,
    projectsSimulationsShowcasesCommunity: 15,
  },
};

const WEEKLY_CLASSROOM_RHYTHM = [
  {
    dayStage: 'Monday – Learn',
    learnerExperience: 'New lesson content is released.',
    systemFunction: 'Unlock module materials and notify learners.',
  },
  {
    dayStage: 'Tuesday – Practice',
    learnerExperience: 'Learners complete worksheet, reflection, or practical task.',
    systemFunction: 'Track submission or draft status.',
  },
  {
    dayStage: 'Wednesday / Thursday – Live',
    learnerExperience: 'Facilitator-led class deepens the topic.',
    systemFunction: 'Attendance, polls, breakout groups, replay capture.',
  },
  {
    dayStage: 'Friday – Assess',
    learnerExperience: 'Quiz, short test, journal, or rubric-based challenge.',
    systemFunction: 'Score and update progress dashboard.',
  },
  {
    dayStage: 'Weekend – Reinforce',
    learnerExperience: 'Replay, peer challenge, family prompt, or extension activity.',
    systemFunction: 'Maintain retention and continuous engagement.',
  },
];

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
        fourLevelCurriculumFramework: FOUR_LEVEL_CURRICULUM_FRAMEWORK,
        learningArchitecture: LEARNING_LAYERS,
        contentObjectFields: CONTENT_OBJECT_FIELDS,
        subscriptionDeliveryModel: SUBSCRIPTION_DELIVERY_MODEL,
        weeklyClassroomRhythm: WEEKLY_CLASSROOM_RHYTHM,
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
