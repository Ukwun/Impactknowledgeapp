// In-memory authentication service for local development/testing
// This stores user data in memory for quick testing without database setup

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// In-memory user storage
const users = new Map();

// Counter for generating user IDs
let userIdCounter = 1;

const JWT_SECRET = process.env.JWT_SECRET || 'test-jwt-secret-key-for-local-testing-impactknowledge';

function generateTokens(userId) {
  const accessToken = jwt.sign({ id: userId }, JWT_SECRET, { expiresIn: '24h' });
  const refreshToken = jwt.sign({ id: userId }, JWT_SECRET, { expiresIn: '7d' });
  return { accessToken, refreshToken };
}

async function registerUser(email, password, fullName, role = 'student') {
  // Check if user exists
  const existingUser = Array.from(users.values()).find(u => u.email === email);
  if (existingUser) {
    throw new Error('User already exists');
  }

  const userId = userIdCounter++;
  const passwordHash = await bcrypt.hash(password, 10);

  const user = {
    id: userId,
    email,
    password_hash: passwordHash,
    full_name: fullName,
    role,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    email_verified: false,
  };

  users.set(userId, user);
  console.log(`✅ User registered: ${email} (ID: ${userId})`);
  
  return user;
}

async function loginUser(email, password) {
  // Find user by email
  const user = Array.from(users.values()).find(u => u.email === email);
  if (!user) {
    throw new Error('Invalid credentials');
  }

  // Verify password
  const passwordValid = await bcrypt.compare(password, user.password_hash);
  if (!passwordValid) {
    throw new Error('Invalid credentials');
  }

  console.log(`✅ User logged in: ${email}`);
  
  return user;
}

function getUserById(userId) {
  return users.get(userId);
}

module.exports = {
  registerUser,
  loginUser,
  getUserById,
  generateTokens,
  JWT_SECRET
};
