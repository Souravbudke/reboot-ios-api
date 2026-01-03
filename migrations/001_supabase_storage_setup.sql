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
