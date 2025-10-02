-- =====================================================
-- BERNER SUPER APP - ADVANCED HELPER FUNCTIONS
-- =====================================================
-- Additional helper functions for complex operations
-- =====================================================

-- =====================================================
-- EXPENSE MANAGEMENT FUNCTIONS
-- =====================================================

-- Function to get pending expenses for approval
CREATE OR REPLACE FUNCTION get_pending_expenses_for_approver(
    p_approver_id BIGINT
)
RETURNS TABLE (
    expense_id BIGINT,
    title VARCHAR,
    amount DECIMAL,
    expense_date DATE,
    user_name TEXT,
    days_pending INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.id,
        e.title,
        e.amount,
        e.expense_date,
        up.full_name,
        EXTRACT(DAY FROM NOW() - e.created_at)::INTEGER as days_pending
    FROM expenses e
    JOIN users u ON e.user_id = u.id
    JOIN user_profiles up ON u.id = up.user_id
    WHERE e.status = 'pending'
      AND e.deleted_at IS NULL
      AND (
          -- Owner/Admin can approve all
          (SELECT role FROM users WHERE id = p_approver_id) IN ('owner', 'admin')
          OR
          -- Manager can approve their team's expenses
          up.reporting_to = p_approver_id
      )
    ORDER BY e.created_at ASC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_pending_expenses_for_approver IS 'Get expenses pending approval for a specific approver';

-- =====================================================

-- Function to approve expense
CREATE OR REPLACE FUNCTION approve_expense_advanced(
    p_expense_id BIGINT,
    p_approver_id BIGINT,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_expense expenses%ROWTYPE;
    v_approver users%ROWTYPE;
    v_user users%ROWTYPE;
BEGIN
    -- Get expense details
    SELECT * INTO v_expense FROM expenses WHERE id = p_expense_id AND deleted_at IS NULL;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Expense not found');
    END IF;

    -- Get approver details
    SELECT * INTO v_approver FROM users WHERE id = p_approver_id AND is_active = true;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Approver not found or inactive');
    END IF;

    -- Check if approver has permission (owner/admin)
    IF v_approver.role NOT IN ('owner', 'admin') THEN
        RETURN jsonb_build_object('success', false, 'message', 'Insufficient permissions');
    END IF;

    -- Check if already approved
    IF v_expense.is_approved THEN
        RETURN jsonb_build_object('success', false, 'message', 'Expense already approved');
    END IF;

    -- Update expense
    UPDATE expenses SET
        status = 'approved',
        is_approved = true,
        approved_by = p_approver_id,
        approved_at = NOW(),
        approval_notes = p_notes,
        updated_at = NOW()
    WHERE id = p_expense_id;

    -- Log approval
    INSERT INTO expense_approvals (expense_id, approver_id, action, notes)
    VALUES (p_expense_id, p_approver_id, 'approved', p_notes);

    -- Get user for notification
    SELECT * INTO v_user FROM users WHERE id = v_expense.user_id;

    -- Create notification
    INSERT INTO notifications (user_id, title, message, type, related_entity_type, related_entity_id)
    VALUES (
        v_expense.user_id,
        'Expense Approved',
        format('Your expense "%s" of LKR %.2f has been approved', v_expense.title, v_expense.amount),
        'success',
        'expense',
        p_expense_id
    );

    -- Log activity
    INSERT INTO activity_logs (user_id, action, entity_type, entity_id, changes_summary)
    VALUES (
        p_approver_id,
        'approved_expense',
        'expense',
        p_expense_id,
        format('Approved expense: %s (LKR %.2f)', v_expense.title, v_expense.amount)
    );

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Expense approved successfully',
        'expense_id', p_expense_id
    );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION approve_expense_advanced IS 'Approve expense with full workflow (notifications, logging)';

-- =====================================================

-- Function to reject expense
CREATE OR REPLACE FUNCTION reject_expense(
    p_expense_id BIGINT,
    p_rejector_id BIGINT,
    p_reason TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_expense expenses%ROWTYPE;
BEGIN
    -- Get expense
    SELECT * INTO v_expense FROM expenses WHERE id = p_expense_id AND deleted_at IS NULL;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Expense not found');
    END IF;

    -- Update expense
    UPDATE expenses SET
        status = 'rejected',
        is_approved = false,
        rejected_by = p_rejector_id,
        rejected_at = NOW(),
        rejection_reason = p_reason,
        updated_at = NOW()
    WHERE id = p_expense_id;

    -- Log rejection
    INSERT INTO expense_approvals (expense_id, approver_id, action, notes)
    VALUES (p_expense_id, p_rejector_id, 'rejected', p_reason);

    -- Create notification
    INSERT INTO notifications (user_id, title, message, type, related_entity_type, related_entity_id, priority)
    VALUES (
        v_expense.user_id,
        'Expense Rejected',
        format('Your expense "%s" has been rejected. Reason: %s', v_expense.title, p_reason),
        'warning',
        'expense',
        p_expense_id,
        'high'
    );

    RETURN jsonb_build_object('success', true, 'message', 'Expense rejected');
END;
$$ LANGUAGE plpgsql;

-- =====================================================

-- Function to get expense statistics for user
CREATE OR REPLACE FUNCTION get_user_expense_stats(
    p_user_id BIGINT,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_stats JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_expenses', COUNT(*),
        'total_amount', COALESCE(SUM(amount), 0),
        'approved_count', COUNT(*) FILTER (WHERE is_approved = true),
        'approved_amount', COALESCE(SUM(amount) FILTER (WHERE is_approved = true), 0),
        'pending_count', COUNT(*) FILTER (WHERE status = 'pending'),
        'pending_amount', COALESCE(SUM(amount) FILTER (WHERE status = 'pending'), 0),
        'rejected_count', COUNT(*) FILTER (WHERE status = 'rejected'),
        'rejected_amount', COALESCE(SUM(amount) FILTER (WHERE status = 'rejected'), 0),
        'average_expense', COALESCE(AVG(amount), 0)
    ) INTO v_stats
    FROM expenses
    WHERE user_id = p_user_id
      AND deleted_at IS NULL
      AND (p_start_date IS NULL OR expense_date >= p_start_date)
      AND (p_end_date IS NULL OR expense_date <= p_end_date);

    RETURN v_stats;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_user_expense_stats IS 'Get comprehensive expense statistics for a user';

-- =====================================================

-- Function to get expenses by category
CREATE OR REPLACE FUNCTION get_expenses_by_category(
    p_user_id BIGINT DEFAULT NULL,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    category_name VARCHAR,
    expense_count BIGINT,
    total_amount DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(ec.name, 'Uncategorized') as category_name,
        COUNT(e.id) as expense_count,
        SUM(e.amount) as total_amount
    FROM expenses e
    LEFT JOIN expense_categories ec ON e.category_id = ec.id
    WHERE e.deleted_at IS NULL
      AND (p_user_id IS NULL OR e.user_id = p_user_id)
      AND (p_start_date IS NULL OR e.expense_date >= p_start_date)
      AND (p_end_date IS NULL OR e.expense_date <= p_end_date)
    GROUP BY ec.name
    ORDER BY total_amount DESC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- USER MANAGEMENT FUNCTIONS
-- =====================================================

-- Function to create complete user profile
CREATE OR REPLACE FUNCTION create_user_with_profile(
    p_mobile_number VARCHAR,
    p_role VARCHAR,
    p_first_name VARCHAR DEFAULT NULL,
    p_last_name VARCHAR DEFAULT NULL,
    p_email VARCHAR DEFAULT NULL,
    p_nic VARCHAR DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_user_id BIGINT;
    v_adm_code VARCHAR(20);
    v_full_name VARCHAR(100);
BEGIN
    -- Generate ADM code if employee
    IF p_role = 'employee' THEN
        v_adm_code := (SELECT generate_adm_code());
    END IF;

    -- Create user
    INSERT INTO users (mobile_number, role, adm_code, is_verified)
    VALUES (p_mobile_number, p_role, v_adm_code, true)
    RETURNING id INTO v_user_id;

    -- Create full name
    v_full_name := TRIM(CONCAT(p_first_name, ' ', p_last_name));

    -- Create profile
    INSERT INTO user_profiles (
        user_id,
        first_name,
        last_name,
        full_name,
        email,
        nic
    ) VALUES (
        v_user_id,
        p_first_name,
        p_last_name,
        NULLIF(v_full_name, ''),
        p_email,
        p_nic
    );

    -- Create welcome notification
    INSERT INTO notifications (user_id, title, message, type)
    VALUES (
        v_user_id,
        'Welcome to Berner Super App!',
        'Your account has been created successfully. Complete your profile to get started.',
        'info'
    );

    -- Log activity
    INSERT INTO activity_logs (user_id, action, entity_type, entity_id)
    VALUES (v_user_id, 'user_registered', 'user', v_user_id);

    RETURN jsonb_build_object(
        'success', true,
        'user_id', v_user_id,
        'adm_code', v_adm_code,
        'message', 'User created successfully'
    );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION create_user_with_profile IS 'Create user with profile in one transaction';

-- =====================================================

-- Function to block/unblock user
CREATE OR REPLACE FUNCTION set_user_block_status(
    p_user_id BIGINT,
    p_is_blocked BOOLEAN,
    p_reason TEXT DEFAULT NULL,
    p_admin_id BIGINT DEFAULT NULL
)
RETURNS JSONB AS $$
BEGIN
    UPDATE users SET
        is_blocked = p_is_blocked,
        blocked_reason = CASE WHEN p_is_blocked THEN p_reason ELSE NULL END,
        blocked_at = CASE WHEN p_is_blocked THEN NOW() ELSE NULL END,
        updated_at = NOW()
    WHERE id = p_user_id;

    -- Terminate all sessions if blocking
    IF p_is_blocked THEN
        UPDATE user_sessions SET
            is_active = false,
            terminated_at = NOW(),
            termination_reason = 'user_blocked'
        WHERE user_id = p_user_id AND is_active = true;
    END IF;

    -- Log activity
    IF p_admin_id IS NOT NULL THEN
        INSERT INTO activity_logs (user_id, action, entity_type, entity_id, changes_summary)
        VALUES (
            p_admin_id,
            CASE WHEN p_is_blocked THEN 'blocked_user' ELSE 'unblocked_user' END,
            'user',
            p_user_id,
            p_reason
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'message', CASE WHEN p_is_blocked THEN 'User blocked' ELSE 'User unblocked' END
    );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- NOTIFICATION FUNCTIONS
-- =====================================================

-- Function to create notification for multiple users
CREATE OR REPLACE FUNCTION create_bulk_notification(
    p_user_ids BIGINT[],
    p_title VARCHAR,
    p_message TEXT,
    p_type VARCHAR DEFAULT 'info'
)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER := 0;
    v_user_id BIGINT;
BEGIN
    FOREACH v_user_id IN ARRAY p_user_ids
    LOOP
        INSERT INTO notifications (user_id, title, message, type)
        VALUES (v_user_id, p_title, p_message, p_type);
        v_count := v_count + 1;
    END LOOP;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION create_bulk_notification IS 'Create notification for multiple users';

-- =====================================================

-- Function to get unread notification count
CREATE OR REPLACE FUNCTION get_unread_notification_count(
    p_user_id BIGINT
)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM notifications
    WHERE user_id = p_user_id
      AND is_read = false
      AND is_dismissed = false
      AND (expires_at IS NULL OR expires_at > NOW());

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================

-- Function to mark all notifications as read
CREATE OR REPLACE FUNCTION mark_all_user_notifications_read(
    p_user_id BIGINT
)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    WITH updated AS (
        UPDATE notifications
        SET is_read = true, read_at = NOW()
        WHERE user_id = p_user_id
          AND is_read = false
        RETURNING *
    )
    SELECT COUNT(*) INTO v_count FROM updated;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SESSION MANAGEMENT FUNCTIONS
-- =====================================================

-- Function to create user session
CREATE OR REPLACE FUNCTION create_user_session(
    p_user_id BIGINT,
    p_device_info JSONB DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_session_duration_minutes INTEGER DEFAULT 60
)
RETURNS JSONB AS $$
DECLARE
    v_session_id UUID;
    v_session_token VARCHAR(255);
    v_expires_at TIMESTAMPTZ;
BEGIN
    -- Generate session token
    v_session_token := encode(gen_random_bytes(32), 'base64');

    -- Calculate expiry
    v_expires_at := NOW() + (p_session_duration_minutes || ' minutes')::INTERVAL;

    -- Create session
    INSERT INTO user_sessions (
        user_id,
        session_token,
        device_info,
        ip_address,
        expires_at
    ) VALUES (
        p_user_id,
        v_session_token,
        p_device_info,
        p_ip_address,
        v_expires_at
    ) RETURNING id INTO v_session_id;

    -- Update last login
    UPDATE users SET last_login_at = NOW() WHERE id = p_user_id;

    RETURN jsonb_build_object(
        'success', true,
        'session_id', v_session_id,
        'session_token', v_session_token,
        'expires_at', v_expires_at
    );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION create_user_session IS 'Create new user session with token';

-- =====================================================

-- Function to validate and refresh session
CREATE OR REPLACE FUNCTION validate_session(
    p_session_token VARCHAR
)
RETURNS JSONB AS $$
DECLARE
    v_session user_sessions%ROWTYPE;
    v_user users%ROWTYPE;
BEGIN
    -- Get session
    SELECT * INTO v_session
    FROM user_sessions
    WHERE session_token = p_session_token
      AND is_active = true;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('valid', false, 'reason', 'Session not found');
    END IF;

    -- Check if expired
    IF v_session.expires_at < NOW() THEN
        UPDATE user_sessions SET is_active = false WHERE id = v_session.id;
        RETURN jsonb_build_object('valid', false, 'reason', 'Session expired');
    END IF;

    -- Get user
    SELECT * INTO v_user FROM users WHERE id = v_session.user_id;

    -- Check if user is active
    IF NOT v_user.is_active OR v_user.is_blocked THEN
        UPDATE user_sessions SET is_active = false WHERE id = v_session.id;
        RETURN jsonb_build_object('valid', false, 'reason', 'User inactive or blocked');
    END IF;

    -- Update last activity
    UPDATE user_sessions SET last_activity_at = NOW() WHERE id = v_session.id;

    RETURN jsonb_build_object(
        'valid', true,
        'user_id', v_session.user_id,
        'session_id', v_session.id
    );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- STATISTICS & REPORTING FUNCTIONS
-- =====================================================

-- Function to get dashboard statistics
CREATE OR REPLACE FUNCTION get_dashboard_stats(
    p_user_id BIGINT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_stats JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_users', (SELECT COUNT(*) FROM users WHERE deleted_at IS NULL),
        'active_users', (SELECT COUNT(*) FROM users WHERE is_active = true AND deleted_at IS NULL),
        'total_expenses', (SELECT COUNT(*) FROM expenses WHERE deleted_at IS NULL),
        'pending_expenses', (SELECT COUNT(*) FROM expenses WHERE status = 'pending' AND deleted_at IS NULL),
        'total_expense_amount', (SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE deleted_at IS NULL),
        'approved_expense_amount', (SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE is_approved = true AND deleted_at IS NULL),
        'today_expenses', (SELECT COUNT(*) FROM expenses WHERE expense_date = CURRENT_DATE AND deleted_at IS NULL),
        'this_month_expenses', (SELECT COUNT(*) FROM expenses WHERE DATE_TRUNC('month', expense_date) = DATE_TRUNC('month', CURRENT_DATE) AND deleted_at IS NULL),
        'unread_notifications', CASE WHEN p_user_id IS NOT NULL THEN get_unread_notification_count(p_user_id) ELSE 0 END
    ) INTO v_stats;

    RETURN v_stats;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_dashboard_stats IS 'Get comprehensive dashboard statistics';

-- =====================================================

-- Function to get monthly expense trend
CREATE OR REPLACE FUNCTION get_monthly_expense_trend(
    p_months INTEGER DEFAULT 6,
    p_user_id BIGINT DEFAULT NULL
)
RETURNS TABLE (
    month_year TEXT,
    expense_count BIGINT,
    total_amount DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        TO_CHAR(expense_date, 'YYYY-MM') as month_year,
        COUNT(*) as expense_count,
        SUM(amount) as total_amount
    FROM expenses
    WHERE deleted_at IS NULL
      AND expense_date >= CURRENT_DATE - (p_months || ' months')::INTERVAL
      AND (p_user_id IS NULL OR user_id = p_user_id)
    GROUP BY TO_CHAR(expense_date, 'YYYY-MM')
    ORDER BY month_year DESC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- MAINTENANCE FUNCTIONS
-- =====================================================

-- Function to clean expired sessions
CREATE OR REPLACE FUNCTION clean_expired_sessions()
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    WITH deleted AS (
        UPDATE user_sessions
        SET is_active = false, terminated_at = NOW(), termination_reason = 'expired'
        WHERE expires_at < NOW() AND is_active = true
        RETURNING *
    )
    SELECT COUNT(*) INTO v_count FROM deleted;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION clean_expired_sessions IS 'Mark expired sessions as inactive';

-- =====================================================

-- Function to clean old notifications
CREATE OR REPLACE FUNCTION clean_old_notifications(
    p_days_old INTEGER DEFAULT 90
)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    WITH deleted AS (
        DELETE FROM notifications
        WHERE (
            (is_read = true AND read_at < NOW() - (p_days_old || ' days')::INTERVAL)
            OR
            (expires_at IS NOT NULL AND expires_at < NOW())
        )
        RETURNING *
    )
    SELECT COUNT(*) INTO v_count FROM deleted;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================

-- Function to clean old activity logs
CREATE OR REPLACE FUNCTION clean_old_activity_logs(
    p_days_old INTEGER DEFAULT 180
)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    WITH deleted AS (
        DELETE FROM activity_logs
        WHERE created_at < NOW() - (p_days_old || ' days')::INTERVAL
        RETURNING *
    )
    SELECT COUNT(*) INTO v_count FROM deleted;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================

-- Function to get system health check
CREATE OR REPLACE FUNCTION system_health_check()
RETURNS JSONB AS $$
DECLARE
    v_health JSONB;
BEGIN
    SELECT jsonb_build_object(
        'database', 'connected',
        'tables', (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'),
        'total_users', (SELECT COUNT(*) FROM users),
        'active_sessions', (SELECT COUNT(*) FROM user_sessions WHERE is_active = true),
        'pending_expenses', (SELECT COUNT(*) FROM expenses WHERE status = 'pending'),
        'unprocessed_notifications', (SELECT COUNT(*) FROM notifications WHERE is_read = false),
        'disk_usage', pg_database_size(current_database()),
        'check_time', NOW()
    ) INTO v_health;

    RETURN v_health;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION system_health_check IS 'Perform system health check';

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'ADVANCED FUNCTIONS INSTALLED SUCCESSFULLY';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Functions created:';
    RAISE NOTICE '- Expense management (approve, reject, stats)';
    RAISE NOTICE '- User management (create, block, profile)';
    RAISE NOTICE '- Notification system (bulk, read, count)';
    RAISE NOTICE '- Session management (create, validate)';
    RAISE NOTICE '- Statistics & reporting';
    RAISE NOTICE '- Maintenance utilities';
    RAISE NOTICE '==============================================';
END $$;
