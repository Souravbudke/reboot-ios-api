import { NextRequest, NextResponse } from 'next/server'
import { auth, clerkClient } from '@clerk/nextjs/server'
import { supabase } from '@/lib/supabase'
import { handleError, successResponse, ApiError } from '@/lib/errors'

// POST /api/users/sync - Sync all Clerk users to Supabase
export async function POST(request: NextRequest) {
    try {
        const { userId } = await auth()

        if (!userId) {
            throw new ApiError(401, 'Unauthorized')
        }

        // Check if user is admin
        const { data: userData } = await supabase
            .from('users')
            .select('role')
            .eq('clerk_id', userId)
            .single()

        if (userData?.role !== 'admin') {
            throw new ApiError(403, 'Admin access required')
        }

        // Get all Clerk users
        const clerk = await clerkClient()
        const clerkUsers = await clerk.users.getUserList({ limit: 500 })

        let created = 0
        let updated = 0
        let errors = 0

        for (const clerkUser of clerkUsers.data) {
            const email = clerkUser.emailAddresses?.[0]?.emailAddress
            const name = [clerkUser.firstName, clerkUser.lastName].filter(Boolean).join(' ') || 'User'
            const role = (clerkUser.publicMetadata?.role as string) || 'customer'

            // Check if user exists
            const { data: existingUser } = await supabase
                .from('users')
                .select('id')
                .eq('clerk_id', clerkUser.id)
                .single()

            if (existingUser) {
                // Update existing user
                const { error } = await supabase
                    .from('users')
                    .update({
                        email,
                        name,
                        role,
                        profile_image: clerkUser.imageUrl,
                        updated_at: new Date().toISOString(),
                    })
                    .eq('clerk_id', clerkUser.id)

                if (error) {
                    console.error('Error updating user:', error)
                    errors++
                } else {
                    updated++
                }
            } else {
                // Create new user
                const { error } = await supabase.from('users').insert({
                    clerk_id: clerkUser.id,
                    email,
                    name,
                    role,
                    profile_image: clerkUser.imageUrl,
                    created_at: new Date(clerkUser.createdAt).toISOString(),
                })

                if (error) {
                    console.error('Error creating user:', error)
                    errors++
                } else {
                    created++
                }
            }
        }

        return successResponse({
            message: 'Sync completed',
            total: clerkUsers.data.length,
            created,
            updated,
            errors,
        })
    } catch (error) {
        return handleError(error)
    }
}
