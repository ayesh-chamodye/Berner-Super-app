-- =====================================================
-- Berner Super App - Sample Data (Development Only)
-- =====================================================
-- This script inserts sample data for testing
-- DO NOT RUN IN PRODUCTION
-- =====================================================

-- =====================================================
-- SAMPLE USERS
-- =====================================================

-- Insert sample employees
INSERT INTO users (mobile_number, adm_code, role, name, nic, date_of_birth, gender, is_verified, is_active) VALUES
    ('0771234567', 'ADM25123456', 'employee', 'John Doe', '199012345678', '1990-05-15', 'male', true, true),
    ('0772345678', 'ADM25234567', 'employee', 'Jane Smith', '199123456789', '1991-08-22', 'female', true, true),
    ('0773456789', 'ADM25345678', 'employee', 'Bob Johnson', '198934567890', '1989-03-10', 'male', true, true)
ON CONFLICT (mobile_number) DO NOTHING;

-- Insert sample owners
INSERT INTO users (mobile_number, role, name, nic, date_of_birth, gender, is_verified, is_active) VALUES
    ('0774567890', 'owner', 'Alice Williams', '198545678901', '1985-12-05', 'female', true, true),
    ('0775678901', 'owner', 'Charlie Brown', '198756789012', '1987-07-18', 'male', true, true)
ON CONFLICT (mobile_number) DO NOTHING;

-- =====================================================
-- SAMPLE EXPENSES
-- =====================================================

-- Get user IDs (we'll use the first employee and owner)
DO $$
DECLARE
    v_employee_id BIGINT;
    v_owner_id BIGINT;
BEGIN
    -- Get first employee
    SELECT id INTO v_employee_id FROM users WHERE role = 'employee' LIMIT 1;

    -- Get first owner
    SELECT id INTO v_owner_id FROM users WHERE role = 'owner' LIMIT 1;

    -- Insert sample expenses for employee
    IF v_employee_id IS NOT NULL THEN
        INSERT INTO expenses (user_id, title, description, amount, category, expense_date, is_approved, approved_by, approved_at) VALUES
            (v_employee_id, 'Office Supplies', 'Pens, papers, and folders', 1500.00, 'office', CURRENT_DATE - INTERVAL '5 days', true, v_owner_id, CURRENT_TIMESTAMP - INTERVAL '3 days'),
            (v_employee_id, 'Client Lunch', 'Lunch meeting with client ABC Corp', 3500.00, 'meals', CURRENT_DATE - INTERVAL '3 days', true, v_owner_id, CURRENT_TIMESTAMP - INTERVAL '2 days'),
            (v_employee_id, 'Taxi Fare', 'Transportation to client office', 800.00, 'transport', CURRENT_DATE - INTERVAL '2 days', false, NULL, NULL),
            (v_employee_id, 'Printer Cartridges', 'Black and color cartridges', 4500.00, 'office', CURRENT_DATE - INTERVAL '1 day', false, NULL, NULL)
        ON CONFLICT DO NOTHING;
    END IF;

    -- Insert sample expenses for owner
    IF v_owner_id IS NOT NULL THEN
        INSERT INTO expenses (user_id, title, description, amount, category, expense_date, is_approved) VALUES
            (v_owner_id, 'Business Dinner', 'Dinner with potential investors', 8500.00, 'meals', CURRENT_DATE - INTERVAL '4 days', false),
            (v_owner_id, 'Conference Registration', 'Tech conference 2025', 15000.00, 'events', CURRENT_DATE - INTERVAL '7 days', false)
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- =====================================================
-- SAMPLE OTP LOGS
-- =====================================================

INSERT INTO otp_logs (phone, success, error_message) VALUES
    ('0771234567', true, NULL),
    ('0772345678', true, NULL),
    ('0773456789', false, 'Invalid phone number'),
    ('0774567890', true, NULL),
    ('0775678901', true, NULL),
    ('0771111111', false, 'Rate limit exceeded')
ON CONFLICT DO NOTHING;

-- =====================================================
-- SAMPLE NOTIFICATIONS
-- =====================================================

DO $$
DECLARE
    v_employee_id BIGINT;
    v_owner_id BIGINT;
BEGIN
    -- Get first employee
    SELECT id INTO v_employee_id FROM users WHERE role = 'employee' LIMIT 1;

    -- Get first owner
    SELECT id INTO v_owner_id FROM users WHERE role = 'owner' LIMIT 1;

    -- Insert sample notifications
    IF v_employee_id IS NOT NULL THEN
        INSERT INTO notifications (user_id, title, message, type, related_entity_type, related_entity_id) VALUES
            (v_employee_id, 'Welcome to Berner!', 'Your account has been created successfully.', 'success', 'user', v_employee_id),
            (v_employee_id, 'Expense Approved', 'Your expense "Office Supplies" has been approved.', 'success', 'expense', NULL),
            (v_employee_id, 'New Feature', 'Check out the new expense tracking features!', 'info', NULL, NULL)
        ON CONFLICT DO NOTHING;
    END IF;

    IF v_owner_id IS NOT NULL THEN
        INSERT INTO notifications (user_id, title, message, type, related_entity_type, related_entity_id) VALUES
            (v_owner_id, 'Welcome to Berner!', 'Your owner account has been created successfully.', 'success', 'user', v_owner_id),
            (v_owner_id, 'Pending Approvals', 'You have 2 expenses waiting for approval.', 'warning', 'expense', NULL)
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Display summary of inserted data
DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Sample Data Insertion Complete';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Users: % (% employees, % owners)',
        (SELECT COUNT(*) FROM users),
        (SELECT COUNT(*) FROM users WHERE role = 'employee'),
        (SELECT COUNT(*) FROM users WHERE role = 'owner');
    RAISE NOTICE 'Expenses: %', (SELECT COUNT(*) FROM expenses);
    RAISE NOTICE 'OTP Logs: %', (SELECT COUNT(*) FROM otp_logs);
    RAISE NOTICE 'Notifications: %', (SELECT COUNT(*) FROM notifications);
    RAISE NOTICE '==============================================';
END $$;

-- =====================================================
-- END OF SAMPLE DATA
-- =====================================================
