require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { initializeDatabase } = require('./src/database');
const authRoutes = require('./src/routes/auth');
const courseRoutes = require('./src/routes/courses');
const achievementRoutes = require('./src/routes/achievements');
const paymentRoutes = require('./src/routes/payments');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Log requests in development
if (process.env.NODE_ENV !== 'production') {
  app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} ${req.method} ${req.path}`);
    next();
  });
}

// Initialize database
initializeDatabase().then(() => {
  console.log('Database initialized successfully');
}).catch(err => {
  console.error('Database initialization failed:', err);
  console.error('⚠️  Running without database - API endpoints will return 500 for database operations');
  // Don't exit - let the server continue so we can test endpoints
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Test endpoint to verify connectivity
app.post('/api/test', (req, res) => {
  console.log('TEST endpoint hit!');
  console.log('Headers:', req.headers);
  console.log('Body:', req.body);
  res.json({ 
    message: 'Test endpoint works!', 
    received: req.body,
    timestamp: new Date().toISOString()
  });
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/courses', courseRoutes);
app.use('/api/achievements', achievementRoutes);
app.use('/api/users', require('./src/routes/users'));
app.use('/api/enrollments', require('./src/routes/enrollments'));
app.use('/api/leaderboard', require('./src/routes/leaderboard'));
app.use('/api/membership-tiers', require('./src/routes/membership'));
app.use('/api/payments', paymentRoutes);
app.use('/api/dashboard', require('./src/routes/dashboard'));

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    error: err.message || 'Internal server error'
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = app;
