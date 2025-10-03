-- =====================================================
-- AD BANNERS TABLE - For Home Page Slider
-- =====================================================

CREATE TABLE IF NOT EXISTS ad_banners (
    -- Primary Key
    id BIGSERIAL PRIMARY KEY,

    -- Banner Details
    title VARCHAR(255),
    description TEXT,

    -- Image Storage
    image_url TEXT NOT NULL,
    image_path TEXT,
    storage_bucket VARCHAR(100) DEFAULT 'ad-banners',

    -- Link/Action
    link_url TEXT,
    link_type VARCHAR(50) CHECK (link_type IN ('internal', 'external', 'none')) DEFAULT 'none',
    action_data JSONB, -- For internal navigation: {"screen": "expense", "params": {}}

    -- Display Settings
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,

    -- Scheduling
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,

    -- Target Audience
    target_roles TEXT[], -- ['employee', 'owner', 'admin'] or NULL for all

    -- Analytics
    view_count INTEGER DEFAULT 0,
    click_count INTEGER DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by BIGINT REFERENCES users(id) ON DELETE SET NULL
);

-- Indexes
CREATE INDEX idx_ad_banners_is_active ON ad_banners(is_active, display_order);
CREATE INDEX idx_ad_banners_dates ON ad_banners(start_date, end_date) WHERE is_active = true;
CREATE INDEX idx_ad_banners_display_order ON ad_banners(display_order) WHERE is_active = true;

COMMENT ON TABLE ad_banners IS 'Advertisement banners for home page slider';
COMMENT ON COLUMN ad_banners.image_url IS 'Public URL of the banner image';
COMMENT ON COLUMN ad_banners.display_order IS 'Lower number = higher priority';
COMMENT ON COLUMN ad_banners.target_roles IS 'NULL = show to all users, or specific roles';

-- =====================================================
-- RLS POLICIES FOR AD BANNERS
-- =====================================================

-- Enable RLS
ALTER TABLE ad_banners ENABLE ROW LEVEL SECURITY;

-- Allow everyone to view active banners
CREATE POLICY "Anyone can view active ad banners"
    ON ad_banners FOR SELECT
    TO anon, authenticated
    USING (
        is_active = true
        AND (start_date IS NULL OR start_date <= NOW())
        AND (end_date IS NULL OR end_date >= NOW())
    );

-- Only admins can insert/update/delete banners
CREATE POLICY "Only admins can manage ad banners"
    ON ad_banners FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = (current_setting('request.jwt.claims', true)::json->>'user_id')::bigint
            AND users.role = 'admin'
        )
    );

-- =====================================================
-- INSERT SAMPLE BANNERS
-- =====================================================

-- Insert sample banners (you can replace with your actual images)
INSERT INTO ad_banners (title, description, image_url, display_order, is_active) VALUES
    ('Welcome to Berner', 'Manage your expenses efficiently', 'https://via.placeholder.com/800x400/FF6B35/FFFFFF?text=Welcome+to+Berner', 1, true),
    ('Track Your Expenses', 'Keep track of all your business expenses', 'https://via.placeholder.com/800x400/004E89/FFFFFF?text=Track+Expenses', 2, true),
    ('Easy Approval Process', 'Get your expenses approved quickly', 'https://via.placeholder.com/800x400/1B998B/FFFFFF?text=Easy+Approvals', 3, true)
ON CONFLICT DO NOTHING;

-- =====================================================
-- HELPER FUNCTION: Get Active Banners
-- =====================================================

CREATE OR REPLACE FUNCTION get_active_banners(user_role TEXT DEFAULT NULL)
RETURNS TABLE (
    id BIGINT,
    title VARCHAR,
    description TEXT,
    image_url TEXT,
    link_url TEXT,
    link_type VARCHAR,
    action_data JSONB,
    display_order INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        b.id,
        b.title,
        b.description,
        b.image_url,
        b.link_url,
        b.link_type,
        b.action_data,
        b.display_order
    FROM ad_banners b
    WHERE b.is_active = true
        AND (b.start_date IS NULL OR b.start_date <= NOW())
        AND (b.end_date IS NULL OR b.end_date >= NOW())
        AND (b.target_roles IS NULL OR user_role = ANY(b.target_roles))
    ORDER BY b.display_order ASC, b.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_active_banners IS 'Fetch active banners for given user role, respecting scheduling and targeting';

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Check if table was created
SELECT
    'ad_banners table created' AS status,
    COUNT(*) AS banner_count
FROM ad_banners;

-- List all active banners
SELECT * FROM get_active_banners();
