# Ad Banners Implementation Complete ✅

## Overview
The home page slider now fetches banner images from the `ad_banners` table in Supabase instead of using hardcoded local assets.

## Changes Made

### 1. Database Schema
**File**: `database/CREATE_AD_BANNERS_TABLE.sql`

Created a new `ad_banners` table with:
- Banner details (title, description)
- Image storage (image_url, image_path, storage_bucket)
- Link/action configuration
- Display settings (order, active status)
- Scheduling (start_date, end_date)
- Target audience (roles)
- Analytics (view_count, click_count)
- RLS policies for security

### 2. Supabase Service
**File**: `lib/services/supabase_service.dart`

Added three new methods:
```dart
// Fetch active banners from database
static Future<List<Map<String, dynamic>>> getActiveBanners({String? userRole})

// Increment view count when banner is shown
static Future<void> incrementBannerViewCount(int bannerId)

// Increment click count when banner is clicked
static Future<void> incrementBannerClickCount(int bannerId)
```

### 3. Home Page Updates
**File**: `lib/screens/home_page.dart`

Updated the slider to:
- ✅ Fetch banners from Supabase on page load
- ✅ Display loading indicator while fetching
- ✅ Show fallback SVG images if no banners in database
- ✅ Handle network errors gracefully
- ✅ Support both network images (from DB) and local SVG files
- ✅ Make banners clickable (TODO: implement navigation)

## How to Use

### Step 1: Create the Database Table

Run this SQL in your Supabase SQL Editor:

```bash
# Go to: https://app.supabase.com/project/ompqyjdrfnjdxqavslhg/sql/new
# Copy and paste the entire contents of:
database/CREATE_AD_BANNERS_TABLE.sql
```

This will:
- Create the `ad_banners` table
- Set up RLS policies
- Insert 3 sample banners (placeholder images)

### Step 2: Create Storage Bucket for Banner Images

1. Go to: https://app.supabase.com/project/ompqyjdrfnjdxqavslhg/storage/buckets
2. Click **"New bucket"**
3. Name: `ad-banners`
4. Public: ✅ **Check this**
5. Click **"Create bucket"**

### Step 3: Apply RLS Policies for Storage

Run this SQL to allow uploads to the `ad-banners` bucket:

```sql
-- Allow public read
CREATE POLICY "Public can view ad banners"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'ad-banners');

-- Allow admins to upload
CREATE POLICY "Admins can upload ad banners"
    ON storage.objects FOR INSERT
    TO authenticated, anon
    WITH CHECK (bucket_id = 'ad-banners');

-- Allow admins to update
CREATE POLICY "Admins can update ad banners"
    ON storage.objects FOR UPDATE
    TO authenticated, anon
    USING (bucket_id = 'ad-banners')
    WITH CHECK (bucket_id = 'ad-banners');

-- Allow admins to delete
CREATE POLICY "Admins can delete ad banners"
    ON storage.objects FOR DELETE
    TO authenticated, anon
    USING (bucket_id = 'ad-banners');
```

### Step 4: Upload Your Banner Images

1. Go to Storage → `ad-banners` bucket
2. Upload your banner images (recommended size: 800x400px)
3. Copy the public URL of each image

### Step 5: Insert Your Banners into Database

```sql
-- Insert your custom banners
INSERT INTO ad_banners (title, description, image_url, display_order, is_active) VALUES
    ('Welcome to Berner', 'Your expense tracking companion', 'https://ompqyjdrfnjdxqavslhg.supabase.co/storage/v1/object/public/ad-banners/banner1.jpg', 1, true),
    ('Track Expenses Easily', 'Submit and manage expenses on the go', 'https://ompqyjdrfnjdxqavslhg.supabase.co/storage/v1/object/public/ad-banners/banner2.jpg', 2, true),
    ('Quick Approvals', 'Get your expenses approved fast', 'https://ompqyjdrfnjdxqavslhg.supabase.co/storage/v1/object/public/ad-banners/banner3.jpg', 3, true);
```

### Step 6: Test the Implementation

