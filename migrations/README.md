# Database Migrations

## 📁 Migration Files

### 001_supabase_storage_setup.sql
**Purpose**: Set up Supabase Storage for images  
**Run on**: Supabase SQL Editor  
**Creates**:
- `product-images` bucket
- RLS policies for secure access
- Public read, authenticated write permissions

**How to run**:
1. Go to Supabase Dashboard → SQL Editor
2. Copy contents of this file
3. Paste and click "Run"
4. Verify in Storage tab

---

### 002_create_postgres_tables.sql
**Purpose**: Create all PostgreSQL tables  
**Run on**: Supabase SQL Editor  
**Creates**:
- 7 tables (users, products, categories, orders, order_items, reviews, carousel)
- Indexes for performance
- RLS policies for security
- Auto-update triggers
- Helpful views

**How to run**:
1. Go to Supabase Dashboard → SQL Editor
2. Copy contents of this file
3. Paste and click "Run"
4. Verify in Table Editor

---

## 🚀 Quick Start

### Step 1: Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Create new project
3. Save your credentials

### Step 2: Run Migrations
```bash
# Run in order:
1. 001_supabase_storage_setup.sql
2. 002_create_postgres_tables.sql
```

### Step 3: Update .env
```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_BUCKET_NAME=product-images
```

### Step 4: Install Dependencies
```bash
npm install @supabase/supabase-js
```

---

## 📊 Database Schema

### Tables Created

1. **users** - User accounts
   - id (UUID, PK)
   - name, email, role, password
   - clerk_id (for Clerk integration)
   - created_at, updated_at

2. **products** - Product catalog
   - id (UUID, PK)
   - name, description, price, category
   - image, image_path, image_storage
   - stock
   - created_at, updated_at

3. **categories** - Product categories
   - id (UUID, PK)
   - name, description, slug
   - is_active
   - created_at, updated_at

4. **orders** - Customer orders
   - id (UUID, PK)
   - user_id, status, total
   - shipping_address (JSONB)
   - payment_method, payment_status, payment_details
   - created_at, updated_at

5. **order_items** - Products in orders
   - id (UUID, PK)
   - order_id (FK), product_id (FK)
   - quantity, price
   - created_at

6. **reviews** - Product reviews
   - id (UUID, PK)
   - product_id (FK), user_id, user_name
   - rating, comment, verified
   - created_at, updated_at

7. **carousel** - Homepage carousel
   - id (UUID, PK)
   - images (JSONB array)
   - created_at, updated_at

---

## 🔐 Security (RLS Policies)

All tables have Row Level Security enabled:

- **Public can**: View products, categories, reviews, carousel
- **Authenticated can**: Create orders, reviews; View own orders
- **Admins can**: Manage everything

---

## ✅ Verification

After running migrations, verify:

```sql
-- Check tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check RLS policies
SELECT tablename, policyname FROM pg_policies
WHERE schemaname = 'public';

-- Check storage bucket
SELECT * FROM storage.buckets WHERE id = 'product-images';
```

---

## 🔄 Rollback

If you need to undo migrations:

```sql
-- Drop all tables (WARNING: Deletes all data!)
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS carousel CASCADE;

-- Drop storage bucket
DELETE FROM storage.buckets WHERE id = 'product-images';
```

---

## 📝 Notes

- Run migrations in order (001, 002, etc.)
- Each migration is idempotent (safe to run multiple times)
- Verify each migration before proceeding
- Keep MongoDB running during transition
- Test thoroughly before removing MongoDB

---

## 🆘 Troubleshooting

### "Bucket already exists"
- Safe to ignore, or remove `ON CONFLICT DO NOTHING`

### "Table already exists"
- Safe to ignore, migrations use `IF NOT EXISTS`

### "Permission denied"
- Check you're using the correct Supabase project
- Verify you're logged in to Supabase Dashboard

### "RLS policy error"
- Check auth.uid() is available
- Verify users table exists first

---

**Need help?** Check the complete migration plan in `mdfiles/imagemigration/COMPLETE_MIGRATION_PLAN.md`
