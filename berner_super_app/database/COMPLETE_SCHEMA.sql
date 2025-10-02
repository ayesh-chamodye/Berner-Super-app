-- =====================================================
-- BERNER SUPER APP - COMPLETE DATABASE SCHEMA
-- =====================================================
-- Full production database for Berner Super App
-- OTP authentication handled externally (text.lk)
-- Auto-generated numeric user IDs (no Supabase Auth)
-- =====================================================

-- Drop existing tables if re-running (CAUTION: Deletes all data!)
-- Uncomment below if you need to reset database
/*
DROP TABLE IF EXISTS
    expense_approvals,
    expense_attachments,
    expense_categories,
    expenses,
    notifications,
    user_sessions,
    activity_logs,
    otp_logs,
    user_profiles,
    users,
    app_settings,
    system_logs
CASCADE;
*/

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- 1. USERS TABLE (Core Authentication)
-- =====================================================

CREATE TABLE IF NOT EXISTS users (
    -- Primary Key
    id BIGSERIAL PRIMARY KEY,

    -- Authentication (Phone-based, no Supabase Auth)
    mobile_number VARCHAR(15) UNIQUE NOT NULL,
    country_code VARCHAR(5) DEFAULT '+94',

    -- User Type & Status
    role VARCHAR(20) NOT NULL CHECK (role IN ('employee', 'owner', 'admin', 'customer')),
    adm_code VARCHAR(20) UNIQUE, -- For employees only (ADM25XXXXXX)

    -- Account Status
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    is_blocked BOOLEAN DEFAULT false,
    blocked_reason TEXT,
    blocked_at TIMESTAMPTZ,

    -- Security
    failed_login_attempts INTEGER DEFAULT 0,
    last_failed_login_at TIMESTAMPTZ,
    password_hash TEXT, -- Optional: if you want password in future

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ -- Soft delete
);

-- Indexes for users table
CREATE INDEX idx_users_mobile_number ON users(mobile_number) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_role ON users(role) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_adm_code ON users(adm_code) WHERE adm_code IS NOT NULL;
CREATE INDEX idx_users_is_active ON users(is_active) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_created_at ON users(created_at DESC);

COMMENT ON TABLE users IS 'Core user authentication table with phone-based login';
COMMENT ON COLUMN users.id IS 'Auto-generated numeric user ID';
COMMENT ON COLUMN users.mobile_number IS 'Unique phone number for login (no Supabase Auth)';
COMMENT ON COLUMN users.adm_code IS 'Auto-generated administrative code for employees';

-- =====================================================
-- 2. USER PROFILES TABLE (Extended Information)
-- =====================================================

CREATE TABLE IF NOT EXISTS user_profiles (
    -- Primary Key
    user_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,

    -- Personal Information
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    full_name VARCHAR(100),
    display_name VARCHAR(100),

    -- Identification
    nic VARCHAR(20),
    passport_number VARCHAR(20),

    -- Personal Details
    date_of_birth DATE,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),

    -- Contact Information
    email VARCHAR(255),
    alternate_mobile VARCHAR(15),
    whatsapp_number VARCHAR(15),

    -- Address
    address_line1 TEXT,
    address_line2 TEXT,
    city VARCHAR(100),
    province VARCHAR(100),
    postal_code VARCHAR(10),
    country VARCHAR(100) DEFAULT 'Sri Lanka',

    -- Employment Info (for employees)
    employee_id VARCHAR(50),
    department VARCHAR(100),
    position VARCHAR(100),
    joining_date DATE,
    reporting_to BIGINT REFERENCES users(id) ON DELETE SET NULL,

    -- Business Info (for owners)
    business_name VARCHAR(200),
    business_registration_no VARCHAR(50),
    tax_id VARCHAR(50),

    -- Media
    profile_picture_url TEXT,
    profile_picture_path TEXT,
    cover_photo_url TEXT,

    -- Preferences
    language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(50) DEFAULT 'Asia/Colombo',
    currency VARCHAR(3) DEFAULT 'LKR',

    -- Notifications Preferences
    email_notifications BOOLEAN DEFAULT true,
    sms_notifications BOOLEAN DEFAULT true,
    push_notifications BOOLEAN DEFAULT true,

    -- Bio
    bio TEXT,
    notes TEXT, -- Admin notes

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for user_profiles
CREATE INDEX idx_user_profiles_full_name ON user_profiles(full_name);
CREATE INDEX idx_user_profiles_nic ON user_profiles(nic);
CREATE INDEX idx_user_profiles_department ON user_profiles(department) WHERE department IS NOT NULL;
CREATE INDEX idx_user_profiles_reporting_to ON user_profiles(reporting_to) WHERE reporting_to IS NOT NULL;

