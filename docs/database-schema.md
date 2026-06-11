# Partner Vault - Database Schema Documentation

## Overview

This document describes the complete database schema for Partner Vault, a Lead Protection & Transparency Platform for Real Estate Channel Partners.

**Key Principles:**
- 90-day automatic lead protection windows
- Role-based access control via Row-Level Security (RLS)
- Comprehensive duplicate detection
- Complete audit trail for compliance
- Immutable protection windows

---

## Core Entities

### 1. Users

**Purpose:** User management with role-based access control

**Schema:**
```sql
id UUID PRIMARY KEY
full_name TEXT NOT NULL
email TEXT UNIQUE NOT NULL
phone TEXT
role user_role ENUM NOT NULL (super_admin | admin | salesperson | channel_partner)
active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP DEFAULT NOW()
updated_at TIMESTAMP DEFAULT NOW()
```

**Roles:**
- **Super Admin**: Full platform access, user management
- **Admin**: Operational control (assignments, approvals, disputes)
- **Salesperson**: View assigned leads, update status, schedule visits
- **Channel Partner**: Register and manage their own leads

---

### 2. Projects

**Purpose:** Real estate projects with commission configuration

**Schema:**
```sql
id UUID PRIMARY KEY
project_name TEXT NOT NULL
location TEXT NOT NULL
rera_number TEXT (optional)
commission_percentage NUMERIC(5,2) NOT NULL (0-100)
active BOOLEAN DEFAULT TRUE
created_at TIMESTAMP DEFAULT NOW()
```

**Notes:**
- Each project has its own commission percentage
- Can be activated/deactivated for lead intake
- RERA number is optional (India-specific)

---

### 3. Leads (Core Entity)

**Purpose:** Lead registration with protection and duplicate detection

**Schema:**
```sql
id UUID PRIMARY KEY
lead_number TEXT UNIQUE NOT NULL
project_id UUID FK -> projects
channel_partner_id UUID FK -> users (who registered)
assigned_salesperson_id UUID FK -> users (optional)
customer_name TEXT NOT NULL
customer_phone TEXT NOT NULL
customer_email TEXT
status lead_status ENUM NOT NULL
lead_source TEXT

-- Protection Window (90 days)
protection_start_date DATE DEFAULT CURRENT_DATE
protection_expiry_date DATE DEFAULT CURRENT_DATE + 90 DAYS
protection_status protection_status ENUM (active | expiring_soon | expired)
lead_owner_locked BOOLEAN DEFAULT TRUE

-- Duplicate Detection
is_duplicate BOOLEAN DEFAULT FALSE
duplicate_reason TEXT
duplicate_confidence_score NUMERIC(0-1)
duplicate_type TEXT

created_at TIMESTAMP DEFAULT NOW()
updated_at TIMESTAMP DEFAULT NOW()
```

**Key Features:**

1. **Protection Window:**
   - Automatically set to 90 days from creation
   - Once set, cannot be modified (immutable)
   - Cannot be transferred to another partner
   - Statuses: active, expiring_soon (last 15 days), expired

2. **Ownership Protection:**
   - `lead_owner_locked = true` prevents unwanted reassignment
   - Only channel partner can modify their own leads when locked
   - Admin can forcibly reassign if needed

3. **Duplicate Detection:**
   - `duplicate_confidence_score` (0-1): fuzzy match confidence
   - `duplicate_type`: exact_match or similar_name
   - Flagged leads still tradeable but marked for admin review

4. **Status Pipeline:**
   ```
   registered -> assigned -> contacted -> site_visit_scheduled 
   -> site_visit_completed -> negotiation -> booking -> closed_won/closed_lost
   ```

---

### 4. Lead Activity

**Purpose:** Activity timeline for each lead

**Schema:**
```sql
id UUID PRIMARY KEY
lead_id UUID FK -> leads CASCADE
activity_type TEXT NOT NULL (registration, assignment, note, contact, etc.)
note TEXT
activity_date TIMESTAMP DEFAULT NOW()
created_by UUID FK -> users
created_at TIMESTAMP DEFAULT NOW()
```

**Usage:**
- Log all lead interactions
- Audit trail of activities
- Timeline view in UI

---

### 5. Site Visits (First-Class Entity)

**Purpose:** Dedicated workflow for property visit scheduling and tracking

**Schema:**
```sql
id UUID PRIMARY KEY
lead_id UUID FK -> leads CASCADE
scheduled_by UUID FK -> users
visit_date DATE NOT NULL
visit_time TIME NOT NULL
status site_visit_status ENUM NOT NULL
  (scheduled | confirmed | completed | cancelled | no_show)
notes TEXT
completed_at TIMESTAMP (only set when status = completed)
created_at TIMESTAMP DEFAULT NOW()
updated_at TIMESTAMP DEFAULT NOW()
```

**Status Workflow:**
```
scheduled -> confirmed -> completed
         ↓-> cancelled/no_show
```

**Key Features:**
- Dedicated table (not stored in lead_activity)
- Salespersons can schedule and update visits
- Admins can manage all visits
- Completion timestamp for analytics

---

### 6. Commissions

**Purpose:** Track commission calculations and approvals

**Schema:**
```sql
id UUID PRIMARY KEY
lead_id UUID FK -> leads
project_id UUID FK -> projects
partner_id UUID FK -> users
commission_percentage NUMERIC(5,2) NOT NULL
commission_amount NUMERIC(12,2) (optional)
status commission_status ENUM (pending | approved | paid)
approved_by UUID FK -> users (optional)
approved_at TIMESTAMP (optional)
paid_at TIMESTAMP (optional)
created_at TIMESTAMP DEFAULT NOW()
```

