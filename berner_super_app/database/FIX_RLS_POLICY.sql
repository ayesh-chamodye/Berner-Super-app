-- =====================================================
-- FIX: Allow Anonymous User Registration
-- =====================================================
-- This script adds the missing RLS policy that allows
-- anonymous users to create accounts during registration
-- =====================================================

-- Allow anonymous users to INSERT into users table (for registration)
CREATE POLICY IF NOT EXISTS "Allow anon to create users"
    ON users
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- Allow anonymous users to READ from users table (for login check)
CREATE POLICY IF NOT EXISTS "Allow anon to read users"
    ON users
    FOR SELECT
    TO anon
    USING (true);

-- Allow anonymous users to UPDATE users table (for marking as verified)
CREATE POLICY IF NOT EXISTS "Allow anon to update users"
    ON users
    FOR UPDATE
    TO anon
    USING (true)
    WITH CHECK (true);

-- Allow anonymous users to INSERT into user_profiles (for profile setup)
CREATE POLICY IF NOT EXISTS "Allow anon to create user_profiles"
    ON user_profiles
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- =====================================================
-- VERIFICATION
-- =====================================================
-- Run this to verify policies were created:
--
-- SELECT schemaname, tablename, policyname, roles, cmd
-- FROM pg_policies
-- WHERE tablename IN ('users', 'user_profiles')
-- ORDER BY tablename, policyname;
--
-- =====================================================

COMMENT ON POLICY "Allow anon to create users" ON users IS
'Allows anonymous users to register new accounts via phone number';

COMMENT ON POLICY "Allow anon to read users" ON users IS
'Allows anonymous users to check if phone number exists during login';

COMMENT ON POLICY "Allow anon to update users" ON users IS
'Allows anonymous users to mark account as verified after OTP';

COMMENT ON POLICY "Allow anon to create user_profiles" ON user_profiles IS
'Allows anonymous users to create profile after registration';
