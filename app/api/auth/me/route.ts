import { NextRequest } from 'next/server'
import { auth } from '@clerk/nextjs/server'
import { handleError, successResponse, ApiError } from '@/lib/errors'

// GET /api/auth/me - Get current user info
export async function GET(request: NextRequest) {
    try {
        const { userId } = await auth()

        if (!userId) {
            throw new ApiError(401, 'Unauthorized')
        }

        // Return user info from Clerk
        return successResponse({ userId })
    } catch (error) {
        return handleError(error)
    }
}
