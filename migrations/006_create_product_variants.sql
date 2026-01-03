-- ============================================
-- Product Variants System for Pre-owned Electronics
-- Supports: Colors, Storage, Conditions, Tech Specs
-- ============================================

-- ============================================
-- Table 1: Product Variants
-- ============================================
CREATE TABLE IF NOT EXISTS product_variants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  
  -- Variant Details
  sku TEXT UNIQUE NOT NULL, -- Stock Keeping Unit
  color TEXT, -- e.g., "Midnight Black", "Silver", "Gold"
  color_hex TEXT, -- Hex code for color display
  storage TEXT, -- e.g., "64GB", "128GB", "256GB", "512GB", "1TB"
  condition TEXT NOT NULL DEFAULT 'excellent' CHECK (condition IN ('excellent', 'very_good', 'good', 'fair')),
  
  -- Pricing
  price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
  original_price DECIMAL(10, 2), -- Original retail price for comparison
  discount_percentage INTEGER, -- Calculated discount
  
  -- Inventory
  stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
  is_available BOOLEAN NOT NULL DEFAULT true,
  
  -- Images
  images JSONB DEFAULT '[]'::jsonb, -- Array of image URLs for this variant
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_product_variants_product_id ON product_variants(product_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_sku ON product_variants(sku);
CREATE INDEX IF NOT EXISTS idx_product_variants_color ON product_variants(color);
CREATE INDEX IF NOT EXISTS idx_product_variants_storage ON product_variants(storage);
CREATE INDEX IF NOT EXISTS idx_product_variants_condition ON product_variants(condition);
CREATE INDEX IF NOT EXISTS idx_product_variants_is_available ON product_variants(is_available);

-- ============================================
-- Table 2: Product Specifications
-- ============================================
CREATE TABLE IF NOT EXISTS product_specifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  
  -- Specification Details
  spec_key TEXT NOT NULL, -- e.g., "processor", "ram", "display", "battery"
  spec_label TEXT NOT NULL, -- e.g., "Processor", "RAM", "Display Size"
  spec_value TEXT NOT NULL, -- e.g., "Apple A15 Bionic", "8GB", "6.1 inches"
  spec_category TEXT, -- e.g., "performance", "display", "camera", "battery"
  display_order INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(product_id, spec_key)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_product_specifications_product_id ON product_specifications(product_id);
CREATE INDEX IF NOT EXISTS idx_product_specifications_category ON product_specifications(spec_category);

-- ============================================
-- Table 3: Product Condition Details
-- ============================================
CREATE TABLE IF NOT EXISTS product_condition_details (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  variant_id UUID NOT NULL REFERENCES product_variants(id) ON DELETE CASCADE,
  
  -- Condition Assessment
  cosmetic_grade TEXT, -- e.g., "Minimal scratches", "Light wear"
  functional_grade TEXT, -- e.g., "Fully functional", "Battery health 85%"
  battery_health INTEGER, -- Battery health percentage (for devices with batteries)
  warranty_months INTEGER DEFAULT 0, -- Warranty period in months
  
  -- Inspection Details
  tested BOOLEAN DEFAULT true,
  certified BOOLEAN DEFAULT false,
  refurbished BOOLEAN DEFAULT false,
  
  -- Additional Notes
  notes TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(variant_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_product_condition_details_variant_id ON product_condition_details(variant_id);

-- ============================================
-- Table 4: Product Images
-- ============================================
CREATE TABLE IF NOT EXISTS product_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  variant_id UUID REFERENCES product_variants(id) ON DELETE CASCADE,
  
  -- Image Details
  image_url TEXT NOT NULL,
  image_path TEXT, -- Storage path
  image_storage TEXT DEFAULT 'supabase' CHECK (image_storage IN ('pinata', 'supabase')),
  alt_text TEXT,
  is_primary BOOLEAN DEFAULT false,
  display_order INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_product_images_product_id ON product_images(product_id);
CREATE INDEX IF NOT EXISTS idx_product_images_variant_id ON product_images(variant_id);
CREATE INDEX IF NOT EXISTS idx_product_images_is_primary ON product_images(is_primary);

-- ============================================
-- Triggers for updated_at
-- ============================================
CREATE TRIGGER update_product_variants_updated_at 
  BEFORE UPDATE ON product_variants
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_product_condition_details_updated_at 
  BEFORE UPDATE ON product_condition_details
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Views for Easy Querying
-- ============================================

-- View: Products with all variants
CREATE OR REPLACE VIEW products_with_variants AS
SELECT 
  p.*,
  json_agg(
    json_build_object(
      'id', pv.id,
      'sku', pv.sku,
      'color', pv.color,
      'color_hex', pv.color_hex,
      'storage', pv.storage,
      'condition', pv.condition,
      'price', pv.price,
      'original_price', pv.original_price,
      'discount_percentage', pv.discount_percentage,
      'stock', pv.stock,
      'is_available', pv.is_available,
      'images', pv.images
    ) ORDER BY pv.price
  ) FILTER (WHERE pv.id IS NOT NULL) as variants
FROM products p
LEFT JOIN product_variants pv ON p.id = pv.product_id
GROUP BY p.id;

-- View: Variants with condition details
CREATE OR REPLACE VIEW variants_with_details AS
SELECT 
  pv.*,
  pcd.cosmetic_grade,
  pcd.functional_grade,
  pcd.battery_health,
  pcd.warranty_months,
  pcd.tested,
  pcd.certified,
  pcd.refurbished,
  pcd.notes as condition_notes
FROM product_variants pv
LEFT JOIN product_condition_details pcd ON pv.id = pcd.variant_id;

-- ============================================
-- Sample Data for Testing
-- ============================================

-- Example: iPhone 13 Pro with variants
DO $$
DECLARE
  product_uuid UUID;
  variant_uuid UUID;
BEGIN
  -- Insert a sample product (if not exists)
  INSERT INTO products (name, description, price, category, image, stock)
  VALUES (
    'iPhone 13 Pro',
    'Pre-owned iPhone 13 Pro in excellent condition. Fully tested and certified.',
    899.00,
    'Smartphones',
    'https://example.com/iphone13pro.jpg',
    10
  )
  ON CONFLICT DO NOTHING
  RETURNING id INTO product_uuid;

  -- If product was inserted, add variants
  IF product_uuid IS NOT NULL THEN
    -- Variant 1: Midnight Black, 128GB, Excellent
    INSERT INTO product_variants (
      product_id, sku, color, color_hex, storage, condition, 
      price, original_price, discount_percentage, stock, is_available
    )
    VALUES (
      product_uuid, 'IP13P-BLK-128-EXC', 'Midnight Black', '#1a1a1a', 
      '128GB', 'excellent', 899.00, 1099.00, 18, 3, true
    )
    RETURNING id INTO variant_uuid;

    -- Add condition details
    INSERT INTO product_condition_details (
      variant_id, cosmetic_grade, functional_grade, battery_health, 
      warranty_months, tested, certified, refurbished
    )
    VALUES (
      variant_uuid, 'Minimal wear, no scratches', 'Fully functional', 
      92, 6, true, true, true
    );

    -- Variant 2: Silver, 256GB, Very Good
    INSERT INTO product_variants (
      product_id, sku, color, color_hex, storage, condition, 
      price, original_price, discount_percentage, stock, is_available
    )
    VALUES (
      product_uuid, 'IP13P-SLV-256-VG', 'Silver', '#c0c0c0', 
      '256GB', 'very_good', 949.00, 1199.00, 21, 2, true
    )
    RETURNING id INTO variant_uuid;

    INSERT INTO product_condition_details (
      variant_id, cosmetic_grade, functional_grade, battery_health, 
      warranty_months, tested, certified, refurbished
    )
    VALUES (
      variant_uuid, 'Light wear on edges', 'Fully functional', 
      88, 6, true, true, true
    );

    -- Add specifications
    INSERT INTO product_specifications (product_id, spec_key, spec_label, spec_value, spec_category, display_order)
    VALUES 
      (product_uuid, 'processor', 'Processor', 'Apple A15 Bionic', 'performance', 1),
      (product_uuid, 'ram', 'RAM', '6GB', 'performance', 2),
      (product_uuid, 'display', 'Display', '6.1-inch Super Retina XDR', 'display', 3),
      (product_uuid, 'camera', 'Camera', 'Triple 12MP (Wide, Ultra Wide, Telephoto)', 'camera', 4),
      (product_uuid, 'battery', 'Battery', 'Up to 22 hours video playback', 'battery', 5),
      (product_uuid, 'os', 'Operating System', 'iOS 17', 'software', 6);
  END IF;
END $$;

-- ============================================
-- RLS Policies (Disable for now, enable later)
-- ============================================
ALTER TABLE product_variants DISABLE ROW LEVEL SECURITY;
ALTER TABLE product_specifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE product_condition_details DISABLE ROW LEVEL SECURITY;
ALTER TABLE product_images DISABLE ROW LEVEL SECURITY;

-- ============================================
-- Verification
-- ============================================
SELECT 'Migration 006: Product Variants System Created Successfully' as status;
