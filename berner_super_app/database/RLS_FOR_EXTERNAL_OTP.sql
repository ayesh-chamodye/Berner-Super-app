-- =====================================================
-- RLS POLICIES FOR EXTERNAL OTP AUTHENTICATION
-- =====================================================
-- This script configures Row Level Security (RLS) policies
-- for apps using EXTERNAL OTP providers (e.g., text.lk)
-- instead of Supabase Auth.
--
-- Since users are NOT authenticated via Supabase Auth,
-- we need to allow anonymous (anon) role access for:
-- 1. User registration (INSERT into users)
-- 2. Profile creation (INSERT into user_profiles)
-- 3. Login checks (SELECT from users)
-- 4. OTP verification updates (UPDATE users)
-- 5. OTP logging (INSERT into otp_logs)
-- =====================================================

-- =====================================================
-- STEP 1: DROP EXISTING CONFLICTING POLICIES
-- =====================================================
-- Drop any restrictive policies that might block anon access

DROP POLICY IF EXISTS "Allow anon to create users" ON users;
DROP POLICY IF EXISTS "Allow anon to read users" ON users;
DROP POLICY IF EXISTS "Allow anon to update users" ON users;
DROP POLICY IF EXISTS "Allow anon to create user_profiles" ON user_profiles;
DROP POLICY IF EXISTS "Allow anon to read user_profiles" ON user_profiles;
DROP POLICY IF EXISTS "Allow anon to update user_profiles" ON user_profiles;
DROP POLICY IF EXISTS "Allow anon to insert otp_logs" ON otp_logs;

-- =====================================================
-- STEP 2: USERS TABLE - Full Anonymous Access
-- =====================================================
-- Allow anonymous users to create accounts during registration

CREATE POLICY "Anon can insert users (external OTP)"
    ON users
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- Allow anonymous users to read users table (for login check & phone validation)
CREATE POLICY "Anon can read users (external OTP)"
    ON users
    FOR SELECT
    TO anon
    USING (true);

-- Allow anonymous users to update users (for marking as verified after OTP)
CREATE POLICY "Anon can update users (external OTP)"
    ON users
    FOR UPDATE
    TO anon
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- STEP 3: USER_PROFILES TABLE - Full Anonymous Access
-- =====================================================
-- Allow anonymous users to create their profile after registration

CREATE POLICY "Anon can insert user_profiles (external OTP)"
    ON user_profiles
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- Allow anonymous users to read profiles (for app functionality)
CREATE POLICY "Anon can read user_profiles (external OTP)"
    ON user_profiles
    FOR SELECT
    TO anon
    USING (true);

-- Allow anonymous users to update their own profile
CREATE POLICY "Anon can update user_profiles (external OTP)"
    ON user_profiles
    FOR UPDATE
    TO anon
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- STEP 4: OTP_LOGS TABLE - Anonymous Insert Access
-- =====================================================
-- Allow anonymous users to log OTP attempts (for audit trail)

CREATE POLICY "Anon can insert otp_logs (external OTP)"
    ON otp_logs
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- Allow anonymous users to read OTP logs (for rate limiting checks)
CREATE POLICY "Anon can read otp_logs (external OTP)"
    ON otp_logs
    FOR SELECT
    TO anon
    USING (true);

-- =====================================================
-- STEP 5: EXPENSES TABLE - Anonymous Access
-- =====================================================
-- Allow anonymous users to manage expenses (app-level auth)

CREATE POLICY "Anon can manage expenses (external OTP)"
    ON expenses
    FOR ALL
    TO anon
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- STEP 6: EXPENSE_ATTACHMENTS TABLE - Anonymous Access
-- =====================================================
-- Allow anonymous users to manage expense attachments

CREATE POLICY "Anon can manage expense_attachments (external OTP)"
    ON expense_attachments
    FOR ALL
    TO anon
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- STEP 7: NOTIFICATIONS TABLE - Anonymous Access
-- =====================================================
-- Allow anonymous users to read and update notifications

CREATE POLICY "Anon can read notifications (external OTP)"
    ON notifications
    FOR SELECT
    TO anon
    USING (true);

CREATE POLICY "Anon can update notifications (external OTP)"
    ON notifications
    FOR UPDATE
    TO anon
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Anon can insert notifications (external OTP)"
    ON notifications
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- =====================================================
-- STEP 8: ACTIVITY_LOGS TABLE - Anonymous Insert
-- =====================================================
-- Allow anonymous users to create activity logs

CREATE POLICY "Anon can insert activity_logs (external OTP)"
    ON activity_logs
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- =====================================================
-- STEP 9: EXPENSE_APPROVALS TABLE - Anonymous Access
-- =====================================================
-- Allow anonymous users to manage approvals (app-level auth)

CREATE POLICY "Anon can manage expense_approvals (external OTP)"
    ON expense_approvals
    FOR ALL
    TO anon
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- STEP 10: USER_SESSIONS TABLE - Anonymous Access
-- =====================================================
-- Allow anonymous users to manage sessions (app-level auth)

CREATE POLICY "Anon can manage user_sessions (external OTP)"
    ON user_sessions
    FOR ALL
    TO anon
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================
-- Run these queries to verify policies were created correctly:

-- 1. Check all policies for users table
-- SELECT policyname, roles, cmd, qual, with_check
-- FROM pg_policies
-- WHERE tablename = 'users'
-- ORDER BY policyname;

