import { NextRequest } from 'next/server'
import { supabase } from '@/lib/supabase'
import { handleError, successResponse } from '@/lib/errors'

export async function GET(request: NextRequest) {
    try {
        const { data, error } = await supabase
            .from('carousel')
            .select('*')

        if (error) throw error

        return successResponse(data || [])
    } catch (error) {
        return handleError(error)
    }
}