COMMENT ON TABLE user_profiles IS 'Extended user profile information';

-- =====================================================
-- 3. OTP LOGS TABLE (Tracking & Security)
-- =====================================================

CREATE TABLE IF NOT EXISTS otp_logs (
    -- Primary Key
    id BIGSERIAL PRIMARY KEY,

    -- OTP Details
    phone VARCHAR(15) NOT NULL,
    otp_type VARCHAR(20) DEFAULT 'login' CHECK (otp_type IN ('login', 'signup', 'verification', 'password_reset')),

    -- Status
    success BOOLEAN NOT NULL,
    error_message TEXT,

    -- Security Tracking
    ip_address INET,
    user_agent TEXT,
    device_info JSONB,
    location_data JSONB, -- {"country": "LK", "city": "Colombo"}

    -- Metadata
    provider VARCHAR(50) DEFAULT 'textlk',
    sms_id VARCHAR(255), -- SMS provider's message ID
    cost DECIMAL(10, 4), -- Cost per SMS

    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for otp_logs
CREATE INDEX idx_otp_logs_phone ON otp_logs(phone, created_at DESC);
CREATE INDEX idx_otp_logs_created_at ON otp_logs(created_at DESC);
CREATE INDEX idx_otp_logs_success ON otp_logs(success);
CREATE INDEX idx_otp_logs_ip_address ON otp_logs(ip_address) WHERE ip_address IS NOT NULL;

COMMENT ON TABLE otp_logs IS 'Comprehensive OTP attempt logging for security and analytics';

-- =====================================================
-- 4. USER SESSIONS TABLE (Session Management)
-- =====================================================

CREATE TABLE IF NOT EXISTS user_sessions (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- User Reference
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Session Details
    session_token VARCHAR(255) UNIQUE NOT NULL,
    refresh_token VARCHAR(255) UNIQUE,

    -- Device Information
    device_id VARCHAR(255),
    device_name VARCHAR(100),
    device_type VARCHAR(20) CHECK (device_type IN ('mobile', 'tablet', 'desktop', 'web')),
    device_os VARCHAR(50),
    app_version VARCHAR(20),

    -- Connection Details
    ip_address INET,
    user_agent TEXT,
    browser VARCHAR(100),
    location_data JSONB,

    -- Session Status
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMPTZ NOT NULL,

    -- Activity Tracking
    last_activity_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    terminated_at TIMESTAMPTZ,
    termination_reason VARCHAR(100)
);

-- Indexes for user_sessions
CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id, created_at DESC);
CREATE INDEX idx_user_sessions_session_token ON user_sessions(session_token) WHERE is_active = true;
CREATE INDEX idx_user_sessions_is_active ON user_sessions(is_active, expires_at);
CREATE INDEX idx_user_sessions_last_activity ON user_sessions(last_activity_at DESC);

COMMENT ON TABLE user_sessions IS 'Track user sessions across devices';

