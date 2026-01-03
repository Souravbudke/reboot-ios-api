-- Add missing columns to product_variants table
ALTER TABLE product_variants 
ADD COLUMN IF NOT EXISTS battery_health INTEGER,
ADD COLUMN IF NOT EXISTS warranty_months INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS cosmetic_grade TEXT,
ADD COLUMN IF NOT EXISTS functional_grade TEXT,
ADD COLUMN IF NOT EXISTS tested BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS certified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS refurbished BOOLEAN DEFAULT false;
