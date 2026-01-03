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
            .from('categories')
            .select('*')
            .eq('id', id)
            .single()

        if (error) throw error
        if (!data) throw new ApiError(404, 'Category not found')

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

        if (body.name !== undefined) updateData.name = body.name
        if (body.slug !== undefined) updateData.slug = body.slug
        if (body.description !== undefined) updateData.description = body.description
        if (body.image !== undefined) updateData.image = body.image
        if (body.icon !== undefined) updateData.icon = body.icon
        if (body.isActive !== undefined) updateData.is_active = body.isActive

        updateData.updated_at = new Date().toISOString()

        const { data, error } = await supabase
            .from('categories')
            .update(updateData)
            .eq('id', id)
            .select()
            .single()

        if (error) throw error
        if (!data) throw new ApiError(404, 'Category not found')

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

        const { error } = await supabase
            .from('categories')
            .delete()
            .eq('id', id)

        if (error) throw error

        return successResponse({ message: 'Category deleted successfully' })
    } catch (error) {
        return handleError(error)
    }
}
