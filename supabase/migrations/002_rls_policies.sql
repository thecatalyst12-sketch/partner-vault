-- Phase 1.2: Row-Level Security (RLS) Policies
-- Partner Vault Lead Protection Platform
-- Roles: super_admin, admin, salesperson, channel_partner

-- ============================================================================
-- ENABLE RLS ON ALL TABLES
-- ============================================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE lead_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE site_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE commissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

CREATE OR REPLACE FUNCTION auth.user_id() RETURNS UUID AS $$
  SELECT COALESCE(
    nullif(current_setting('auth.user_id', true), ''),
    auth.uid()
  )::uuid
GUARD;;
CREATE OR REPLACE FUNCTION current_user_role() RETURNS user_role AS $$
  SELECT role FROM users WHERE id = auth.user_id() LIMIT 1;
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- ============================================================================
-- USERS TABLE POLICIES
-- ============================================================================

-- Super Admin: Can see all users
CREATE POLICY "super_admin_select_users"
  ON users FOR SELECT
  USING (current_user_role() = 'super_admin');

-- Admin: Can see all users
CREATE POLICY "admin_select_users"
  ON users FOR SELECT
  USING (current_user_role() = 'admin');

-- Users can see themselves
CREATE POLICY "users_select_self"
  ON users FOR SELECT
  USING (id = auth.user_id());

-- Super Admin: Can create/update/delete users
CREATE POLICY "super_admin_manage_users"
  ON users FOR ALL
  USING (current_user_role() = 'super_admin')
  WITH CHECK (current_user_role() = 'super_admin');

-- Users can update their own profile (except role)
CREATE POLICY "users_update_self"
  ON users FOR UPDATE
  USING (id = auth.user_id())
  WITH CHECK (id = auth.user_id() AND role = (SELECT role FROM users WHERE id = auth.user_id()));

-- ============================================================================
-- PROJECTS TABLE POLICIES
-- ============================================================================

-- All authenticated users can view active projects
CREATE POLICY "all_users_select_active_projects"
  ON projects FOR SELECT
  USING (active = true);

-- Super Admin: Can see all projects (including inactive)
CREATE POLICY "super_admin_select_all_projects"
  ON projects FOR SELECT
  USING (current_user_role() = 'super_admin');

-- Super Admin: Can manage projects
CREATE POLICY "super_admin_manage_projects"
  ON projects FOR ALL
  USING (current_user_role() = 'super_admin')
  WITH CHECK (current_user_role() = 'super_admin');

-- ============================================================================
-- LEADS TABLE POLICIES
-- ============================================================================

-- Super Admin: Can see all leads
CREATE POLICY "super_admin_select_leads"
  ON leads FOR SELECT
  USING (current_user_role() = 'super_admin');

-- Admin: Can see all leads
CREATE POLICY "admin_select_leads"
  ON leads FOR SELECT
  USING (current_user_role() = 'admin');

-- Salesperson: Can see leads assigned to them
CREATE POLICY "salesperson_select_assigned_leads"
  ON leads FOR SELECT
  USING (
    current_user_role() = 'salesperson' AND
    assigned_salesperson_id = auth.user_id()
  );

-- Channel Partner: Can see only their own leads
CREATE POLICY "channel_partner_select_own_leads"
  ON leads FOR SELECT
  USING (
    current_user_role() = 'channel_partner' AND
    channel_partner_id = auth.user_id()
  );

-- Channel Partner: Can register leads
CREATE POLICY "channel_partner_insert_leads"
  ON leads FOR INSERT
  WITH CHECK (
    current_user_role() = 'channel_partner' AND
    channel_partner_id = auth.user_id()
  );

-- Channel Partner: Can update their own leads (except ownership fields)
CREATE POLICY "channel_partner_update_own_leads"
  ON leads FOR UPDATE
  USING (
    current_user_role() = 'channel_partner' AND
    channel_partner_id = auth.user_id() AND
    lead_owner_locked = true
  )
  WITH CHECK (
    current_user_role() = 'channel_partner' AND
    channel_partner_id = auth.user_id() AND
    channel_partner_id = (SELECT channel_partner_id FROM leads WHERE id = leads.id) AND
    is_duplicate = (SELECT is_duplicate FROM leads WHERE id = leads.id)
  );

