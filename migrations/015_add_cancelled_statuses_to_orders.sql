-- Migration: Add cancelled and cancelled_refunded statuses to orders table
-- Date: 2025-12-21
-- Description: Updates the orders_status_check constraint to include 'cancelled' and 'cancelled_refunded' statuses
--              This enables order cancellation and refund tracking functionality

-- Drop the existing constraint
ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check;

-- Add the updated constraint with new statuses
ALTER TABLE orders ADD CONSTRAINT orders_status_check 
  CHECK (status = ANY (ARRAY[
    'pending'::text, 
    'processing'::text, 
    'shipped'::text, 
    'delivered'::text, 
    'cancelled'::text, 
    'cancelled_refunded'::text
  ]));

-- Add comment for documentation
COMMENT ON CONSTRAINT orders_status_check ON orders IS 'Valid order statuses: pending, processing, shipped, delivered, cancelled, cancelled_refunded';
