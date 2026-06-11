# Partner Vault - Row-Level Security (RLS) Policies Documentation

## Overview

This document describes the comprehensive Row-Level Security implementation for Partner Vault. RLS is enforced at the PostgreSQL level, ensuring that no user can access data they're not authorized to see, regardless of how they query the database.

**Security Model:**
- Data access controlled by user role and ownership
- Policies enforced before any data is returned
- No client-side authorization checks (server-side only)
- Audit trail of all access attempts

---

## Role Hierarchy

```
Super Admin (Level 4)
    ↓
Admin (Level 3)
    ↓
Salesperson (Level 2)
    ↓
Channel Partner (Level 1)
```

**Rule:** Higher level roles can see all data accessible to lower level roles.

---

## Helper Functions

### `current_user_role()`

```sql
CREATE OR REPLACE FUNCTION current_user_role() RETURNS user_role AS $$
  SELECT role FROM users WHERE id = auth.user_id() LIMIT 1;
$$ LANGUAGE SQL SECURITY DEFINER STABLE;
```

**Purpose:** Get current user's role for RLS policy checks

**Used in:** All RLS policies to determine access level

---

## Per-Table RLS Policies

### 1. Users Table

#### SELECT Policies

| Policy | Role | Condition | Access |
|--------|------|-----------|--------|
| `super_admin_select_users` | Super Admin | Any | ✅ All users |
| `admin_select_users` | Admin | Any | ✅ All users |
| `users_select_self` | All | `id = auth.user_id()` | ✅ Own profile |

**Summary:**
- Super Admin & Admin see all users
- Others see only themselves
- Prevents user enumeration for channel partners

#### UPDATE Policies

| Policy | Role | Condition | Allowed Updates |
|--------|------|-----------|----------|
| `super_admin_manage_users` | Super Admin | Any | ✅ Full access |
| `users_update_self` | All | `id = auth.user_id()` | ⚠️ Except role |

**Summary:**
- Users can update their own profile (name, email, phone)
- Cannot change their own role (prevents privilege escalation)
- Super Admin can change any user's role

---

### 2. Projects Table

#### SELECT Policies

| Policy | Role | Condition | Access |
|--------|------|-----------|--------|
| `all_users_select_active_projects` | All | `active = true` | ✅ Active projects |
| `super_admin_select_all_projects` | Super Admin | Any | ✅ All projects |

**Summary:**
- All users see active projects (for lead registration)
- Super Admin sees all (including inactive)
- Prevents visibility of inactive/archived projects

#### INSERT/UPDATE/DELETE Policies

| Policy | Role | Access |
|--------|------|--------|
| `super_admin_manage_projects` | Super Admin | ✅ Full access |

**Summary:**
- Only Super Admin can create/modify/delete projects
- Prevents unauthorized project changes

---

### 3. Leads Table (Complex)

#### SELECT Policies

| Policy | Role | Condition | Access |
|--------|------|-----------|--------|
| `super_admin_select_leads` | Super Admin | Any | ✅ All leads |
| `admin_select_leads` | Admin | Any | ✅ All leads |
| `salesperson_select_assigned_leads` | Salesperson | `assigned_salesperson_id = auth.user_id()` | ✅ Assigned leads |
| `channel_partner_select_own_leads` | Channel Partner | `channel_partner_id = auth.user_id()` | ✅ Own leads |

**Summary:**
- Super Admin & Admin: Full visibility
- Salesperson: Only leads assigned to them
- Channel Partner: Only leads they registered
- Prevents data leakage between partners

#### INSERT Policies

| Policy | Role | Condition | Access |
|--------|------|-----------|--------|
| `channel_partner_insert_leads` | Channel Partner | `channel_partner_id = auth.user_id()` | ✅ Register own |

**Summary:**
- Only channel partners can register leads
- Must register with themselves as partner
- Prevents unauthorized lead creation

#### UPDATE Policies

| Policy | Role | Condition | Allowed |
|--------|------|-----------|----------|
| `channel_partner_update_own_leads` | Channel Partner | Own lead + `lead_owner_locked = true` | ⚠️ Limited fields |
| `admin_update_leads` | Admin | Any | ✅ Status, assignment |
| `super_admin_manage_leads` | Super Admin | Any | ✅ Full access |

**Summary:**
- Channel Partner can update their leads (but not transfer ownership)
- Admin can assign leads and update status
- Super Admin has full control
- Lead ownership is immutable once registered

**Protected Fields (Cannot Change):**
- `channel_partner_id` - Original owner
- `is_duplicate` - Set by system
- `protection_*` fields - Immutable

---

### 4. Lead Activity Table

#### SELECT Policies

