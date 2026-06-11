/**
 * Core Supabase Client Setup
 * Browser client with automatic cookie handling
 */

import { createBrowserClient } from '@supabase/ssr';
import type { Database } from '@/supabase/types';

export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
