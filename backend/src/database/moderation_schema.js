/**
 * Content Moderation Database Schema
 * Supports flagging and resolution of user-generated content
 */

const { query } = require('../database');

async function initializeContentModerationTables() {
  try {
    // Content flags table
    await query(`
      CREATE TABLE IF NOT EXISTS content_flags (
        id SERIAL PRIMARY KEY,
        reported_by INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        content_type VARCHAR(50) NOT NULL, -- 'course', 'comment', 'user', 'lesson'
        content_id INTEGER NOT NULL,
        reason VARCHAR(100) NOT NULL, -- 'spam', 'inappropriate', 'misleading', 'copyright', 'other'
        description TEXT,
        status VARCHAR(50) NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
        resolved_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
        resolution_note TEXT,
        resolved_at TIMESTAMP,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        
        -- Optimized indexes
        INDEX idx_status (status),
        INDEX idx_content_type (content_type),
        INDEX idx_created_at DESC (created_at),
        INDEX idx_reported_by (reported_by)
      );
    `);

    // Content moderation log (audit trail)
    await query(`
      CREATE TABLE IF NOT EXISTS moderation_actions (
        id SERIAL PRIMARY KEY,
        flag_id INTEGER NOT NULL REFERENCES content_flags(id) ON DELETE CASCADE,
        admin_id INTEGER NOT NULL REFERENCES users(id),
        action VARCHAR(50) NOT NULL, -- 'flagged', 'approved', 'rejected', 'note_added'
        details TEXT,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        
        INDEX idx_flag_id (flag_id),
        INDEX idx_admin_id (admin_id)
      );
    `);

    console.log('✅ Content moderation tables initialized');
  } catch (err) {
    console.error('⚠️  Content moderation table initialization failed:', err.message);
    // Don't throw - allow app to continue
  }
}

module.exports = { initializeContentModerationTables };
