-- Migration: Add RLS policies for access_token table
-- Enables admin CRUD, anon token lookup (for login), and token-owner consumption

-- Enable RLS on the table
ALTER TABLE access_token ENABLE ROW LEVEL SECURITY;

-- 1. Admin full access (INSERT, SELECT, UPDATE, DELETE)
--    Admin users are identified by role = 'ADMIN' in the contact table
CREATE POLICY "Admin full access" ON access_token
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM contact
      WHERE id = auth.uid() AND role = 'ADMIN'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM contact
      WHERE id = auth.uid() AND role = 'ADMIN'
    )
  );

-- 2. Anyone can read tokens by value (for login flow)
--    The token itself acts as the access credential
CREATE POLICY "Anyone can read tokens" ON access_token
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- 3. Token owner can consume their own token (mark as used)
CREATE POLICY "Owner can use token" ON access_token
  FOR UPDATE
  TO authenticated
  USING (contact_id = auth.uid())
  WITH CHECK (contact_id = auth.uid() AND is_used = true);
