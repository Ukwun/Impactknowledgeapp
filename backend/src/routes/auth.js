const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');
const ActivityService = require('../services/activity-service');

const router = express.Router();

const JWT_SECRET = process.env.JWT_SECRET || 'test-jwt-secret-key-for-local-testing-impactknowledge';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'test-jwt-refresh-secret-for-testing';
const TOKEN_EXPIRY = '24h';
const REFRESH_TOKEN_EXPIRY = '7d';

console.log('✅ AUTH USING REAL DATABASE WITH POSTGRESQL');

// Helper function to generate tokens
function generateTokens(userId, userRole) {
  const accessToken = jwt.sign(
    { id: userId, role: userRole },
    JWT_SECRET,
    { expiresIn: TOKEN_EXPIRY }
  );

  const refreshToken = jwt.sign(
    { id: userId },
    JWT_REFRESH_SECRET,
    { expiresIn: REFRESH_TOKEN_EXPIRY }
  );

  return { accessToken, refreshToken };
}

// Register endpoint
router.post('/register', async (req, res) => {
  console.log('=== REGISTER ===', { email: req.body.email, name: req.body.full_name });
  
  try {
    const { email, password, full_name, role = 'student' } = req.body;

    // Validation
    if (!email || !password || !full_name) {
      return res.status(400).json({ 
        success: false,
        error: 'Email, password, and full_name are required' 
      });
    }

    if (password.length < 6) {
      return res.status(400).json({ 
        success: false,
        error: 'Password must be at least 6 characters long' 
      });
    }

    // Check if user already exists
    const existingResult = await query(
      'SELECT id FROM users WHERE email = $1',
      [email.toLowerCase()]
    );

    if (existingResult.rows.length > 0) {
      return res.status(409).json({ 
        success: false,
        error: 'User with this email already exists' 
      });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // Create user
    const registerResult = await query(
      `INSERT INTO users (email, password_hash, full_name, role, created_at, updated_at)
       VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
       RETURNING id, email, full_name, role, created_at, updated_at`,
      [email.toLowerCase(), passwordHash, full_name, role]
    );

    const user = registerResult.rows[0];

    // Initialize user analytics
    await ActivityService.updateUserAnalytics(user.id);

    // Log registration activity
    await ActivityService.logActivity(user.id, 'REGISTER', 'user', user.id, { role }, req);

    // Generate tokens
    const { accessToken, refreshToken } = generateTokens(user.id, user.role);

    console.log('✅ REGISTER SUCCESS: New user created with ID:', user.id, 'Email:', email);

    res.status(201).json({
      success: true,
      data: {
        accessToken,
        refreshToken,
        user: {
          id: String(user.id),
          email: user.email,
          full_name: user.full_name,
          role: user.role,
          createdAt: user.created_at,
          updatedAt: user.updated_at
        }
      }
    });
  } catch (err) {
    console.error('❌ Register error:', err);
    res.status(500).json({ 
      success: false,
      error: 'Registration failed. Please try again.' 
    });
  }
});

// Login endpoint
router.post('/login', async (req, res) => {
  console.log('=== LOGIN ===', { email: req.body.email });
  
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({ 
        success: false,
        error: 'Email and password are required' 
      });
    }

    // Find user
    const userResult = await query(
      'SELECT id, email, password_hash, full_name, role FROM users WHERE email = $1',
      [email.toLowerCase()]
    );

    if (userResult.rows.length === 0) {
      return res.status(401).json({ 
        success: false,
        error: 'Invalid email or password' 
      });
    }

    const user = userResult.rows[0];

    // Compare passwords
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);

    if (!isPasswordValid) {
      return res.status(401).json({ 
        success: false,
        error: 'Invalid email or password' 
      });
    }

    // Log login activity
    await ActivityService.logActivity(user.id, 'LOGIN', 'user', user.id, {}, req);

    // Generate tokens
    const { accessToken, refreshToken } = generateTokens(user.id, user.role);

    console.log('✅ LOGIN SUCCESS: User authenticated:', user.id);

    res.json({
      success: true,
      data: {
        accessToken,
        refreshToken,
        user: {
          id: String(user.id),
          email: user.email,
          full_name: user.full_name,
          role: user.role
        }
      }
    });
  } catch (err) {
    console.error('❌ Login error:', err);
    res.status(500).json({ 
      success: false,
      error: 'Login failed. Please try again.' 
    });
  }
});

