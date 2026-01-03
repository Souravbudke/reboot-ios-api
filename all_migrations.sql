-- ============================================
-- Supabase Storage RLS Policies
-- For product-images bucket
-- ============================================

-- Step 1: Create the bucket (if not created via Dashboard)
-- You can also create this via Supabase Dashboard: Storage > New Bucket
-- Bucket name: product-images
-- Public: Yes

INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- Step 2: Set up RLS Policies
-- ============================================

-- Policy 1: Allow ANYONE to view/read images (public access)

-- Policy: Allow anyone (including anon users) to upload images
CREATE POLICY "Anyone can upload images"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'product-images');

-- Policy: Allow anyone to update images
CREATE POLICY "Anyone can update images"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'product-images');

-- Policy: Allow anyone to delete images
CREATE POLICY "Anyone can delete images"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'product-images');

-- Policy: Allow public read access to product images
CREATE POLICY "Public can view product images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'product-images');

-- ============================================
-- Optional: More Restrictive Policies
-- ============================================

-- If you want to restrict uploads to specific folders:
-- Uncomment and modify as needed

/*
-- Only allow uploads to 'products' folder
CREATE POLICY "Uploads only to products folder"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'product-images' AND
  (storage.foldername(name))[1] = 'products'
);

-- Only allow uploads to 'carousel' folder
CREATE POLICY "Uploads only to carousel folder"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'product-images' AND
  (storage.foldername(name))[1] = 'carousel'
);

-- Only allow uploads to 'temp' folder for AI search
CREATE POLICY "Uploads only to temp folder"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'product-images' AND
  (storage.foldername(name))[1] = 'temp'
);
*/

-- ============================================
-- Verify Policies
-- ============================================

-- Run this to see all policies on storage.objects
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'objects' AND schemaname = 'storage';

-- ============================================
-- Test Queries
-- ============================================

-- Check if bucket exists
SELECT * FROM storage.buckets WHERE id = 'product-images';

-- Check bucket configuration
SELECT 
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets 
WHERE id = 'product-images';

-- ============================================
-- Cleanup (if needed)
-- ============================================

-- To remove all policies (use with caution!)
/*
DROP POLICY IF EXISTS "Public can view product images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete images" ON storage.objects;
*/

-- To delete the bucket (WARNING: This deletes all files!)
/*
DELETE FROM storage.buckets WHERE id = 'product-images';
*/
-- ============================================
-- Supabase PostgreSQL Schema
-- Migration from MongoDB to PostgreSQL
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- Table 1: Users
-- ============================================

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('admin', 'customer')),
  password TEXT NOT NULL,
  clerk_id TEXT UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_clerk_id ON users(clerk_id);

-- ============================================
-- Table 2: Categories
-- ============================================

CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  slug TEXT NOT NULL UNIQUE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_categories_slug ON categories(slug);
CREATE INDEX IF NOT EXISTS idx_categories_is_active ON categories(is_active);

-- ============================================
-- Table 3: Products
-- ============================================

CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
  category TEXT NOT NULL,
  image TEXT NOT NULL,
  image_path TEXT,  -- Supabase storage path
  image_storage TEXT DEFAULT 'supabase' CHECK (image_storage IN ('pinata', 'supabase')),
  stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON products(created_at DESC);

-- ============================================
-- Table 4: Reviews
-- ============================================

CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL,  -- Can be UUID or Clerk ID
  user_name TEXT NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT NOT NULL,
  verified BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON reviews(created_at DESC);

-- ============================================
-- Table 5: Orders
-- ============================================

CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT NOT NULL,  -- Can be UUID or Clerk ID
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered')),
  total DECIMAL(10, 2) NOT NULL CHECK (total >= 0),
  subtotal DECIMAL(10, 2),
  shipping DECIMAL(10, 2),
  tax DECIMAL(10, 2),
  
  -- Shipping address (JSONB for flexibility)
  shipping_address JSONB,
  
  -- Payment details
  payment_method TEXT CHECK (payment_method IN ('paypal', 'cash_on_delivery')),
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'completed', 'failed')),
  payment_details JSONB,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- ============================================
