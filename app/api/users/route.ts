import { NextRequest } from 'next/server'
import { auth } from '@clerk/nextjs/server'
import { supabase } from '@/lib/supabase'
import { handleError, successResponse, ApiError } from '@/lib/errors'

export async function GET(request: NextRequest) {
    try {
        const { userId } = await auth()

        if (!userId) {
            throw new ApiError(401, 'Unauthorized - Please sign in')
        }

        // Check if user is admin
        const { data: currentUser } = await supabase
            .from('users')
            .select('role')
            .eq('clerk_id', userId)
            .single()

        if (currentUser?.role !== 'admin') {
            throw new ApiError(403, 'Admin access required')
        }

        const { searchParams } = new URL(request.url)
        const role = searchParams.get('role')

        // Get users with order counts
        let query = supabase
            .from('users')
            .select(`
                *,
                orders:orders(count)
            `)
            .order('created_at', { ascending: false })

        if (role) {
            query = query.eq('role', role)
        }

        const { data: users, error } = await query

        if (error) throw error

        // Transform to include order_count
        const usersWithOrderCount = (users || []).map((user: any) => ({
            ...user,
            order_count: user.orders?.[0]?.count || 0,
            orders: undefined,
        }))

        return successResponse(usersWithOrderCount)
    } catch (error) {
        return handleError(error)
    }
}

// DELETE /api/users - Delete a user
export async function DELETE(request: NextRequest) {
    try {
        const { userId } = await auth()

        if (!userId) {
            throw new ApiError(401, 'Unauthorized')
        }

        // Check if user is admin
        const { data: currentUser } = await supabase
            .from('users')
            .select('role')
            .eq('clerk_id', userId)
            .single()

        if (currentUser?.role !== 'admin') {
            throw new ApiError(403, 'Admin access required')
        }

        const { searchParams } = new URL(request.url)
        const deleteUserId = searchParams.get('id')

        if (!deleteUserId) {
            throw new ApiError(400, 'User ID required')
        }

        const { error } = await supabase
            .from('users')
            .delete()
            .eq('id', deleteUserId)

        if (error) throw error

        return successResponse({ message: 'User deleted' })
    } catch (error) {
        return handleError(error)
    }
}
