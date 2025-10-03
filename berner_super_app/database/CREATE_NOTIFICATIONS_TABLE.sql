-- ============================================================================
-- NOTIFICATIONS TABLE SCHEMA
-- ============================================================================
-- This script creates the notifications table for the Berner Super App
-- Users receive notifications for various app activities
-- ============================================================================

-- Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id BIGINT NOT NULL, -- Changed from UUID to BIGINT to match users table
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'general', -- general, expense, support, weather, system
    icon TEXT, -- icon name or URL
    image_url TEXT, -- optional notification image
    action_type TEXT, -- navigate, open_link, open_page
    action_data JSONB, -- stores action parameters like page route, link URL
    is_read BOOLEAN DEFAULT FALSE,
    is_important BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ, -- optional expiration date
    metadata JSONB DEFAULT '{}'::jsonb -- additional flexible data
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id, is_read) WHERE is_read = FALSE;

-- Enable Row Level Security
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow all operations for anonymous users" ON public.notifications;

-- RLS policy for anonymous users (for external auth like text.lk)
-- Since the app uses external authentication, allow all operations
CREATE POLICY "Allow all operations for anonymous users"
    ON public.notifications
    FOR ALL
    TO anon, public, authenticated
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to mark notification as read
CREATE OR REPLACE FUNCTION mark_notification_read(notification_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.notifications
    SET is_read = TRUE, read_at = NOW()
    WHERE id = notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark all user notifications as read
CREATE OR REPLACE FUNCTION mark_all_notifications_read(p_user_id BIGINT)
RETURNS INTEGER AS $$
DECLARE
    affected_count INTEGER;
BEGIN
    UPDATE public.notifications
    SET is_read = TRUE, read_at = NOW()
    WHERE user_id = p_user_id AND is_read = FALSE;

    GET DIAGNOSTICS affected_count = ROW_COUNT;
    RETURN affected_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get unread notification count
CREATE OR REPLACE FUNCTION get_unread_notification_count(p_user_id BIGINT)
RETURNS INTEGER AS $$
DECLARE
    unread_count INTEGER;
BEGIN
    SELECT COUNT(*)::INTEGER INTO unread_count
    FROM public.notifications
    WHERE user_id = p_user_id
      AND is_read = FALSE
      AND (expires_at IS NULL OR expires_at > NOW());

    RETURN COALESCE(unread_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to delete old read notifications
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM public.notifications
    WHERE is_read = TRUE
      AND read_at < NOW() - INTERVAL '30 days';

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to delete expired notifications
CREATE OR REPLACE FUNCTION delete_expired_notifications()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM public.notifications
    WHERE expires_at IS NOT NULL
      AND expires_at < NOW();

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================================================

-- Insert sample notifications (replace 1 with actual user ID from users table)
/*
INSERT INTO public.notifications (user_id, title, message, type, icon, is_important)
VALUES
    (1, 'Welcome to Berner!', 'Thank you for joining us. Explore all the features.', 'system', 'celebration', TRUE),
    (1, 'Expense Added', 'Your expense of Rs. 500 has been recorded.', 'expense', 'attach_money', FALSE),
    (1, 'Support Reply', 'Admin has replied to your support ticket #12345.', 'support', 'support_agent', TRUE);
*/

-- ============================================================================
-- NOTES
-- ============================================================================
-- 1. Run this script in your Supabase SQL Editor
-- 2. The table uses BIGINT for user_id to match users table (external auth)
-- 3. For external auth (text.lk), user_id is the integer ID from users table
-- 4. Notifications expire automatically if expires_at is set
-- 5. Use cleanup functions periodically to maintain performance
-- 6. action_data JSONB allows flexible action parameters:
--    - {"route": "/expense", "expense_id": "123"} for navigation
--    - {"url": "https://example.com"} for external links
