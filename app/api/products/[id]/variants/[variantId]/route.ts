import { NextRequest } from 'next/server'
import { supabase } from '@/lib/supabase'
import { handleError, successResponse, ApiError } from '@/lib/errors'

export async function GET(
    request: NextRequest,
    { params }: { params: Promise<{ id: string; variantId: string }> }
) {
    try {
        const { variantId } = await params

        const { data, error } = await supabase
            .from('product_variants')
            .select('*')
            .eq('id', variantId)
            .single()

        if (error) throw error
        if (!data) throw new ApiError(404, 'Variant not found')

        return successResponse(data)
    } catch (error) {
        return handleError(error)
    }
}

export async function PUT(
    request: NextRequest,
    { params }: { params: Promise<{ id: string; variantId: string }> }
) {
    try {
        const { variantId } = await params
        const body = await request.json()

        const updateData: Record<string, unknown> = {}

        if (body.sku !== undefined) updateData.sku = body.sku
        if (body.color !== undefined) updateData.color = body.color
        if (body.color_hex !== undefined) updateData.color_hex = body.color_hex
        if (body.storage !== undefined) updateData.storage = body.storage
        if (body.condition !== undefined) updateData.condition = body.condition
        if (body.price !== undefined) updateData.price = body.price
        if (body.original_price !== undefined) updateData.original_price = body.original_price
        if (body.stock !== undefined) updateData.stock = body.stock
        if (body.is_available !== undefined) updateData.is_available = body.is_available
        if (body.images !== undefined) updateData.images = body.images

        // Handle condition_details as nested object
        if (body.battery_health !== undefined) updateData.battery_health = body.battery_health
        if (body.warranty_months !== undefined) updateData.warranty_months = body.warranty_months
        if (body.cosmetic_grade !== undefined) updateData.cosmetic_grade = body.cosmetic_grade
        if (body.functional_grade !== undefined) updateData.functional_grade = body.functional_grade
        if (body.tested !== undefined) updateData.tested = body.tested
        if (body.certified !== undefined) updateData.certified = body.certified
        if (body.refurbished !== undefined) updateData.refurbished = body.refurbished

        updateData.updated_at = new Date().toISOString()

        const { data, error } = await supabase
            .from('product_variants')
            .update(updateData)
            .eq('id', variantId)
            .select()
            .single()

        if (error) throw error
        if (!data) throw new ApiError(404, 'Variant not found')

        return successResponse(data)
    } catch (error) {
        return handleError(error)
    }
}

export async function DELETE(
    request: NextRequest,
    { params }: { params: Promise<{ id: string; variantId: string }> }
) {
    try {
        const { variantId } = await params

        const { error } = await supabase
            .from('product_variants')
            .delete()
            .eq('id', variantId)

        if (error) throw error

        return successResponse({ message: 'Variant deleted successfully' })
    } catch (error) {
        return handleError(error)
    }
}