**Workflow:**
```
Pending -> Approved -> Paid
```

**Notes:**
- Commission % comes from project
- Amount calculated when booking confirmed
- Only admins can approve

---

### 7. Disputes

**Purpose:** Track and resolve lead ownership disputes

**Schema:**
```sql
id UUID PRIMARY KEY
lead_id UUID FK -> leads
partner_id UUID FK -> users (who raised)
title TEXT NOT NULL
description TEXT NOT NULL
status dispute_status ENUM (open | under_review | resolved | closed)
resolution TEXT
resolved_by UUID FK -> users (optional)
resolved_at TIMESTAMP (optional)
created_at TIMESTAMP DEFAULT NOW()
```

**Workflow:**
```
Open -> Under Review -> Resolved -> Closed
```

**Features:**
- Channel partners can raise disputes
- Admins review and resolve
- Resolution notes for transparency

---

### 8. Audit Logs

**Purpose:** Immutable audit trail for compliance

**Schema:**
```sql
id UUID PRIMARY KEY
entity_type TEXT NOT NULL (user, lead, commission, etc.)
entity_id UUID NOT NULL
action TEXT NOT NULL (create, update, delete, approve, etc.)
old_value JSONB (before state)
new_value JSONB (after state)
performed_by UUID FK -> users
created_at TIMESTAMP DEFAULT NOW()
```

**Features:**
- Immutable (no updates/deletes allowed)
- Complete before/after state tracking
- Timestamp of every action
- Used for compliance and debugging

---

## Enums

### user_role
```
'super_admin' | 'admin' | 'salesperson' | 'channel_partner'
```

### lead_status
```
'registered' | 'assigned' | 'contacted' | 'site_visit_scheduled' |
'site_visit_completed' | 'negotiation' | 'booking' | 'closed_won' | 'closed_lost'
```

### commission_status
```
'pending' | 'approved' | 'paid'
```

### dispute_status
```
'open' | 'under_review' | 'resolved' | 'closed'
```

### site_visit_status
```
'scheduled' | 'confirmed' | 'completed' | 'cancelled' | 'no_show'
```

### protection_status
```
'active' | 'expiring_soon' | 'expired'
```

---

## Constraints

### Data Integrity
- Protection dates: `protection_expiry_date >= protection_start_date`
- Commissions: `0 <= commission_percentage <= 100`
- Commissions: `commission_amount >= 0`
- Duplicate score: `0 <= duplicate_confidence_score <= 1`
- Site visits: `completed_at` only set when `status = 'completed'`

### Foreign Keys
- All FK relationships use `ON DELETE RESTRICT` to prevent orphaned records
- Exception: Lead activities and site visits use `CASCADE` (deleted with lead)

---

## Indexes

**Performance Optimizations:**

### Lookup Indexes
- `users(email, role, active)`
- `projects(active)`
- `leads(lead_number, channel_partner_id, assigned_salesperson_id, project_id, status)`
- `commissions(partner_id, status, created_at)`
- `disputes(partner_id, status, created_at)`
- `site_visits(scheduled_by, visit_date, status)`

### Composite Indexes (Common Queries)
- `leads(channel_partner_id, status)` - Partner's lead list
- `leads(assigned_salesperson_id, status)` - Salesperson's leads
- `commissions(partner_id, status)` - Partner commission summary
- `disputes(partner_id, status)` - Partner dispute history
- `site_visits(scheduled_by, status, visit_date)` - Upcoming visits

### Timeline Indexes
- `leads(created_at DESC, updated_at DESC)`
- `commissions(created_at DESC)`
- `disputes(created_at DESC)`
- `audit_logs(created_at DESC)`

---

## Relationships (ER Summary)

```
Users (1)
  ├── leads (1->N) [channel_partner, assigned_salesperson]
  ├── site_visits (1->N) [scheduled_by]
  ├── lead_activity (1->N) [created_by]
  ├── commissions (1->N) [partner, approved_by]
  ├── disputes (1->N) [partner, resolved_by]
  └── audit_logs (1->N) [performed_by]

Projects (1)
  ├── leads (1->N)
  └── commissions (1->N)

Leads (1)
  ├── lead_activity (1->N) [CASCADE on delete]
  ├── site_visits (1->N) [CASCADE on delete]
  ├── commissions (1->N)
  ├── disputes (1->N)
  └── audit_logs (1->N)
```

---

## Migration Strategy

**Phase 1.2 Migrations:**
1. `001_initial_schema.sql` - Create all tables with enums
2. `002_rls_policies.sql` - Enable RLS and set policies
3. `003_indexes.sql` - Create all performance indexes
4. `004_seed_data.sql` - Load test data

**Future Migrations:**
- Trigger for audit log creation
- Trigger for protection status updates
- Trigger for updated_at timestamps

---

## Security Considerations

1. **Row-Level Security (RLS):** Enforced at database level
2. **No localStorage:** All auth state stored in secure cookies
3. **Immutable Protection:** Once set, cannot be changed
4. **Audit Trail:** All changes logged for compliance
5. **Encryption:** Customer data encrypted at rest

---

## Next Steps

1. ✅ Schema created with protection fields
2. ✅ RLS policies enforced
3. ✅ Indexes for performance
4. ⏳ Trigger functions for automation
5. ⏳ API layer with server actions
