import { NextRequest } from 'next/server'
import { supabase } from '@/lib/supabase'
import { handleError, successResponse } from '@/lib/errors'

export async function GET(request: NextRequest) {
    try {
        const { data, error } = await supabase
            .from('categories')
            .select('*')
            .eq('is_active', true)
            .order('name', { ascending: true })

        if (error) throw error

        return successResponse(data || [])
    } catch (error) {
        return handleError(error)
    }
}

export async function POST(request: NextRequest) {
    try {
        const body = await request.json()

        if (!body.name) {
            return handleError(new Error('Category name is required'))
        }

        // Generate slug from name if not provided
        const slug = body.slug || body.name.toLowerCase().replace(/\s+/g, '-')

        const categoryData = {
            name: body.name,
            slug: slug,
            description: body.description || null,
            image: body.image || null,
            icon: body.icon || null,
            is_active: body.isActive !== false
        }

        const { data, error } = await supabase
            .from('categories')
            .insert(categoryData)
            .select()
            .single()

        if (error) throw error

        return successResponse(data)
    } catch (error) {
        return handleError(error)
    }
}
