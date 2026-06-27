-- Migration: Merge users table into contacts table
-- Apply schema changes to support unified contact model

-- Add new columns to contact table for user fields
ALTER TABLE contact 
ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'ENABLER',
ADD COLUMN IF NOT EXISTS avatar_initials TEXT,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;

-- Migrate data from users to contact (only if a contact doesn't exist for that user)
INSERT INTO contact (id, mobile, name, email, role, avatar_initials, is_active, created_at, updated_at)
SELECT 
  u.uid::uuid,
  u.phone,
  u.name,
  u.email,
  CASE WHEN u.role = 'ADMIN' THEN 'ADMIN' ELSE 'ENABLER' END,
  u.avatar_initials,
  u.is_active,
  u.created_at,
  u.updated_at
FROM users u
ON CONFLICT (id) DO UPDATE 
SET mobile = EXCLUDED.mobile,
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    avatar_initials = EXCLUDED.avatar_initials,
    is_active = EXCLUDED.is_active;

-- Update existing contact records to set role for enablers (from is_enabler column)
UPDATE contact SET role = 'ENABLER' WHERE (is_enabler = 'true' OR is_enabler = true) AND role = 'ENABLER';

-- For PostgreSQL/ Supabase, update foreign key references (may require constraint name adjustments)
-- These commands need to be adapted based on your actual constraint names
-- ALTER TABLE assignment DROP CONSTRAINT IF EXISTS assignment_enabler_id_fkey;
-- ALTER TABLE assignment ADD CONSTRAINT assignment_enabler_id_fkey FOREIGN KEY (enabler_id) REFERENCES contact(id);
-- ALTER TABLE assignment DROP CONSTRAINT IF EXISTS assignment_assigned_by_fkey;
-- ALTER TABLE assignment ADD CONSTRAINT assignment_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES contact(id);
-- ALTER TABLE call_log DROP CONSTRAINT IF EXISTS call_log_enabler_id_fkey;
-- ALTER TABLE call_log ADD CONSTRAINT call_log_enabler_id_fkey FOREIGN KEY (enabler_id) REFERENCES contact(id);
-- ALTER TABLE event DROP CONSTRAINT IF EXISTS event_created_by_fkey;
-- ALTER TABLE event ADD CONSTRAINT event_created_by_fkey FOREIGN KEY (created_by) REFERENCES contact(id);

-- After verifying everything works, you can drop the users table:
-- DROP TABLE users CASCADE;