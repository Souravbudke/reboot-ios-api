-- ============================================
-- Migration 007: Add Variant Support to Order Items
-- ============================================
-- This migration adds variant_id column to order_items table
-- to support variant-based product orders

-- Add variant_id column to order_items
ALTER TABLE order_items 
ADD COLUMN IF NOT EXISTS variant_id UUID REFERENCES product_variants(id) ON DELETE SET NULL;

-- Create index for faster variant lookups
CREATE INDEX IF NOT EXISTS idx_order_items_variant_id ON order_items(variant_id);

-- Update the constraint on product_id to allow NULL when variant_id is present
-- This way, for variant-based orders, we can store the variant_id instead
-- For backward compatibility, product_id can still be used for non-variant products
ALTER TABLE order_items 
ALTER COLUMN product_id DROP NOT NULL;

-- Add a check constraint to ensure either product_id or variant_id is present
ALTER TABLE order_items
ADD CONSTRAINT order_items_product_or_variant_check 
CHECK (product_id IS NOT NULL OR variant_id IS NOT NULL);

-- Comments for documentation
COMMENT ON COLUMN order_items.variant_id IS 'Reference to product variant if order item is a variant-based product';
COMMENT ON CONSTRAINT order_items_product_or_variant_check ON order_items IS 'Ensures either product_id or variant_id is present for each order item';