// Get current user endpoint
router.get('/me', verifyToken, async (req, res) => {
  try {
    const userResult = await query(
      'SELECT id, email, full_name, role, profile_picture_url, bio, phone_number, location, created_at, updated_at FROM users WHERE id = $1',
      [req.user.id]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'User not found' 
      });
    }

    const user = userResult.rows[0];

    res.json({
      success: true,
      data: {
        id: String(user.id),
        email: user.email,
        full_name: user.full_name,
        role: user.role,
        profile_picture_url: user.profile_picture_url,
        bio: user.bio,
        phone_number: user.phone_number,
        location: user.location,
        createdAt: user.created_at,
        updatedAt: user.updated_at
      }
    });
  } catch (err) {
    console.error('❌ Get user error:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch user' 
    });
  }
});

// Update user profile
router.put('/me', verifyToken, async (req, res) => {
  try {
    const { full_name, bio, phone_number, location, profile_picture_url } = req.body;
    const userId = req.user.id;

    const updateResult = await query(
      `UPDATE users SET 
        full_name = COALESCE($2, full_name),
        bio = COALESCE($3, bio),
        phone_number = COALESCE($4, phone_number),
        location = COALESCE($5, location),
        profile_picture_url = COALESCE($6, profile_picture_url),
        updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING id, email, full_name, role, profile_picture_url, bio, phone_number, location`,
      [userId, full_name, bio, phone_number, location, profile_picture_url]
    );

    if (updateResult.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'User not found' 
      });
    }

    // Log activity
    await ActivityService.logActivity(userId, 'UPDATE_PROFILE', 'user', userId, { fields: Object.keys(req.body) }, req);

    res.json({
      success: true,
      data: updateResult.rows[0]
    });
  } catch (err) {
    console.error('Error updating profile:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to update profile' 
    });
  }
});

// Logout endpoint
router.post('/logout', verifyToken, async (req, res) => {
  try {
    // Log logout activity
    await ActivityService.logActivity(req.user.id, 'LOGOUT', 'user', req.user.id, {}, req);

    res.json({ 
      success: true,
      message: 'Logged out successfully' 
    });
  } catch (err) {
    console.error('Logout error:', err);
    res.status(500).json({ 
      success: false,
      error: 'Logout failed' 
    });
  }
});

// Refresh token endpoint
router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ 
        success: false,
        error: 'Refresh token is required' 
      });
    }

    try {
      const decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
      const { accessToken, refreshToken: newRefreshToken } = generateTokens(decoded.id, decoded.role);

      res.json({
        success: true,
        data: {
          accessToken,
          refreshToken: newRefreshToken
        }
      });
    } catch (err) {
      console.error('❌ Token verification failed:', err.message);
      res.status(403).json({ 
        success: false,
        error: 'Invalid refresh token' 
      });
    }
  } catch (err) {
    console.error('❌ Refresh token error:', err);
    res.status(500).json({ 
      success: false,
      error: 'Token refresh failed' 
    });
  }
});

// Change password endpoint
router.post('/change-password', verifyToken, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const userId = req.user.id;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ 
        success: false,
        error: 'Current and new passwords are required' 
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ 
        success: false,
        error: 'New password must be at least 6 characters long' 
      });
    }

    // Get current user password hash
    const userResult = await query(
      'SELECT password_hash FROM users WHERE id = $1',
      [userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ 
        success: false,
        error: 'User not found' 
      });
    }

    // Verify current password
    const isPasswordValid = await bcrypt.compare(currentPassword, userResult.rows[0].password_hash);

    if (!isPasswordValid) {
      return res.status(401).json({ 
        success: false,
        error: 'Current password is incorrect' 
      });
    }

    // Hash new password
    const salt = await bcrypt.genSalt(10);
    const newPasswordHash = await bcrypt.hash(newPassword, salt);

    // Update password
    await query(
      'UPDATE users SET password_hash = $2, updated_at = CURRENT_TIMESTAMP WHERE id = $1',
      [userId, newPasswordHash]
    );

    // Log activity
    await ActivityService.logActivity(userId, 'CHANGE_PASSWORD', 'user', userId, {}, req);

    res.json({
      success: true,
      message: 'Password changed successfully'
    });
  } catch (err) {
    console.error('Error changing password:', err);
    res.status(500).json({ 
      success: false,
      error: 'Failed to change password' 
    });
  }
});

module.exports = router;
