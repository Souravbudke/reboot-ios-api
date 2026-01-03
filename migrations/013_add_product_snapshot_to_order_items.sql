-- Migration: Add product snapshot to order_items
-- This preserves product details (name, image, etc.) at time of order
-- Even if product is later deleted from inventory

-- Add product_snapshot column to store product details at time of order
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS product_snapshot JSONB;

-- Add comment for documentation
COMMENT ON COLUMN order_items.product_snapshot IS 'Snapshot of product details at time of order (name, image, description, etc.)';

-- Create index for faster queries on product snapshot
CREATE INDEX IF NOT EXISTS idx_order_items_product_snapshot ON order_items USING GIN (product_snapshot);

-- Note: New orders will store product snapshot automatically
-- Existing orders will show Product ID until re-ordered
