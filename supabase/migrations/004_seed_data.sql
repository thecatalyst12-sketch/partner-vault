-- Phase 1.2: Seed Data for Testing and Development
-- Partner Vault Lead Protection Platform
-- WARNING: This file contains test data only - delete for production

-- ============================================================================
-- TEST USERS
-- ============================================================================

INSERT INTO users (id, full_name, email, phone, role, active) VALUES
-- Super Admin
('550e8400-e29b-41d4-a716-446655440000', 'Super Admin', 'super@partnervault.local', '+91-9876543210', 'super_admin', true),

-- Admin
('550e8400-e29b-41d4-a716-446655440001', 'Admin User', 'admin@partnervault.local', '+91-9876543211', 'admin', true),

-- Salesperson
('550e8400-e29b-41d4-a716-446655440002', 'Raj Kumar (Salesperson)', 'raj.kumar@partnervault.local', '+91-9876543212', 'salesperson', true),
('550e8400-e29b-41d4-a716-446655440003', 'Priya Singh (Salesperson)', 'priya.singh@partnervault.local', '+91-9876543213', 'salesperson', true),

-- Channel Partners
('550e8400-e29b-41d4-a716-446655440010', 'Rahul Sharma (Partner)', 'rahul.sharma@partnervault.local', '+91-9876543220', 'channel_partner', true),
('550e8400-e29b-41d4-a716-446655440011', 'Deepak Patel (Partner)', 'deepak.patel@partnervault.local', '+91-9876543221', 'channel_partner', true),
('550e8400-e29b-41d4-a716-446655440012', 'Anita Verma (Partner)', 'anita.verma@partnervault.local', '+91-9876543222', 'channel_partner', true);

-- ============================================================================
-- TEST PROJECTS
-- ============================================================================

INSERT INTO projects (id, project_name, location, rera_number, commission_percentage, active) VALUES
('650e8400-e29b-41d4-a716-446655440000', 'Prestige Towers', 'Mumbai, India', 'MH-PR-2024-001', 2.50, true),
('650e8400-e29b-41d4-a716-446655440001', 'Lodha Crown', 'Bangalore, India', 'KA-LO-2024-002', 3.00, true),
('650e8400-e29b-41d4-a716-446655440002', 'Godrej Garden City', 'Pune, India', 'MH-GO-2024-003', 2.75, true),
('650e8400-e29b-41d4-a716-446655440003', 'DLF Aralias', 'Gurgaon, India', 'HR-DL-2024-004', 3.50, true);

-- ============================================================================
-- TEST LEADS
-- ============================================================================

INSERT INTO leads (
  id, lead_number, project_id, channel_partner_id, assigned_salesperson_id,
  customer_name, customer_phone, customer_email, status,
  protection_start_date, protection_expiry_date, protection_status,
  lead_owner_locked, is_duplicate, duplicate_confidence_score
) VALUES

-- Leads for Rahul Sharma
('750e8400-e29b-41d4-a716-446655440000', 'LEAD-001-2024', '650e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440002',
  'Amit Kumar', '+91-9123456789', 'amit@example.com', 'registered',
  CURRENT_DATE, CURRENT_DATE + INTERVAL '90 days', 'active', true, false, NULL),

('750e8400-e29b-41d4-a716-446655440001', 'LEAD-002-2024', '650e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440010', NULL,
  'Bhavna Desai', '+91-9223456789', 'bhavna@example.com', 'assigned',
  CURRENT_DATE - INTERVAL '15 days', CURRENT_DATE - INTERVAL '15 days' + INTERVAL '90 days', 'expiring_soon', true, false, NULL),

('750e8400-e29b-41d4-a716-446655440002', 'LEAD-003-2024', '650e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440002',
  'Chitresh Gupta', '+91-9323456789', 'chitresh@example.com', 'contacted',
  CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE - INTERVAL '30 days' + INTERVAL '90 days', 'expired', true, false, NULL),

-- Leads for Deepak Patel
('750e8400-e29b-41d4-a716-446655440010', 'LEAD-004-2024', '650e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440003',
  'Diana Singh', '+91-9423456789', 'diana@example.com', 'site_visit_scheduled',
  CURRENT_DATE - INTERVAL '10 days', CURRENT_DATE - INTERVAL '10 days' + INTERVAL '90 days', 'active', true, false, NULL),

