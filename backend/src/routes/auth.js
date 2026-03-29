const express = require('express');
const mockAuth = require('../services/mock-auth');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

console.log('⚠️  AUTH USING IN-MEMORY MOCK AUTHENTICATION');
console.log('⚠️  Data is NOT persisted between server restarts');

// Register endpoint
router.post('/register', async (req, res) => {
  console.log('=== REGISTER ===', req.body);
  
  try {
    const { email, password, full_name, role = 'student' } = req.body;

    if (!email || !password || !full_name) {
      return res.status(400).json({ error: 'Email, password, and full_name are required' });
    }

    // Register using mock auth
    const user = await mockAuth.registerUser(email, password, full_name, role);
    const { accessToken, refreshToken } = mockAuth.generateTokens(user.id);

    console.log('✅ REGISTER SUCCESS: New user created with ID:', user.id);

    res.status(201).json({
      accessToken,
      refreshToken,
      user: {
        id: String(user.id),
        email: user.email,
        full_name: user.full_name,
        role: user.role,
        createdAt: user.created_at,
        updatedAt: user.updated_at,
        emailVerified: user.email_verified
      }
    });
  } catch (err) {
    console.error('❌ Register error:', err.message);
    if (err.message ===  'User already exists') {
      return res.status(409).json({ error: err.message });
    }
    res.status(500).json({ error: err.message || 'Registration failed' });
  }
});

// Login endpoint
router.post('/login', async (req, res) => {
  console.log('=== LOGIN ===', req.body);
  
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Login using mock auth
    const user = await mockAuth.loginUser(email, password);
    const { accessToken, refreshToken } = mockAuth.generateTokens(user.id);

    console.log('✅ LOGIN SUCCESS: User authenticated:', user.id, 'Email:', email);
    console.log('🔑 TOKEN ISSUED: Access token starts with:', accessToken.substring(0, 50) + '...');

    res.json({
      accessToken,
      refreshToken,
      user: {
        id: String(user.id),
        email: user.email,
        full_name: user.full_name,
        role: user.role,
        createdAt: user.created_at,
        updatedAt: user.updated_at,
        emailVerified: user.email_verified
      }
    });
  } catch (err) {
    console.error('❌ Login error:', err.message);
    if (err.message === 'Invalid credentials') {
      return res.status(401).json({ error: err.message });
    }
    res.status(500).json({ error: err.message || 'Login failed' });
  }
});

// Get current user endpoint
router.get('/me', verifyToken, async (req, res) => {
  try {
    const user = mockAuth.getUserById(req.user.id);
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      id: String(user.id),
      email: user.email,
      full_name: user.full_name,
      role: user.role,
      createdAt: user.created_at,
      updatedAt: user.updated_at
    });
  } catch (err) {
    console.error('❌ Get user error:', err.message);
    res.status(500).json({ error: err.message || 'Failed to fetch user' });
  }
});

// Logout endpoint
router.post('/logout', verifyToken, async (req, res) => {
  try {
    // In a simple implementation, logout is handled on the client side
    // In production, you might want to blacklist tokens in Redis
    res.json({ message: 'Logged out successfully' });
  } catch (err) {
    console.error('Logout error:', err);
    res.status(500).json({ error: 'Logout failed' });
  }
});

// Refresh token endpoint
router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token is required' });
    }

    try {
      const jwt = require('jsonwebtoken');
      console.log('🔄 REFRESH TOKEN: Attempting to verify refresh token');
      const decoded = jwt.verify(refreshToken, mockAuth.JWT_SECRET);
      console.log('✅ REFRESH TOKEN: Token verified, generating new tokens');
      const { accessToken, refreshToken: newRefreshToken } = mockAuth.generateTokens(decoded.id);

      res.json({
        accessToken,
        refreshToken: newRefreshToken
      });
    } catch (err) {
      console.error('❌ REFRESH TOKEN ERROR:', err.message);
      res.status(403).json({ error: 'Invalid refresh token', details: err.message });
    }
  } catch (err) {
    console.error('❌ Refresh token error:', err.message);
    res.status(500).json({ error: 'Token refresh failed' });
  }
});

module.exports = router;
