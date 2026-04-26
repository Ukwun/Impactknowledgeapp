const { Pool } = require('pg');

// Support both DATABASE_URL (Render) and individual variables (local development)
let pool;
if (process.env.DATABASE_URL) {
  pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  });
} else {
  pool = new Pool({
    user: process.env.DB_USER || 'impactapp_db_user',
    password: process.env.DB_PASSWORD || 'password',
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'impactapp_db',
  });
}

pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

async function initializeDatabase() {
  try {
    // Create tables if they don't exist
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        full_name VARCHAR(255) NOT NULL,
        role VARCHAR(50) DEFAULT 'student',
        profile_picture_url VARCHAR(500),
        bio TEXT,
        phone_number VARCHAR(20),
        location VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS courses (
        id SERIAL PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        category VARCHAR(100),
        instructor_id INTEGER REFERENCES users(id),
        thumbnail_url VARCHAR(500),
        price DECIMAL(10, 2) DEFAULT 0,
        level VARCHAR(50),
        duration_hours INTEGER,
        is_published BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS modules (
        id SERIAL PRIMARY KEY,
        course_id INTEGER NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        order_index INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS lessons (
        id SERIAL PRIMARY KEY,
        module_id INTEGER NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        content_body TEXT,
        content_type VARCHAR(50),
        content_url VARCHAR(500),
        order_index INTEGER,
        duration_minutes INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS enrollments (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        course_id INTEGER NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
        enrollment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        completion_status VARCHAR(50) DEFAULT 'in_progress',
        progress_percentage INTEGER DEFAULT 0,
        UNIQUE(user_id, course_id)
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS achievements (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        icon_url VARCHAR(500),
        points_reward INTEGER DEFAULT 0,
        criteria VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS user_achievements (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        achievement_id INTEGER NOT NULL REFERENCES achievements(id),
        earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, achievement_id)
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS user_points (
        id SERIAL PRIMARY KEY,
        user_id INTEGER UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        total_points INTEGER DEFAULT 0,
        month_points INTEGER DEFAULT 0,
        week_points INTEGER DEFAULT 0,
        last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS membership_tiers (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        monthly_price DECIMAL(10, 2),
        annual_price DECIMAL(10, 2),
        benefits TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS payments (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id),
        type VARCHAR(50),
        item_type VARCHAR(50),
        item_id INTEGER,
        amount DECIMAL(10, 2),
        currency VARCHAR(10),
        reference_id VARCHAR(255) UNIQUE,
        reference VARCHAR(255),
        flutterwave_id VARCHAR(255),
        status VARCHAR(50),
        payment_method VARCHAR(50),
        metadata JSONB,
        email VARCHAR(255),
        phone_number VARCHAR(20),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await pool.query(`
      ALTER TABLE payments ADD COLUMN IF NOT EXISTS item_type VARCHAR(50);
    `).catch(() => {});
    await pool.query(`
      ALTER TABLE payments ADD COLUMN IF NOT EXISTS item_id INTEGER;
    `).catch(() => {});
    await pool.query(`
      ALTER TABLE payments ADD COLUMN IF NOT EXISTS reference VARCHAR(255);
    `).catch(() => {});
    await pool.query(`
      ALTER TABLE payments ADD COLUMN IF NOT EXISTS metadata JSONB;
    `).catch(() => {});
    await pool.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS idx_payments_reference_unique ON payments(reference);
    `).catch(() => {});

    // Activity Tracking Tables
    await pool.query(`
      CREATE TABLE IF NOT EXISTS user_activities (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        activity_type VARCHAR(100) NOT NULL,
        resource_type VARCHAR(100),
        resource_id INTEGER,
        metadata JSONB,
        session_id VARCHAR(255),
        ip_address VARCHAR(45),
        user_agent TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Create indexes for performance
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_user_activities_user_id ON user_activities(user_id);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_user_activities_type ON user_activities(activity_type);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_user_activities_created ON user_activities(created_at);
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS user_analytics (
        id SERIAL PRIMARY KEY,
        user_id INTEGER UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        total_lessons_completed INTEGER DEFAULT 0,
        total_courses_completed INTEGER DEFAULT 0,
        total_quiz_attempts INTEGER DEFAULT 0,
        average_quiz_score DECIMAL(5, 2),
        total_engagement_minutes INTEGER DEFAULT 0,
        total_points_earned INTEGER DEFAULT 0,
        membership_status VARCHAR(50),
        last_active_at TIMESTAMP,
        learning_style VARCHAR(50),
        preferred_category VARCHAR(100),
        estimated_difficulty_level VARCHAR(50),
        churn_risk_score DECIMAL(3, 2),
        engagement_level VARCHAR(50) DEFAULT 'low',
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS lesson_progress (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        lesson_id INTEGER NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
        status VARCHAR(50) DEFAULT 'not_started',
        time_spent_minutes INTEGER DEFAULT 0,
        completion_percentage INTEGER DEFAULT 0,
        last_accessed_at TIMESTAMP,
        completed_at TIMESTAMP,
        UNIQUE(user_id, lesson_id)
      );
    `).catch(() => {});

    // Quiz Tables
    await pool.query(`
      CREATE TABLE IF NOT EXISTS quizzes (
        id SERIAL PRIMARY KEY,
        course_id INTEGER NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
        module_id INTEGER REFERENCES modules(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        passing_score INTEGER DEFAULT 70,
        time_limit_minutes INTEGER,
        max_attempts INTEGER DEFAULT 3,
        show_answers BOOLEAN DEFAULT false,
        shuffle_questions BOOLEAN DEFAULT false,
        is_published BOOLEAN DEFAULT false,
        created_by INTEGER NOT NULL REFERENCES users(id),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS quiz_questions (
        id SERIAL PRIMARY KEY,
        quiz_id INTEGER NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
        question_text TEXT NOT NULL,
        question_type VARCHAR(50) NOT NULL,
        explanation TEXT,
        points INTEGER DEFAULT 1,
        order_index INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS quiz_answers (
        id SERIAL PRIMARY KEY,
        question_id INTEGER NOT NULL REFERENCES quiz_questions(id) ON DELETE CASCADE,
        answer_text TEXT NOT NULL,
        is_correct BOOLEAN DEFAULT false,
        order_index INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS quiz_attempts (
        id SERIAL PRIMARY KEY,
        quiz_id INTEGER NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        score INTEGER,
        percentage_score DECIMAL(5, 2),
        passed BOOLEAN DEFAULT false,
        time_spent_minutes INTEGER,
        started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        completed_at TIMESTAMP,
        metadata JSONB
      );
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS quiz_user_answers (
        id SERIAL PRIMARY KEY,
        attempt_id INTEGER NOT NULL REFERENCES quiz_attempts(id) ON DELETE CASCADE,
        question_id INTEGER NOT NULL REFERENCES quiz_questions(id) ON DELETE CASCADE,
        selected_answer_id INTEGER REFERENCES quiz_answers(id),
        user_answer_text TEXT,
        is_correct BOOLEAN,
        points_earned INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    // Assignment Tables
    await pool.query(`
      CREATE TABLE IF NOT EXISTS assignments (
        id SERIAL PRIMARY KEY,
        course_id INTEGER NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
        module_id INTEGER REFERENCES modules(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        instructions TEXT,
        total_points INTEGER DEFAULT 100,
        due_date TIMESTAMP,
        created_by INTEGER NOT NULL REFERENCES users(id),
        allow_late_submission BOOLEAN DEFAULT false,
        late_penalty_percent INTEGER DEFAULT 0,
        is_published BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS submissions (
        id SERIAL PRIMARY KEY,
        assignment_id INTEGER NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        submission_text TEXT,
        file_url VARCHAR(500),
        submission_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        is_late BOOLEAN DEFAULT false,
        status VARCHAR(50) DEFAULT 'submitted',
        UNIQUE(assignment_id, user_id)
      );
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS submissions_grades (
        id SERIAL PRIMARY KEY,
        submission_id INTEGER NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
        graded_by INTEGER NOT NULL REFERENCES users(id),
        points_earned INTEGER,
        feedback TEXT,
        graded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    // User soft delete and status fields
    await pool.query(`
      ALTER TABLE users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
    `).catch(() => {});

    await pool.query(`
      ALTER TABLE users ADD COLUMN IF NOT EXISTS deactivated_at TIMESTAMP;
    `).catch(() => {});

    await pool.query(`
      ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token TEXT;
    `).catch(() => {});

    // Events Management Tables
    await pool.query(`
      CREATE TABLE IF NOT EXISTS events (
        id SERIAL PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        event_type VARCHAR(100),
        start_date TIMESTAMP NOT NULL,
        end_date TIMESTAMP,
        location VARCHAR(500),
        capacity INTEGER,
        status VARCHAR(50) DEFAULT 'scheduled',
        created_by INTEGER NOT NULL REFERENCES users(id),
        thumbnail_url VARCHAR(500),
        is_published BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS event_registrations (
        id SERIAL PRIMARY KEY,
        event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        attendance_status VARCHAR(50) DEFAULT 'registered',
        notes TEXT,
        UNIQUE(event_id, user_id)
      );
    `).catch(() => {});

    // Achievements & Badges Management
    await pool.query(`
      ALTER TABLE achievements ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
    `).catch(() => {});

    await pool.query(`
      ALTER TABLE achievements ADD COLUMN IF NOT EXISTS unlock_condition VARCHAR(255);
    `).catch(() => {});

    await pool.query(`
      ALTER TABLE achievements ADD COLUMN IF NOT EXISTS category VARCHAR(100);
    `).catch(() => {});

    // Achievement unlock logs
    await pool.query(`
      CREATE TABLE IF NOT EXISTS achievement_unlock_logs (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        achievement_id INTEGER NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
        unlock_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        trigger_event VARCHAR(255),
        metadata JSONB,
        UNIQUE(user_id, achievement_id)
      );
    `).catch(() => {});

    // Create indexes for quiz and assignment queries
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_quizzes_course_id ON quizzes(course_id);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_quiz_attempts_user_id ON quiz_attempts(user_id);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_quiz_attempts_quiz_id ON quiz_attempts(quiz_id);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_assignments_course_id ON assignments(course_id);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_submissions_user_id ON submissions(user_id);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_submissions_assignment_id ON submissions(assignment_id);
    `).catch(() => {});

    // Indexes for events and achievements
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_events_created_by ON events(created_by);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_events_start_date ON events(start_date);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_event_registrations_event_id ON event_registrations(event_id);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_event_registrations_user_id ON event_registrations(user_id);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_achievement_unlock_logs_user_id ON achievement_unlock_logs(user_id);
    `).catch(() => {});

    // Content Moderation Tables
    await pool.query(`
      CREATE TABLE IF NOT EXISTS content_flags (
        id SERIAL PRIMARY KEY,
        reported_by INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        content_type VARCHAR(50) NOT NULL,
        content_id INTEGER NOT NULL,
        reason VARCHAR(100) NOT NULL,
        description TEXT,
        status VARCHAR(50) NOT NULL DEFAULT 'pending',
        resolved_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
        resolution_note TEXT,
        resolved_at TIMESTAMP,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS moderation_actions (
        id SERIAL PRIMARY KEY,
        flag_id INTEGER NOT NULL REFERENCES content_flags(id) ON DELETE CASCADE,
        admin_id INTEGER NOT NULL REFERENCES users(id),
        action VARCHAR(50) NOT NULL,
        details TEXT,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_content_flags_status ON content_flags(status);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_content_flags_reported_by ON content_flags(reported_by);
    `).catch(() => {});

    // Support system tables
    await pool.query(`
      CREATE TABLE IF NOT EXISTS support_tickets (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        category VARCHAR(50) NOT NULL,
        subject VARCHAR(255) NOT NULL,
        description TEXT,
        status VARCHAR(50) NOT NULL DEFAULT 'open',
        priority VARCHAR(50) NOT NULL DEFAULT 'normal',
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS support_messages (
        id SERIAL PRIMARY KEY,
        ticket_id INTEGER NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
        sender_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        message TEXT NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    // Support tables indexes for performance
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_support_tickets_user ON support_tickets(user_id);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_support_messages_ticket ON support_messages(ticket_id);
    `).catch(() => {});

    // In-app notifications
    await pool.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        type VARCHAR(50) DEFAULT 'info',
        action_url VARCHAR(500),
        metadata JSONB,
        is_read BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        read_at TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
    `).catch(() => {});

    // Payment refunds ledger
    await pool.query(`
      CREATE TABLE IF NOT EXISTS payment_refunds (
        id SERIAL PRIMARY KEY,
        payment_id INTEGER NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
        requested_by INTEGER NOT NULL REFERENCES users(id),
        amount DECIMAL(10, 2) NOT NULL,
        reason TEXT,
        status VARCHAR(50) DEFAULT 'approved',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_payment_refunds_payment_id ON payment_refunds(payment_id);
    `).catch(() => {});

    // Parent-child and mentor-mentee relationship workflows
    await pool.query(`
      CREATE TABLE IF NOT EXISTS parent_child_links (
        id SERIAL PRIMARY KEY,
        parent_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        child_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        relationship VARCHAR(50) DEFAULT 'guardian',
        is_active BOOLEAN DEFAULT true,
        created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(parent_user_id, child_user_id)
      );
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_parent_child_links_parent ON parent_child_links(parent_user_id, is_active);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_parent_child_links_child ON parent_child_links(child_user_id, is_active);
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS mentor_mentee_links (
        id SERIAL PRIMARY KEY,
        mentor_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        mentee_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        status VARCHAR(50) DEFAULT 'active',
        goals TEXT,
        notes TEXT,
        next_session_at TIMESTAMP,
        last_session_at TIMESTAMP,
        is_active BOOLEAN DEFAULT true,
        created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(mentor_user_id, mentee_user_id)
      );
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_mentor_mentee_links_mentor ON mentor_mentee_links(mentor_user_id, is_active);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_mentor_mentee_links_mentee ON mentor_mentee_links(mentee_user_id, is_active);
    `).catch(() => {});

    // Role-specific operational resources (mentor, circle_member, progress)
    await pool.query(`
      CREATE TABLE IF NOT EXISTS role_resources (
        id SERIAL PRIMARY KEY,
        namespace VARCHAR(50) NOT NULL,
        owner_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        status VARCHAR(50) DEFAULT 'active',
        metadata JSONB,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_role_resources_ns_owner ON role_resources(namespace, owner_user_id);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_role_resources_status ON role_resources(status);
    `).catch(() => {});

    // Subscription classroom blueprint hierarchy
    await pool.query(`
      CREATE TABLE IF NOT EXISTS classroom_programmes (
        id SERIAL PRIMARY KEY,
        code VARCHAR(100) UNIQUE NOT NULL,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        delivery_model TEXT,
        objectives JSONB,
        online_classroom_structure JSONB,
        curriculum_architecture JSONB,
        live_facilitator_framework JSONB,
        is_active BOOLEAN DEFAULT true,
        created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS classroom_levels (
        id SERIAL PRIMARY KEY,
        programme_id INTEGER NOT NULL REFERENCES classroom_programmes(id) ON DELETE CASCADE,
        name VARCHAR(255) NOT NULL,
        level_order INTEGER DEFAULT 1,
        description TEXT,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(programme_id, name)
      );
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS classroom_cycles (
        id SERIAL PRIMARY KEY,
        level_id INTEGER NOT NULL REFERENCES classroom_levels(id) ON DELETE CASCADE,
        name VARCHAR(255) NOT NULL,
        cycle_type VARCHAR(50) DEFAULT 'term',
        start_date DATE,
        end_date DATE,
        status VARCHAR(50) DEFAULT 'planned',
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(level_id, name)
      );
    `).catch(() => {});

    await pool.query(`
      ALTER TABLE courses ADD COLUMN IF NOT EXISTS programme_id INTEGER REFERENCES classroom_programmes(id) ON DELETE SET NULL;
    `).catch(() => {});

    await pool.query(`
      ALTER TABLE courses ADD COLUMN IF NOT EXISTS classroom_level_id INTEGER REFERENCES classroom_levels(id) ON DELETE SET NULL;
    `).catch(() => {});

    await pool.query(`
      ALTER TABLE modules ADD COLUMN IF NOT EXISTS cycle_id INTEGER REFERENCES classroom_cycles(id) ON DELETE SET NULL;
    `).catch(() => {});

    await pool.query(`
      ALTER TABLE lessons ADD COLUMN IF NOT EXISTS learning_layer VARCHAR(50) DEFAULT 'learn';
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS classroom_activities (
        id SERIAL PRIMARY KEY,
        lesson_id INTEGER NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
        activity_type VARCHAR(100) NOT NULL,
        title VARCHAR(255) NOT NULL,
        instructions TEXT,
        resource_url VARCHAR(500),
        metadata JSONB,
        order_index INTEGER DEFAULT 1,
        is_required BOOLEAN DEFAULT true,
        created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS classroom_live_sessions (
        id SERIAL PRIMARY KEY,
        cycle_id INTEGER NOT NULL REFERENCES classroom_cycles(id) ON DELETE CASCADE,
        module_id INTEGER REFERENCES modules(id) ON DELETE SET NULL,
        title VARCHAR(255) NOT NULL,
        session_type VARCHAR(100) DEFAULT 'facilitator_class',
        facilitator_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
        starts_at TIMESTAMP NOT NULL,
        ends_at TIMESTAMP,
        join_url VARCHAR(500),
        capacity INTEGER,
        status VARCHAR(50) DEFAULT 'scheduled',
        notes TEXT,
        created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS classroom_assessments (
        id SERIAL PRIMARY KEY,
        cycle_id INTEGER NOT NULL REFERENCES classroom_cycles(id) ON DELETE CASCADE,
        module_id INTEGER REFERENCES modules(id) ON DELETE SET NULL,
        assessment_type VARCHAR(100) NOT NULL,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        scoring_method VARCHAR(100) DEFAULT 'points',
        max_score DECIMAL(10, 2),
        pass_threshold DECIMAL(10, 2),
        due_at TIMESTAMP,
        metadata JSONB,
        created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS classroom_showcases (
        id SERIAL PRIMARY KEY,
        cycle_id INTEGER NOT NULL REFERENCES classroom_cycles(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        submission_type VARCHAR(100) DEFAULT 'project',
        visibility VARCHAR(50) DEFAULT 'private',
        created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS classroom_badges (
        id SERIAL PRIMARY KEY,
        assessment_id INTEGER REFERENCES classroom_assessments(id) ON DELETE SET NULL,
        showcase_id INTEGER REFERENCES classroom_showcases(id) ON DELETE SET NULL,
        title VARCHAR(255) NOT NULL,
        badge_type VARCHAR(100) NOT NULL,
        criteria TEXT,
        certificate_template_url VARCHAR(500),
        points_reward INTEGER DEFAULT 0,
        is_active BOOLEAN DEFAULT true,
        created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_classroom_levels_programme ON classroom_levels(programme_id, level_order);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_classroom_cycles_level ON classroom_cycles(level_id, status);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_modules_cycle_id ON modules(cycle_id);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_lessons_learning_layer ON lessons(learning_layer);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_classroom_activities_lesson ON classroom_activities(lesson_id, order_index);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_classroom_live_sessions_cycle ON classroom_live_sessions(cycle_id, starts_at);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_classroom_assessments_cycle ON classroom_assessments(cycle_id, due_at);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_classroom_showcases_cycle ON classroom_showcases(cycle_id);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_classroom_badges_assessment ON classroom_badges(assessment_id);
    `).catch(() => {});

    // Backfill rich content column for existing DBs
    await pool.query(`
      ALTER TABLE lessons ADD COLUMN IF NOT EXISTS content_body TEXT;
    `).catch(() => {});

    await pool.query(`
      ALTER TABLE lessons ADD COLUMN IF NOT EXISTS is_published BOOLEAN DEFAULT true;
    `).catch(() => {});

    // Public content management tables
    await pool.query(`
      CREATE TABLE IF NOT EXISTS platform_partners (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        website_url VARCHAR(500),
        logo_url VARCHAR(500),
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS testimonials (
        id SERIAL PRIMARY KEY,
        quote TEXT NOT NULL,
        author_name VARCHAR(255) NOT NULL,
        author_role VARCHAR(255),
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_platform_partners_active ON platform_partners(is_active);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_testimonials_active ON testimonials(is_active);
    `).catch(() => {});

    // Security and compliance tables
    await pool.query(`
      CREATE TABLE IF NOT EXISTS refresh_tokens (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        token_jti VARCHAR(255) UNIQUE NOT NULL,
        expires_at TIMESTAMP NOT NULL,
        revoked_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id, expires_at);
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS media_assets (
        id SERIAL PRIMARY KEY,
        owner_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        file_name VARCHAR(255) NOT NULL,
        mime_type VARCHAR(120) NOT NULL,
        byte_size BIGINT NOT NULL,
        storage_path TEXT NOT NULL,
        access_scope VARCHAR(30) DEFAULT 'private',
        scan_status VARCHAR(30) DEFAULT 'pending_scan',
        transcoding_status VARCHAR(30),
        thumbnail_path TEXT,
        metadata JSONB,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_media_assets_owner ON media_assets(owner_id, created_at);
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS consent_records (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        consent_type VARCHAR(80) NOT NULL,
        consent_version VARCHAR(40) NOT NULL,
        granted BOOLEAN NOT NULL,
        metadata JSONB,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_consent_records_user ON consent_records(user_id, consent_type, created_at);
    `).catch(() => {});

    await pool.query(`
      CREATE TABLE IF NOT EXISTS audit_logs (
        id SERIAL PRIMARY KEY,
        actor_id INTEGER REFERENCES users(id),
        actor_role VARCHAR(50),
        action VARCHAR(120) NOT NULL,
        entity_type VARCHAR(80),
        entity_id VARCHAR(120),
        ip_address VARCHAR(45),
        user_agent TEXT,
        metadata JSONB,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON audit_logs(actor_id, created_at);
    `).catch(() => {});

    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action, created_at);
    `).catch(() => {});

    console.log('Database tables initialized successfully');
    return pool;
  } catch (err) {
    console.error('Database initialization error:', err);
    throw err;
  }
}

module.exports = {
  pool,
  query: (text, params) => pool.query(text, params),
  initializeDatabase
};
