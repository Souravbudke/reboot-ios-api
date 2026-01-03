-- ============================================
-- Social Proof Popup Feature
-- Admin-controlled purchase notification popups
-- ============================================

-- ============================================
-- 1. SOCIAL PROOF SETTINGS TABLE (Global Configuration)
-- ============================================

CREATE TABLE IF NOT EXISTS social_proof_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  is_enabled BOOLEAN NOT NULL DEFAULT true,
  display_duration INTEGER NOT NULL DEFAULT 5000,      -- milliseconds popup stays visible
  interval_min INTEGER NOT NULL DEFAULT 10000,         -- min delay between popups (ms)
  interval_max INTEGER NOT NULL DEFAULT 15000,         -- max delay between popups (ms)
  show_on_mobile BOOLEAN NOT NULL DEFAULT true,
  loop_popups BOOLEAN NOT NULL DEFAULT true,           -- restart queue when finished
  max_popups_per_session INTEGER NOT NULL DEFAULT 10,  -- cap popups per user session
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insert default settings (only one row needed)
INSERT INTO social_proof_settings (
  is_enabled, 
  display_duration, 
  interval_min, 
  interval_max, 
  show_on_mobile, 
  loop_popups, 
  max_popups_per_session
)
VALUES (true, 5000, 10000, 15000, true, true, 10)
ON CONFLICT DO NOTHING;

-- Enable RLS
ALTER TABLE social_proof_settings ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read settings (storefront needs this)
CREATE POLICY "Anyone can read social proof settings"
  ON social_proof_settings
  FOR SELECT
  USING (true);

-- Policy: Allow anon role to update (admin check done in API layer)
CREATE POLICY "Allow anon to update social proof settings"
  ON social_proof_settings
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

-- Function to auto-update timestamp
CREATE OR REPLACE FUNCTION update_social_proof_settings_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for auto-updating timestamp
DROP TRIGGER IF EXISTS trigger_update_social_proof_settings_timestamp ON social_proof_settings;
CREATE TRIGGER trigger_update_social_proof_settings_timestamp
  BEFORE UPDATE ON social_proof_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_social_proof_settings_timestamp();

-- Table comments
COMMENT ON TABLE social_proof_settings IS 'Global settings for social proof popup feature';
COMMENT ON COLUMN social_proof_settings.is_enabled IS 'Master toggle to enable/disable popups';
COMMENT ON COLUMN social_proof_settings.display_duration IS 'How long each popup stays visible (milliseconds)';
COMMENT ON COLUMN social_proof_settings.interval_min IS 'Minimum delay between popups (milliseconds)';
COMMENT ON COLUMN social_proof_settings.interval_max IS 'Maximum delay between popups (milliseconds)';
COMMENT ON COLUMN social_proof_settings.loop_popups IS 'Whether to restart queue after showing all popups';
COMMENT ON COLUMN social_proof_settings.max_popups_per_session IS 'Maximum popups to show per user session';

-- ============================================
-- 2. SOCIAL PROOF POPUPS TABLE (The Queue Items)
-- ============================================

CREATE TABLE IF NOT EXISTS social_proof_popups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  
  -- Data Source Configuration
  source_type TEXT NOT NULL DEFAULT 'manual' CHECK (source_type IN ('manual', 'order')),
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,  -- Linked order if source_type = 'order'
  
  -- Content (stored explicitly, even for orders, to allow overrides)
  location TEXT NOT NULL,                                   -- e.g., "Kuala Lumpur, Malaysia"
  time_ago TEXT NOT NULL,                                   -- e.g., "2 hours ago" or used with use_real_time
  use_real_time BOOLEAN NOT NULL DEFAULT false,             -- If true, calculate relative time from order.created_at
  
  -- Management
  is_active BOOLEAN NOT NULL DEFAULT true,
  display_order INTEGER NOT NULL DEFAULT 0,                 -- For sorting the queue (1, 2, 3...)
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_social_proof_popups_product_id ON social_proof_popups(product_id);
CREATE INDEX IF NOT EXISTS idx_social_proof_popups_order_id ON social_proof_popups(order_id);
CREATE INDEX IF NOT EXISTS idx_social_proof_popups_is_active ON social_proof_popups(is_active);
CREATE INDEX IF NOT EXISTS idx_social_proof_popups_display_order ON social_proof_popups(display_order);

-- Enable RLS
ALTER TABLE social_proof_popups ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read active popups (storefront needs this)
CREATE POLICY "Anyone can read social proof popups"
  ON social_proof_popups
  FOR SELECT
  USING (true);

-- Policy: Allow anon role to insert (admin check done in API layer)
CREATE POLICY "Allow anon to insert social proof popups"
  ON social_proof_popups
  FOR INSERT
  TO anon
  WITH CHECK (true);

