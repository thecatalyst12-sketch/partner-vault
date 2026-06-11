/**
 * Role Constants and Utilities
 * Partner Vault User Roles
 */

import type { UserRole } from '@/supabase/types';

export const ROLES = {
  SUPER_ADMIN: 'super_admin' as const,
  ADMIN: 'admin' as const,
  SALESPERSON: 'salesperson' as const,
  CHANNEL_PARTNER: 'channel_partner' as const,
} as const;

export type RoleType = (typeof ROLES)[keyof typeof ROLES];

export const ROLE_HIERARCHY = {
  super_admin: 4,
  admin: 3,
  salesperson: 2,
  channel_partner: 1,
} as const;

export function getRoleLevel(role: UserRole): number {
  return ROLE_HIERARCHY[role] || 0;
}

export function hasHigherOrEqualRole(userRole: UserRole, requiredRole: UserRole): boolean {
  return getRoleLevel(userRole) >= getRoleLevel(requiredRole);
}

export const ROLE_LABELS: Record<UserRole, string> = {
  super_admin: 'Super Admin',
  admin: 'Admin',
  salesperson: 'Salesperson',
  channel_partner: 'Channel Partner',
};
