# Reboot iOS API

Next.js backend API for the RebootiOS mobile application. This API serves as middleware between the iOS app and Supabase database, providing authentication via Clerk and data access endpoints.

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ installed
- Supabase project
- Clerk account

### Installation

```bash
cd reboot-ios-api
npm install
```

### Environment Variables

Create a `.env.local` file in the root directory:

```env
SUPABASE_URL=https://wtnysxqseanefgddicyh.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key_here

NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_c3dlZXQtdGFkcG9sZS0yNS5jbGVyay5hY2NvdW50cy5kZXYk
CLERK_SECRET_KEY=your_clerk_secret_key_here

NEXT_PUBLIC_API_URL=http://localhost:3000/api
```

> **Note:** Get your Supabase Service Role Key from: Supabase Dashboard → Project Settings → API → service_role key
> 
> Get your Clerk Secret Key from: Clerk Dashboard → API Keys → Secret keys

### Development

```bash
npm run dev
```

API will be available at `http://localhost:3000`

### Production Build

```bash
npm run build
npm start
```

## 📡 API Endpoints

### Public Endpoints (No Authentication Required)

#### Products

**GET `/api/products`**
- Get all products with optional filtering
- Query params:
  - `category` - Filter by category slug
  - `search` - Search in name and description
  - `minPrice` - Minimum price filter
  - `maxPrice` - Maximum price filter
  - `condition` - Filter by condition (Excellent, Good, Fair)
  - `sort` - Sort by: `newest`, `price_low`, `price_high`, `popular`

**GET `/api/products/[id]`**
- Get single product by ID

**GET `/api/products/[id]/variants`**
- Get product variants

**GET `/api/products/[id]/reviews`**
- Get product reviews

#### Categories

**GET `/api/categories`**
- Get all active categories

#### Carousel

**GET `/api/carousel`**
- Get carousel images for home screen

### Protected Endpoints (Require Authentication)

#### Orders

**GET `/api/orders`**
- Get all orders for authenticated user

**POST `/api/orders`**
- Create new order
- Body:
```json
{
  "items": [
    {
      "productId": "uuid",
      "variantId": "uuid", // optional
      "quantity": 1
    }
  ],
  "shippingAddress": {
    "name": "John Doe",
    "addressLine1": "123 Main St",
    "addressLine2": "Apt 4",
    "city": "Mumbai",
    "state": "Maharashtra",
    "postalCode": "400001",
    "country": "IN"
  },
  "paymentMethod": "card"
}
```

**GET `/api/orders/[id]`**
- Get single order by ID (only user's own orders)

#### Auth

**GET `/api/auth/me`**
- Get current authenticated user info

## 🔐 Authentication

This API uses Clerk for authentication. Protected endpoints require a valid Clerk session token in the request headers.

### iOS Integration

When calling protected endpoints from iOS:

```swift
// Add Clerk session token to headers
request.setValue("Bearer \(clerkToken)", forHTTPHeaderField: "Authorization")
```

## 🔧 Project Structure

```
reboot-ios-api/
├── app/
│   ├── api/
│   │   ├── auth/
│   │   │   └── me/route.ts
│   │   ├── products/
│   │   │   ├── route.ts
│   │   │   └── [id]/
│   │   │       ├── route.ts
│   │   │       ├── variants/route.ts
│   │   │       └── reviews/route.ts
│   │   ├── categories/route.ts
│   │   ├── carousel/route.ts
│   │   └── orders/
│   │       ├── route.ts
│   │       └── [id]/route.ts
│   └── route.ts
├── lib/
│   ├── supabase.ts       # Supabase client config
│   ├── errors.ts         # Error handling utilities
│   └── validation.ts     # Zod validation schemas
├── middleware.ts         # Clerk auth + CORS
└── package.json
```

## 🌐 CORS

CORS is configured in `middleware.ts` to allow requests from any origin. For production, update to restrict to your iOS app domain.

## 🚢 Deployment (Vercel)

1. Push code to GitHub
2. Import project to Vercel
3. Add environment variables in Vercel dashboard
4. Deploy

Vercel will automatically detect Next.js and configure deployment.

## 📝 Environment Variables for Vercel

Add these in Vercel Dashboard → Settings → Environment Variables:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`
- `CLERK_SECRET_KEY`
- `NEXT_PUBLIC_API_URL` (set to your Vercel deployment URL)

## 🧪 Testing

Test endpoints using curl or Postman:

```bash
# Test products endpoint
curl http://localhost:3000/api/products

# Test with filters
curl "http://localhost:3000/api/products?category=smartphones&sort=price_low"

# Test single product
curl http://localhost:3000/api/products/YOUR_PRODUCT_ID
```

## 📚 Database Schema

This API expects the following Supabase tables:

- `products` - Product catalog
- `product_variants` - Product variations (size, color, etc.)
- `categories` - Product categories
- `orders` - User orders
- `reviews` - Product reviews
- `carousel` - Homepage carousel images

Run migrations using the Supabase MCP server or dashboard.

## 🔄 iOS App Integration

### Update APIService

Replace `SupabaseService.swift` with API calls to this backend:

```swift
// Before: Direct Supabase
let url = URL(string: "https://wtnysxqseanefgddicyh.supabase.co/rest/v1/products")

// After: Next.js API
let url = URL(string: "https://your-app.vercel.app/api/products")
```

### Auth Token

Use Clerk iOS SDK to get session token and include in API requests.

## 📄 License

MIT

## 👤 Author

Sourav Budke