-- Policy: Allow anon role to update (admin check done in API layer)
CREATE POLICY "Allow anon to update social proof popups"
  ON social_proof_popups
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

-- Policy: Allow anon role to delete (admin check done in API layer)
CREATE POLICY "Allow anon to delete social proof popups"
  ON social_proof_popups
  FOR DELETE
  TO anon
  USING (true);

-- Function to auto-update timestamp
CREATE OR REPLACE FUNCTION update_social_proof_popups_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for auto-updating timestamp
DROP TRIGGER IF EXISTS trigger_update_social_proof_popups_timestamp ON social_proof_popups;
CREATE TRIGGER trigger_update_social_proof_popups_timestamp
  BEFORE UPDATE ON social_proof_popups
  FOR EACH ROW
  EXECUTE FUNCTION update_social_proof_popups_timestamp();

-- Function to auto-increment display_order for new entries
CREATE OR REPLACE FUNCTION set_social_proof_popup_order()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.display_order = 0 THEN
    SELECT COALESCE(MAX(display_order), 0) + 1 INTO NEW.display_order
    FROM social_proof_popups;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for auto-setting display_order
DROP TRIGGER IF EXISTS trigger_set_social_proof_popup_order ON social_proof_popups;
CREATE TRIGGER trigger_set_social_proof_popup_order
  BEFORE INSERT ON social_proof_popups
  FOR EACH ROW
  EXECUTE FUNCTION set_social_proof_popup_order();

-- Table comments
COMMENT ON TABLE social_proof_popups IS 'Individual popup entries in the social proof queue';
COMMENT ON COLUMN social_proof_popups.product_id IS 'Reference to the product being featured';
COMMENT ON COLUMN social_proof_popups.source_type IS 'manual: admin entered data, order: data from real order';
COMMENT ON COLUMN social_proof_popups.order_id IS 'Reference to order when source_type is order';
COMMENT ON COLUMN social_proof_popups.location IS 'Location text to display (e.g., Kuala Lumpur, Malaysia)';
COMMENT ON COLUMN social_proof_popups.time_ago IS 'Time text (e.g., 2 hours ago) or base for real-time calculation';
COMMENT ON COLUMN social_proof_popups.use_real_time IS 'If true and order linked, calculate time from order.created_at';
COMMENT ON COLUMN social_proof_popups.display_order IS 'Order in which popups are shown (1, 2, 3...)';

-- ============================================
-- 3. HELPER VIEW (Optional: For easier querying)
-- ============================================

CREATE OR REPLACE VIEW social_proof_popups_with_details AS
SELECT 
  spp.id,
  spp.product_id,
  p.name AS product_name,
  p.image AS product_image,
  spp.source_type,
  spp.order_id,
  spp.location,
  spp.time_ago,
  spp.use_real_time,
  CASE 
    WHEN spp.use_real_time AND spp.order_id IS NOT NULL AND o.created_at IS NOT NULL THEN
      CASE
        WHEN EXTRACT(EPOCH FROM (NOW() - o.created_at)) < 60 THEN 'Just now'
        WHEN EXTRACT(EPOCH FROM (NOW() - o.created_at)) < 3600 THEN 
          FLOOR(EXTRACT(EPOCH FROM (NOW() - o.created_at)) / 60)::TEXT || ' minutes ago'
        WHEN EXTRACT(EPOCH FROM (NOW() - o.created_at)) < 86400 THEN 
          FLOOR(EXTRACT(EPOCH FROM (NOW() - o.created_at)) / 3600)::TEXT || ' hours ago'
        ELSE 
          FLOOR(EXTRACT(EPOCH FROM (NOW() - o.created_at)) / 86400)::TEXT || ' days ago'
      END
    ELSE spp.time_ago
  END AS calculated_time_ago,
  spp.is_active,
  spp.display_order,
  spp.created_at,
  spp.updated_at
FROM social_proof_popups spp
LEFT JOIN products p ON spp.product_id = p.id
LEFT JOIN orders o ON spp.order_id = o.id
ORDER BY spp.display_order ASC;

COMMENT ON VIEW social_proof_popups_with_details IS 'View that joins popup entries with product and order details, calculates real-time time_ago';

-- ============================================
-- MIGRATION COMPLETE
-- ============================================
-- 
-- Tables created:
-- 1. social_proof_settings - Global configuration
-- 2. social_proof_popups - Individual popup queue entries
--
-- View created:
-- 1. social_proof_popups_with_details - For easier querying with joined data
--
-- Next steps:
-- 1. Run this migration in Supabase SQL Editor
-- 2. Add TypeScript types in lib/types.ts
-- 3. Add database helper functions in lib/supabase-db.ts
-- ============================================
