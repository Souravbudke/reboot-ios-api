import { NextRequest } from 'next/server'
import { auth } from '@clerk/nextjs/server'
import { supabase } from '@/lib/supabase'
import { handleError, successResponse, ApiError } from '@/lib/errors'

export async function GET(
    request: NextRequest,
    { params }: { params: Promise<{ id: string }> }
) {
    try {
        const { userId } = await auth()

        if (!userId) {
            throw new ApiError(401, 'Unauthorized')
        }

        const { id } = await params

        const { data, error } = await supabase
            .from('orders')
            .select('*')
            .eq('id', id)
            .eq('user_id', userId) // Ensure user can only access their own orders
            .single()

        if (error) throw error
        if (!data) throw new ApiError(404, 'Order not found')

        return successResponse(data)
    } catch (error) {
        return handleError(error)
    }
}

export async function DELETE(
    request: NextRequest,
    { params }: { params: Promise<{ id: string }> }
) {
    try {
        const { userId } = await auth()

        if (!userId) {
            throw new ApiError(401, 'Unauthorized')
        }

        const { id } = await params

        // First delete order items
        await supabase
            .from('order_items')
            .delete()
            .eq('order_id', id)

        // Then delete the order
        const { error } = await supabase
            .from('orders')
            .delete()
            .eq('id', id)

        if (error) throw error

        return successResponse({ message: 'Order deleted successfully' })
    } catch (error) {
        return handleError(error)
    }
}
