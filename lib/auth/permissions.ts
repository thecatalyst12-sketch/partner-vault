/**
 * Permission Checking Utilities
 * Server-side authorization checks
 */

import type { UserRole } from '@/supabase/types';
import { ROLES, hasHigherOrEqualRole } from './roles';

export interface PermissionContext {
  userRole: UserRole;
  userId: string;
  resourceOwnerId?: string;
}

/**
 * Check if user can view a lead
 */
export function canViewLead(
  context: PermissionContext,
  leadChannelPartnerId: string,
  leadSalespersonId?: string
): boolean {
  const { userRole, userId } = context;

  switch (userRole) {
    case ROLES.SUPER_ADMIN:
    case ROLES.ADMIN:
      return true;
    case ROLES.CHANNEL_PARTNER:
      return leadChannelPartnerId === userId;
    case ROLES.SALESPERSON:
      return leadSalespersonId === userId;
    default:
      return false;
  }
}

/**
 * Check if user can register a lead
 */
export function canRegisterLead(context: PermissionContext): boolean {
  return context.userRole === ROLES.CHANNEL_PARTNER;
}

/**
 * Check if user can assign a lead
 */
export function canAssignLead(context: PermissionContext): boolean {
  return [ROLES.ADMIN, ROLES.SUPER_ADMIN].includes(context.userRole);
}

/**
 * Check if user can update lead status
 */
export function canUpdateLeadStatus(context: PermissionContext): boolean {
  return [ROLES.ADMIN, ROLES.SALESPERSON, ROLES.SUPER_ADMIN].includes(context.userRole);
}

/**
 * Check if user can approve commissions
 */
export function canApproveCommission(context: PermissionContext): boolean {
  return [ROLES.ADMIN, ROLES.SUPER_ADMIN].includes(context.userRole);
}

/**
 * Check if user can resolve disputes
 */
export function canResolveDispute(context: PermissionContext): boolean {
  return [ROLES.ADMIN, ROLES.SUPER_ADMIN].includes(context.userRole);
}

/**
 * Check if user can create a site visit
 */
export function canCreateSiteVisit(context: PermissionContext): boolean {
  return [ROLES.SALESPERSON, ROLES.ADMIN, ROLES.SUPER_ADMIN].includes(context.userRole);
}

/**
 * Check if user can manage users
 */
export function canManageUsers(context: PermissionContext): boolean {
  return context.userRole === ROLES.SUPER_ADMIN;
}

/**
 * Check if user is admin or higher
 */
export function isAdmin(context: PermissionContext): boolean {
  return hasHigherOrEqualRole(context.userRole, ROLES.ADMIN);
}

/**
 * Check if user is super admin
 */
export function isSuperAdmin(context: PermissionContext): boolean {
  return context.userRole === ROLES.SUPER_ADMIN;
}
