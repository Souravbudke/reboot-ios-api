-- ============================================
-- Multiple Images Support for Products and Variants
-- ============================================

-- ============================================
-- Step 1: Add images column to products table
-- ============================================
-- Add a JSONB column to store multiple images for products (when no variants exist)
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS images JSONB DEFAULT '[]'::jsonb;

-- Create index for faster queries on images
CREATE INDEX IF NOT EXISTS idx_products_images ON products USING GIN (images);

-- ============================================
-- Step 2: Migrate existing single image to images array
-- ============================================
-- Copy existing image to images array if not already done
UPDATE products 
SET images = jsonb_build_array(jsonb_build_object('url', image, 'order', 0))
WHERE images = '[]'::jsonb AND image IS NOT NULL AND image != '';

-- ============================================
-- Step 3: Add comment to clarify usage
-- ============================================
COMMENT ON COLUMN products.image IS 'Legacy single image field - kept for backward compatibility. Use images array for new products.';
COMMENT ON COLUMN products.images IS 'Array of image objects with url and order. Used when product has no variants.';
COMMENT ON COLUMN product_variants.images IS 'Array of image URLs for this specific variant. Each variant can have its own images.';

-- ============================================
-- Step 4: Create helper function to get product images
-- ============================================
-- This function returns the appropriate images based on whether product has variants
CREATE OR REPLACE FUNCTION get_product_images(p_product_id UUID)
RETURNS JSONB AS $$
DECLARE
  variant_count INTEGER;
  product_images JSONB;
BEGIN
  -- Check if product has variants
  SELECT COUNT(*) INTO variant_count
  FROM product_variants
  WHERE product_id = p_product_id;
  
  -- If has variants, return empty (variants handle their own images)
  IF variant_count > 0 THEN
    RETURN '[]'::jsonb;
  END IF;
  
  -- Otherwise return product images
  SELECT COALESCE(images, '[]'::jsonb) INTO product_images
  FROM products
  WHERE id = p_product_id;
  
  RETURN product_images;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Step 5: Update RLS policies if needed
-- ============================================
-- Ensure products table allows reading images
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Allow public read access to products" ON products;

-- Create policy for public read access
CREATE POLICY "Allow public read access to products"
ON products FOR SELECT
TO public
USING (true);

-- ============================================
-- Step 6: Add updated_at trigger for products if not exists
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists
DROP TRIGGER IF EXISTS update_products_updated_at ON products;

-- Create trigger
CREATE TRIGGER update_products_updated_at
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Migration Complete
-- ============================================
-- Products now support multiple images via images JSONB array
-- Variants already had images JSONB array support
-- Use product.images when no variants exist
-- Use variant.images for each specific variant
