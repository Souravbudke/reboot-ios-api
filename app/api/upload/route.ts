import { NextRequest } from 'next/server'
import { supabase } from '@/lib/supabase'
import { handleError, successResponse, ApiError } from '@/lib/errors'

export async function POST(request: NextRequest) {
    try {
        const formData = await request.formData()
        const file = formData.get('file') as File
        const bucket = (formData.get('bucket') as string) || 'product-images'
        const folder = (formData.get('folder') as string) || ''

        if (!file) {
            throw new ApiError(400, 'No file provided')
        }

        // Convert file to buffer
        const bytes = await file.arrayBuffer()
        const buffer = Buffer.from(bytes)

        // Generate unique filename
        const timestamp = Date.now()
        const extension = file.name.split('.').pop()
        const filename = folder
            ? `${folder}/${timestamp}-${file.name}`
            : `${timestamp}-${file.name}`

        // Upload to Supabase storage
        const { data, error } = await supabase.storage
            .from(bucket)
            .upload(filename, buffer, {
                contentType: file.type,
                upsert: true
            })

        if (error) throw error

        // Get public URL
        const { data: { publicUrl } } = supabase.storage
            .from(bucket)
            .getPublicUrl(data.path)

        return successResponse({
            url: publicUrl,
            path: data.path,
            filename: filename
        })
    } catch (error) {
        return handleError(error)
    }
}
