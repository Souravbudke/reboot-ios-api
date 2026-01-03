-- Migration: Add soft delete support to products table
-- This allows products to be "deleted" while preserving order history

-- Step 1: Add deleted_at column to products table
ALTER TABLE products ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- Step 2: Create index for faster queries on active products
CREATE INDEX IF NOT EXISTS idx_products_deleted_at ON products(deleted_at);

-- Step 3: Add comment for documentation
COMMENT ON COLUMN products.deleted_at IS 'Timestamp when product was soft deleted. NULL means product is active.';

-- Note: To query active products only, use: WHERE deleted_at IS NULL
-- Note: For order history, query all products (no filter on deleted_at)
