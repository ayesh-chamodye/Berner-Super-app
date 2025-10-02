-- =====================================================
-- Berner Super App - Database Schema
-- =====================================================
-- This script creates all necessary tables for the Berner Super App
-- with auto-generated numeric UIDs (no Supabase Auth integration)
-- =====================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. USERS TABLE
-- =====================================================
-- Stores user profile information with auto-generated numeric UIDs

CREATE TABLE IF NOT EXISTS users (
    -- Primary Key: Auto-incrementing numeric ID
    id BIGSERIAL PRIMARY KEY,

    -- User Information
    mobile_number VARCHAR(15) UNIQUE NOT NULL,
    adm_code VARCHAR(20) UNIQUE, -- Only for employees (ADM25123456 format)
    role VARCHAR(20) NOT NULL CHECK (role IN ('employee', 'owner')),

    -- Profile Information
    name VARCHAR(100),
    nic VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
    profile_picture_path TEXT,

    -- Status
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ
);

-- Create indexes for better query performance
CREATE INDEX idx_users_mobile_number ON users(mobile_number);
CREATE INDEX idx_users_adm_code ON users(adm_code) WHERE adm_code IS NOT NULL;
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_created_at ON users(created_at);

-- Add comment to table
COMMENT ON TABLE users IS 'Stores user profiles with auto-generated numeric IDs';
COMMENT ON COLUMN users.id IS 'Auto-generated numeric user ID';
COMMENT ON COLUMN users.mobile_number IS 'User phone number (unique identifier for login)';
COMMENT ON COLUMN users.adm_code IS 'Administrative code for employees (format: ADM25XXXXXX)';

-- =====================================================
-- 2. OTP LOGS TABLE
-- =====================================================
-- Tracks all OTP attempts for security and debugging

