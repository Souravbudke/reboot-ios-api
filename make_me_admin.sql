-- 1. Go to your Supabase Dashboard -> SQL Editor
-- 2. Paste the following query to make yourself an admin
-- 3. Replace 'your_email@example.com' with your actual email address used to sign in

UPDATE users
SET role = 'admin'
WHERE email = 'souravbudke@gmail.com';

-- 4. Run the query.
-- 5. Sign Out and Sign In again in the iOS App for changes to take effect.