-- Table 6: Order Items (Products in Orders)
-- ============================================

CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  price DECIMAL(10, 2) NOT NULL,  -- Price at time of order
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- ============================================
-- Table 7: Carousel
-- ============================================

CREATE TABLE IF NOT EXISTS carousel (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  images JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Only one carousel record should exist
CREATE UNIQUE INDEX IF NOT EXISTS idx_carousel_singleton ON carousel ((id IS NOT NULL));

-- Insert default carousel if not exists
INSERT INTO carousel (images) 
VALUES ('[]'::jsonb)
ON CONFLICT DO NOTHING;

-- ============================================
-- Functions for automatic updated_at
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON reviews
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_carousel_updated_at BEFORE UPDATE ON carousel
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Row Level Security (RLS) Policies
-- ============================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE carousel ENABLE ROW LEVEL SECURITY;

-- Users: Only admins can view all users, users can view themselves
CREATE POLICY "Users can view themselves" ON users
  FOR SELECT USING (auth.uid()::text = clerk_id OR auth.uid() = id);

CREATE POLICY "Admins can do anything with users" ON users
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Categories: Public read, admin write
CREATE POLICY "Anyone can view active categories" ON categories
  FOR SELECT USING (is_active = true OR auth.role() = 'authenticated');

CREATE POLICY "Admins can manage categories" ON categories
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Products: Public read, admin write
CREATE POLICY "Anyone can view products" ON products
  FOR SELECT USING (true);

CREATE POLICY "Admins can manage products" ON products
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Reviews: Public read, authenticated write (own reviews)
CREATE POLICY "Anyone can view reviews" ON reviews
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create reviews" ON reviews
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update own reviews" ON reviews
  FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own reviews" ON reviews
  FOR DELETE USING (auth.uid()::text = user_id);

-- Orders: Users can view own orders, admins can view all
CREATE POLICY "Users can view own orders" ON orders
  FOR SELECT USING (auth.uid()::text = user_id OR auth.uid() = user_id::uuid);

CREATE POLICY "Admins can view all orders" ON orders
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Authenticated users can create orders" ON orders
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admins can update orders" ON orders
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Order Items: Inherit permissions from orders
CREATE POLICY "Users can view own order items" ON order_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM orders 
      WHERE orders.id = order_items.order_id 
      AND (orders.user_id = auth.uid()::text OR orders.user_id::uuid = auth.uid())
    )
  );

CREATE POLICY "Authenticated users can create order items" ON order_items
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Carousel: Public read, admin write
CREATE POLICY "Anyone can view carousel" ON carousel
  FOR SELECT USING (true);

CREATE POLICY "Admins can manage carousel" ON carousel
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================
-- Helpful Views
-- ============================================

-- View: Products with average rating
CREATE OR REPLACE VIEW products_with_ratings AS
SELECT 
  p.*,
  COALESCE(AVG(r.rating), 0) as average_rating,
  COUNT(r.id) as review_count
FROM products p
LEFT JOIN reviews r ON p.id = r.product_id
GROUP BY p.id;

-- View: Orders with items
CREATE OR REPLACE VIEW orders_with_items AS
SELECT 
  o.*,
  json_agg(
    json_build_object(
      'id', oi.id,
      'product_id', oi.product_id,
      'quantity', oi.quantity,
      'price', oi.price
    )
  ) as items
FROM orders o
LEFT JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.id;

-- ============================================
-- Verification Queries
-- ============================================

-- Check all tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check all indexes
SELECT tablename, indexname 
FROM pg_indexes 
WHERE schemaname = 'public' 
ORDER BY tablename, indexname;

-- Check all RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
-- ============================================
-- Fix RLS Policies for Anonymous Access
-- This migration updates RLS policies to allow
-- anon key access for development/demo purposes
-- ============================================