| Policy | Role | Condition | Access |
|--------|------|-----------|--------|
| `super_admin_select_lead_activity` | Super Admin | Any | ✅ All activity |
| `admin_select_lead_activity` | Admin | Any | ✅ All activity |
| `users_select_lead_activity` | All | Can view parent lead | ✅ Related activity |

**Summary:**
- Access follows lead visibility
- Cannot see activity on leads you can't view

#### INSERT Policies

| Policy | Role | Condition | Access |
|--------|------|-----------|--------|
| `users_insert_lead_activity` | All | Can view parent lead | ✅ Add notes |

**Summary:**
- Users can add activity to leads they can view
- Activity timestamp automatic

---

### 5. Site Visits Table (Dedicated)

#### SELECT Policies

| Policy | Role | Condition | Access |
|--------|------|-----------|--------|
| `super_admin_select_site_visits` | Super Admin | Any | ✅ All visits |
| `admin_select_site_visits` | Admin | Any | ✅ All visits |
| `salesperson_select_site_visits` | Salesperson | Assigned lead | ✅ Their visits |
| `channel_partner_select_site_visits` | Channel Partner | Own lead | ✅ Their visits |

**Summary:**
- Access follows lead visibility
- Salesperson sees visits for assigned leads
- Partner sees visits for their leads

#### INSERT/UPDATE Policies

| Policy | Role | Condition | Access |
|--------|------|-----------|--------|
| `salesperson_manage_site_visits` | Salesperson | `scheduled_by = auth.user_id()` | ✅ Own visits |
| `admin_manage_site_visits` | Admin | Any | ✅ Full access |
| `super_admin_manage_site_visits` | Super Admin | Any | ✅ Full access |

**Summary:**
- Salesperson can only manage visits they scheduled
- Admin & Super Admin can manage any visit
- Prevents cross-salesperson interference

---

### 6. Commissions Table

#### SELECT Policies

| Policy | Role | Condition | Access |
|--------|------|-----------|--------|
| `super_admin_select_commissions` | Super Admin | Any | ✅ All |
| `admin_select_commissions` | Admin | Any | ✅ All |
| `channel_partner_select_own_commissions` | Channel Partner | `partner_id = auth.user_id()` | ✅ Own only |

**Summary:**
- Partners can only see their own commissions
- Admin & Super Admin have full visibility

#### UPDATE Policies

| Policy | Role | Condition | Access |
|--------|------|-----------|--------|
| `admin_update_commissions` | Admin | Any | ✅ Approve/pay |
| `super_admin_manage_commissions` | Super Admin | Any | ✅ Full access |

**Summary:**
- Admin can approve and mark as paid
- Super Admin has full control
- Prevents partner from approving own commissions

---

### 7. Disputes Table

#### SELECT Policies

| Policy | Role | Condition | Access |
|--------|------|-----------|--------|
| `super_admin_select_disputes` | Super Admin | Any | ✅ All |
| `admin_select_disputes` | Admin | Any | ✅ All |
| `channel_partner_select_own_disputes` | Channel Partner | `partner_id = auth.user_id()` | ✅ Own only |

**Summary:**
- Partners see only their disputes
- Admin & Super Admin have full visibility
- Prevents visibility of other partner's disputes

#### INSERT Policies

| Policy | Role | Condition | Access |
|--------|------|-----------|--------|
| `channel_partner_insert_disputes` | Channel Partner | `partner_id = auth.user_id()` | ✅ Raise own |

**Summary:**
- Only channel partners can raise disputes
- Cannot raise dispute on behalf of others

#### UPDATE Policies

| Policy | Role | Condition | Access |
|--------|------|-----------|--------|
| `admin_update_disputes` | Admin | Any | ✅ Resolve |
| `super_admin_manage_disputes` | Super Admin | Any | ✅ Full access |

**Summary:**
- Only admin can update/resolve disputes
- Prevents partner from resolving own disputes

---

### 8. Audit Logs Table (Immutable)

#### SELECT Policies

| Policy | Role | Condition | Access |
|--------|------|-----------|--------|
| `super_admin_select_audit_logs` | Super Admin | Any | ✅ All |
| `admin_select_audit_logs` | Admin | Any | ✅ All |

**Summary:**
- Only Admin & Super Admin can view logs
- Prevents tampering visibility

#### Immutable Policies

```sql
CREATE POLICY "no_update_audit_logs" ON audit_logs
  FOR UPDATE USING (FALSE) WITH CHECK (FALSE);

CREATE POLICY "no_delete_audit_logs" ON audit_logs
  FOR DELETE USING (FALSE);
```

**Summary:**
- Audit logs cannot be modified once created
- Prevents tampering for compliance

---

## Security Patterns

