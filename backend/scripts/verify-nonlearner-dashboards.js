/* eslint-disable no-console */
const BASE_URL = process.env.VERIFY_BASE_URL || 'http://localhost:3000';
const PASSWORD = process.env.VERIFY_USER_PASSWORD || 'Impact123!';

const endpointSpecs = [
  { role: 'parent', endpoint: '/api/dashboard/parent', keys: ['childrenLinked', 'avgProgress', 'attendanceRate', 'unreadMessages'] },
  { role: 'facilitator', endpoint: '/api/dashboard/facilitator', keys: ['activeClasses', 'pendingReviews', 'atRiskLearners', 'unreadMessages'] },
  { role: 'instructor', endpoint: '/api/dashboard/facilitator', keys: ['activeClasses', 'pendingReviews', 'atRiskLearners', 'unreadMessages'] },
  { role: 'school_admin', endpoint: '/api/dashboard/school-admin', keys: ['totalStudents', 'totalFacilitators', 'completionRate', 'openAlerts'] },
  { role: 'mentor', endpoint: '/api/dashboard/mentor', keys: ['totalMentees', 'upcomingSessions', 'completedSessions', 'avgMenteeGrowth'] },
  { role: 'circle_member', endpoint: '/api/dashboard/circle-member', keys: ['connections', 'postsThisMonth', 'roundtables', 'profileReach'] },
  { role: 'uni_member', endpoint: '/api/dashboard/uni-member', keys: ['ventureStage', 'teamMembers', 'mentorSessions', 'openOpportunities'] },
  { role: 'admin', endpoint: '/api/dashboard/admin', keys: ['totalUsers', 'activeCourses', 'completionRate', 'openAlerts'] },
];

async function request(path, { method = 'GET', token, body } = {}) {
  const response = await fetch(`${BASE_URL}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  let json;
  try {
    json = await response.json();
  } catch {
    json = null;
  }

  return { response, json };
}

async function registerOrLogin(role, suffix) {
  const email = `verify.${role}.${suffix}@impactknowledge.local`;
  const fullName = `Verify ${role}`;

  const extractAuthPayload = (json) => {
    if (!json || typeof json !== 'object') return null;
    if (json.data && typeof json.data === 'object') return json.data;
    if (json.accessToken && json.user) return json;
    return null;
  };

  const register = await request('/api/auth/register', {
    method: 'POST',
    body: {
      email,
      password: PASSWORD,
      full_name: fullName,
      role,
    },
  });

  const registerPayload = extractAuthPayload(register.json);
  if (register.response.ok && registerPayload?.accessToken) {
    return {
      email,
      token: registerPayload.accessToken,
      userId: parseInt(registerPayload.user.id, 10),
    };
  }

  const login = await request('/api/auth/login', {
    method: 'POST',
    body: { email, password: PASSWORD },
  });

  const loginPayload = extractAuthPayload(login.json);
  if (!login.response.ok || !loginPayload?.accessToken) {
    throw new Error(`Unable to register/login role=${role}. Response: ${JSON.stringify(login.json)}`);
  }

  return {
    email,
    token: loginPayload.accessToken,
    userId: parseInt(loginPayload.user.id, 10),
  };
}

async function ensureRelationshipData(admin, parent, mentor) {
  const child = await registerOrLogin('student', `child.${Date.now()}`);
  const mentee = await registerOrLogin('student', `mentee.${Date.now()}`);

  await request('/api/relationships/parent/children/link', {
    method: 'POST',
    token: admin.token,
    body: {
      parentUserId: parent.userId,
      childUserId: child.userId,
      relationship: 'guardian',
    },
  });

  await request('/api/relationships/mentor/mentees/link', {
    method: 'POST',
    token: admin.token,
    body: {
      mentorUserId: mentor.userId,
      menteeUserId: mentee.userId,
      goals: 'Academic growth and project execution',
    },
  });
}

function hasSummaryShape(data, expectedKeys) {
  const summary = data?.summary;
  if (!summary || typeof summary !== 'object') {
    return { ok: false, missing: expectedKeys, summary };
  }

  const missing = expectedKeys.filter((key) => !(key in summary));
  return { ok: missing.length === 0, missing, summary };
}

async function main() {
  const health = await request('/health');
  if (!health.response.ok) {
    throw new Error(`Backend not healthy on ${BASE_URL}`);
  }

  const suffix = Date.now();
  const identities = {};
  for (const spec of endpointSpecs) {
    identities[spec.role] = await registerOrLogin(spec.role, suffix);
  }

  await ensureRelationshipData(
    identities.admin,
    identities.parent,
    identities.mentor
  );

  const results = [];
  for (const spec of endpointSpecs) {
    const identity = identities[spec.role];
    const { response, json } = await request(spec.endpoint, { token: identity.token });
    const shape = hasSummaryShape(json?.data, spec.keys);

    results.push({
      role: spec.role,
      endpoint: spec.endpoint,
      status: response.status,
      ok: response.ok && json?.success === true && shape.ok,
      missing: shape.missing,
      summary: shape.summary,
      error: json?.error || null,
    });
  }

  console.log('\nNon-learner dashboard contract checks:\n');
  let passCount = 0;
  for (const result of results) {
    if (result.ok) {
      passCount += 1;
      console.log(`PASS ${result.role} -> ${result.endpoint} (${result.status})`);
    } else {
      console.log(`FAIL ${result.role} -> ${result.endpoint} (${result.status})`);
      console.log(`  missing keys: ${result.missing.join(', ') || 'none'}`);
      console.log(`  error: ${result.error || 'none'}`);
    }
  }

  console.log(`\nSummary: ${passCount}/${results.length} role dashboards passed.`);

  if (passCount !== results.length) {
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error('Verification failed:', error.message);
  process.exit(1);
});