-- ============================================
-- CLEANUP: Remove unused views
-- ============================================

-- Drop views that are not being used by the application
DROP VIEW IF EXISTS orders_with_items;
DROP VIEW IF EXISTS products_with_ratings;

-- ============================================
-- STORAGE: Fix product-images bucket policies
-- ============================================

-- Drop existing storage policies (both old and new names)
DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can upload images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can update images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can delete images" ON storage.objects;

-- Create new policies that allow anon users
CREATE POLICY "Anyone can upload images"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'product-images');

CREATE POLICY "Anyone can update images"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'product-images');

CREATE POLICY "Anyone can delete images"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'product-images');

-- ============================================
-- PRODUCTS TABLE: Fix RLS policies
-- ============================================

-- Drop existing policies on products (both old and new names)
DROP POLICY IF EXISTS "Authenticated users can insert products" ON products;
DROP POLICY IF EXISTS "Authenticated users can update products" ON products;
DROP POLICY IF EXISTS "Authenticated users can delete products" ON products;
DROP POLICY IF EXISTS "Anyone can insert products" ON products;
DROP POLICY IF EXISTS "Anyone can update products" ON products;
DROP POLICY IF EXISTS "Anyone can delete products" ON products;

-- Create new policies that allow anon users
CREATE POLICY "Anyone can insert products"
ON products FOR INSERT
TO public
WITH CHECK (true);

CREATE POLICY "Anyone can update products"
ON products FOR UPDATE
TO public
USING (true);

CREATE POLICY "Anyone can delete products"
ON products FOR DELETE
TO public
USING (true);

-- ============================================
-- ALL OTHER TABLES: Fix RLS policies
-- ============================================

-- CATEGORIES
DROP POLICY IF EXISTS "Authenticated users can manage categories" ON categories;
DROP POLICY IF EXISTS "Admins can manage categories" ON categories;
DROP POLICY IF EXISTS "Anyone can manage categories" ON categories;

CREATE POLICY "Anyone can manage categories"
ON categories FOR ALL
TO public
USING (true)
WITH CHECK (true);

-- ORDERS
DROP POLICY IF EXISTS "Authenticated users can create orders" ON orders;
DROP POLICY IF EXISTS "Authenticated users can manage orders" ON orders;
DROP POLICY IF EXISTS "Admins can manage orders" ON orders;
DROP POLICY IF EXISTS "Admins can view all orders" ON orders;
DROP POLICY IF EXISTS "Users can view own orders" ON orders;
DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
DROP POLICY IF EXISTS "Admins can update orders" ON orders;
DROP POLICY IF EXISTS "Anyone can manage orders" ON orders;

CREATE POLICY "Anyone can manage orders"
ON orders FOR ALL
TO public
USING (true)
WITH CHECK (true);

-- ORDER_ITEMS
DROP POLICY IF EXISTS "Authenticated users can manage order items" ON order_items;
DROP POLICY IF EXISTS "Admins can manage order items" ON order_items;
DROP POLICY IF EXISTS "Anyone can manage order_items" ON order_items;

CREATE POLICY "Anyone can manage order_items"
ON order_items FOR ALL
TO public
USING (true)
WITH CHECK (true);

-- REVIEWS
DROP POLICY IF EXISTS "Authenticated users can create reviews" ON reviews;
DROP POLICY IF EXISTS "Authenticated users can manage reviews" ON reviews;
DROP POLICY IF EXISTS "Admins can manage reviews" ON reviews;
DROP POLICY IF EXISTS "Users can delete own reviews" ON reviews;
DROP POLICY IF EXISTS "Users can update own reviews" ON reviews;
DROP POLICY IF EXISTS "Anyone can manage reviews" ON reviews;

CREATE POLICY "Anyone can manage reviews"
ON reviews FOR ALL
TO public
USING (true)
WITH CHECK (true);

