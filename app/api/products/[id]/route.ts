import { NextRequest } from 'next/server'
import { supabase } from '@/lib/supabase'
import { handleError, successResponse, ApiError } from '@/lib/errors'

export async function GET(
    request: NextRequest,
    { params }: { params: Promise<{ id: string }> }
) {
    try {
        const { id } = await params

        const { data, error } = await supabase
            .from('products')
            .select('*')
            .eq('id', id)
            .single()

        if (error) throw error
        if (!data) throw new ApiError(404, 'Product not found')

        return successResponse(data)
    } catch (error) {
        return handleError(error)
    }
}

export async function PUT(
    request: NextRequest,
    { params }: { params: Promise<{ id: string }> }
) {
    try {
        const { id } = await params
        const body = await request.json()

        const updateData: Record<string, unknown> = {}

        // Only include fields that are provided
        if (body.name !== undefined) updateData.name = body.name
        if (body.description !== undefined) updateData.description = body.description
        if (body.price !== undefined) updateData.price = body.price
        if (body.category !== undefined) updateData.category = body.category
        if (body.image !== undefined) updateData.image = body.image
        if (body.stock !== undefined) updateData.stock = body.stock

        updateData.updated_at = new Date().toISOString()

        const { data, error } = await supabase
            .from('products')
            .update(updateData)
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

export async function DELETE(
    request: NextRequest,
    { params }: { params: Promise<{ id: string }> }
) {
    try {
        const { id } = await params

        // First delete related variants
        await supabase
            .from('product_variants')
            .delete()
            .eq('product_id', id)

        // Then delete the product
        const { error } = await supabase
            .from('products')
            .delete()
            .eq('id', id)

        if (error) throw error

        return successResponse({ message: 'Product deleted successfully' })
    } catch (error) {
        return handleError(error)
    }
}
