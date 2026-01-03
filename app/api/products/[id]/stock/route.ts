import { NextRequest } from 'next/server'
import { supabase } from '@/lib/supabase'
import { handleError, successResponse, ApiError } from '@/lib/errors'

export async function PUT(
    request: NextRequest,
    { params }: { params: Promise<{ id: string }> }
) {
    try {
        const { id } = await params
        const body = await request.json()

        if (body.stock === undefined) {
            throw new ApiError(400, 'Stock value is required')
        }

        const { data, error } = await supabase
            .from('products')
            .update({
                stock: body.stock,
                updated_at: new Date().toISOString()
            })
            .eq('id', id)
            .select()
            .single()

        if (error) throw error
        if (!data) throw new ApiError(404, 'Product not found')

        return successResponse(data)
    } catch (error) {
        return handleError(error)
    }
}
