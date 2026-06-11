-- Phase 1.2: Database Indexes for Performance
-- Partner Vault Lead Protection Platform

-- ============================================================================
-- USERS INDEXES
-- ============================================================================

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_active ON users(active);

-- ============================================================================
-- PROJECTS INDEXES
-- ============================================================================

CREATE INDEX idx_projects_active ON projects(active);

-- ============================================================================
-- LEADS INDEXES
-- ============================================================================

-- Core lookups
CREATE INDEX idx_leads_lead_number ON leads(lead_number);
CREATE INDEX idx_leads_project_id ON leads(project_id);
CREATE INDEX idx_leads_channel_partner_id ON leads(channel_partner_id);
CREATE INDEX idx_leads_assigned_salesperson_id ON leads(assigned_salesperson_id);

-- Status and timeline queries
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_created_at ON leads(created_at DESC);
CREATE INDEX idx_leads_updated_at ON leads(updated_at DESC);

-- Protection window queries
CREATE INDEX idx_leads_protection_expiry_date ON leads(protection_expiry_date);
CREATE INDEX idx_leads_protection_status ON leads(protection_status);

-- Duplicate detection queries
CREATE INDEX idx_leads_is_duplicate ON leads(is_duplicate);
CREATE INDEX idx_leads_customer_phone ON leads(customer_phone);

-- Composite indexes for common queries
CREATE INDEX idx_leads_partner_status ON leads(channel_partner_id, status);
CREATE INDEX idx_leads_salesperson_status ON leads(assigned_salesperson_id, status);
CREATE INDEX idx_leads_project_status ON leads(project_id, status);

-- ============================================================================
-- LEAD_ACTIVITY INDEXES
-- ============================================================================

CREATE INDEX idx_lead_activity_lead_id ON lead_activity(lead_id);
CREATE INDEX idx_lead_activity_created_by ON lead_activity(created_by);
CREATE INDEX idx_lead_activity_created_at ON lead_activity(created_at DESC);
CREATE INDEX idx_lead_activity_activity_type ON lead_activity(activity_type);

-- ============================================================================
-- SITE_VISITS INDEXES
-- ============================================================================

CREATE INDEX idx_site_visits_lead_id ON site_visits(lead_id);
CREATE INDEX idx_site_visits_scheduled_by ON site_visits(scheduled_by);
CREATE INDEX idx_site_visits_visit_date ON site_visits(visit_date);
CREATE INDEX idx_site_visits_status ON site_visits(status);
CREATE INDEX idx_site_visits_created_at ON site_visits(created_at DESC);

-- Composite index for salesperson's upcoming visits
CREATE INDEX idx_site_visits_scheduled_by_status_date ON site_visits(scheduled_by, status, visit_date);

-- ============================================================================
-- COMMISSIONS INDEXES
-- ============================================================================

CREATE INDEX idx_commissions_lead_id ON commissions(lead_id);
CREATE INDEX idx_commissions_project_id ON commissions(project_id);
CREATE INDEX idx_commissions_partner_id ON commissions(partner_id);
CREATE INDEX idx_commissions_status ON commissions(status);
CREATE INDEX idx_commissions_created_at ON commissions(created_at DESC);

-- Composite index for partner commission lookup
CREATE INDEX idx_commissions_partner_status ON commissions(partner_id, status);

-- ============================================================================
-- DISPUTES INDEXES
-- ============================================================================

CREATE INDEX idx_disputes_lead_id ON disputes(lead_id);
CREATE INDEX idx_disputes_partner_id ON disputes(partner_id);
CREATE INDEX idx_disputes_status ON disputes(status);
CREATE INDEX idx_disputes_created_at ON disputes(created_at DESC);

-- Composite index for partner dispute lookup
CREATE INDEX idx_disputes_partner_status ON disputes(partner_id, status);

-- ============================================================================
-- AUDIT_LOGS INDEXES
-- ============================================================================

CREATE INDEX idx_audit_logs_entity_id ON audit_logs(entity_id);
CREATE INDEX idx_audit_logs_entity_type ON audit_logs(entity_type);
CREATE INDEX idx_audit_logs_performed_by ON audit_logs(performed_by);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- Composite indexes for audit queries
CREATE INDEX idx_audit_logs_entity_type_id ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_entity_type_action ON audit_logs(entity_type, action);
