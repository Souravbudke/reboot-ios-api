import { NextRequest } from 'next/server'
import { auth } from '@clerk/nextjs/server'
import { supabase } from '@/lib/supabase'
import { handleError, successResponse, ApiError } from '@/lib/errors'
import { createOrderSchema } from '@/lib/validation'

// GET /api/orders - Get user's orders (Admin sees all)
export async function GET(request: NextRequest) {
    try {
        const { userId } = await auth()

        if (!userId) {
            throw new ApiError(401, 'Unauthorized')
        }

        // Check if user is admin
        const { data: userData } = await supabase
            .from('users')
            .select('role')
            .eq('clerk_id', userId)
            .single()

        const isAdmin = userData?.role === 'admin'

        let query = supabase
            .from('orders')
            .select('*')

        // If not admin, restrict to own orders
        if (!isAdmin) {
            query = query.eq('user_id', userId)
        }

        const { data, error } = await query.order('created_at', { ascending: false })

        if (error) throw error

        return successResponse(data || [])
    } catch (error) {
        return handleError(error)
    }
}

// POST /api/orders - Create new order
export async function POST(request: NextRequest) {
    try {
        const { userId } = await auth()

        if (!userId) {
            throw new ApiError(401, 'Unauthorized')
        }

        const body = await request.json()
        const validatedData = createOrderSchema.parse(body)

        // Create order in database
        const { data, error } = await supabase
            .from('orders')
            .insert({
                user_id: userId,
                items: validatedData.items,
                shipping_address: validatedData.shippingAddress,
                payment_method: validatedData.paymentMethod,
                status: 'pending'
            })
            .select()
            .single()

        if (error) throw error

        return successResponse(data, 201)
    } catch (error) {
        return handleError(error)
    }
}
