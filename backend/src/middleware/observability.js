const crypto = require('crypto');

const warningThresholdsMs = {
  auth: Number(process.env.OBS_AUTH_WARN_MS || 600),
  classroom: Number(process.env.OBS_CLASSROOM_WARN_MS || 800),
  uploads: Number(process.env.OBS_UPLOADS_WARN_MS || 1200),
  payments: Number(process.env.OBS_PAYMENTS_WARN_MS || 1500),
  default: Number(process.env.OBS_DEFAULT_WARN_MS || 1000),
};

function getBucket(path) {
  if (path.startsWith('/api/auth')) return 'auth';
  if (path.startsWith('/api/classroom')) return 'classroom';
  if (path.startsWith('/api/uploads')) return 'uploads';
  if (path.startsWith('/api/payments')) return 'payments';
  return 'default';
}

function requestObservability(req, res, next) {
  const startedAt = Date.now();
  const requestId = req.headers['x-request-id'] || crypto.randomUUID();
  req.requestId = requestId;
  res.setHeader('x-request-id', requestId);

  res.on('finish', () => {
    const durationMs = Date.now() - startedAt;
    const bucket = getBucket(req.path || req.originalUrl || '');
    const thresholdMs = warningThresholdsMs[bucket] || warningThresholdsMs.default;

    const payload = {
      level: durationMs >= thresholdMs || res.statusCode >= 500 ? 'warn' : 'info',
      type: 'http_request',
      requestId,
      method: req.method,
      path: req.originalUrl,
      statusCode: res.statusCode,
      durationMs,
      bucket,
      thresholdMs,
      userId: req.user?.id || null,
      role: req.user?.role || null,
    };

    if (payload.level === 'warn') {
      payload.alertHint = `${bucket}_latency_or_error`;
    }

    console.log(JSON.stringify(payload));
  });

  next();
}

module.exports = {
  requestObservability,
  warningThresholdsMs,
};
