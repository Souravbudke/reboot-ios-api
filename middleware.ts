import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server'
import { NextResponse } from 'next/server'

// Define public routes that don't require authentication
const isPublicRoute = createRouteMatcher([
    '/api/products(.*)',
    '/api/categories(.*)',
    '/api/carousel(.*)',
    '/api/webhooks(.*)',  // Clerk webhooks must be public
    '/'
])

export default clerkMiddleware(async (auth, request) => {
    const response = NextResponse.next()

    // Add CORS headers
    response.headers.set('Access-Control-Allow-Origin', '*')
    response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
    response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-api-key')

    // Handle preflight requests
    if (request.method === 'OPTIONS') {
        return new NextResponse(null, {
            status: 204,
            headers: response.headers
        })
    }

    // SECURITY CHECK:
    // Allow access if a valid API Key is provided (for iOS App)
    // OR if the user is authenticated via Clerk
    const paramApiKey = request.headers.get('x-api-key')
    const validApiKey = process.env.API_SECRET_KEY || 'vfavU5jLSM59NdLKIaEIDd+STCgaijE2XLmITRA7wso='

    if (paramApiKey === validApiKey) {
        return response // Allow access with valid API Key
    }

    // Protect private routes
    if (!isPublicRoute(request)) {
        await auth.protect()
    }

    return response
})

export const config = {
    matcher: [
        // Skip Next.js internals and static files
        '/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)',
        // Always run for API routes
        '/(api|trpc)(.*)',
    ],
}