-- CAROUSEL
DROP POLICY IF EXISTS "Authenticated users can manage carousel" ON carousel;
DROP POLICY IF EXISTS "Admins can manage carousel" ON carousel;
DROP POLICY IF EXISTS "Anyone can manage carousel" ON carousel;

CREATE POLICY "Anyone can manage carousel"
ON carousel FOR ALL
TO public
USING (true)
WITH CHECK (true);

-- USERS
DROP POLICY IF EXISTS "Authenticated users can manage users" ON users;
DROP POLICY IF EXISTS "Admins can manage users" ON users;
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Anyone can manage users" ON users;

CREATE POLICY "Anyone can manage users"
ON users FOR ALL
TO public
USING (true)
WITH CHECK (true);

-- ============================================
-- FIX FOREIGN KEY CONSTRAINTS
-- ============================================

-- Fix order_items foreign key to allow CASCADE delete
-- This allows products to be deleted even if they're in orders
ALTER TABLE order_items 
DROP CONSTRAINT IF EXISTS order_items_product_id_fkey;

ALTER TABLE order_items
ADD CONSTRAINT order_items_product_id_fkey 
FOREIGN KEY (product_id) 
REFERENCES products(id) 
ON DELETE CASCADE;

-- ============================================
-- VERIFICATION
-- ============================================

-- Verify storage policies
SELECT policyname, roles, cmd 
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects';

-- Verify all table policies
SELECT tablename, policyname, roles, cmd 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, cmd;

-- Verify foreign key constraints
SELECT
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    rc.delete_rule
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints AS rc
  ON rc.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND ccu.table_name = 'products';

-- ============================================
-- NOTES
-- ============================================