('750e8400-e29b-41d4-a716-446655440011', 'LEAD-005-2024', '650e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440011', NULL,
  'Erica Ferreira', '+91-9523456789', 'erica@example.com', 'registered',
  CURRENT_DATE, CURRENT_DATE + INTERVAL '90 days', 'active', true, false, NULL),

-- Leads for Anita Verma
('750e8400-e29b-41d4-a716-446655440020', 'LEAD-006-2024', '650e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440012', '550e8400-e29b-41d4-a716-446655440003',
  'Farah Khan', '+91-9623456789', 'farah@example.com', 'booking',
  CURRENT_DATE - INTERVAL '45 days', CURRENT_DATE - INTERVAL '45 days' + INTERVAL '90 days', 'active', true, false, NULL);

-- ============================================================================
-- TEST LEAD ACTIVITY
-- ============================================================================

INSERT INTO lead_activity (id, lead_id, activity_type, note, created_by) VALUES
('850e8400-e29b-41d4-a716-446655440000', '750e8400-e29b-41d4-a716-446655440000', 'Registration', 'Lead registered by partner', '550e8400-e29b-41d4-a716-446655440010'),
('850e8400-e29b-41d4-a716-446655440001', '750e8400-e29b-41d4-a716-446655440001', 'Assignment', 'Assigned to salesperson', '550e8400-e29b-41d4-a716-446655440001'),
('850e8400-e29b-41d4-a716-446655440002', '750e8400-e29b-41d4-a716-446655440001', 'Note', 'Customer showed great interest in property', '550e8400-e29b-41d4-a716-446655440002'),
('850e8400-e29b-41d4-a716-446655440003', '750e8400-e29b-41d4-a716-446655440010', 'Contact', 'Called customer, interested in site visit', '550e8400-e29b-41d4-a716-446655440003');

-- ============================================================================
-- TEST SITE VISITS
-- ============================================================================

INSERT INTO site_visits (id, lead_id, scheduled_by, visit_date, visit_time, status, notes) VALUES
('950e8400-e29b-41d4-a716-446655440000', '750e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', CURRENT_DATE + INTERVAL '3 days', '10:00', 'scheduled', 'Customer prefers morning visits'),
('950e8400-e29b-41d4-a716-446655440001', '750e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440003', CURRENT_DATE + INTERVAL '5 days', '14:00', 'confirmed', 'Confirmed by customer'),
('950e8400-e29b-41d4-a716-446655440002', '750e8400-e29b-41d4-a716-446655440020', '550e8400-e29b-41d4-a716-446655440003', CURRENT_DATE - INTERVAL '2 days', '11:00', 'completed', 'Customer very impressed, moving towards booking', CURRENT_TIMESTAMP);

-- ============================================================================
-- TEST COMMISSIONS
-- ============================================================================

INSERT INTO commissions (id, lead_id, project_id, partner_id, commission_percentage, commission_amount, status) VALUES
('a50e8400-e29b-41d4-a716-446655440000', '750e8400-e29b-41d4-a716-446655440020', '650e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440012', 3.50, 1050000.00, 'pending');

-- ============================================================================
-- TEST DISPUTES
-- ============================================================================

INSERT INTO disputes (id, lead_id, partner_id, title, description, status) VALUES
('b50e8400-e29b-41d4-a716-446655440000', '750e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440010', 'Lead Ownership Dispute', 'Partner claims lead was registered first', 'open');

-- ============================================================================
-- TEST AUDIT LOGS
-- ============================================================================

INSERT INTO audit_logs (id, entity_type, entity_id, action, new_value, performed_by) VALUES
('c50e8400-e29b-41d4-a716-446655440000', 'lead', '750e8400-e29b-41d4-a716-446655440000', 'create', 
  '{"lead_number": "LEAD-001-2024", "customer_name": "Amit Kumar", "status": "registered"}'::jsonb,
  '550e8400-e29b-41d4-a716-446655440010'),
('c50e8400-e29b-41d4-a716-446655440001', 'lead', '750e8400-e29b-41d4-a716-446655440001', 'update',
  '{"assigned_salesperson_id": "550e8400-e29b-41d4-a716-446655440002", "status": "assigned"}'::jsonb,
  '550e8400-e29b-41d4-a716-446655440001');
