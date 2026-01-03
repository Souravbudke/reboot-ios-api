import { NextRequest } from 'next/server'
import { auth } from '@clerk/nextjs/server'
import { supabase } from '@/lib/supabase'
import { handleError, successResponse, ApiError } from '@/lib/errors'

export async function PUT(
    request: NextRequest,
    { params }: { params: Promise<{ id: string }> }
) {
    try {
        const { userId } = await auth()

        if (!userId) {
            throw new ApiError(401, 'Unauthorized')
        }

        const { id } = await params
        const body = await request.json()

        if (!body.status) {
            throw new ApiError(400, 'Status is required')
        }

        const validStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled', 'cancelled_refunded']
        if (!validStatuses.includes(body.status)) {
            throw new ApiError(400, `Invalid status. Must be one of: ${validStatuses.join(', ')}`)
        }

        const { data, error } = await supabase
            .from('orders')
            .update({
                status: body.status,
                updated_at: new Date().toISOString()
            })
            .eq('id', id)
            .select()
            .single()

        if (error) throw error
        if (!data) throw new ApiError(404, 'Order not found')

        return successResponse(data)
    } catch (error) {
        return handleError(error)
    }
}
