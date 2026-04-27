const rateLimit = require('express-rate-limit');

/**
 * Global Rate Limiter
 * Limits requests per IP address
 */
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true, // Return rate limit info in `RateLimit-*` headers
  legacyHeaders: false, // Disable `X-RateLimit-*` headers
  keyGenerator: (req, res) => req.ip || req.connection.remoteAddress,
  skip: (req, res) => {
    // Skip rate limiting for health checks
    return req.path === '/health';
  },
});

/**
 * Strict Auth Rate Limiter
 * Prevents brute force attacks on auth endpoints
 */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts per 15 minutes
  message: 'Too many login attempts, please try again later.',
  standardHeaders: false,
  legacyHeaders: false,
  skipSuccessfulRequests: true, // Only count failed requests
});

/**
 * API Route Rate Limiter
 * Moderate limits for general API usage
 */
const apiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 30, // 30 requests per minute
  message: 'Too many API requests, please try again later.',
  standardHeaders: false,
  legacyHeaders: false,
});

/**
 * Payment Rate Limiter
 * Strict limits for payment endpoints
 */
const paymentLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 10, // 10 payment attempts per hour
  message: 'Too many payment attempts, please try again later.',
  standardHeaders: false,
  legacyHeaders: false,
});

/**
 * File Upload Rate Limiter
 * Limits file uploads to prevent abuse
 */
const uploadLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 20, // 20 uploads per hour
  message: 'Too many file uploads, please try again later.',
  standardHeaders: false,
  legacyHeaders: false,
});

const refreshLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: 'Too many token refresh attempts, please try again later.',
  standardHeaders: false,
  legacyHeaders: false,
});

const analyticsLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  message: 'Too many analytics requests, please try again later.',
  standardHeaders: false,
  legacyHeaders: false,
});

const systemLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  message: 'Too many system requests, please try again later.',
  standardHeaders: false,
  legacyHeaders: false,
});

module.exports = {
  globalLimiter,
  authLimiter,
  apiLimiter,
  paymentLimiter,
  uploadLimiter,
  refreshLimiter,
  analyticsLimiter,
  systemLimiter,
};
