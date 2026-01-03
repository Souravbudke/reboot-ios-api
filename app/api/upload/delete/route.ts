import { NextRequest } from 'next/server'
import { supabase } from '@/lib/supabase'
import { handleError, successResponse, ApiError } from '@/lib/errors'

export async function POST(request: NextRequest) {
    try {
        const body = await request.json()
        const { path, bucket = 'product-images' } = body

        if (!path) {
            throw new ApiError(400, 'Path is required')
        }

        const { error } = await supabase.storage
            .from(bucket)
            .remove([path])

        if (error) throw error

        return successResponse({ message: 'File deleted successfully' })
    } catch (error) {
        return handleError(error)
    }
}