-- Admin: Can update lead status and assignment
CREATE POLICY "admin_update_leads"
  ON leads FOR UPDATE
  USING (current_user_role() = 'admin')
  WITH CHECK (current_user_role() = 'admin');

-- Super Admin: Can do anything with leads
CREATE POLICY "super_admin_manage_leads"
  ON leads FOR ALL
  USING (current_user_role() = 'super_admin')
  WITH CHECK (current_user_role() = 'super_admin');

-- ============================================================================
-- LEAD_ACTIVITY TABLE POLICIES
-- ============================================================================

-- Super Admin: Can see all activity
CREATE POLICY "super_admin_select_lead_activity"
  ON lead_activity FOR SELECT
  USING (current_user_role() = 'super_admin');

-- Admin: Can see all activity
CREATE POLICY "admin_select_lead_activity"
  ON lead_activity FOR SELECT
  USING (current_user_role() = 'admin');

-- Users can see activity on leads they can see
CREATE POLICY "users_select_lead_activity"
  ON lead_activity FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM leads
      WHERE leads.id = lead_activity.lead_id AND (
        current_user_role() = 'super_admin' OR
        current_user_role() = 'admin' OR
        (current_user_role() = 'channel_partner' AND leads.channel_partner_id = auth.user_id()) OR
        (current_user_role() = 'salesperson' AND leads.assigned_salesperson_id = auth.user_id())
      )
    )
  );

-- Users can insert activity on leads they have access to
CREATE POLICY "users_insert_lead_activity"
  ON lead_activity FOR INSERT
  WITH CHECK (
    created_by = auth.user_id() AND
    EXISTS (
      SELECT 1 FROM leads
      WHERE leads.id = lead_activity.lead_id AND (
        current_user_role() = 'super_admin' OR
        current_user_role() = 'admin' OR
        (current_user_role() = 'channel_partner' AND leads.channel_partner_id = auth.user_id()) OR
        (current_user_role() = 'salesperson' AND leads.assigned_salesperson_id = auth.user_id())
      )
    )
  );

-- ============================================================================
-- SITE_VISITS TABLE POLICIES
-- ============================================================================

-- Super Admin: Can see all site visits
CREATE POLICY "super_admin_select_site_visits"
  ON site_visits FOR SELECT
  USING (current_user_role() = 'super_admin');

-- Admin: Can see all site visits
CREATE POLICY "admin_select_site_visits"
  ON site_visits FOR SELECT
  USING (current_user_role() = 'admin');

-- Salesperson: Can see site visits for their assigned leads
CREATE POLICY "salesperson_select_site_visits"
  ON site_visits FOR SELECT
  USING (
    current_user_role() = 'salesperson' AND
    EXISTS (
      SELECT 1 FROM leads
      WHERE leads.id = site_visits.lead_id AND
      leads.assigned_salesperson_id = auth.user_id()
    )
  );

-- Channel Partner: Can see site visits for their leads
CREATE POLICY "channel_partner_select_site_visits"
  ON site_visits FOR SELECT
  USING (
    current_user_role() = 'channel_partner' AND
    EXISTS (
      SELECT 1 FROM leads
      WHERE leads.id = site_visits.lead_id AND
      leads.channel_partner_id = auth.user_id()
    )
  );

-- Salesperson: Can create and update site visits for their assigned leads
CREATE POLICY "salesperson_manage_site_visits"
  ON site_visits FOR ALL
  USING (
    current_user_role() = 'salesperson' AND
    scheduled_by = auth.user_id() AND
    EXISTS (
      SELECT 1 FROM leads
      WHERE leads.id = site_visits.lead_id AND
      leads.assigned_salesperson_id = auth.user_id()
    )
  )
  WITH CHECK (
    current_user_role() = 'salesperson' AND
    scheduled_by = auth.user_id() AND
    EXISTS (
      SELECT 1 FROM leads
      WHERE leads.id = site_visits.lead_id AND
      leads.assigned_salesperson_id = auth.user_id()
    )
  );