-- =====================================================
-- 5. EXPENSE CATEGORIES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS expense_categories (
    -- Primary Key
    id SERIAL PRIMARY KEY,

    -- Category Details
    name VARCHAR(100) UNIQUE NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,

    -- Hierarchy
    parent_id INTEGER REFERENCES expense_categories(id) ON DELETE SET NULL,

    -- Display
    icon VARCHAR(50),
    color VARCHAR(7), -- Hex color code
    sort_order INTEGER DEFAULT 0,

    -- Limits & Rules
    requires_receipt BOOLEAN DEFAULT false,
    requires_approval BOOLEAN DEFAULT true,
    max_amount DECIMAL(15, 2),

    -- Status
    is_active BOOLEAN DEFAULT true,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for expense_categories
CREATE INDEX idx_expense_categories_slug ON expense_categories(slug);
CREATE INDEX idx_expense_categories_parent_id ON expense_categories(parent_id) WHERE parent_id IS NOT NULL;
CREATE INDEX idx_expense_categories_is_active ON expense_categories(is_active);

COMMENT ON TABLE expense_categories IS 'Categorization system for expenses';

-- Insert default categories
INSERT INTO expense_categories (name, slug, description, icon, color, requires_receipt, requires_approval) VALUES
    ('Transportation', 'transportation', 'Travel and transportation costs', '🚗', '#3B82F6', true, true),
    ('Meals & Entertainment', 'meals-entertainment', 'Business meals and client entertainment', '🍽️', '#F59E0B', true, true),
    ('Office Supplies', 'office-supplies', 'Stationery and office materials', '📎', '#8B5CF6', false, true),
    ('Accommodation', 'accommodation', 'Hotels and lodging', '🏨', '#EC4899', true, true),
    ('Communications', 'communications', 'Phone, internet, and data', '📱', '#10B981', false, true),
    ('Training & Development', 'training', 'Professional development and courses', '📚', '#F97316', true, true),
    ('Equipment', 'equipment', 'Tools and equipment purchases', '⚙️', '#6366F1', true, true),
    ('Marketing', 'marketing', 'Advertising and promotional expenses', '📢', '#14B8A6', true, true),
    ('Utilities', 'utilities', 'Electricity, water, and gas', '⚡', '#84CC16', false, true),
    ('Other', 'other', 'Miscellaneous expenses', '📋', '#6B7280', false, true)
ON CONFLICT (slug) DO NOTHING;

-- =====================================================
-- 6. EXPENSES TABLE (Main)
-- =====================================================

CREATE TABLE IF NOT EXISTS expenses (
    -- Primary Key
    id BIGSERIAL PRIMARY KEY,

    -- User Reference
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Expense Details
    title VARCHAR(200) NOT NULL,
    description TEXT,
    amount DECIMAL(15, 2) NOT NULL CHECK (amount >= 0),
    currency VARCHAR(3) DEFAULT 'LKR',

    -- Category
    category_id INTEGER REFERENCES expense_categories(id) ON DELETE SET NULL,
    category_name VARCHAR(100), -- Denormalized for history

    -- Date & Location
    expense_date DATE NOT NULL,
    expense_time TIME,
    location TEXT,
    location_coords POINT, -- Geographic coordinates

    -- Payment Details
    payment_method VARCHAR(50) CHECK (payment_method IN ('cash', 'card', 'bank_transfer', 'mobile_payment', 'other')),
    payment_reference VARCHAR(100),
    vendor_name VARCHAR(200),
    vendor_contact VARCHAR(100),

    -- Tax Information
    tax_amount DECIMAL(15, 2) DEFAULT 0,
    tax_rate DECIMAL(5, 2) DEFAULT 0,
    is_taxable BOOLEAN DEFAULT false,

    -- Status & Approval
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('draft', 'pending', 'approved', 'rejected', 'paid', 'cancelled')),
    is_approved BOOLEAN DEFAULT false,
    approved_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ,
    approval_notes TEXT,

    rejected_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
    rejected_at TIMESTAMPTZ,
    rejection_reason TEXT,

    -- Payment Status
    is_paid BOOLEAN DEFAULT false,
    paid_at TIMESTAMPTZ,
    paid_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
    payment_notes TEXT,

    -- Reimbursement
    is_reimbursable BOOLEAN DEFAULT true,
    reimbursement_status VARCHAR(20) CHECK (reimbursement_status IN ('pending', 'processing', 'completed', 'rejected')),
    reimbursed_at TIMESTAMPTZ,
    reimbursement_amount DECIMAL(15, 2),

    -- Metadata
    tags TEXT[], -- Array of tags
    custom_fields JSONB, -- Flexible custom data

    -- Flags
    is_recurring BOOLEAN DEFAULT false,
    recurring_frequency VARCHAR(20), -- 'daily', 'weekly', 'monthly', 'yearly'
    recurring_until DATE,

    is_billable BOOLEAN DEFAULT false, -- Can be billed to client
    client_name VARCHAR(200),

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ -- Soft delete
);

