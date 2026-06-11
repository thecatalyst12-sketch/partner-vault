/**
 * Admin Supabase Client
 * Used only in secure backend operations with service role key
 * DO NOT use in client-side code
 */

import { createClient } from '@supabase/supabase-js';
import type { Database } from '@/supabase/types';

let adminClient: ReturnType<typeof createClient<Database>> | null = null;

export function getAdminClient() {
  if (adminClient) {
    return adminClient;
  }

  adminClient = createClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    }
  );

  return adminClient;
}
