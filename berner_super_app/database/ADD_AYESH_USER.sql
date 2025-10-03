-- =====================================================
-- Add Ayesh User to Database
-- =====================================================
-- This script creates the user that was previously stored locally
-- Run this in Supabase SQL Editor
-- =====================================================

-- Step 1: Create user in users table
INSERT INTO users (
    mobile_number,
    role,
    adm_code,
    is_verified,
    is_active,
    created_at
)
VALUES (
    '0766568369',
    'employee',
    'ADM25674107',
    true,
    true,
    NOW()
)
ON CONFLICT (mobile_number) DO UPDATE SET
    role = EXCLUDED.role,
    adm_code = EXCLUDED.adm_code,
    is_verified = true,
    is_active = true;

-- Step 2: Create profile in user_profiles table
INSERT INTO user_profiles (
    user_id,
    first_name,
    last_name,
    full_name,
    nic,
    date_of_birth,
    gender
)
VALUES (
    (SELECT id FROM users WHERE mobile_number = '0766568369'),
    'Ayesh',
    '',
    'Ayesh',
    '200427302163',
    '2007-10-01',
    'male'
)
ON CONFLICT (user_id) DO UPDATE SET
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    full_name = EXCLUDED.full_name,
    nic = EXCLUDED.nic,
    date_of_birth = EXCLUDED.date_of_birth,
    gender = EXCLUDED.gender;

-- Step 3: Verify the user was created
SELECT
    u.id,
    u.mobile_number,
    u.role,
    u.adm_code,
    p.full_name,
    p.nic,
    p.date_of_birth,
    p.gender
FROM users u
LEFT JOIN user_profiles p ON u.id = p.user_id
WHERE u.mobile_number = '0766568369';

-- =====================================================
-- Expected Output:
-- id | mobile_number | role     | adm_code      | full_name | nic           | date_of_birth | gender
-- ---|---------------|----------|---------------|-----------|---------------|---------------|-------
-- 1  | 0766568369    | employee | ADM25674107   | Ayesh     | 200427302163  | 2007-10-01    | male
-- =====================================================
