jest.mock('../database', () => ({
  query: jest.fn(),
}));

jest.mock('../middleware/auth', () => ({
  verifyToken: (req, res, next) => {
    req.user = req.user || { id: 1, role: 'admin' };
    next();
  },
}));

const { query } = require('../database');
const classroomRouter = require('./classroom');

function getRoute(method, path) {
  const layer = classroomRouter.stack.find(
    (entry) => entry.route && entry.route.path === path && entry.route.methods[method]
  );
  return layer ? layer.route : null;
}

function createMockRes() {
  return {
    statusCode: 200,
    body: undefined,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(payload) {
      this.body = payload;
      return this;
    },
  };
}

describe('classroom route contracts', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('registers required public and protected routes', () => {
    const registered = classroomRouter.stack
      .filter((entry) => entry.route)
      .flatMap((entry) => {
        const methods = Object.keys(entry.route.methods);
        return methods.map((method) => `${method.toUpperCase()} ${entry.route.path}`);
      });

    expect(registered).toEqual(
      expect.arrayContaining([
        'GET /blueprint',
        'GET /hierarchy',
        'POST /programmes',
        'POST /programmes/:programmeId/levels',
        'POST /levels/:levelId/cycles',
        'POST /lessons/:lessonId/activities',
        'POST /cycles/:cycleId/live-sessions',
        'POST /cycles/:cycleId/assessments',
        'POST /cycles/:cycleId/showcases',
        'POST /badges',
      ])
    );
  });

  test('blueprint contract returns critical framework sections', async () => {
    const route = getRoute('get', '/blueprint');
    expect(route).not.toBeNull();

    const handler = route.stack[0].handle;
    const req = {};
    const res = createMockRes();

    await handler(req, res);

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toEqual(
      expect.objectContaining({
        objectives: expect.any(Array),
        deliveryModel: expect.any(Object),
        onlineClassroomStructure: expect.any(Object),
        curriculumArchitecture: expect.any(Object),
        liveFacilitatorFramework: expect.any(Object),
        fourLevelCurriculumFramework: expect.any(Array),
        learningArchitecture: expect.any(Array),
      })
    );
  });

  test('protected post routes enforce middleware chain before handlers', () => {
    const protectedPaths = [
      '/programmes',
      '/programmes/:programmeId/levels',
      '/levels/:levelId/cycles',
      '/lessons/:lessonId/activities',
      '/cycles/:cycleId/live-sessions',
      '/cycles/:cycleId/assessments',
      '/cycles/:cycleId/showcases',
      '/badges',
    ];

    for (const path of protectedPaths) {
      const route = getRoute('post', path);
      expect(route).not.toBeNull();
      expect(route.stack.length).toBeGreaterThan(1);
    }
  });

  test('create activity rejects invalid learning layer values', async () => {
    const route = getRoute('post', '/lessons/:lessonId/activities');
    expect(route).not.toBeNull();

    const handler = route.stack[route.stack.length - 1].handle;
    const req = {
      params: { lessonId: '14' },
      user: { id: 55, role: 'admin' },
      body: {
        activityType: 'assignment',
        title: 'Practical task',
        learningLayer: 'invalid_layer',
      },
    };
    const res = createMockRes();

    await handler(req, res);

    expect(res.statusCode).toBe(400);
    expect(res.body).toEqual({ success: false, error: 'Invalid learningLayer value' });
    expect(query).not.toHaveBeenCalled();
  });

  test('create activity passes metadata through to insert query', async () => {
    const route = getRoute('post', '/lessons/:lessonId/activities');
    expect(route).not.toBeNull();

    query.mockResolvedValueOnce({ rows: [] }); // lesson update when learningLayer is set
    query.mockResolvedValueOnce({ rows: [{ id: 991, title: 'Practical task' }] });

    const handler = route.stack[route.stack.length - 1].handle;
    const req = {
      params: { lessonId: '14' },
      user: { id: 55, role: 'admin' },
      body: {
        activityType: 'assignment',
        title: 'Practical task',
        learningLayer: 'apply',
        metadata: {
          uploadedAssets: [
            {
              type: 'pdf',
              url: 'https://cdn.example.test/assets/uploaded-material.pdf',
            },
          ],
          progressionRules: {
            completionThresholdPercent: 75,
            assessmentScoreThresholdPercent: 60,
            liveParticipationThresholdPercent: 70,
            projectSubmissionRequired: true,
          },
        },
      },
    };
    const res = createMockRes();

    await handler(req, res);

    expect(res.statusCode).toBe(201);
    expect(query).toHaveBeenCalledTimes(2);

    const insertCall = query.mock.calls[1];
    const insertParams = insertCall[1];
    expect(insertParams[5]).toEqual(
      expect.objectContaining({
        uploadedAssets: expect.any(Array),
        progressionRules: expect.objectContaining({
          completionThresholdPercent: 75,
          assessmentScoreThresholdPercent: 60,
          liveParticipationThresholdPercent: 70,
          projectSubmissionRequired: true,
        }),
      })
    );
  });

  test('create live session requires title and startsAt', async () => {
    const route = getRoute('post', '/cycles/:cycleId/live-sessions');
    expect(route).not.toBeNull();

    const handler = route.stack[route.stack.length - 1].handle;
    const req = {
      params: { cycleId: '2' },
      user: { id: 55, role: 'admin' },
      body: {
        title: '',
      },
    };
    const res = createMockRes();

    await handler(req, res);

    expect(res.statusCode).toBe(400);
    expect(res.body).toEqual({ success: false, error: 'title and startsAt are required' });
    expect(query).not.toHaveBeenCalled();
  });
});
