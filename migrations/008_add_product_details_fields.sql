-- ============================================
-- Add Product Details Fields for Products Without Variants
-- ============================================

-- Add new columns to products table
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS color TEXT,
ADD COLUMN IF NOT EXISTS color_hex TEXT,
ADD COLUMN IF NOT EXISTS storage TEXT,
ADD COLUMN IF NOT EXISTS condition TEXT CHECK (condition IN ('excellent', 'very_good', 'good', 'fair')),
ADD COLUMN IF NOT EXISTS original_price DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS battery_health INTEGER CHECK (battery_health >= 0 AND battery_health <= 100),
ADD COLUMN IF NOT EXISTS warranty_months INTEGER CHECK (warranty_months >= 0),
ADD COLUMN IF NOT EXISTS cosmetic_grade TEXT,
ADD COLUMN IF NOT EXISTS functional_grade TEXT;

-- Add comments
COMMENT ON COLUMN products.color IS 'Product color (for products without variants)';
COMMENT ON COLUMN products.color_hex IS 'Product color hex code (for products without variants)';
COMMENT ON COLUMN products.storage IS 'Product storage/capacity (for products without variants)';
COMMENT ON COLUMN products.condition IS 'Product condition (for products without variants)';
COMMENT ON COLUMN products.original_price IS 'Original price before discount (for products without variants)';
COMMENT ON COLUMN products.battery_health IS 'Battery health percentage 0-100 (for products without variants)';
COMMENT ON COLUMN products.warranty_months IS 'Warranty period in months (for products without variants)';
COMMENT ON COLUMN products.cosmetic_grade IS 'Cosmetic condition description (for products without variants)';
COMMENT ON COLUMN products.functional_grade IS 'Functional condition description (for products without variants)';

-- Create indexes for commonly queried fields
CREATE INDEX IF NOT EXISTS idx_products_condition ON products(condition) WHERE condition IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_products_storage ON products(storage) WHERE storage IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_products_color ON products(color) WHERE color IS NOT NULL;