-- 2. Check all policies for user_profiles table
-- SELECT policyname, roles, cmd, qual, with_check
-- FROM pg_policies
-- WHERE tablename = 'user_profiles'
-- ORDER BY policyname;

-- 3. List all tables with RLS enabled
-- SELECT schemaname, tablename, rowsecurity
-- FROM pg_tables
-- WHERE schemaname = 'public'
-- AND rowsecurity = true
-- ORDER BY tablename;

-- 4. Count policies by table
-- SELECT tablename, COUNT(*) as policy_count
-- FROM pg_policies
-- WHERE schemaname = 'public'
-- GROUP BY tablename
-- ORDER BY tablename;

-- =====================================================
-- IMPORTANT NOTES
-- =====================================================
-- ⚠️ SECURITY CONSIDERATIONS:
--
-- 1. These policies allow FULL anonymous access to tables
--    because we're using EXTERNAL OTP authentication
--    (text.lk), NOT Supabase Auth.
--
-- 2. App-level security is handled by:
--    - OTP verification via text.lk API
--    - Session management in SharedPreferences
--    - Business logic validation in Flutter app
--
-- 3. Database-level security relies on:
--    - Your app being the only client with anon key
--    - Anon key kept secret (not exposed in public repos)
--    - API rate limiting on Supabase project
--
-- 4. For production, consider:
--    - Adding service-level authentication middleware
--    - Implementing API key validation
--    - Using Supabase Edge Functions for auth
--    - Adding IP whitelisting on Supabase dashboard
--
-- 5. Alternative approach (more secure):
--    - After OTP verification, create a Supabase Auth session
--    - Use authenticated role instead of anon role
--    - Restrict anon role to only registration operations
--
-- =====================================================
-- TESTING
-- =====================================================
-- Test anonymous insert into users table:
/*
INSERT INTO users (mobile_number, role, is_verified, is_active)
VALUES ('+94771234567', 'employee', false, true)
RETURNING id, mobile_number, role;
*/

-- Test anonymous select from users table:
/*
SELECT id, mobile_number, role, is_verified
FROM users
WHERE mobile_number = '+94771234567';
*/

-- Test anonymous update on users table:
/*
UPDATE users
SET is_verified = true
WHERE mobile_number = '+94771234567'
RETURNING id, is_verified;
*/

-- =====================================================
-- ROLLBACK (if needed)
-- =====================================================
-- If you need to remove these policies and start over:
/*
DROP POLICY IF EXISTS "Anon can insert users (external OTP)" ON users;
DROP POLICY IF EXISTS "Anon can read users (external OTP)" ON users;
DROP POLICY IF EXISTS "Anon can update users (external OTP)" ON users;
DROP POLICY IF EXISTS "Anon can insert user_profiles (external OTP)" ON user_profiles;
DROP POLICY IF EXISTS "Anon can read user_profiles (external OTP)" ON user_profiles;
DROP POLICY IF EXISTS "Anon can update user_profiles (external OTP)" ON user_profiles;
DROP POLICY IF EXISTS "Anon can insert otp_logs (external OTP)" ON otp_logs;
DROP POLICY IF EXISTS "Anon can read otp_logs (external OTP)" ON otp_logs;
DROP POLICY IF EXISTS "Anon can manage expenses (external OTP)" ON expenses;
DROP POLICY IF EXISTS "Anon can manage expense_attachments (external OTP)" ON expense_attachments;
DROP POLICY IF EXISTS "Anon can read notifications (external OTP)" ON notifications;
DROP POLICY IF EXISTS "Anon can update notifications (external OTP)" ON notifications;
DROP POLICY IF EXISTS "Anon can insert notifications (external OTP)" ON notifications;
DROP POLICY IF EXISTS "Anon can insert activity_logs (external OTP)" ON activity_logs;
DROP POLICY IF EXISTS "Anon can manage expense_approvals (external OTP)" ON expense_approvals;
DROP POLICY IF EXISTS "Anon can manage user_sessions (external OTP)" ON user_sessions;
*/

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'RLS POLICIES FOR EXTERNAL OTP - APPLIED ✓';
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Anonymous users can now:';
    RAISE NOTICE '  ✓ Register accounts (INSERT users)';
    RAISE NOTICE '  ✓ Create profiles (INSERT user_profiles)';
    RAISE NOTICE '  ✓ Login/validate (SELECT users)';
    RAISE NOTICE '  ✓ Verify OTP (UPDATE users)';
    RAISE NOTICE '  ✓ Log OTP attempts (INSERT otp_logs)';
    RAISE NOTICE '  ✓ Manage app data (expenses, notifications, etc.)';
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Security Notes:';
    RAISE NOTICE '  ⚠️ Keep your Supabase anon key SECRET';
    RAISE NOTICE '  ⚠️ App-level auth via text.lk OTP';
    RAISE NOTICE '  ⚠️ Session management in Flutter app';
    RAISE NOTICE '  ⚠️ Consider API rate limiting';
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '  1. Test registration flow in your app';
    RAISE NOTICE '  2. Verify OTP verification works';
    RAISE NOTICE '  3. Check profile creation succeeds';
    RAISE NOTICE '  4. Review security settings on Supabase dashboard';
    RAISE NOTICE '================================================';
END $$;
