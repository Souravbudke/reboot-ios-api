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
            .from('product_specifications')
            .select('*')
            .eq('product_id', id)
            .order('display_order', { ascending: true })

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

        const specData = {
            product_id: productId,
            spec_key: body.spec_key,
            spec_label: body.spec_label,
            spec_value: body.spec_value,
            spec_category: body.spec_category || 'other',
            display_order: body.display_order || 0
        }

        const { data, error } = await supabase
            .from('product_specifications')
            .insert(specData)
            .select()
            .single()

        if (error) throw error

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
        const { id: productId } = await params
        const { searchParams } = new URL(request.url)
        const specId = searchParams.get('specId')

        if (specId) {
            // Delete specific specification
            const { error } = await supabase
                .from('product_specifications')
                .delete()
                .eq('id', specId)

            if (error) throw error
        } else {
            // Delete all specifications for product
            const { error } = await supabase
                .from('product_specifications')
                .delete()
                .eq('product_id', productId)

            if (error) throw error
        }

        return successResponse({ message: 'Specifications deleted successfully' })
    } catch (error) {
        return handleError(error)
    }
}
