import { z } from 'zod'

// Auth validation schemas
export const loginSchema = z.object({
    email: z.string().email('Invalid email address'),
    password: z.string().min(8, 'Password must be at least 8 characters')
})

export const registerSchema = z.object({
    name: z.string().min(2, 'Name must be at least 2 characters'),
    email: z.string().email('Invalid email address'),
    password: z.string().min(8, 'Password must be at least 8 characters')
})

// Product validation schemas
export const productQuerySchema = z.object({
    category: z.string().nullish(),
    search: z.string().nullish(),
    minPrice: z.coerce.number().optional().nullable(),
    maxPrice: z.coerce.number().optional().nullable(),
    condition: z.string().nullish(),
    sort: z.enum(['newest', 'price_low', 'price_high', 'popular']).nullish()
})

// Order validation schemas
export const createOrderSchema = z.object({
    items: z.array(z.object({
        productId: z.string().uuid(),
        variantId: z.string().uuid().optional(),
        quantity: z.number().int().positive()
    })),
    shippingAddress: z.object({
        name: z.string(),
        addressLine1: z.string(),
        addressLine2: z.string().optional(),
        city: z.string(),
        state: z.string(),
        postalCode: z.string(),
        country: z.string()
    }),
    paymentMethod: z.string()
})
