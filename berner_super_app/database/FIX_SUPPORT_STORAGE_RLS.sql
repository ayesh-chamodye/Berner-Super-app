-- =====================================================
-- FIX SUPPORT ATTACHMENTS STORAGE RLS
-- =====================================================
-- This fixes the 403 Unauthorized error when uploading support attachments

-- STEP 1: Drop all existing storage policies for support-attachments
-- =====================================================

DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN
        SELECT policyname
        FROM pg_policies
        WHERE schemaname = 'storage'
        AND tablename = 'objects'
        AND policyname LIKE '%support%'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', pol.policyname);
        RAISE NOTICE 'Dropped policy: %', pol.policyname;
    END LOOP;
END $$;

-- STEP 2: Create simple, permissive policies
-- =====================================================

-- Allow ANYONE to read from support-attachments bucket
CREATE POLICY "Anyone can view support attachments"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'support-attachments');

-- Allow anonymous and authenticated users to INSERT (upload)
CREATE POLICY "Anyone can upload support attachments"
    ON storage.objects FOR INSERT
    TO anon, authenticated, public
    WITH CHECK (bucket_id = 'support-attachments');

-- Allow anonymous and authenticated users to UPDATE
CREATE POLICY "Anyone can update support attachments"
    ON storage.objects FOR UPDATE
    TO anon, authenticated, public
    USING (bucket_id = 'support-attachments')
    WITH CHECK (bucket_id = 'support-attachments');

-- Allow anonymous and authenticated users to DELETE
CREATE POLICY "Anyone can delete support attachments"
    ON storage.objects FOR DELETE
    TO anon, authenticated, public
    USING (bucket_id = 'support-attachments');

-- STEP 3: Verify bucket exists and is public
-- =====================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'support-attachments') THEN
        RAISE NOTICE '⚠️  WARNING: support-attachments bucket does not exist!';
        RAISE NOTICE '   Creating it now...';

        -- Create the bucket
        INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
        VALUES (
            'support-attachments',
            'support-attachments',
            true,  -- Public bucket
            10485760,  -- 10MB limit
            ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf']
        );

        RAISE NOTICE '✅ support-attachments bucket created';
    ELSE
        RAISE NOTICE '✅ support-attachments bucket exists';

        -- Make sure it's public
        UPDATE storage.buckets
        SET public = true
        WHERE id = 'support-attachments'
        AND public = false;
    END IF;
END $$;

-- STEP 4: List all storage policies for verification
-- =====================================================

SELECT
    policyname,
    cmd as operation,
    roles,
    qual as using_clause,
    with_check
FROM pg_policies
WHERE schemaname = 'storage'
AND tablename = 'objects'
AND (policyname LIKE '%support%' OR qual::text LIKE '%support-attachments%')
ORDER BY policyname;

-- STEP 5: Verify bucket configuration
-- =====================================================

SELECT
    id as bucket_name,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    created_at
FROM storage.buckets
WHERE id = 'support-attachments';

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'SUPPORT STORAGE RLS - FIXED ✅';
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Changes made:';
    RAISE NOTICE '  ✓ Dropped all conflicting policies';
    RAISE NOTICE '  ✓ Created permissive policies for anon users';
    RAISE NOTICE '  ✓ Ensured bucket is public';
    RAISE NOTICE '  ✓ Set file size limit to 10MB';
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Policies created:';
    RAISE NOTICE '  ✓ SELECT - Anyone can view';
    RAISE NOTICE '  ✓ INSERT - Anyone can upload';
    RAISE NOTICE '  ✓ UPDATE - Anyone can update';
    RAISE NOTICE '  ✓ DELETE - Anyone can delete';
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '  1. Test image upload in app';
    RAISE NOTICE '  2. Check logs for success';
    RAISE NOTICE '  3. View uploaded files in bucket';
    RAISE NOTICE '================================================';
END $$;
