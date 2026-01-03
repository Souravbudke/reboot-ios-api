import { NextRequest } from 'next/server'
import { supabase } from '@/lib/supabase'
import { handleError, successResponse } from '@/lib/errors'
import { productQuerySchema } from '@/lib/validation'

export async function GET(request: NextRequest) {
    try {
        const searchParams = request.nextUrl.searchParams

        // Parse and validate query parameters - filter out null values
        const rawParams = {
            category: searchParams.get('category'),
            search: searchParams.get('search'),
            minPrice: searchParams.get('minPrice'),
            maxPrice: searchParams.get('maxPrice'),
            condition: searchParams.get('condition'),
            sort: searchParams.get('sort')
        }

        // Only include non-null values
        const params = productQuerySchema.parse(
            Object.fromEntries(
                Object.entries(rawParams).filter(([_, v]) => v !== null)
            )
        )

        // Build Supabase query
        let query = supabase
            .from('products')
            .select('*')

        // Apply filters
        if (params.category) {
            query = query.eq('category', params.category)
        }

        if (params.search) {
            query = query.or(`name.ilike.%${params.search}%,description.ilike.%${params.search}%`)
        }

        if (params.minPrice !== undefined) {
            query = query.gte('price', params.minPrice)
        }

        if (params.maxPrice !== undefined) {
            query = query.lte('price', params.maxPrice)
        }

        if (params.condition) {
            query = query.eq('condition', params.condition)
        }

        // Apply sorting
        switch (params.sort) {
            case 'price_low':
                query = query.order('price', { ascending: true })
                break
            case 'price_high':
                query = query.order('price', { ascending: false })
                break
            case 'popular':
                query = query.order('review_count', { ascending: false })
                break
            case 'newest':
            default:
                query = query.order('created_at', { ascending: false })
        }

        const { data, error } = await query

        if (error) throw error

        return successResponse(data)
    } catch (error) {
        return handleError(error)
    }
}

export async function POST(request: NextRequest) {
    try {
        const body = await request.json()

        // Validate required fields
        if (!body.name || !body.description || body.price === undefined) {
            return handleError(new Error('Missing required fields: name, description, price'))
        }

        const productData = {
            name: body.name,
            description: body.description,
            price: body.price,
            category: body.category || null,
            image: body.image || null,
            stock: body.stock || 0,
        }

        const { data, error } = await supabase
            .from('products')
            .insert(productData)
            .select()
            .single()

        if (error) throw error

        return successResponse(data)
    } catch (error) {
        return handleError(error)
    }
}
