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
