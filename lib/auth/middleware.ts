/**
 * Middleware Helper Functions
 * Role-based access control utilities
 */

import { createServerClient } from '@supabase/ssr';
import type { NextRequest } from 'next/server';
import type { UserRole } from '@/supabase/types';

export async function getUserRole(request: NextRequest): Promise<UserRole | null> {
  try {
    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        cookies: {
          getAll() {
            return request.cookies.getAll();
          },
          setAll() {},
        },
      }
    );

    const { data: { user } } = await supabase.auth.getUser();

    if (!user) return null;

    const { data, error } = await supabase
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single();

    if (error || !data) return null;

    return data.role as UserRole;
  } catch (error) {
    return null;
  }
}

export function requireRole(allowedRoles: UserRole[], userRole: UserRole | null): boolean {
  if (!userRole) return false;
  return allowedRoles.includes(userRole);
}
