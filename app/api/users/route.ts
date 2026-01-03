import { NextRequest } from 'next/server'
import { supabase } from '@/lib/supabase'
import { handleError, successResponse } from '@/lib/errors'

export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url)
        const role = searchParams.get('role')

        let query = supabase
            .from('users')
            .select('*')
            .order('created_at', { ascending: false })

        if (role) {
            query = query.eq('role', role)
        }

        const { data, error } = await query

        if (error) throw error

        return successResponse(data || [])
    } catch (error) {
        return handleError(error)
    }
}
