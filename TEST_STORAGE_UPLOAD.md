# Storage Upload Diagnostic Guide

## Problem
Files not uploading to Supabase Storage buckets.

## Root Causes Found

### 1. Missing Storage Buckets
The app tries to upload to buckets that don't exist:
- `profile-pictures` - for user profile photos
- `expense-receipts` - for expense receipts and mileage images

### 2. Missing RLS Policies
Even if buckets exist, there are no Row Level Security policies allowing uploads.

## Fix Steps

### Step 1: Create Buckets (REQUIRED)

1. Go to: https://app.supabase.com/project/ompqyjdrfnjdxqavslhg/storage/buckets

2. Create **profile-pictures** bucket:
   - Click "New bucket"
   - Name: `profile-pictures`
   - Public: ✅ YES
   - Click "Create"

3. Create **expense-receipts** bucket:
   - Click "New bucket"
   - Name: `expense-receipts`
   - Public: ✅ YES
   - Click "Create"

### Step 2: Apply RLS Policies (REQUIRED)

1. Go to: https://app.supabase.com/project/ompqyjdrfnjdxqavslhg/sql/new

2. Copy the entire contents of `database/FIX_STORAGE_RLS.sql`

3. Paste into SQL Editor

4. Click "Run"

5. Check output for:
   ```
   ✅ profile-pictures bucket exists
   ✅ expense-receipts bucket exists
   ✅ STORAGE RLS POLICIES - FIXED
   ```

### Step 3: Test Upload from App

1. Run your Flutter app
2. Go to Profile Setup or Edit Profile
3. Select a profile picture
4. Save profile
5. Check debug logs for:
   ```
   🟢 SupabaseService: Profile picture uploaded successfully
   🟢 SupabaseService: Public URL: https://...
   ```

## Common Errors and Solutions

### Error: "Bucket not found"
**Cause:** Bucket doesn't exist or name is wrong
**Solution:** Create buckets exactly as: `profile-pictures` and `expense-receipts` (with hyphens)

### Error: "new row violates row-level security policy"
**Cause:** RLS policies not created or too restrictive
**Solution:** Run the `FIX_STORAGE_RLS.sql` script

### Error: "infinite recursion detected"
**Cause:** Old RLS policies reference themselves
**Solution:** The `FIX_STORAGE_RLS.sql` script drops old policies and creates simple ones

### Upload silently fails (no error)
**Cause:** Network issue or bucket doesn't exist
**Solution:**
1. Check Supabase project URL in `.env`
2. Check internet connection
3. Verify buckets exist

## How to Verify Buckets Exist

Run this SQL query:
```sql
SELECT
    id as bucket_name,
    public,
    created_at
FROM storage.buckets
WHERE id IN ('profile-pictures', 'expense-receipts');
```

Expected result: 2 rows showing both buckets

## How to Verify Policies Exist

Run this SQL query:
```sql
SELECT
    policyname,
    cmd as operation,
    roles
FROM pg_policies
WHERE schemaname = 'storage'
AND tablename = 'objects'
ORDER BY policyname;
```

Expected: At least 4 policies (SELECT, INSERT, UPDATE, DELETE)

## Test Upload Manually via Supabase Dashboard

1. Go to: https://app.supabase.com/project/ompqyjdrfnjdxqavslhg/storage/buckets/profile-pictures
2. Click "Upload file"
3. Select any image
4. If upload succeeds: Buckets are configured correctly
5. If upload fails: RLS policies need fixing

## Still Not Working?

Check Flutter console logs when uploading. Look for:
- `❌ SupabaseService: Error uploading profile picture: <error message>`
- `❌ SupabaseService: File does not exist at <path>`

Common issues:
- File path is wrong
- Image picker returned null
- Network timeout
- Supabase credentials wrong in `.env`

## Verification Checklist

- [ ] `profile-pictures` bucket exists
- [ ] `expense-receipts` bucket exists
- [ ] Both buckets are PUBLIC
- [ ] RLS policies created (run `FIX_STORAGE_RLS.sql`)
- [ ] Supabase URL correct in `.env`
- [ ] Supabase Anon Key correct in `.env`
- [ ] App can connect to Supabase (other features work)
- [ ] Test upload from Dashboard works
- [ ] Test upload from app works

## Summary

**The main issue is:** Storage buckets don't exist yet in your Supabase project.

**The fix is simple:**
1. Create the two buckets (5 minutes)
2. Run the SQL script (1 minute)
3. Test upload (1 minute)

After these steps, file uploads will work!
