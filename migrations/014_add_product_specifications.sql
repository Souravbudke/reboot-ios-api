-- Migration: Add product specification columns
-- These columns store detailed product information for refurbished electronics

-- Add specification columns to products table
ALTER TABLE products ADD COLUMN IF NOT EXISTS color TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS color_hex TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS storage TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS condition TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS battery_health INTEGER CHECK (battery_health >= 0 AND battery_health <= 100);
ALTER TABLE products ADD COLUMN IF NOT EXISTS warranty_months INTEGER CHECK (warranty_months >= 0);
ALTER TABLE products ADD COLUMN IF NOT EXISTS cosmetic_grade TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS functional_grade TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS sku TEXT;

-- Add indexes for commonly filtered fields
CREATE INDEX IF NOT EXISTS idx_products_color ON products(color);
CREATE INDEX IF NOT EXISTS idx_products_storage ON products(storage);
CREATE INDEX IF NOT EXISTS idx_products_condition ON products(condition);
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku);

-- Add comments for documentation
COMMENT ON COLUMN products.color IS 'Product color (e.g., Space Gray, Silver)';
COMMENT ON COLUMN products.color_hex IS 'Hex color code for UI display';
COMMENT ON COLUMN products.storage IS 'Storage capacity (e.g., 128GB, 256GB)';
COMMENT ON COLUMN products.condition IS 'Product condition (e.g., Excellent, Good, Fair)';
COMMENT ON COLUMN products.battery_health IS 'Battery health percentage (0-100)';
COMMENT ON COLUMN products.warranty_months IS 'Warranty duration in months';
COMMENT ON COLUMN products.cosmetic_grade IS 'Cosmetic condition grade (e.g., A+, A, B)';
COMMENT ON COLUMN products.functional_grade IS 'Functional condition grade (e.g., A+, A, B)';
COMMENT ON COLUMN products.sku IS 'Stock Keeping Unit identifier';
