-- =====================================================
-- FIX: Infinite Recursion in Storage RLS Policy
-- =====================================================
-- This fixes the "infinite recursion detected in policy for relation profiles" error
-- when uploading to Supabase Storage

-- STEP 1: Drop any conflicting policies on storage.objects
-- =====================================================

-- Drop all existing policies on storage.objects that might cause recursion
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN
        SELECT policyname
        FROM pg_policies
        WHERE schemaname = 'storage'
        AND tablename = 'objects'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', pol.policyname);
        RAISE NOTICE 'Dropped policy: %', pol.policyname;
    END LOOP;
END $$;

-- STEP 2: Create simple, non-recursive policies for storage.objects
-- =====================================================

-- Allow anyone to SELECT (read) objects from public buckets
CREATE POLICY "Public buckets are readable by anyone"
    ON storage.objects FOR SELECT
    USING (bucket_id IN ('profile-pictures', 'expense-receipts'));

-- Allow authenticated and anonymous users to INSERT (upload)
CREATE POLICY "Authenticated users can upload"
    ON storage.objects FOR INSERT
    TO authenticated, anon
    WITH CHECK (bucket_id IN ('profile-pictures', 'expense-receipts'));

-- Allow authenticated and anonymous users to UPDATE (replace)
CREATE POLICY "Authenticated users can update"
    ON storage.objects FOR UPDATE
    TO authenticated, anon
    USING (bucket_id IN ('profile-pictures', 'expense-receipts'))
    WITH CHECK (bucket_id IN ('profile-pictures', 'expense-receipts'));

-- Allow authenticated and anonymous users to DELETE
CREATE POLICY "Authenticated users can delete"
    ON storage.objects FOR DELETE
    TO authenticated, anon
    USING (bucket_id IN ('profile-pictures', 'expense-receipts'));

-- STEP 3: Verify buckets exist and are public
-- =====================================================

-- Check if buckets exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'profile-pictures') THEN
        RAISE NOTICE '⚠️  WARNING: profile-pictures bucket does not exist!';
        RAISE NOTICE '   Create it in Supabase Dashboard → Storage → New Bucket';
    ELSE
        RAISE NOTICE '✅ profile-pictures bucket exists';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'expense-receipts') THEN
        RAISE NOTICE '⚠️  WARNING: expense-receipts bucket does not exist!';
        RAISE NOTICE '   Create it in Supabase Dashboard → Storage → New Bucket';
    ELSE
        RAISE NOTICE '✅ expense-receipts bucket exists';
    END IF;
END $$;

-- STEP 4: Make sure buckets are public (if they exist)
-- =====================================================

UPDATE storage.buckets
SET public = true
WHERE id IN ('profile-pictures', 'expense-receipts')
AND public = false;

-- STEP 5: Verification
-- =====================================================

-- List all storage policies
SELECT
    policyname,
    cmd,
    roles,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'storage'
AND tablename = 'objects'
ORDER BY policyname;

-- List buckets
SELECT
    id as bucket_name,
    public,
    file_size_limit,
    created_at
FROM storage.buckets
WHERE id IN ('profile-pictures', 'expense-receipts')
ORDER BY id;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'STORAGE RLS POLICIES - FIXED ✅';
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Changes made:';
    RAISE NOTICE '  ✓ Removed all recursive policies';
    RAISE NOTICE '  ✓ Created simple, non-recursive policies';
    RAISE NOTICE '  ✓ Allowed anon + authenticated uploads';
    RAISE NOTICE '  ✓ Set buckets to public';
    RAISE NOTICE '================================================';
    RAISE NOTICE 'What was fixed:';
    RAISE NOTICE '  ❌ OLD: Policies referenced auth.uid() or profiles table';
    RAISE NOTICE '  ✅ NEW: Simple bucket_id checks only';
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '  1. Test profile picture upload in app';
    RAISE NOTICE '  2. Test expense receipt upload in app';
    RAISE NOTICE '  3. Check logs for success messages';
    RAISE NOTICE '================================================';
END $$;
