require('dotenv').config({ path: require('path').resolve(__dirname, '..', '.env') });

const axios = require('axios');

const baseURL = String(process.env.LOADTEST_BASE_URL || 'http://localhost:3000').replace(/\/$/, '');
const accessToken = process.env.LOADTEST_ACCESS_TOKEN || '';
const refreshToken = process.env.LOADTEST_REFRESH_TOKEN || '';
const lessonId = Number(process.env.LOADTEST_LESSON_ID || 0);
const cycleId = Number(process.env.LOADTEST_CYCLE_ID || 0);
const courseId = Number(process.env.LOADTEST_COURSE_ID || 0);
const uploadAssetId = Number(process.env.LOADTEST_UPLOAD_ASSET_ID || 0);
const paymentReference = process.env.LOADTEST_PAYMENT_REFERENCE || '';

const headers = accessToken
  ? { Authorization: `Bearer ${accessToken}` }
  : {};

function average(values) {
  if (!values.length) return 0;
  return Math.round(values.reduce((sum, value) => sum + value, 0) / values.length);
}

async function hit(label, requestFactory, iterations = 5) {
  const samples = [];
  let failures = 0;

  for (let index = 0; index < iterations; index += 1) {
    const startedAt = Date.now();
    try {
      const response = await requestFactory();
      samples.push(Date.now() - startedAt);
      if (response.status >= 400) {
        failures += 1;
      }
    } catch (error) {
      failures += 1;
      samples.push(Date.now() - startedAt);
    }
  }

  return {
    label,
    iterations,
    failures,
    averageMs: average(samples),
    maxMs: samples.length ? Math.max(...samples) : 0,
  };
}

async function run() {
  const checks = [];

  if (refreshToken) {
    checks.push(
      hit('auth.refresh', () =>
        axios.post(`${baseURL}/api/auth/refresh`, { refreshToken })
      )
    );
  }

  if (courseId) {
    checks.push(
      hit('classroom.list', () =>
        axios.get(`${baseURL}/api/classroom/course/${courseId}/activities`, { headers })
      )
    );
  }

  if (lessonId && cycleId) {
    checks.push(
      hit('classroom.createActivity', () =>
        axios.post(
          `${baseURL}/api/classroom/cycles/${cycleId}/activities`,
          {
            lessonId,
            title: `Load Test Activity ${Date.now()}`,
            learningLayer: 'senior_secondary',
            activityType: 'live_session',
          },
          { headers }
        )
      )
    );
  }

  checks.push(
    hit('uploads.sign', () =>
      axios.post(
        `${baseURL}/api/uploads/sign`,
        {
          fileName: 'load-test.pdf',
          mimeType: 'application/pdf',
          byteSize: 4096,
          accessScope: 'private',
          purpose: 'load_test',
        },
        { headers }
      )
    )
  );

  if (uploadAssetId) {
    checks.push(
      hit('uploads.complete', () =>
        axios.post(
          `${baseURL}/api/uploads/complete`,
          {
            assetId: uploadAssetId,
            secureUrl: 'https://res.cloudinary.com/demo/raw/upload/v1/load-test.pdf',
            uploadedBytes: 4096,
            format: 'pdf',
            virusScanStatus: 'clean',
          },
          { headers }
        )
      )
    );
  }

  if (paymentReference) {
    checks.push(
      hit('payments.lookup', () =>
        axios.get(`${baseURL}/api/payments/reference/${paymentReference}`, { headers })
      )
    );
  }

  checks.push(
    hit('payments.list', () =>
      axios.get(`${baseURL}/api/payments`, { headers })
    )
  );

  const results = await Promise.all(checks);
  console.log(JSON.stringify({ baseURL, results }, null, 2));

  const hasFailures = results.some((result) => result.failures > 0);
  process.exitCode = hasFailures ? 1 : 0;
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
