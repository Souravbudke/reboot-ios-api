import { NextResponse } from 'next/server'
import { ZodError } from 'zod'

export class ApiError extends Error {
    constructor(
        public statusCode: number,
        public message: string
    ) {
        super(message)
        this.name = 'ApiError'
    }
}

export function handleError(error: unknown): NextResponse {
    console.error('API Error:', error)

    // Zod validation errors
    if (error instanceof ZodError) {
        return NextResponse.json(
            {
                error: 'Validation failed',
                details: error.issues.map((err) => ({
                    field: String(err.path.join('.')),
                    message: err.message
                }))
            },
            { status: 400 }
        )
    }

    // Custom API errors
    if (error instanceof ApiError) {
        return NextResponse.json(
            { error: error.message },
            { status: error.statusCode }
        )
    }

    // Generic errors
    if (error instanceof Error) {
        return NextResponse.json(
            { error: error.message },
            { status: 500 }
        )
    }

    // Unknown errors
    return NextResponse.json(
        { error: 'An unexpected error occurred' },
        { status: 500 }
    )
}

export function successResponse<T>(data: T, status: number = 200): NextResponse {
    return NextResponse.json(data, { status })
}
