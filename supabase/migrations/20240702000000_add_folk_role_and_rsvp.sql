-- 1. Create event_rsvp table
CREATE TABLE IF NOT EXISTS event_rsvp (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id   UUID NOT NULL REFERENCES event(id) ON DELETE CASCADE,
  contact_id UUID NOT NULL REFERENCES contact(id) ON DELETE CASCADE,
  status     TEXT NOT NULL DEFAULT 'GOING' CHECK (status IN ('GOING', 'NOT_GOING', 'MAYBE')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (event_id, contact_id)
);

-- 2. RLS for event_rsvp
ALTER TABLE event_rsvp ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read event_rsvp"
  ON event_rsvp FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can insert/update own RSVP"
  ON event_rsvp FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update own RSVP"
  ON event_rsvp FOR UPDATE
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete own RSVP"
  ON event_rsvp FOR DELETE
  USING (auth.role() = 'authenticated');

-- 3. Change ENABLER → FOLK for all contacts except the two designated enablers
UPDATE contact
SET role = 'FOLK'
WHERE role = 'ENABLER'
  AND id NOT IN (
    '396464e9-b075-4e18-bd15-5b59bee91caf',  -- Bhuvan HO
    '7f9ecc61-5bd3-4850-8ff3-21d418f4f43f'   -- Keerthan Hitesh R
  );