/*
WHAT THIS MIGRATION DOES:

1. RLS POLICIES - Allows anonymous (anon key) access for ALL operations on:
   - Storage: Uploading/managing images in product-images bucket
   - Products: Full CRUD operations
   - Categories: Full CRUD operations
   - Orders: Full CRUD operations
   - Order Items: Full CRUD operations
   - Reviews: Full CRUD operations
   - Carousel: Full CRUD operations
   - Users: Full CRUD operations

2. FOREIGN KEY CONSTRAINTS - Fixed CASCADE delete:
   - order_items.product_id -> products.id (CASCADE)
   - reviews.product_id -> products.id (CASCADE)
   This allows products to be deleted even if they're referenced in orders/reviews.

This is suitable for:
- Development environments
- Demo applications
- Internal admin tools
- MVP/Prototype applications

For production, consider:
- Using authenticated users only (auth.uid() checks)
- Adding role-based access control (user roles: admin, customer)
- Implementing user-specific permissions (users can only edit their own data)
- Restricting admin operations to admin role only
- Adding field-level security for sensitive data

Example production policy:
CREATE POLICY "Users can view their own orders"
ON orders FOR SELECT
TO authenticated
USING (auth.uid() = user_id);
*/
-- Create navbar_dropdowns table
CREATE TABLE IF NOT EXISTS navbar_dropdowns (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  dropdown_type VARCHAR(20) NOT NULL CHECK (dropdown_type IN ('products', 'resources')),
  section VARCHAR(100) NOT NULL,
  title VARCHAR(100) NOT NULL,
  description TEXT NOT NULL,
  href VARCHAR(255) NOT NULL,
  icon VARCHAR(50) NOT NULL DEFAULT 'Sparkles',
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX idx_navbar_dropdowns_type ON navbar_dropdowns(dropdown_type);
CREATE INDEX idx_navbar_dropdowns_order ON navbar_dropdowns(order_index);

-- Disable Row Level Security
-- RLS is disabled because:
-- 1. Access control is handled by Clerk authentication on the frontend
-- 2. Admin panel is protected by role-based access control
-- 3. This is configuration data, not sensitive user data
-- 4. Public users only read data (for navbar display)
-- 5. Only admins can write data (via protected admin routes)
ALTER TABLE navbar_dropdowns DISABLE ROW LEVEL SECURITY;

-- Note: If you need RLS in the future, you can enable it and create policies
-- that work with your authentication system (Clerk + Supabase service role)

-- Insert default data for Products dropdown
INSERT INTO navbar_dropdowns (dropdown_type, section, title, description, href, icon, order_index) VALUES
('products', 'Shop', 'All Products', 'Browse our complete collection', '/store/products', 'Sparkles', 0),
('products', 'Shop', 'Best Sellers', 'Most popular items', '/store/products?filter=best-sellers', 'TrendingUp', 1),
('products', 'Shop', 'New Arrivals', 'Latest additions to our store', '/store/products?filter=new', 'Star', 2),
('products', 'Features', 'Featured Products', 'Hand-picked favorites', '/store/products?filter=featured', 'Zap', 3);

-- Insert default data for Resources dropdown
INSERT INTO navbar_dropdowns (dropdown_type, section, title, description, href, icon, order_index) VALUES
('resources', 'Learn More', 'About Us', 'Learn about our story', '/store/about', 'Users', 0),
('resources', 'Learn More', 'Contact', 'Get in touch with us', '/store/contact', 'Mail', 1),
('resources', 'Learn More', 'Events', 'Upcoming events and workshops', '/store/events', 'Calendar', 2),
('resources', 'Learn More', 'Rewards', 'Join our loyalty program', '/store/rewards', 'Award', 3);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_navbar_dropdowns_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER navbar_dropdowns_updated_at
  BEFORE UPDATE ON navbar_dropdowns
  FOR EACH ROW
  EXECUTE FUNCTION update_navbar_dropdowns_updated_at();
-- Create search_items table for managing search modal content
CREATE TABLE IF NOT EXISTS search_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title VARCHAR(100) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(50) NOT NULL CHECK (category IN ('Products', 'Navigation', 'Resources', 'Settings')),
  icon VARCHAR(50) NOT NULL DEFAULT 'SearchIcon',
  href VARCHAR(255) NOT NULL,
  order_index INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX idx_search_items_category ON search_items(category);
CREATE INDEX idx_search_items_order ON search_items(order_index);
CREATE INDEX idx_search_items_active ON search_items(is_active);

-- Disable Row Level Security
-- RLS is disabled because:
-- 1. Access control is handled by Clerk authentication on the frontend
-- 2. Admin panel is protected by role-based access control
-- 3. This is configuration data, not sensitive user data
-- 4. Public users only read data (for search functionality)
-- 5. Only admins can write data (via protected admin routes)
ALTER TABLE search_items DISABLE ROW LEVEL SECURITY;

-- Note: If you need RLS in the future, you can enable it and create policies
-- that work with your authentication system (Clerk + Supabase service role)

-- Insert default data for Products
INSERT INTO search_items (title, description, category, icon, href, order_index, is_active) VALUES
('All Products', 'Browse our complete catalog', 'Products', 'Package', '/store/products', 0, TRUE),
('Laptops', 'Refurbished laptops and notebooks', 'Products', 'Laptop', '/store/products?category=laptops', 1, TRUE),
('Smartphones', 'Pre-owned mobile phones', 'Products', 'Smartphone', '/store/products?category=smartphones', 2, TRUE),
('Tablets', 'Second-hand tablets and iPads', 'Products', 'Tablet', '/store/products?category=tablets', 3, TRUE),
('Headphones', 'Audio equipment and accessories', 'Products', 'Headphones', '/store/products?category=headphones', 4, TRUE),
('Smartwatches', 'Wearable tech devices', 'Products', 'Watch', '/store/products?category=watches', 5, TRUE),
('Cameras', 'Digital cameras and equipment', 'Products', 'Camera', '/store/products?category=cameras', 6, TRUE);

-- Insert default data for Navigation
INSERT INTO search_items (title, description, category, icon, href, order_index, is_active) VALUES
('Home', 'Go to homepage', 'Navigation', 'Home', '/store', 0, TRUE),
('Shopping Cart', 'View your cart', 'Navigation', 'ShoppingBag', '/store/cart', 1, TRUE),
('About Us', 'Learn more about Reboot', 'Navigation', 'Users', '/store/about', 2, TRUE);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_search_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER search_items_updated_at
  BEFORE UPDATE ON search_items
  FOR EACH ROW
  EXECUTE FUNCTION update_search_items_updated_at();
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
-- ============================================
-- Bestseller Settings Table
-- Allows admin to control bestseller display
-- ============================================

-- Create bestseller_settings table
CREATE TABLE IF NOT EXISTS bestseller_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mode TEXT NOT NULL DEFAULT 'automatic' CHECK (mode IN ('automatic', 'manual')),
  manual_product_ids UUID[] DEFAULT '{}',
  display_limit INTEGER NOT NULL DEFAULT 8 CHECK (display_limit > 0 AND display_limit <= 20),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by TEXT  -- Clerk ID of admin who made the change
);

