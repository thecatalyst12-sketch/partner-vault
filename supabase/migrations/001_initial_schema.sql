-- Phase 1.2: Initial Database Schema
-- Partner Vault Lead Protection Platform
-- Created: 2024

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- ENUMS
-- ============================================================================

CREATE TYPE user_role AS ENUM ('super_admin', 'admin', 'salesperson', 'channel_partner');
CREATE TYPE lead_status AS ENUM (
  'registered',
  'assigned',
  'contacted',
  'site_visit_scheduled',
  'site_visit_completed',
  'negotiation',
  'booking',
  'closed_won',
  'closed_lost'
);
CREATE TYPE commission_status AS ENUM ('pending', 'approved', 'paid');
CREATE TYPE dispute_status AS ENUM ('open', 'under_review', 'resolved', 'closed');
CREATE TYPE site_visit_status AS ENUM ('scheduled', 'confirmed', 'completed', 'cancelled', 'no_show');
CREATE TYPE protection_status AS ENUM ('active', 'expiring_soon', 'expired');

-- ============================================================================
-- TABLES
-- ============================================================================

-- Users Table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  role user_role NOT NULL DEFAULT 'channel_partner',
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Projects Table
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_name TEXT NOT NULL,
  location TEXT NOT NULL,
  rera_number TEXT,
  commission_percentage NUMERIC(5, 2) NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Leads Table (with protection-specific fields)
CREATE TABLE leads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_number TEXT UNIQUE NOT NULL,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE RESTRICT,
  channel_partner_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  assigned_salesperson_id UUID REFERENCES users(id) ON DELETE SET NULL,
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  customer_email TEXT,
  status lead_status NOT NULL DEFAULT 'registered',
  lead_source TEXT,
  
  -- Protection fields
  protection_start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  protection_expiry_date DATE NOT NULL DEFAULT CURRENT_DATE + INTERVAL '90 days',
  protection_status protection_status NOT NULL DEFAULT 'active',
  lead_owner_locked BOOLEAN NOT NULL DEFAULT TRUE,
  
  -- Duplicate detection fields
  is_duplicate BOOLEAN NOT NULL DEFAULT FALSE,
  duplicate_reason TEXT,
  duplicate_confidence_score NUMERIC(3, 2),
  duplicate_type TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Lead Activity Table
CREATE TABLE lead_activity (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL,
  note TEXT,
  activity_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Site Visits Table (first-class entity)
CREATE TABLE site_visits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  scheduled_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  visit_date DATE NOT NULL,
  visit_time TIME NOT NULL,
  status site_visit_status NOT NULL DEFAULT 'scheduled',
  notes TEXT,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Commissions Table
CREATE TABLE commissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE RESTRICT,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE RESTRICT,
  partner_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  commission_percentage NUMERIC(5, 2) NOT NULL,
  commission_amount NUMERIC(12, 2),
  status commission_status NOT NULL DEFAULT 'pending',
  approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
  approved_at TIMESTAMP WITH TIME ZONE,
  paid_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Disputes Table
CREATE TABLE disputes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE RESTRICT,
  partner_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  status dispute_status NOT NULL DEFAULT 'open',
  resolution TEXT,
  resolved_by UUID REFERENCES users(id) ON DELETE SET NULL,
  resolved_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Audit Logs Table
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  action TEXT NOT NULL,
  old_value JSONB,
  new_value JSONB,
  performed_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- CONSTRAINTS
-- ============================================================================

-- Lead protection expiry must be after start date
ALTER TABLE leads
ADD CONSTRAINT protection_dates_valid CHECK (protection_expiry_date >= protection_start_date);

-- Commission amount should be non-negative
ALTER TABLE commissions
ADD CONSTRAINT commission_amount_non_negative CHECK (commission_amount >= 0 OR commission_amount IS NULL);

-- Commission percentage should be valid
ALTER TABLE commissions
ADD CONSTRAINT commission_percentage_valid CHECK (commission_percentage >= 0 AND commission_percentage <= 100);

-- Project commission percentage should be valid
ALTER TABLE projects
ADD CONSTRAINT project_commission_percentage_valid CHECK (commission_percentage >= 0 AND commission_percentage <= 100);

-- Duplicate confidence score should be between 0 and 1
ALTER TABLE leads
ADD CONSTRAINT duplicate_confidence_valid CHECK (
  duplicate_confidence_score IS NULL OR 
  (duplicate_confidence_score >= 0 AND duplicate_confidence_score <= 1)
);

-- Site visit completed_at can only be set when status is completed
ALTER TABLE site_visits
ADD CONSTRAINT site_visit_completed_at_valid CHECK (
  (status = 'completed' AND completed_at IS NOT NULL) OR 
  (status != 'completed' AND completed_at IS NULL)
);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE leads IS 'Core leads table with 90-day protection windows and duplicate detection';
COMMENT ON COLUMN leads.protection_expiry_date IS 'Automatically set to 90 days from creation';
COMMENT ON COLUMN leads.lead_owner_locked IS 'When TRUE, only channel partner can modify; prevents ownership disputes';
COMMENT ON COLUMN leads.duplicate_confidence_score IS 'Fuzzy match confidence (0-1); used for duplicate warnings';
COMMENT ON TABLE site_visits IS 'Dedicated table for visit scheduling and tracking workflow';
COMMENT ON TABLE audit_logs IS 'Immutable audit trail of all changes for compliance';
