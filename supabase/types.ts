/**
 * Database Types - Auto-generated from Supabase Schema
 * Partner Vault Lead Protection Platform
 */

// User Roles
export type UserRole = 'super_admin' | 'admin' | 'salesperson' | 'channel_partner';

// Lead Statuses
export type LeadStatus =
  | 'registered'
  | 'assigned'
  | 'contacted'
  | 'site_visit_scheduled'
  | 'site_visit_completed'
  | 'negotiation'
  | 'booking'
  | 'closed_won'
  | 'closed_lost';

// Commission Statuses
export type CommissionStatus = 'pending' | 'approved' | 'paid';

// Dispute Statuses
export type DisputeStatus = 'open' | 'under_review' | 'resolved' | 'closed';

// Site Visit Statuses
export type SiteVisitStatus = 'scheduled' | 'confirmed' | 'completed' | 'cancelled' | 'no_show';

// Protection Statuses
export type ProtectionStatus = 'active' | 'expiring_soon' | 'expired';

// ============================================================================
// DATABASE TABLES
// ============================================================================

export interface User {
  id: string;
  full_name: string;
  email: string;
  phone: string | null;
  role: UserRole;
  active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Project {
  id: string;
  project_name: string;
  location: string;
  rera_number: string | null;
  commission_percentage: number;
  active: boolean;
  created_at: string;
}

export interface Lead {
  id: string;
  lead_number: string;
  project_id: string;
  channel_partner_id: string;
  assigned_salesperson_id: string | null;
  customer_name: string;
  customer_phone: string;
  customer_email: string | null;
  status: LeadStatus;
  lead_source: string | null;
  protection_start_date: string;
  protection_expiry_date: string;
  protection_status: ProtectionStatus;
  lead_owner_locked: boolean;
  is_duplicate: boolean;
  duplicate_reason: string | null;
  duplicate_confidence_score: number | null;
  duplicate_type: string | null;
  created_at: string;
  updated_at: string;
}

export interface LeadActivity {
  id: string;
  lead_id: string;
  activity_type: string;
  note: string | null;
  activity_date: string;
  created_by: string;
  created_at: string;
}

export interface SiteVisit {
  id: string;
  lead_id: string;
  scheduled_by: string;
  visit_date: string;
  visit_time: string;
  status: SiteVisitStatus;
  notes: string | null;
  completed_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface Commission {
  id: string;
  lead_id: string;
  project_id: string;
  partner_id: string;
  commission_percentage: number;
  commission_amount: number | null;
  status: CommissionStatus;
  approved_by: string | null;
  approved_at: string | null;
  paid_at: string | null;
  created_at: string;
}

export interface Dispute {
  id: string;
  lead_id: string;
  partner_id: string;
  title: string;
  description: string;
  status: DisputeStatus;
  resolution: string | null;
  resolved_by: string | null;
  resolved_at: string | null;
  created_at: string;
}

export interface AuditLog {
  id: string;
  entity_type: string;
  entity_id: string;
  action: string;
  old_value: Record<string, any> | null;
  new_value: Record<string, any> | null;
  performed_by: string;
  created_at: string;
}