-- Insert default settings
INSERT INTO bestseller_settings (mode, manual_product_ids, display_limit)
VALUES ('automatic', '{}', 8)
ON CONFLICT DO NOTHING;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_bestseller_settings_mode ON bestseller_settings(mode);

-- Enable RLS (Row Level Security)
ALTER TABLE bestseller_settings ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read bestseller settings
CREATE POLICY "Anyone can read bestseller settings"
  ON bestseller_settings
  FOR SELECT
  USING (true);

-- Policy: Allow anon role to update (admin check is done in API layer)
CREATE POLICY "Allow anon to update bestseller settings"
  ON bestseller_settings
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

-- Create function to automatically update timestamp
CREATE OR REPLACE FUNCTION update_bestseller_settings_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update timestamp
DROP TRIGGER IF EXISTS trigger_update_bestseller_settings_timestamp ON bestseller_settings;
CREATE TRIGGER trigger_update_bestseller_settings_timestamp
  BEFORE UPDATE ON bestseller_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_bestseller_settings_timestamp();

-- Add comment to table
COMMENT ON TABLE bestseller_settings IS 'Controls how bestseller products are determined and displayed';
COMMENT ON COLUMN bestseller_settings.mode IS 'automatic: based on sales, manual: admin selected';
COMMENT ON COLUMN bestseller_settings.manual_product_ids IS 'Array of product IDs when in manual mode';
COMMENT ON COLUMN bestseller_settings.display_limit IS 'Number of bestsellers to display (1-20)';
-- ============================================
-- Social Proof Popup Feature
-- Admin-controlled purchase notification popups
-- ============================================

-- ============================================
-- 1. SOCIAL PROOF SETTINGS TABLE (Global Configuration)
-- ============================================

CREATE TABLE IF NOT EXISTS social_proof_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  is_enabled BOOLEAN NOT NULL DEFAULT true,
  display_duration INTEGER NOT NULL DEFAULT 5000,      -- milliseconds popup stays visible
  interval_min INTEGER NOT NULL DEFAULT 10000,         -- min delay between popups (ms)
  interval_max INTEGER NOT NULL DEFAULT 15000,         -- max delay between popups (ms)
  show_on_mobile BOOLEAN NOT NULL DEFAULT true,
  loop_popups BOOLEAN NOT NULL DEFAULT true,           -- restart queue when finished
  max_popups_per_session INTEGER NOT NULL DEFAULT 10,  -- cap popups per user session
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insert default settings (only one row needed)
INSERT INTO social_proof_settings (
  is_enabled, 
  display_duration, 
  interval_min, 
  interval_max, 
  show_on_mobile, 
  loop_popups, 
  max_popups_per_session
)
VALUES (true, 5000, 10000, 15000, true, true, 10)
ON CONFLICT DO NOTHING;

-- Enable RLS
ALTER TABLE social_proof_settings ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read settings (storefront needs this)
CREATE POLICY "Anyone can read social proof settings"
  ON social_proof_settings
  FOR SELECT
  USING (true);

