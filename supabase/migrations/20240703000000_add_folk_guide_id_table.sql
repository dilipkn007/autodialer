CREATE TABLE IF NOT EXISTS folk_guide_id (
  id BIGSERIAL PRIMARY KEY,
  phone TEXT UNIQUE NOT NULL,
  folk_guide_id TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_folk_guide_id_phone ON folk_guide_id(phone);
CREATE INDEX IF NOT EXISTS idx_folk_guide_id_folk_guide_id ON folk_guide_id(folk_guide_id);