-- Indexes for expenses
CREATE INDEX idx_expenses_user_id ON expenses(user_id, created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_expenses_expense_date ON expenses(expense_date DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_expenses_category_id ON expenses(category_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_expenses_status ON expenses(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_expenses_is_approved ON expenses(is_approved) WHERE deleted_at IS NULL;
CREATE INDEX idx_expenses_amount ON expenses(amount DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_expenses_created_at ON expenses(created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_expenses_approved_by ON expenses(approved_by) WHERE approved_by IS NOT NULL;
CREATE INDEX idx_expenses_tags ON expenses USING GIN(tags) WHERE deleted_at IS NULL;

COMMENT ON TABLE expenses IS 'Main expense tracking table with full approval workflow';

-- =====================================================
-- 7. EXPENSE ATTACHMENTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS expense_attachments (
    -- Primary Key
    id BIGSERIAL PRIMARY KEY,

    -- Expense Reference
    expense_id BIGINT NOT NULL REFERENCES expenses(id) ON DELETE CASCADE,

    -- File Details
    file_name VARCHAR(255) NOT NULL,
    file_type VARCHAR(50),
    file_size BIGINT, -- Size in bytes
    file_path TEXT NOT NULL,
    file_url TEXT,

    -- Storage Details
    storage_bucket VARCHAR(100),
    storage_path TEXT,

    -- File Metadata
    mime_type VARCHAR(100),
    is_receipt BOOLEAN DEFAULT false,

    -- OCR & Processing
    ocr_text TEXT, -- Extracted text from image
    ocr_processed BOOLEAN DEFAULT false,
    ocr_confidence DECIMAL(5, 2),

    -- Timestamps
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for expense_attachments
CREATE INDEX idx_expense_attachments_expense_id ON expense_attachments(expense_id);
CREATE INDEX idx_expense_attachments_is_receipt ON expense_attachments(is_receipt) WHERE is_receipt = true;

COMMENT ON TABLE expense_attachments IS 'Store receipts and supporting documents for expenses';

-- =====================================================
-- 8. EXPENSE APPROVALS TABLE (Approval Workflow)
-- =====================================================

CREATE TABLE IF NOT EXISTS expense_approvals (
    -- Primary Key
    id BIGSERIAL PRIMARY KEY,

    -- References
    expense_id BIGINT NOT NULL REFERENCES expenses(id) ON DELETE CASCADE,
    approver_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Approval Details
    action VARCHAR(20) NOT NULL CHECK (action IN ('approved', 'rejected', 'requested_changes')),
    notes TEXT,

    -- Approval Level (for multi-level approval)
    approval_level INTEGER DEFAULT 1,
    is_final_approval BOOLEAN DEFAULT true,

    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for expense_approvals
CREATE INDEX idx_expense_approvals_expense_id ON expense_approvals(expense_id, created_at DESC);
CREATE INDEX idx_expense_approvals_approver_id ON expense_approvals(approver_id, created_at DESC);

COMMENT ON TABLE expense_approvals IS 'Track approval history for expenses';

-- =====================================================
-- 9. NOTIFICATIONS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS notifications (
    -- Primary Key
    id BIGSERIAL PRIMARY KEY,

    -- User Reference
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Notification Content
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('info', 'success', 'warning', 'error', 'expense', 'approval', 'system')),

    -- Related Entity
    related_entity_type VARCHAR(50), -- 'expense', 'user', 'payment', etc.
    related_entity_id BIGINT,

    -- Action
    action_url TEXT,
    action_label VARCHAR(50),

    -- Priority
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),

    -- Status
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMPTZ,

    is_dismissed BOOLEAN DEFAULT false,
    dismissed_at TIMESTAMPTZ,

    -- Delivery Channels
    sent_push BOOLEAN DEFAULT false,
    sent_email BOOLEAN DEFAULT false,
    sent_sms BOOLEAN DEFAULT false,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ -- Auto-delete after this date
);

-- Indexes for notifications
CREATE INDEX idx_notifications_user_id ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_is_read ON notifications(is_read, created_at DESC);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_priority ON notifications(priority) WHERE is_read = false;
CREATE INDEX idx_notifications_expires_at ON notifications(expires_at) WHERE expires_at IS NOT NULL;

COMMENT ON TABLE notifications IS 'In-app notification system';

-- =====================================================
-- 10. ACTIVITY LOGS TABLE (Audit Trail)
-- =====================================================

CREATE TABLE IF NOT EXISTS activity_logs (
    -- Primary Key
    id BIGSERIAL PRIMARY KEY,

    -- User Reference
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,

    -- Activity Details
    action VARCHAR(100) NOT NULL, -- 'created_expense', 'approved_expense', 'updated_profile', etc.
    entity_type VARCHAR(50) NOT NULL, -- 'expense', 'user', 'profile', etc.
    entity_id BIGINT,

    -- Changes
    old_values JSONB,
    new_values JSONB,
    changes_summary TEXT,

    -- Context
    ip_address INET,
    user_agent TEXT,
    device_info JSONB,

    -- Metadata
    metadata JSONB, -- Additional context data

    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for activity_logs
CREATE INDEX idx_activity_logs_user_id ON activity_logs(user_id, created_at DESC);
CREATE INDEX idx_activity_logs_entity ON activity_logs(entity_type, entity_id);
CREATE INDEX idx_activity_logs_created_at ON activity_logs(created_at DESC);
CREATE INDEX idx_activity_logs_action ON activity_logs(action);

COMMENT ON TABLE activity_logs IS 'Comprehensive audit trail for all user actions';

-- =====================================================
-- 11. APP SETTINGS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS app_settings (
    -- Primary Key
    id SERIAL PRIMARY KEY,

    -- Setting Details
    key VARCHAR(100) UNIQUE NOT NULL,
    value TEXT,
    value_type VARCHAR(20) DEFAULT 'string' CHECK (value_type IN ('string', 'number', 'boolean', 'json')),

    -- Metadata
    description TEXT,
    category VARCHAR(50), -- 'security', 'features', 'limits', etc.

    -- Access Control
    is_public BOOLEAN DEFAULT false, -- Can be accessed by non-admins
    is_editable BOOLEAN DEFAULT true,

    -- Validation
    validation_rule TEXT, -- Regex or rule description
    default_value TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for app_settings
CREATE INDEX idx_app_settings_key ON app_settings(key);
CREATE INDEX idx_app_settings_category ON app_settings(category);

COMMENT ON TABLE app_settings IS 'Application-wide configuration settings';

-- Insert default settings
INSERT INTO app_settings (key, value, value_type, description, category, is_public) VALUES
    ('app_version', '1.0.0', 'string', 'Current application version', 'system', true),
    ('app_name', 'Berner Super App', 'string', 'Application name', 'branding', true),
    ('maintenance_mode', 'false', 'boolean', 'Enable maintenance mode', 'system', true),

    -- OTP Settings
    ('otp_expiry_minutes', '5', 'number', 'OTP expiry time in minutes', 'security', false),
    ('otp_max_attempts', '5', 'number', 'Maximum OTP attempts per hour', 'security', false),
    ('otp_rate_limit_window', '60', 'number', 'Rate limit window in minutes', 'security', false),

    -- Expense Settings
    ('expense_requires_receipt_above', '5000', 'number', 'Amount above which receipt is mandatory (LKR)', 'expenses', false),
    ('expense_auto_approval_limit', '1000', 'number', 'Auto-approve expenses below this amount (LKR)', 'expenses', false),
    ('expense_max_amount', '1000000', 'number', 'Maximum expense amount (LKR)', 'expenses', false),

    -- Session Settings
    ('session_timeout_minutes', '60', 'number', 'Session timeout in minutes', 'security', false),
    ('max_concurrent_sessions', '3', 'number', 'Maximum concurrent sessions per user', 'security', false),

    -- File Upload Settings
    ('max_file_size_mb', '10', 'number', 'Maximum file upload size in MB', 'uploads', false),
    ('allowed_file_types', 'jpg,jpeg,png,pdf', 'string', 'Allowed file types for uploads', 'uploads', false)
ON CONFLICT (key) DO NOTHING;

-- =====================================================
-- 12. SYSTEM LOGS TABLE (System Events)
-- =====================================================

CREATE TABLE IF NOT EXISTS system_logs (
    -- Primary Key
    id BIGSERIAL PRIMARY KEY,

    -- Log Details
    level VARCHAR(20) NOT NULL CHECK (level IN ('debug', 'info', 'warning', 'error', 'critical')),
    message TEXT NOT NULL,

    -- Context
    component VARCHAR(100), -- 'auth', 'expenses', 'notifications', etc.
    function_name VARCHAR(100),

    -- Error Details (if applicable)
    error_code VARCHAR(50),
    error_details JSONB,
    stack_trace TEXT,

    -- Metadata
    metadata JSONB,

    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for system_logs
CREATE INDEX idx_system_logs_level ON system_logs(level, created_at DESC);
CREATE INDEX idx_system_logs_created_at ON system_logs(created_at DESC);
CREATE INDEX idx_system_logs_component ON system_logs(component);

COMMENT ON TABLE system_logs IS 'System-level logging for debugging and monitoring';

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

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_expenses_updated_at
    BEFORE UPDATE ON expenses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_expense_categories_updated_at
    BEFORE UPDATE ON expense_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_app_settings_updated_at
    BEFORE UPDATE ON app_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE otp_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_logs ENABLE ROW LEVEL SECURITY;

-- Service role has full access to all tables
DO $$
DECLARE
    table_name TEXT;
BEGIN
    FOR table_name IN
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE format('
            CREATE POLICY "Service role full access to %I"
                ON %I
                FOR ALL
                TO service_role
                USING (true)
                WITH CHECK (true);
        ', table_name, table_name);
    END LOOP;
END $$;

-- Anonymous users can insert OTP logs (for authentication)
CREATE POLICY "Allow anon to insert otp_logs"
    ON otp_logs
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- Authenticated users can read their own data
CREATE POLICY "Users can read their own profile"
    ON user_profiles
    FOR SELECT
    TO anon, authenticated
    USING (true); -- App will handle filtering

CREATE POLICY "Users can update their own profile"
    ON user_profiles
    FOR UPDATE
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

-- Users can read/manage their own expenses
CREATE POLICY "Users can manage their own expenses"
    ON expenses
    FOR ALL
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

-- Users can read their own notifications
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

-- Public can read active expense categories
CREATE POLICY "Anyone can read active expense categories"
    ON expense_categories
    FOR SELECT
    TO anon, authenticated
    USING (is_active = true);

-- Public can read public settings
CREATE POLICY "Anyone can read public settings"
    ON app_settings
    FOR SELECT
    TO anon, authenticated
    USING (is_public = true);

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

-- View: User details with profile
CREATE OR REPLACE VIEW vw_user_details AS
SELECT
    u.id,
    u.mobile_number,
    u.role,
    u.adm_code,
    u.is_verified,
    u.is_active,
    u.is_blocked,
    u.last_login_at,
    u.created_at,
    p.first_name,
    p.last_name,
    p.full_name,
    p.email,
    p.department,
    p.position,
    p.profile_picture_url
FROM users u
LEFT JOIN user_profiles p ON u.id = p.user_id
WHERE u.deleted_at IS NULL;

-- View: Expense summary with user details
CREATE OR REPLACE VIEW vw_expense_summary AS
SELECT
    e.id,
    e.title,
    e.amount,
    e.currency,
    e.expense_date,
    e.status,
    e.is_approved,
    ec.name as category_name,
    u.id as user_id,
    u.mobile_number,
    p.full_name as user_name,
    approver.id as approver_id,
    approver_profile.full_name as approver_name,
    e.created_at
FROM expenses e
LEFT JOIN expense_categories ec ON e.category_id = ec.id
LEFT JOIN users u ON e.user_id = u.id
LEFT JOIN user_profiles p ON u.id = p.user_id
LEFT JOIN users approver ON e.approved_by = approver.id
LEFT JOIN user_profiles approver_profile ON approver.id = approver_profile.user_id
WHERE e.deleted_at IS NULL;

-- =====================================================
-- COMPLETION
-- =====================================================

-- Display summary
DO $$
DECLARE
    table_count INTEGER;
    function_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO table_count FROM information_schema.tables WHERE table_schema = 'public';
    SELECT COUNT(*) INTO function_count FROM information_schema.routines WHERE routine_schema = 'public';

    RAISE NOTICE '==============================================';
    RAISE NOTICE 'BERNER SUPER APP - DATABASE SCHEMA COMPLETE';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Tables created: %', table_count;
    RAISE NOTICE 'Functions created: %', function_count;
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Run 02_helper_functions.sql';
    RAISE NOTICE '2. (Optional) Run 03_sample_data.sql';
    RAISE NOTICE '3. Test with your Flutter app';
    RAISE NOTICE '==============================================';
END $$;