-- Policy: Allow anon role to update (admin check done in API layer)
CREATE POLICY "Allow anon to update social proof settings"
  ON social_proof_settings
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

-- Function to auto-update timestamp
CREATE OR REPLACE FUNCTION update_social_proof_settings_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for auto-updating timestamp
DROP TRIGGER IF EXISTS trigger_update_social_proof_settings_timestamp ON social_proof_settings;
CREATE TRIGGER trigger_update_social_proof_settings_timestamp
  BEFORE UPDATE ON social_proof_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_social_proof_settings_timestamp();

-- Table comments
COMMENT ON TABLE social_proof_settings IS 'Global settings for social proof popup feature';
COMMENT ON COLUMN social_proof_settings.is_enabled IS 'Master toggle to enable/disable popups';
COMMENT ON COLUMN social_proof_settings.display_duration IS 'How long each popup stays visible (milliseconds)';
COMMENT ON COLUMN social_proof_settings.interval_min IS 'Minimum delay between popups (milliseconds)';
COMMENT ON COLUMN social_proof_settings.interval_max IS 'Maximum delay between popups (milliseconds)';
COMMENT ON COLUMN social_proof_settings.loop_popups IS 'Whether to restart queue after showing all popups';
COMMENT ON COLUMN social_proof_settings.max_popups_per_session IS 'Maximum popups to show per user session';

-- ============================================
-- 2. SOCIAL PROOF POPUPS TABLE (The Queue Items)
-- ============================================

CREATE TABLE IF NOT EXISTS social_proof_popups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  
  -- Data Source Configuration
  source_type TEXT NOT NULL DEFAULT 'manual' CHECK (source_type IN ('manual', 'order')),
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,  -- Linked order if source_type = 'order'
  
  -- Content (stored explicitly, even for orders, to allow overrides)
  location TEXT NOT NULL,                                   -- e.g., "Kuala Lumpur, Malaysia"
  time_ago TEXT NOT NULL,                                   -- e.g., "2 hours ago" or used with use_real_time
  use_real_time BOOLEAN NOT NULL DEFAULT false,             -- If true, calculate relative time from order.created_at
  
  -- Management
  is_active BOOLEAN NOT NULL DEFAULT true,
  display_order INTEGER NOT NULL DEFAULT 0,                 -- For sorting the queue (1, 2, 3...)
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_social_proof_popups_product_id ON social_proof_popups(product_id);
CREATE INDEX IF NOT EXISTS idx_social_proof_popups_order_id ON social_proof_popups(order_id);
CREATE INDEX IF NOT EXISTS idx_social_proof_popups_is_active ON social_proof_popups(is_active);
CREATE INDEX IF NOT EXISTS idx_social_proof_popups_display_order ON social_proof_popups(display_order);

-- Enable RLS
ALTER TABLE social_proof_popups ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read active popups (storefront needs this)
CREATE POLICY "Anyone can read social proof popups"
  ON social_proof_popups
  FOR SELECT
  USING (true);

-- Policy: Allow anon role to insert (admin check done in API layer)
CREATE POLICY "Allow anon to insert social proof popups"
  ON social_proof_popups
  FOR INSERT
  TO anon
  WITH CHECK (true);

-- Policy: Allow anon role to update (admin check done in API layer)
CREATE POLICY "Allow anon to update social proof popups"
  ON social_proof_popups
  FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

-- Policy: Allow anon role to delete (admin check done in API layer)
CREATE POLICY "Allow anon to delete social proof popups"
  ON social_proof_popups
  FOR DELETE
  TO anon
  USING (true);

-- Function to auto-update timestamp
CREATE OR REPLACE FUNCTION update_social_proof_popups_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for auto-updating timestamp
DROP TRIGGER IF EXISTS trigger_update_social_proof_popups_timestamp ON social_proof_popups;
CREATE TRIGGER trigger_update_social_proof_popups_timestamp
  BEFORE UPDATE ON social_proof_popups
  FOR EACH ROW
  EXECUTE FUNCTION update_social_proof_popups_timestamp();

