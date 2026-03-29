const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'test-jwt-secret-key-for-local-testing-impactknowledge';

const verifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization;
  const token = authHeader?.split(' ')[1];

  if (!token) {
    console.warn('⚠️  NO TOKEN provided. Headers:', req.headers);
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    console.log('🔑 TOKEN to verify:', token.substring(0, 50) + '...');
    console.log('🔑 JWT_SECRET being used:', JWT_SECRET.substring(0, 30) + '...');
    
    const decoded = jwt.verify(token, JWT_SECRET);
    console.log('✅ Token verified successfully:', decoded);
    req.user = decoded;
    next();
  } catch (err) {
    console.error('❌ Token verification failed:', err.message);
    console.error('   Error type:', err.name);
    console.error('   Token:', token.substring(0, 50) + '...');
    return res.status(403).json({ error: 'Invalid token', details: err.message });
  }
};

module.exports = { verifyToken };