-- Admin: Can manage all site visits
CREATE POLICY "admin_manage_site_visits"
  ON site_visits FOR ALL
  USING (current_user_role() = 'admin')
  WITH CHECK (current_user_role() = 'admin');

-- Super Admin: Can manage all site visits
CREATE POLICY "super_admin_manage_site_visits"
  ON site_visits FOR ALL
  USING (current_user_role() = 'super_admin')
  WITH CHECK (current_user_role() = 'super_admin');

-- ============================================================================
-- COMMISSIONS TABLE POLICIES
-- ============================================================================

-- Super Admin: Can see all commissions
CREATE POLICY "super_admin_select_commissions"
  ON commissions FOR SELECT
  USING (current_user_role() = 'super_admin');

-- Admin: Can see all commissions
CREATE POLICY "admin_select_commissions"
  ON commissions FOR SELECT
  USING (current_user_role() = 'admin');

-- Channel Partner: Can see their own commissions
CREATE POLICY "channel_partner_select_own_commissions"
  ON commissions FOR SELECT
  USING (
    current_user_role() = 'channel_partner' AND
    partner_id = auth.user_id()
  );

-- Admin: Can approve commissions
CREATE POLICY "admin_update_commissions"
  ON commissions FOR UPDATE
  USING (current_user_role() = 'admin')
  WITH CHECK (current_user_role() = 'admin');

-- Super Admin: Can manage all commissions
CREATE POLICY "super_admin_manage_commissions"
  ON commissions FOR ALL
  USING (current_user_role() = 'super_admin')
  WITH CHECK (current_user_role() = 'super_admin');

-- ============================================================================
-- DISPUTES TABLE POLICIES
-- ============================================================================

-- Super Admin: Can see all disputes
CREATE POLICY "super_admin_select_disputes"
  ON disputes FOR SELECT
  USING (current_user_role() = 'super_admin');

-- Admin: Can see all disputes
CREATE POLICY "admin_select_disputes"
  ON disputes FOR SELECT
  USING (current_user_role() = 'admin');

-- Channel Partner: Can see their own disputes
CREATE POLICY "channel_partner_select_own_disputes"
  ON disputes FOR SELECT
  USING (
    current_user_role() = 'channel_partner' AND
    partner_id = auth.user_id()
  );

-- Channel Partner: Can create disputes
CREATE POLICY "channel_partner_insert_disputes"
  ON disputes FOR INSERT
  WITH CHECK (
    current_user_role() = 'channel_partner' AND
    partner_id = auth.user_id()
  );

-- Admin: Can update disputes
CREATE POLICY "admin_update_disputes"
  ON disputes FOR UPDATE
  USING (current_user_role() = 'admin')
  WITH CHECK (current_user_role() = 'admin');

-- Super Admin: Can manage all disputes
CREATE POLICY "super_admin_manage_disputes"
  ON disputes FOR ALL
  USING (current_user_role() = 'super_admin')
  WITH CHECK (current_user_role() = 'super_admin');

-- ============================================================================
-- AUDIT_LOGS TABLE POLICIES
-- ============================================================================

-- Super Admin: Can see all audit logs
CREATE POLICY "super_admin_select_audit_logs"
  ON audit_logs FOR SELECT
  USING (current_user_role() = 'super_admin');

-- Admin: Can see all audit logs
CREATE POLICY "admin_select_audit_logs"
  ON audit_logs FOR SELECT
  USING (current_user_role() = 'admin');

-- Only admins can insert audit logs (via triggers/app logic)
CREATE POLICY "insert_audit_logs"
  ON audit_logs FOR INSERT
  WITH CHECK (
    current_user_role() IN ('super_admin', 'admin')
  );

-- Audit logs are immutable
CREATE POLICY "no_update_audit_logs"
  ON audit_logs FOR UPDATE
  USING (FALSE)
  WITH CHECK (FALSE);

CREATE POLICY "no_delete_audit_logs"
  ON audit_logs FOR DELETE
  USING (FALSE);
