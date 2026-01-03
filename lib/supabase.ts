import { createClient } from '@supabase/supabase-js'

// Create Supabase client for server-side use
// Using service role key for full database access
export const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  }
)