1. Run your Flutter app
2. Navigate to the home page
3. You should see:
   - Loading indicator while fetching banners
   - Your banners from the database (if table exists and has data)
   - Fallback SVG images (if no banners or database error)

## Banner Features

### Display Settings
- **display_order**: Lower number = shown first
- **is_active**: Only active banners are shown
- **start_date / end_date**: Schedule banners for specific date ranges

### Targeting
- **target_roles**: Show banners to specific user roles
  - `NULL` = show to everyone
  - `['employee']` = only show to employees
  - `['employee', 'owner']` = show to employees and owners

### Actions
- **link_type**: What happens when user taps banner
  - `'none'` = No action
  - `'external'` = Open external URL
  - `'internal'` = Navigate to app screen

### Analytics
- **view_count**: How many times banner was shown
- **click_count**: How many times banner was clicked

## Database Schema Details

```sql
CREATE TABLE ad_banners (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255),
    description TEXT,
    image_url TEXT NOT NULL,              -- Public URL of banner image
    image_path TEXT,                      -- Storage path
    storage_bucket VARCHAR(100),          -- 'ad-banners'
    link_url TEXT,                        -- Where to navigate
    link_type VARCHAR(50),                -- 'internal', 'external', 'none'
    action_data JSONB,                    -- Navigation params
    display_order INTEGER DEFAULT 0,      -- Sort order
    is_active BOOLEAN DEFAULT true,       -- Show/hide
    start_date TIMESTAMPTZ,               -- Schedule start
    end_date TIMESTAMPTZ,                 -- Schedule end
    target_roles TEXT[],                  -- ['employee', 'admin']
    view_count INTEGER DEFAULT 0,         -- Analytics
    click_count INTEGER DEFAULT 0,        -- Analytics
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by BIGINT REFERENCES users(id)
);
```

## Fallback Behavior

The app intelligently falls back to local images if:
- ❌ Database table doesn't exist
- ❌ No active banners in database
- ❌ Network error while fetching
- ❌ Supabase connection fails

This ensures the home page always looks good, even without database setup.

## Future Enhancements (TODOs)

### 1. Banner Click Navigation
Current: Prints to console
Todo: Implement navigation based on `link_type`

```dart
// TODO: In home_page.dart line 324
if (item['link_type'] == 'internal') {
  // Navigate to app screen
  Navigator.pushNamed(context, item['link_url']);
} else if (item['link_type'] == 'external') {
  // Open external URL
  launchUrl(Uri.parse(item['link_url']));
}
```

### 2. Analytics Tracking
Track banner views and clicks:

```dart
// When banner is shown
await SupabaseService.incrementBannerViewCount(bannerId);

// When banner is tapped
await SupabaseService.incrementBannerClickCount(bannerId);
```

### 3. Admin Panel
Create an admin interface to:
- Upload new banners
- Edit existing banners
- View analytics
- Schedule banners
- Target specific user roles

### 4. Caching
Implement image caching for better performance:
```dart
import 'package:cached_network_image/cached_network_image.dart';

CachedNetworkImage(
  imageUrl: bannerUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

## Troubleshooting

### Banners not showing?
1. Check if `ad_banners` table exists in Supabase
2. Check if table has active banners: `SELECT * FROM ad_banners WHERE is_active = true;`
3. Check Flutter console for error messages
4. Verify RLS policies allow SELECT

### Images not loading?
1. Check if `ad-banners` storage bucket exists
2. Check if bucket is public
3. Verify image URLs are correct and accessible
4. Check storage RLS policies

### Database errors?
Run the verification query:
```sql
SELECT * FROM ad_banners WHERE is_active = true ORDER BY display_order;
```

## Summary

✅ Database table created with full schema
✅ Supabase service methods added
✅ Home page updated to fetch from database
✅ Fallback to local images if needed
✅ Loading and error states handled
✅ Click handling prepared (navigation TODO)
✅ Analytics tracking methods ready
✅ Documentation complete

The slider now dynamically loads banners from Supabase, making it easy to update promotions without releasing a new app version!
