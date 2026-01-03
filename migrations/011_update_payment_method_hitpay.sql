-- Migration: Update payment_method constraint for HitPay
-- Replace PayPal with HitPay as the only payment method

-- Step 1: Drop existing constraint
ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_payment_method_check;

-- Step 2: Add new constraint for HitPay only
ALTER TABLE orders ADD CONSTRAINT orders_payment_method_check 
  CHECK (payment_method IN ('hitpay'));

-- Step 3: Verify the change
SELECT DISTINCT payment_method FROM orders;

-- Note: Existing orders with 'paypal' or 'cash_on_delivery' will need to be handled
-- You may want to update them or keep them as historical data
