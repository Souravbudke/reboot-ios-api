# Next.js Backend Setup Guide

## Getting Your API Keys

### 1. Supabase Service Role Key

1. Go to your Supabase Dashboard: https://app.supabase.com
2. Select your project
3. Go to **Project Settings** (gear icon) → **API**
4. Copy the `service_role` key (NOT the `anon` key)
5. ⚠️ **Keep this secret!** Never commit to git or expose to clients

### 2. Clerk Secret Key

1. Go to Clerk Dashboard: https://dashboard.clerk.com
2. Select your application (Reboot iOS)
3. Go to **API Keys** in the sidebar
4. Under **Secret Keys**, copy the key that starts with `sk_test_...`
5. ⚠️ **Keep this secret!** Never commit to git

## Setting Up Environment Variables

1. Create `.env.local` file in the `reboot-ios-api` directory:

```bash
cd /Users/souravbudke/Desktop/job_application_documents/projects/wevibe/reboot/xcode/reboot-ios-api
cp env-template.txt .env.local
```

2. Edit `.env.local` and add the keys you copied:

```env
SUPABASE_URL=https://wtnysxqseanefgddicyh.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<paste your service_role key here>

NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_c3dlZXQtdGFkcG9sZS0yNS5jbGVyay5hY2NvdW50cy5kZXYk
CLERK_SECRET_KEY=<paste your clerk secret key here>

NEXT_PUBLIC_API_URL=http://localhost:3000/api
```

## Testing the API Locally

1. Start the development server:

```bash
npm run dev
```

2. Test the API:

```bash
# Test root endpoint
curl http://localhost:3000

# Test products endpoint  
curl http://localhost:3000/api/products

# Test categories
curl http://localhost:3000/api/categories
```

## iOS App Configuration

### Bundle ID is NOT needed in the backend!

The bundle ID (`sourav.RebootiOS`) is configured in:
- **Xcode project settings** (iOS app)
- **Clerk iOS SDK** (in the iOS app)
- **Apple Developer Portal**

The backend only needs Clerk keys to verify authentication tokens from the iOS app.

### iOS Auth Flow

1. User signs in using Clerk iOS SDK in the app
2. iOS app gets a session token from Clerk
3. iOS app sends requests to your API with the token in headers:
   ```swift
   request.setValue("Bearer \(clerkToken)", forHTTPHeaderField: "Authorization")
   ```
4. Backend middleware validates the token with Clerk
5. If valid, processes the request

## Deployment to Vercel

1. Push code to GitHub
2. Import to Vercel
3. Add environment variables in Vercel:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY` 
   - `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`
   - `CLERK_SECRET_KEY`
   - `NEXT_PUBLIC_API_URL` (set to `https://your-app.vercel.app/api`)

4. Deploy!

Your API will be live at: `https://your-project-name.vercel.app`

## Next Steps

1. ✅ Get the secret keys from Supabase and Clerk
2. ✅ Create `.env.local` file
3. ✅ Test API locally with `npm run dev`
4. ✅ Run database migrations (if needed)
5. ✅ Deploy to Vercel
6. ✅ Update iOS app to use the API
