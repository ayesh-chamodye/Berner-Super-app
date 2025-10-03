# Fix: Support Storage 403 Error ❌→✅

## Problem
```
StorageException(message: new row violates row-level security policy, statusCode: 403, error: Unauthorized)
```

This happens because the storage RLS policies are blocking anonymous users from uploading files.

## Root Cause
Your app doesn't use Supabase Auth (you use phone OTP via text.lk), so users are **anonymous** from Supabase's perspective. The default storage policies block anonymous uploads.

## Solution

### Option 1: Run SQL Script (Recommended)

1. **Open Supabase SQL Editor:**
   - Go to: https://app.supabase.com/project/ompqyjdrfnjdxqavslhg/sql/new

2. **Run this SQL:**
   - Copy entire contents of `database/FIX_SUPPORT_STORAGE_RLS.sql`
   - Paste into SQL Editor
   - Click "Run"

3. **Verify:**
   - You should see success messages
   - Check that policies are created

### Option 2: Manual Steps in Supabase Dashboard

#### Step A: Create Bucket (if doesn't exist)

1. Go to: https://app.supabase.com/project/ompqyjdrfnjdxqavslhg/storage/buckets

2. Click "New bucket"
   - Name: `support-attachments`
   - Public: ✅ **Check this**
   - File size limit: `10MB`
   - Allowed MIME types: `image/jpeg, image/png, image/gif, image/webp`
   - Click "Create"

#### Step B: Configure Policies

1. Go to: https://app.supabase.com/project/ompqyjdrfnjdxqavslhg/storage/policies

2. Click on `support-attachments` bucket

3. Click "New Policy"

**Policy 1: Allow Anyone to Upload**
```
Policy name: Anyone can upload support attachments
Allowed operation: INSERT
Target roles: public, anon, authenticated
Policy definition:
  USING: (bucket_id = 'support-attachments')
  WITH CHECK: (bucket_id = 'support-attachments')
```

**Policy 2: Allow Anyone to View**
```
Policy name: Anyone can view support attachments
Allowed operation: SELECT
Target roles: public, anon, authenticated
Policy definition:
  USING: (bucket_id = 'support-attachments')
```

**Policy 3: Allow Anyone to Update**
```
Policy name: Anyone can update support attachments
Allowed operation: UPDATE
Target roles: public, anon, authenticated
Policy definition:
  USING: (bucket_id = 'support-attachments')
  WITH CHECK: (bucket_id = 'support-attachments')
```

**Policy 4: Allow Anyone to Delete**
```
Policy name: Anyone can delete support attachments
Allowed operation: DELETE
Target roles: public, anon, authenticated
Policy definition:
  USING: (bucket_id = 'support-attachments')
```

## Why This Happens

Your app architecture:
```
User Login → Phone OTP (text.lk) → Local auth state
                ↓
         NO Supabase Auth
                ↓
    User is "anonymous" to Supabase
                ↓
    Default policies block anonymous uploads
```

The fix allows anonymous users to upload because:
1. Your auth is external (text.lk)
2. User identity is tracked in `users` table
3. Storage doesn't need strict auth checks

## Security Note

**Current setup (Development):**
- ✅ Anyone can upload to support bucket
- ✅ Good for development/testing
- ⚠️ Not ideal for production

**For Production:**
Consider these improvements:

### 1. Add File Size Validation
Already done in bucket config (10MB limit)

### 2. Restrict by User ID (Future)
When you implement Supabase Auth:
```sql
CREATE POLICY "Users can upload their own files"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'support-attachments'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );
```

### 3. Rate Limiting
Add rate limiting in your app:
```dart
// Limit uploads per user per hour
if (_uploadCount > 10) {
  throw Exception('Upload limit reached');
}
```

### 4. File Validation
Already implemented in your code:
```dart
final XFile? image = await _imagePicker.pickImage(
  maxWidth: 1920,
  maxHeight: 1920,
  imageQuality: 85,
);
```

## Test the Fix

1. Run the SQL script
2. Open your app
3. Go to Support Chat
4. Tap image icon
5. Select image
6. Tap send
7. ✅ Should upload successfully

**Check logs for:**
```
🔵 Uploading image from: /path/to/image
🟢 Image uploaded to: https://...supabase.co/storage/v1/object/public/support-attachments/...
🟢 Message sent successfully
```

## Troubleshooting

### Still getting 403?

**Check 1: Bucket exists**
```sql
SELECT * FROM storage.buckets WHERE id = 'support-attachments';
```
Should return 1 row.

**Check 2: Bucket is public**
```sql
SELECT id, public FROM storage.buckets WHERE id = 'support-attachments';
```
`public` should be `true`.

**Check 3: Policies exist**
```sql
SELECT policyname, cmd, roles
FROM pg_policies
WHERE schemaname = 'storage'
AND tablename = 'objects'
AND qual::text LIKE '%support-attachments%';
```
Should return 4 policies (SELECT, INSERT, UPDATE, DELETE).

**Check 4: Policies include 'anon' role**
```sql
SELECT policyname, roles
FROM pg_policies
WHERE schemaname = 'storage'
AND tablename = 'objects'
AND qual::text LIKE '%support-attachments%';
```
Each policy should include `{anon}` or `{public}` in roles array.

### Clear and recreate policies

If still not working:
```sql
-- Drop ALL storage policies
DROP POLICY IF EXISTS "Anyone can view support attachments" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can upload support attachments" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can update support attachments" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can delete support attachments" ON storage.objects;

-- Then run FIX_SUPPORT_STORAGE_RLS.sql again
```

### Check app-side errors

Enable verbose logging:
```dart
await client.storage.from('support-attachments').uploadBinary(
  storagePath,
  bytes,
  fileOptions: FileOptions(
    upsert: true,
    contentType: 'image/${fileExt == 'jpg' ? 'jpeg' : fileExt}',
  ),
);
```

Common issues:
- ❌ Wrong bucket name (should be `support-attachments`)
- ❌ File doesn't exist at path
- ❌ Network timeout
- ❌ File too large (>10MB)

## Summary

**The Problem:**
- 403 error when uploading images
- RLS policies blocking anonymous users

**The Solution:**
- Run `FIX_SUPPORT_STORAGE_RLS.sql`
- Creates permissive policies for `support-attachments` bucket
- Allows anonymous users to upload

**Why It Works:**
- Your app uses external auth (text.lk)
- Users are anonymous to Supabase
- Bucket policies now allow anonymous uploads
- File organization by ticket_id maintains security

**Result:**
✅ Image uploads work
✅ Chat system fully functional
✅ Support attachments enabled

Run the SQL script and test again! 🚀