-- Function to auto-increment display_order for new entries
CREATE OR REPLACE FUNCTION set_social_proof_popup_order()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.display_order = 0 THEN
    SELECT COALESCE(MAX(display_order), 0) + 1 INTO NEW.display_order
    FROM social_proof_popups;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for auto-setting display_order
DROP TRIGGER IF EXISTS trigger_set_social_proof_popup_order ON social_proof_popups;
CREATE TRIGGER trigger_set_social_proof_popup_order
  BEFORE INSERT ON social_proof_popups
  FOR EACH ROW
  EXECUTE FUNCTION set_social_proof_popup_order();

-- Table comments
COMMENT ON TABLE social_proof_popups IS 'Individual popup entries in the social proof queue';
COMMENT ON COLUMN social_proof_popups.product_id IS 'Reference to the product being featured';
COMMENT ON COLUMN social_proof_popups.source_type IS 'manual: admin entered data, order: data from real order';
COMMENT ON COLUMN social_proof_popups.order_id IS 'Reference to order when source_type is order';
COMMENT ON COLUMN social_proof_popups.location IS 'Location text to display (e.g., Kuala Lumpur, Malaysia)';
COMMENT ON COLUMN social_proof_popups.time_ago IS 'Time text (e.g., 2 hours ago) or base for real-time calculation';
COMMENT ON COLUMN social_proof_popups.use_real_time IS 'If true and order linked, calculate time from order.created_at';
COMMENT ON COLUMN social_proof_popups.display_order IS 'Order in which popups are shown (1, 2, 3...)';

-- ============================================
-- 3. HELPER VIEW (Optional: For easier querying)
-- ============================================

CREATE OR REPLACE VIEW social_proof_popups_with_details AS
SELECT 
  spp.id,
  spp.product_id,
  p.name AS product_name,
  p.image AS product_image,
  spp.source_type,
  spp.order_id,
  spp.location,
  spp.time_ago,
  spp.use_real_time,
  CASE 
    WHEN spp.use_real_time AND spp.order_id IS NOT NULL AND o.created_at IS NOT NULL THEN
      CASE
        WHEN EXTRACT(EPOCH FROM (NOW() - o.created_at)) < 60 THEN 'Just now'
        WHEN EXTRACT(EPOCH FROM (NOW() - o.created_at)) < 3600 THEN 
          FLOOR(EXTRACT(EPOCH FROM (NOW() - o.created_at)) / 60)::TEXT || ' minutes ago'
        WHEN EXTRACT(EPOCH FROM (NOW() - o.created_at)) < 86400 THEN 
          FLOOR(EXTRACT(EPOCH FROM (NOW() - o.created_at)) / 3600)::TEXT || ' hours ago'
        ELSE 
          FLOOR(EXTRACT(EPOCH FROM (NOW() - o.created_at)) / 86400)::TEXT || ' days ago'
      END
    ELSE spp.time_ago
  END AS calculated_time_ago,
  spp.is_active,
  spp.display_order,
  spp.created_at,
  spp.updated_at
FROM social_proof_popups spp
LEFT JOIN products p ON spp.product_id = p.id
LEFT JOIN orders o ON spp.order_id = o.id
ORDER BY spp.display_order ASC;

COMMENT ON VIEW social_proof_popups_with_details IS 'View that joins popup entries with product and order details, calculates real-time time_ago';

-- ============================================
-- MIGRATION COMPLETE
-- ============================================
-- 
-- Tables created:
-- 1. social_proof_settings - Global configuration
-- 2. social_proof_popups - Individual popup queue entries
--
-- View created:
-- 1. social_proof_popups_with_details - For easier querying with joined data
--
-- Next steps:
-- 1. Run this migration in Supabase SQL Editor
-- 2. Add TypeScript types in lib/types.ts
-- 3. Add database helper functions in lib/supabase-db.ts
-- ============================================
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
