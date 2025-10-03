# Setup Supabase Storage for Profile Pictures

## Overview
This guide will help you set up Supabase Storage to store profile pictures uploaded from the app.

## Step 1: Create Storage Bucket

1. **Go to Supabase Dashboard**
   - Navigate to: https://app.supabase.com
   - Select your project: `ompqyjdrfnjdxqavslhg`

2. **Create Storage Bucket**
   - Click on **Storage** in the left sidebar
   - Click **New Bucket**
   - Enter the following details:
     - **Name**: `profile-pictures`
     - **Public bucket**: ✅ **YES** (Enable this)
     - **File size limit**: `5MB` (optional)
     - **Allowed MIME types**: `image/*` (optional - only allow images)

3. **Click "Create Bucket"**

## Step 2: Set Storage Policies (RLS)

After creating the bucket, you need to set up policies to allow anonymous users to upload/view pictures.

### Option A: Using Supabase Dashboard UI

1. Go to **Storage** → **Policies**
2. Click on `profile-pictures` bucket
3. Click **New Policy**

**Policy 1: Allow Anonymous Upload**
- Policy name: `Allow anonymous users to upload profile pictures`
- Policy definition: `INSERT`
- Target roles: `anon`, `authenticated`
- USING expression: `true`
- WITH CHECK expression: `true`

**Policy 2: Allow Public Read**
- Policy name: `Allow public read access to profile pictures`
- Policy definition: `SELECT`
- Target roles: `anon`, `authenticated`, `public`
- USING expression: `true`

**Policy 3: Allow Users to Update Their Own Pictures**
- Policy name: `Allow users to update their own profile pictures`
- Policy definition: `UPDATE`
- Target roles: `anon`, `authenticated`
- USING expression: `true`
- WITH CHECK expression: `true`

**Policy 4: Allow Users to Delete Their Own Pictures**
- Policy name: `Allow users to delete their own profile pictures`
- Policy definition: `DELETE`
- Target roles: `anon`, `authenticated`
- USING expression: `true`

### Option B: Using SQL (Faster)

Run this SQL in the **SQL Editor**:

```sql
-- Create storage policies for profile-pictures bucket

-- Allow anonymous users to upload (INSERT)
INSERT INTO storage.policies (name, bucket_id, definition, check)
VALUES (
  'Allow anonymous upload to profile-pictures',
  'profile-pictures',
  '(bucket_id = ''profile-pictures''::text)',
  '(bucket_id = ''profile-pictures''::text)'
);

-- Allow public read (SELECT)
INSERT INTO storage.policies (name, bucket_id, definition)
VALUES (
  'Allow public read from profile-pictures',
  'profile-pictures',
  '(bucket_id = ''profile-pictures''::text)'
);

-- Alternative: Use Supabase's helper function (Recommended)
-- This automatically creates proper policies

-- Allow all operations for authenticated and anon users
CREATE POLICY "Public Access to profile-pictures"
  ON storage.objects FOR ALL
  TO anon, authenticated
  USING (bucket_id = 'profile-pictures')
  WITH CHECK (bucket_id = 'profile-pictures');
```

## Step 3: Verify Setup

### Test Upload via SQL
```sql
-- Check if bucket exists
SELECT * FROM storage.buckets WHERE id = 'profile-pictures';

-- Check policies
SELECT * FROM storage.policies WHERE bucket_id = 'profile-pictures';
```

### Test via Flutter App
1. Run your Flutter app
2. Go to Profile Setup or Edit Profile
3. Select a profile picture
4. Save profile
5. Check logs for:
   - `🟢 SupabaseService: Profile picture uploaded successfully`
   - `🟢 SupabaseService: Public URL: https://...`

## Step 4: Configure CORS (If Needed)

If you encounter CORS errors:

1. Go to **Project Settings** → **API**
2. Add your app's domain to **Allowed origins**
3. For development, you can temporarily add `*` (wildcard)
   - ⚠️ **DO NOT** use `*` in production!

## Troubleshooting

### Error: "Bucket not found"
- Verify bucket name is exactly `profile-pictures` (with hyphen, not underscore)
- Check that you created the bucket in the correct project

### Error: "Permission denied"
- Verify RLS policies are created correctly
- Make sure bucket is set to **Public**
- Check that policies allow `anon` role

### Error: "File too large"
- Check bucket file size limit
- Images are compressed to max 500x500 @ 80% quality before upload

### Images not displaying
- Verify the URL is public: `https://PROJECT_ID.supabase.co/storage/v1/object/public/profile-pictures/...`
- Check browser console for CORS errors
- Ensure bucket is marked as **Public**

## File Structure

Profile pictures are stored as:
```
profile-pictures/
  └── profile_pictures/
      ├── profile_5.jpg       (user_id = 5)
      ├── profile_5.png       (overwrites jpg if user changes)
      ├── profile_12.jpg      (user_id = 12)
      └── ...
```

## Security Considerations

### ✅ Current Setup (Development)
- Anonymous users can upload
- Public can read
- Anyone can update/delete

### 🔒 Production Recommendations

1. **Restrict Upload to Authenticated Users Only**
```sql
-- Remove anon from upload policy
CREATE POLICY "Authenticated users can upload"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'profile-pictures');
```

2. **Users Can Only Update Their Own Pictures**
```sql
-- Restrict updates to file owner
CREATE POLICY "Users can update own pictures"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'profile-pictures' AND
    (storage.foldername(name))[1] = 'profile_pictures' AND
    (storage.filename(name) = 'profile_' || auth.uid()::text || '.jpg' OR
     storage.filename(name) = 'profile_' || auth.uid()::text || '.png')
  );
```

3. **Add File Size Validation**
   - Set bucket limit to 5MB
   - Validate file size in app before upload

4. **Add Rate Limiting**
   - Limit uploads per user per day
   - Implement in Supabase Edge Functions

## Next Steps

After setup:
1. ✅ Create `profile-pictures` bucket
2. ✅ Set bucket to **Public**
3. ✅ Create RLS policies
4. ✅ Test upload from app
5. ✅ Verify image displays correctly
6. 📝 (Optional) Set up CDN for faster loading
7. 📝 (Optional) Add image optimization

## Additional Resources

- [Supabase Storage Documentation](https://supabase.com/docs/guides/storage)
- [Storage RLS Policies](https://supabase.com/docs/guides/storage/security/access-control)
- [Flutter File Upload Guide](https://supabase.com/docs/reference/dart/storage-from-upload)
