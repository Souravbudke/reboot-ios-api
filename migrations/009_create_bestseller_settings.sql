-- ============================================
-- Bestseller Settings Table
-- Allows admin to control bestseller display
-- ============================================

-- Create bestseller_settings table
CREATE TABLE IF NOT EXISTS bestseller_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mode TEXT NOT NULL DEFAULT 'automatic' CHECK (mode IN ('automatic', 'manual')),
  manual_product_ids UUID[] DEFAULT '{}',
  display_limit INTEGER NOT NULL DEFAULT 8 CHECK (display_limit > 0 AND display_limit <= 20),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by TEXT  -- Clerk ID of admin who made the change
);

-- Insert default settings
INSERT INTO bestseller_settings (mode, manual_product_ids, display_limit)
VALUES ('automatic', '{}', 8)
ON CONFLICT DO NOTHING;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_bestseller_settings_mode ON bestseller_settings(mode);

-- Enable RLS (Row Level Security)
ALTER TABLE bestseller_settings ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read bestseller settings
CREATE POLICY "Anyone can read bestseller settings"
  ON bestseller_settings
  FOR SELECT
  USING (true);

-- Policy: Allow anon role to update (admin check is done in API layer)
CREATE POLICY "Allow anon to update bestseller settings"
  ON bestseller_settings
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

-- Create function to automatically update timestamp
CREATE OR REPLACE FUNCTION update_bestseller_settings_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update timestamp
DROP TRIGGER IF EXISTS trigger_update_bestseller_settings_timestamp ON bestseller_settings;
CREATE TRIGGER trigger_update_bestseller_settings_timestamp
  BEFORE UPDATE ON bestseller_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_bestseller_settings_timestamp();

-- Add comment to table
COMMENT ON TABLE bestseller_settings IS 'Controls how bestseller products are determined and displayed';
COMMENT ON COLUMN bestseller_settings.mode IS 'automatic: based on sales, manual: admin selected';
COMMENT ON COLUMN bestseller_settings.manual_product_ids IS 'Array of product IDs when in manual mode';
COMMENT ON COLUMN bestseller_settings.display_limit IS 'Number of bestsellers to display (1-20)';
