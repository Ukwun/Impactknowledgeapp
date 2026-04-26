const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { query } = require('../database');
const { verifyToken } = require('../middleware/auth');
const ActivityService = require('../services/activity-service');
const AuditService = require('../services/audit-service');

const router = express.Router();

const JWT_SECRET = process.env.JWT_SECRET || 'test-jwt-secret-key-for-local-testing-impactknowledge';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'test-jwt-refresh-secret-for-testing';
const TOKEN_EXPIRY = '24h';
const REFRESH_TOKEN_EXPIRY = '7d';
const isDev = process.env.NODE_ENV !== 'production';

function devLog(...args) {
  if (isDev) {
    console.log(...args);
  }
}

function normalizeEmail(value) {
  return String(value || '').trim().toLowerCase();
}

devLog('AUTH route initialized with PostgreSQL backend');

// Helper function to generate tokens
function generateTokens(userId, userRole, refreshJti = uuidv4()) {
  const accessToken = jwt.sign(
    { id: userId, role: userRole, type: 'access' },
    JWT_SECRET,
    { expiresIn: TOKEN_EXPIRY }
  );

  const refreshToken = jwt.sign(
    { id: userId, role: userRole, type: 'refresh', jti: refreshJti },
    JWT_REFRESH_SECRET,
    { expiresIn: REFRESH_TOKEN_EXPIRY }
  );

  return { accessToken, refreshToken, refreshJti };
}

async function storeRefreshToken(userId, tokenJti, expiresAtIso) {
  await query(
    `INSERT INTO refresh_tokens (user_id, token_jti, expires_at)
     VALUES ($1, $2, $3)
     ON CONFLICT (token_jti) DO NOTHING`,
    [userId, tokenJti, expiresAtIso]
  );
}

async function revokeRefreshToken(tokenJti) {
  await query(
    `UPDATE refresh_tokens
     SET revoked_at = NOW(), updated_at = NOW()
     WHERE token_jti = $1 AND revoked_at IS NULL`,
    [tokenJti]
  );
}

// Register endpoint
router.post('/register', async (req, res) => {
  devLog('REGISTER attempt', { email: req.body.email, name: req.body.full_name });
  
  try {
    const {
      email,
      password,
      full_name,
      role = 'student',
      termsAccepted = false,
      privacyAccepted = false,
      consentVersion = '2026-04-26',
    } = req.body;
    const normalizedEmail = normalizeEmail(email);
    const normalizedName = String(full_name || '').trim();

    // Validation
    if (!normalizedEmail || !password || !normalizedName) {
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
      'SELECT id FROM users WHERE LOWER(TRIM(email)) = $1 LIMIT 1',
      [normalizedEmail]
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
      [normalizedEmail, passwordHash, normalizedName, role]
    );

    const user = registerResult.rows[0];

    // Initialize user analytics
    await ActivityService.updateUserAnalytics(user.id);

    // Log registration activity
    await ActivityService.logActivity(user.id, 'REGISTER', 'user', user.id, { role }, req);

    if (termsAccepted || privacyAccepted) {
      const consentRows = [];
      if (termsAccepted) {
        consentRows.push(['terms_of_service', consentVersion]);
      }
      if (privacyAccepted) {
        consentRows.push(['privacy_policy', consentVersion]);
      }

      for (const [consentType, version] of consentRows) {
        await query(
          `INSERT INTO consent_records (user_id, consent_type, consent_version, metadata)
           VALUES ($1, $2, $3, $4::jsonb)`,
          [
            user.id,
            consentType,
            String(version),
            JSON.stringify({ source: 'register', accepted: true }),
          ]
        );
      }
    }

    // Generate tokens
    const { accessToken, refreshToken, refreshJti } = generateTokens(user.id, user.role);
    const decodedRefresh = jwt.decode(refreshToken);
    await storeRefreshToken(user.id, refreshJti, new Date(decodedRefresh.exp * 1000).toISOString());

    await AuditService.log({
      actorId: user.id,
      actorRole: user.role,
      action: 'REGISTER_SUCCESS',
      entityType: 'user',
      entityId: String(user.id),
      metadata: { email: normalizedEmail },
      req,
    });

    devLog('REGISTER success', { userId: user.id, email: normalizedEmail });

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
    console.error('Register error:', err);
    res.status(500).json({ 
      success: false,
      error: 'Registration failed. Please try again.' 
    });
  }
});

