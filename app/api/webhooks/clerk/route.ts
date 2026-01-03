import { NextRequest, NextResponse } from 'next/server'
import { Webhook } from 'svix'
import { supabase } from '@/lib/supabase'

const CLERK_WEBHOOK_SECRET = process.env.CLERK_WEBHOOK_SECRET

interface ClerkWebhookEvent {
    type: string
    data: {
        id: string
        email_addresses: Array<{
            id: string
            email_address: string
        }>
        first_name: string | null
        last_name: string | null
        image_url: string | null
        public_metadata: Record<string, unknown>
        created_at: number
        updated_at: number
    }
}

export async function POST(request: NextRequest) {
    try {
        // Verify webhook signature
        const payload = await request.text()
        const headers = {
            'svix-id': request.headers.get('svix-id') || '',
            'svix-timestamp': request.headers.get('svix-timestamp') || '',
            'svix-signature': request.headers.get('svix-signature') || '',
        }

        if (!CLERK_WEBHOOK_SECRET) {
            console.error('Missing CLERK_WEBHOOK_SECRET')
            return NextResponse.json(
                { error: 'Webhook secret not configured' },
                { status: 500 }
            )
        }

        const wh = new Webhook(CLERK_WEBHOOK_SECRET)
        let event: ClerkWebhookEvent

        try {
            event = wh.verify(payload, headers) as ClerkWebhookEvent
        } catch (err) {
            console.error('Webhook verification failed:', err)
            return NextResponse.json(
                { error: 'Invalid webhook signature' },
                { status: 401 }
            )
        }

        const { type, data } = event

        switch (type) {
            case 'user.created':
                await handleUserCreated(data)
                break
            case 'user.updated':
                await handleUserUpdated(data)
                break
            case 'user.deleted':
                await handleUserDeleted(data.id)
                break
            default:
                console.log(`Unhandled webhook event type: ${type}`)
        }

        return NextResponse.json({ received: true })
    } catch (error) {
        console.error('Webhook error:', error)
        return NextResponse.json(
            { error: 'Webhook handler failed' },
            { status: 500 }
        )
    }
}

async function handleUserCreated(data: ClerkWebhookEvent['data']) {
    const email = data.email_addresses?.[0]?.email_address
    const name = [data.first_name, data.last_name].filter(Boolean).join(' ') || 'User'
    const role = (data.public_metadata?.role as string) || 'customer'

    const { error } = await supabase.from('users').insert({
        clerk_id: data.id,
        email,
        name,
        role,
        profile_image: data.image_url,
        created_at: new Date(data.created_at).toISOString(),
    })

    if (error) {
        console.error('Error creating user:', error)
        throw error
    }

    console.log(`User created: ${email}`)
}

async function handleUserUpdated(data: ClerkWebhookEvent['data']) {
    const email = data.email_addresses?.[0]?.email_address
    const name = [data.first_name, data.last_name].filter(Boolean).join(' ') || 'User'
    const role = (data.public_metadata?.role as string) || 'customer'

    const { error } = await supabase
        .from('users')
        .update({
            email,
            name,
            role,
            profile_image: data.image_url,
            updated_at: new Date(data.updated_at).toISOString(),
        })
        .eq('clerk_id', data.id)

    if (error) {
        // User might not exist, create instead
        if (error.code === 'PGRST116') {
            await handleUserCreated(data)
            return
        }
        console.error('Error updating user:', error)
        throw error
    }

    console.log(`User updated: ${email}`)
}

async function handleUserDeleted(clerkId: string) {
    const { error } = await supabase
        .from('users')
        .delete()
        .eq('clerk_id', clerkId)

    if (error) {
        console.error('Error deleting user:', error)
        throw error
    }

    console.log(`User deleted: ${clerkId}`)
}

// GET endpoint to test webhook is accessible
export async function GET() {
    return NextResponse.json({
        status: 'Clerk webhook endpoint active',
        timestamp: new Date().toISOString(),
    })
}