### 1. Ownership-Based Access

```sql
-- User can only see/edit their own data
CREATE POLICY "users_update_self" ON users
  FOR UPDATE
  USING (id = auth.user_id())
  WITH CHECK (id = auth.user_id());
```

**Used for:** Users, Channel Partner leads, Salesperson visits

### 2. Hierarchical Access

```sql
-- Admin sees all, others see filtered
CREATE POLICY "admin_select_all" ON leads
  FOR SELECT
  USING (current_user_role() = 'admin');
```

**Used for:** Most tables to give admin oversight

### 3. Relationship-Based Access

```sql
-- Access based on relationship to parent
CREATE POLICY "salesperson_select_assigned" ON leads
  FOR SELECT
  USING (
    current_user_role() = 'salesperson' AND
    assigned_salesperson_id = auth.user_id()
  );
```

**Used for:** Site visits, lead activity (follow lead access)

### 4. Immutable Fields

```sql
-- Prevent privilege escalation
CREATE POLICY "users_update_self" ON users
  FOR UPDATE
  USING (id = auth.user_id())
  WITH CHECK (
    id = auth.user_id() AND
    role = (SELECT role FROM users WHERE id = auth.user_id())
  );
```

**Used for:** Protection fields, ownership fields

### 5. Approval Gates

```sql
-- Non-admins cannot approve own items
CREATE POLICY "admin_update_commissions" ON commissions
  FOR UPDATE
  USING (current_user_role() = 'admin')
  WITH CHECK (current_user_role() = 'admin');
```

**Used for:** Commission approval, dispute resolution

---

## Testing RLS

### Test Super Admin Access
```sql
-- In Supabase Studio, impersonate super admin user
SET JWT CLAIMS = '{"sub":"550e8400-e29b-41d4-a716-446655440000"}';
SELECT * FROM leads; -- Should return all leads
```

### Test Partner Access
```sql
-- Impersonate channel partner
SET JWT CLAIMS = '{"sub":"550e8400-e29b-41d4-a716-446655440010"}';
SELECT * FROM leads; -- Should return only their leads
SELECT * FROM users; -- Should fail (no access)
```

### Test Update Protection
```sql
-- Impersonate partner
SET JWT CLAIMS = '{"sub":"550e8400-e29b-41d4-a716-446655440010"}';
UPDATE leads SET channel_partner_id = 'different_id' 
WHERE id = 'their_lead'; -- Should fail (protected field)
```

---

## Performance Considerations

1. **Function Calls:** `current_user_role()` called per policy
   - Solution: Cache role in session
   - Consider using app_role claim in JWT

2. **Subquery Overhead:** Some policies use EXISTS subqueries
   - Example: Lead activity checking parent lead access
   - Acceptable for small datasets
   - Consider view-based policies if needed

3. **Index Strategy:** Ensure composite indexes exist for policy conditions
   - `leads(channel_partner_id, status)`
   - `leads(assigned_salesperson_id, status)`

---

## Common Scenarios

### Scenario 1: Partner Registers Lead
1. Partner calls INSERT on leads with `channel_partner_id = self`
2. RLS policy checks: `channel_partner_id = auth.user_id()` ✅
3. Lead created, protection window set to 90 days
4. Audit log created automatically

### Scenario 2: Admin Assigns Lead to Salesperson
1. Admin calls UPDATE leads with new `assigned_salesperson_id`
2. RLS policy: `admin_update_leads` checks `current_user_role() = 'admin'` ✅
3. Lead status updated to 'assigned'
4. Salesperson can now see lead

### Scenario 3: Salesperson Schedules Site Visit
1. Salesperson calls INSERT on site_visits for assigned lead
2. Policy checks: `scheduled_by = auth.user_id()` AND assigned lead ✅
3. Site visit created with scheduled status
4. Partner can see visit on their lead

### Scenario 4: Partner Tries to View Another Partner's Lead
1. Partner queries: `SELECT * FROM leads WHERE id = 'other_partner_lead'`
2. RLS policy: `channel_partner_select_own_leads` checks ownership
3. Query returns empty result (no error)
4. Partner sees no indication lead exists

---

## Compliance & Audit

- **GDPR:** Users can only see their own personal data
- **Data Isolation:** Partners can never see competitor data
- **Audit Trail:** All changes logged with timestamps
- **Role Changes:** Cannot escalate privileges (role field immutable)
- **Immutable Records:** Audit logs cannot be modified

---

## Next Steps

1. ✅ RLS policies defined
2. ✅ Helper functions created
3. ⏳ JWT claims optimization (caching role)
4. ⏳ Audit log trigger functions
5. ⏳ Protection status update trigger
6. ⏳ Integration tests for policies