// Login endpoint
router.post('/login', async (req, res) => {
  devLog('LOGIN attempt', { email: req.body.email });
  
  try {
    const { email, password } = req.body;
    const normalizedEmail = normalizeEmail(email);

    // Validation
    if (!normalizedEmail || !password) {
      return res.status(400).json({ 
        success: false,
        error: 'Email and password are required' 
      });
    }

    // Find user
    const userResult = await query(
      'SELECT id, email, password_hash, full_name, role FROM users WHERE LOWER(TRIM(email)) = $1 LIMIT 1',
      [normalizedEmail]
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
    const { accessToken, refreshToken, refreshJti } = generateTokens(user.id, user.role);
    const decodedRefresh = jwt.decode(refreshToken);
    await storeRefreshToken(user.id, refreshJti, new Date(decodedRefresh.exp * 1000).toISOString());

    await AuditService.log({
      actorId: user.id,
      actorRole: user.role,
      action: 'LOGIN_SUCCESS',
      entityType: 'user',
      entityId: String(user.id),
      metadata: { email: normalizedEmail },
      req,
    });

    devLog('LOGIN success', { userId: user.id });

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
    console.error('Login error:', err);
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
    await query(
      `UPDATE refresh_tokens
       SET revoked_at = NOW(), updated_at = NOW()
       WHERE user_id = $1 AND revoked_at IS NULL`,
      [req.user.id]
    );

    // Log logout activity
    await ActivityService.logActivity(req.user.id, 'LOGOUT', 'user', req.user.id, {}, req);
    await AuditService.log({
      actorId: req.user.id,
      actorRole: req.user.role,
      action: 'LOGOUT',
      entityType: 'refresh_token',
      entityId: String(req.user.id),
      metadata: { strategy: 'revoke_all_active' },
      req,
    });

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

      if (decoded.type !== 'refresh' || !decoded.jti) {
        return res.status(403).json({ success: false, error: 'Invalid refresh token payload' });
      }

      const refreshTokenResult = await query(
        `SELECT user_id, expires_at, revoked_at
         FROM refresh_tokens
         WHERE token_jti = $1
         LIMIT 1`,
        [decoded.jti]
      );

      if (!refreshTokenResult.rows.length) {
        return res.status(403).json({ success: false, error: 'Refresh token not recognized' });
      }

      const tokenRow = refreshTokenResult.rows[0];
      if (tokenRow.revoked_at) {
        return res.status(403).json({ success: false, error: 'Refresh token revoked' });
      }
      if (new Date(tokenRow.expires_at).getTime() < Date.now()) {
        return res.status(403).json({ success: false, error: 'Refresh token expired' });
      }

      const userResult = await query('SELECT id, role FROM users WHERE id = $1 LIMIT 1', [decoded.id]);
      if (!userResult.rows.length) {
        return res.status(404).json({ success: false, error: 'User not found for token' });
      }

      const user = userResult.rows[0];
      const { accessToken, refreshToken: newRefreshToken, refreshJti } = generateTokens(
        user.id,
        user.role
      );

      const decodedNewRefresh = jwt.decode(newRefreshToken);
      await storeRefreshToken(user.id, refreshJti, new Date(decodedNewRefresh.exp * 1000).toISOString());
      await revokeRefreshToken(decoded.jti);

      await AuditService.log({
        actorId: user.id,
        actorRole: user.role,
        action: 'TOKEN_REFRESH_ROTATED',
        entityType: 'refresh_token',
        entityId: decoded.jti,
        metadata: { replacementJti: refreshJti },
      });

      res.json({
        success: true,
        data: {
          accessToken,
          refreshToken: newRefreshToken
        }
      });
    } catch (err) {
      console.error('Token verification failed:', err.message);
      res.status(403).json({ 
        success: false,
        error: 'Invalid refresh token' 
      });
    }
  } catch (err) {
    console.error('Refresh token error:', err);
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

    await query(
      `UPDATE refresh_tokens
       SET revoked_at = NOW(), updated_at = NOW()
       WHERE user_id = $1 AND revoked_at IS NULL`,
      [userId]
    );

    // Log activity
    await ActivityService.logActivity(userId, 'CHANGE_PASSWORD', 'user', userId, {}, req);
    await AuditService.log({
      actorId: userId,
      actorRole: req.user.role,
      action: 'PASSWORD_CHANGED_REFRESH_REVOKED',
      entityType: 'refresh_token',
      entityId: String(userId),
      metadata: { strategy: 'revoke_all_active' },
      req,
    });

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

router.post('/consent', verifyToken, async (req, res) => {
  try {
    const { consentType, consentVersion, accepted = true, metadata = {} } = req.body || {};

    if (!consentType || !consentVersion) {
      return res.status(400).json({
        success: false,
        error: 'consentType and consentVersion are required',
      });
    }

    await query(
      `INSERT INTO consent_records (user_id, consent_type, consent_version, metadata)
       VALUES ($1, $2, $3, $4::jsonb)`,
      [
        req.user.id,
        String(consentType),
        String(consentVersion),
        JSON.stringify({ ...metadata, accepted: Boolean(accepted), source: 'explicit' }),
      ]
    );

    await AuditService.log({
      actorId: req.user.id,
      actorRole: req.user.role,
      action: 'CONSENT_RECORDED',
      entityType: 'consent_record',
      entityId: String(req.user.id),
      metadata: { consentType, consentVersion, accepted: Boolean(accepted) },
      req,
    });

    return res.status(201).json({ success: true });
  } catch (err) {
    console.error('Consent record error:', err);
    return res.status(500).json({ success: false, error: 'Failed to record consent' });
  }
});

module.exports = router;
