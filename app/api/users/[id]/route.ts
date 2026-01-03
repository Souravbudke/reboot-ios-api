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
            .from('users')
            .select('*')
            .eq('id', id)
            .single()

        if (error) throw error
        if (!data) throw new ApiError(404, 'User not found')

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
        if (body.email !== undefined) updateData.email = body.email
        if (body.role !== undefined) updateData.role = body.role
        if (body.avatar_url !== undefined) updateData.avatar_url = body.avatar_url

        updateData.updated_at = new Date().toISOString()

        const { data, error } = await supabase
            .from('users')
            .update(updateData)
            .eq('id', id)
            .select()
            .single()

        if (error) throw error
        if (!data) throw new ApiError(404, 'User not found')

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
            .from('users')
            .delete()
            .eq('id', id)

        if (error) throw error

        return successResponse({ message: 'User deleted successfully' })
    } catch (error) {
        return handleError(error)
    }
}
