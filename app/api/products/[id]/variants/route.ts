import { NextRequest } from 'next/server'
import { supabase } from '@/lib/supabase'
import { handleError, successResponse } from '@/lib/errors'

export async function GET(
    request: NextRequest,
    { params }: { params: Promise<{ id: string }> }
) {
    try {
        const { id } = await params

        const { data, error } = await supabase
            .from('product_variants')
            .select('*')
            .eq('product_id', id)

        if (error) throw error

        return successResponse(data || [])
    } catch (error) {
        return handleError(error)
    }
}

export async function POST(
    request: NextRequest,
    { params }: { params: Promise<{ id: string }> }
) {
    try {
        const { id: productId } = await params
        const body = await request.json()

        const variantData = {
            product_id: productId,
            sku: body.sku || null,
            color: body.color || null,
            color_hex: body.color_hex || null,
            storage: body.storage || null,
            condition: body.condition || 'excellent',
            price: body.price || 0,
            original_price: body.original_price || null,
            discount_percentage: body.discount_percentage || null,
            stock: body.stock || 0,
            is_available: body.is_available !== false,
            images: body.images || [],
            battery_health: body.battery_health || null,
            warranty_months: body.warranty_months || 0,
            cosmetic_grade: body.cosmetic_grade || null,
            functional_grade: body.functional_grade || null,
            tested: body.tested !== false,
            certified: body.certified !== false,
            refurbished: body.refurbished !== false
        }

        const { data, error } = await supabase
            .from('product_variants')
            .insert(variantData)
            .select()
            .single()

        if (error) throw error

        return successResponse(data)
    } catch (error) {
        return handleError(error)
    }
}
