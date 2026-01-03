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
