-- =====================================================
-- Berner Super App - Helper Functions
-- =====================================================
-- Useful database functions for common operations
-- =====================================================

-- =====================================================
-- USER MANAGEMENT FUNCTIONS
-- =====================================================

-- Function to generate ADM code for employees
CREATE OR REPLACE FUNCTION generate_adm_code()
RETURNS VARCHAR AS $$
DECLARE
    year_suffix VARCHAR(2);
    random_number VARCHAR(6);
    adm_code VARCHAR(20);
    code_exists BOOLEAN;
BEGIN
    -- Get last 2 digits of current year
    year_suffix := TO_CHAR(NOW(), 'YY');

    -- Loop until we find a unique code
    LOOP
        -- Generate 6 random digits
        random_number := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');

        -- Construct ADM code
        adm_code := 'ADM' || year_suffix || random_number;

        -- Check if code already exists
        SELECT EXISTS(SELECT 1 FROM users WHERE users.adm_code = adm_code) INTO code_exists;

        -- Exit loop if code is unique
        EXIT WHEN NOT code_exists;
    END LOOP;

    RETURN adm_code;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generate_adm_code IS 'Generates a unique ADM code for employees';

-- =====================================================

-- Function to get user by mobile number
CREATE OR REPLACE FUNCTION get_user_by_mobile(
    p_mobile_number VARCHAR
)
RETURNS TABLE (
    id BIGINT,
    mobile_number VARCHAR,
    adm_code VARCHAR,
    role VARCHAR,
    name VARCHAR,
    nic VARCHAR,
    date_of_birth DATE,
    gender VARCHAR,
    profile_picture_path TEXT,
    is_verified BOOLEAN,
    is_active BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_login_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.id,
        u.mobile_number,
        u.adm_code,
        u.role,
        u.name,
        u.nic,
        u.date_of_birth,
        u.gender,
        u.profile_picture_path,
        u.is_verified,
        u.is_active,
        u.created_at,
        u.updated_at,
        u.last_login_at
    FROM users u
    WHERE u.mobile_number = p_mobile_number;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_user_by_mobile IS 'Retrieves user information by mobile number';

-- =====================================================

-- Function to create or update user
CREATE OR REPLACE FUNCTION upsert_user(
    p_mobile_number VARCHAR,
    p_role VARCHAR,
    p_name VARCHAR DEFAULT NULL,
    p_nic VARCHAR DEFAULT NULL,
    p_date_of_birth DATE DEFAULT NULL,
    p_gender VARCHAR DEFAULT NULL
)
RETURNS BIGINT AS $$
DECLARE
    v_user_id BIGINT;
    v_adm_code VARCHAR(20);
BEGIN
    -- Generate ADM code if role is employee
    IF p_role = 'employee' THEN
        v_adm_code := generate_adm_code();
    END IF;

    -- Insert or update user
    INSERT INTO users (
        mobile_number,
        role,
        adm_code,
        name,
        nic,
        date_of_birth,
        gender,
        is_verified
    ) VALUES (
        p_mobile_number,
        p_role,
        v_adm_code,
        p_name,
        p_nic,
        p_date_of_birth,
        p_gender,
        true
    )
    ON CONFLICT (mobile_number) DO UPDATE SET
        name = COALESCE(EXCLUDED.name, users.name),
        nic = COALESCE(EXCLUDED.nic, users.nic),
        date_of_birth = COALESCE(EXCLUDED.date_of_birth, users.date_of_birth),
        gender = COALESCE(EXCLUDED.gender, users.gender),
        updated_at = NOW()
    RETURNING id INTO v_user_id;

    RETURN v_user_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION upsert_user IS 'Creates a new user or updates existing user';

-- =====================================================

-- Function to update user last login
CREATE OR REPLACE FUNCTION update_user_last_login(
    p_user_id BIGINT
)
RETURNS VOID AS $$
BEGIN
    UPDATE users
    SET last_login_at = NOW()
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_user_last_login IS 'Updates the last login timestamp for a user';

-- =====================================================
-- OTP MANAGEMENT FUNCTIONS
-- =====================================================

-- Function to log OTP attempt
CREATE OR REPLACE FUNCTION log_otp_attempt(
    p_phone VARCHAR,
    p_success BOOLEAN,
    p_error_message TEXT DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS BIGINT AS $$
DECLARE
    v_log_id BIGINT;
BEGIN
    INSERT INTO otp_logs (
        phone,
        success,
        error_message,
        ip_address,
        user_agent
    ) VALUES (
        p_phone,
        p_success,
        p_error_message,
        p_ip_address,
        p_user_agent
    )
    RETURNING id INTO v_log_id;

    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION log_otp_attempt IS 'Logs an OTP attempt';

-- =====================================================

-- Function to check OTP rate limiting
CREATE OR REPLACE FUNCTION check_otp_rate_limit(
    p_phone VARCHAR,
    p_time_window_minutes INTEGER DEFAULT 60,
    p_max_attempts INTEGER DEFAULT 5
)
RETURNS BOOLEAN AS $$
DECLARE
    v_attempt_count INTEGER;
BEGIN
    -- Count OTP attempts in the time window
    SELECT COUNT(*)
    INTO v_attempt_count
    FROM otp_logs
    WHERE phone = p_phone
      AND created_at > NOW() - (p_time_window_minutes || ' minutes')::INTERVAL;

    -- Return true if under the limit, false if over
    RETURN v_attempt_count < p_max_attempts;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_otp_rate_limit IS 'Checks if phone number has exceeded OTP rate limit';

-- =====================================================

-- Function to clean old OTP logs
CREATE OR REPLACE FUNCTION clean_old_otp_logs(
    p_days_old INTEGER DEFAULT 30
)
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    WITH deleted AS (
        DELETE FROM otp_logs
        WHERE created_at < NOW() - (p_days_old || ' days')::INTERVAL
        RETURNING *
    )
    SELECT COUNT(*) INTO v_deleted_count FROM deleted;

    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION clean_old_otp_logs IS 'Deletes OTP logs older than specified days';

-- =====================================================
-- EXPENSE MANAGEMENT FUNCTIONS
-- =====================================================

-- Function to create expense
CREATE OR REPLACE FUNCTION create_expense(
    p_user_id BIGINT,
    p_title VARCHAR,
    p_description TEXT,
    p_amount DECIMAL,
    p_category VARCHAR,
    p_expense_date DATE,
    p_receipt_path TEXT DEFAULT NULL
)
RETURNS BIGINT AS $$
DECLARE
    v_expense_id BIGINT;
BEGIN
    INSERT INTO expenses (
        user_id,
        title,
        description,
        amount,
        category,
        expense_date,
        receipt_path
    ) VALUES (
        p_user_id,
        p_title,
        p_description,
        p_amount,
        p_category,
        p_expense_date,
        p_receipt_path
    )
    RETURNING id INTO v_expense_id;

    RETURN v_expense_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION create_expense IS 'Creates a new expense record';

-- =====================================================

-- Function to approve expense
CREATE OR REPLACE FUNCTION approve_expense(
    p_expense_id BIGINT,
    p_approved_by BIGINT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_success BOOLEAN;
BEGIN
    UPDATE expenses
    SET
        is_approved = true,
        approved_by = p_approved_by,
        approved_at = NOW()
    WHERE id = p_expense_id
      AND is_approved = false;

    -- Check if update was successful
    GET DIAGNOSTICS v_success = ROW_COUNT;

    RETURN v_success > 0;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION approve_expense IS 'Approves an expense record';

-- =====================================================

-- Function to get user expenses summary
CREATE OR REPLACE FUNCTION get_user_expenses_summary(
    p_user_id BIGINT,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    total_expenses DECIMAL,
    approved_expenses DECIMAL,
    pending_expenses DECIMAL,
    expense_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(e.amount), 0) as total_expenses,
        COALESCE(SUM(CASE WHEN e.is_approved THEN e.amount ELSE 0 END), 0) as approved_expenses,
        COALESCE(SUM(CASE WHEN NOT e.is_approved THEN e.amount ELSE 0 END), 0) as pending_expenses,
        COUNT(*) as expense_count
    FROM expenses e
    WHERE e.user_id = p_user_id
      AND (p_start_date IS NULL OR e.expense_date >= p_start_date)
      AND (p_end_date IS NULL OR e.expense_date <= p_end_date);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_user_expenses_summary IS 'Returns expense summary for a user';

-- =====================================================
-- NOTIFICATION FUNCTIONS
-- =====================================================

-- Function to create notification
CREATE OR REPLACE FUNCTION create_notification(
    p_user_id BIGINT,
    p_title VARCHAR,
    p_message TEXT,
    p_type VARCHAR,
    p_related_entity_type VARCHAR DEFAULT NULL,
    p_related_entity_id BIGINT DEFAULT NULL
)
RETURNS BIGINT AS $$
DECLARE
    v_notification_id BIGINT;
BEGIN
    INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        related_entity_type,
        related_entity_id
    ) VALUES (
        p_user_id,
        p_title,
        p_message,
        p_type,
        p_related_entity_type,
        p_related_entity_id
    )
    RETURNING id INTO v_notification_id;

    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION create_notification IS 'Creates a new notification for a user';

-- =====================================================

-- Function to mark notification as read
CREATE OR REPLACE FUNCTION mark_notification_read(
    p_notification_id BIGINT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_success BOOLEAN;
BEGIN
    UPDATE notifications
    SET
        is_read = true,
        read_at = NOW()
    WHERE id = p_notification_id
      AND is_read = false;

    GET DIAGNOSTICS v_success = ROW_COUNT;

    RETURN v_success > 0;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION mark_notification_read IS 'Marks a notification as read';

-- =====================================================

-- Function to mark all user notifications as read
CREATE OR REPLACE FUNCTION mark_all_notifications_read(
    p_user_id BIGINT
)
RETURNS INTEGER AS $$
DECLARE
    v_updated_count INTEGER;
BEGIN
    WITH updated AS (
        UPDATE notifications
        SET
            is_read = true,
            read_at = NOW()
        WHERE user_id = p_user_id
          AND is_read = false
        RETURNING *
    )
    SELECT COUNT(*) INTO v_updated_count FROM updated;

    RETURN v_updated_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION mark_all_notifications_read IS 'Marks all notifications as read for a user';

-- =====================================================
-- STATISTICS FUNCTIONS
-- =====================================================

-- Function to get app statistics
CREATE OR REPLACE FUNCTION get_app_statistics()
RETURNS TABLE (
    total_users BIGINT,
    total_employees BIGINT,
    total_owners BIGINT,
    total_expenses BIGINT,
    total_expense_amount DECIMAL,
    total_otp_attempts BIGINT,
    successful_otp_attempts BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) FILTER (WHERE true) as total_users,
        COUNT(*) FILTER (WHERE role = 'employee') as total_employees,
        COUNT(*) FILTER (WHERE role = 'owner') as total_owners,
        (SELECT COUNT(*) FROM expenses) as total_expenses,
        (SELECT COALESCE(SUM(amount), 0) FROM expenses) as total_expense_amount,
        (SELECT COUNT(*) FROM otp_logs) as total_otp_attempts,
        (SELECT COUNT(*) FROM otp_logs WHERE success = true) as successful_otp_attempts
    FROM users;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_app_statistics IS 'Returns overall app statistics';

-- =====================================================
-- END OF HELPER FUNCTIONS
-- =====================================================