CREATE TABLE IF NOT EXISTS otp_logs (
    -- Primary Key
    id BIGSERIAL PRIMARY KEY,

    -- OTP Information
    phone VARCHAR(15) NOT NULL,
    success BOOLEAN NOT NULL,
    error_message TEXT,

    -- Metadata
    ip_address INET,
    user_agent TEXT,

    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_otp_logs_phone ON otp_logs(phone);
CREATE INDEX idx_otp_logs_created_at ON otp_logs(created_at);
CREATE INDEX idx_otp_logs_success ON otp_logs(success);

-- Add comment
COMMENT ON TABLE otp_logs IS 'Logs all OTP attempts for security monitoring';

-- =====================================================
-- 3. EXPENSES TABLE
-- =====================================================
-- Stores expense records created by users

CREATE TABLE IF NOT EXISTS expenses (
    -- Primary Key
    id BIGSERIAL PRIMARY KEY,

    -- User Reference
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Expense Details
    title VARCHAR(200) NOT NULL,
    description TEXT,
    amount DECIMAL(15, 2) NOT NULL CHECK (amount >= 0),
    category VARCHAR(50) NOT NULL,

    -- Date Information
    expense_date DATE NOT NULL,

    -- Attachments
    receipt_path TEXT,

    -- Status
    is_approved BOOLEAN DEFAULT false,
    approved_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_expenses_user_id ON expenses(user_id);
CREATE INDEX idx_expenses_expense_date ON expenses(expense_date);
CREATE INDEX idx_expenses_category ON expenses(category);
CREATE INDEX idx_expenses_is_approved ON expenses(is_approved);
CREATE INDEX idx_expenses_created_at ON expenses(created_at);

-- Add comment
COMMENT ON TABLE expenses IS 'Stores expense records created by users';
COMMENT ON COLUMN expenses.user_id IS 'References users.id (numeric)';

-- =====================================================
-- 4. USER SESSIONS TABLE
-- =====================================================
-- Tracks user login sessions (optional for analytics)

CREATE TABLE IF NOT EXISTS user_sessions (
    -- Primary Key
    id BIGSERIAL PRIMARY KEY,

    -- User Reference
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Session Information
    session_token VARCHAR(255) UNIQUE NOT NULL,
    device_info TEXT,
    ip_address INET,
    user_agent TEXT,

    -- Session Status
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMPTZ NOT NULL,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_activity_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_session_token ON user_sessions(session_token);
CREATE INDEX idx_user_sessions_is_active ON user_sessions(is_active);
CREATE INDEX idx_user_sessions_expires_at ON user_sessions(expires_at);

-- Add comment
COMMENT ON TABLE user_sessions IS 'Tracks user login sessions for security';

-- =====================================================
-- 5. NOTIFICATIONS TABLE
-- =====================================================
-- Stores in-app notifications for users

CREATE TABLE IF NOT EXISTS notifications (
    -- Primary Key
    id BIGSERIAL PRIMARY KEY,

    -- User Reference
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Notification Content
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'info', 'warning', 'success', 'error'

    -- Related Entity (optional)
    related_entity_type VARCHAR(50), -- 'expense', 'user', etc.
    related_entity_id BIGINT,

    -- Status
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- Add comment
COMMENT ON TABLE notifications IS 'Stores in-app notifications for users';

-- =====================================================
-- 6. APP SETTINGS TABLE
-- =====================================================
-- Stores app-wide settings and configurations

CREATE TABLE IF NOT EXISTS app_settings (
    -- Primary Key
    id BIGSERIAL PRIMARY KEY,

    -- Setting Information
    key VARCHAR(100) UNIQUE NOT NULL,
    value TEXT,
    description TEXT,

    -- Metadata
    is_public BOOLEAN DEFAULT false, -- Whether setting can be accessed by non-admins

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index
CREATE INDEX idx_app_settings_key ON app_settings(key);

-- Add comment
COMMENT ON TABLE app_settings IS 'Stores application-wide settings';

-- =====================================================
-- FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to tables
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_expenses_updated_at
    BEFORE UPDATE ON expenses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_app_settings_updated_at
    BEFORE UPDATE ON app_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================
-- Note: These policies are designed to work without Supabase Auth
-- You'll need to implement custom authentication in your app

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE otp_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

-- Users table policies (allow service role full access)
CREATE POLICY "Allow service role full access to users"
    ON users
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Users can read their own data"
    ON users
    FOR SELECT
    TO anon, authenticated
    USING (true); -- App will handle filtering

CREATE POLICY "Users can update their own data"
    ON users
    FOR UPDATE
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

-- OTP logs policies
CREATE POLICY "Allow service role full access to otp_logs"
    ON otp_logs
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow anon to insert otp_logs"
    ON otp_logs
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- Expenses policies
CREATE POLICY "Allow service role full access to expenses"
    ON expenses
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Users can manage their own expenses"
    ON expenses
    FOR ALL
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

-- User sessions policies
CREATE POLICY "Allow service role full access to user_sessions"
    ON user_sessions
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Notifications policies
CREATE POLICY "Allow service role full access to notifications"
    ON notifications
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Users can read their own notifications"
    ON notifications
    FOR SELECT
    TO anon, authenticated
    USING (true);

CREATE POLICY "Users can update their own notifications"
    ON notifications
    FOR UPDATE
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

-- App settings policies
CREATE POLICY "Allow service role full access to app_settings"
    ON app_settings
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Anyone can read public settings"
    ON app_settings
    FOR SELECT
    TO anon, authenticated
    USING (is_public = true);

-- =====================================================
-- INITIAL DATA
-- =====================================================

-- Insert default app settings
INSERT INTO app_settings (key, value, description, is_public) VALUES
    ('app_version', '1.0.0', 'Current application version', true),
    ('maintenance_mode', 'false', 'Enable maintenance mode', true),
    ('otp_expiry_minutes', '5', 'OTP expiry time in minutes', false),
    ('max_otp_attempts', '3', 'Maximum OTP attempts per hour', false)
ON CONFLICT (key) DO NOTHING;

-- =====================================================
-- END OF SCHEMA
-- =====================================================
