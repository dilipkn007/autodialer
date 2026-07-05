-- Remove duplicate contact rows created by login-with-token edge function.
-- The edge function was creating a new contact with id=auth_user_id and
-- mobile=E.164 format, duplicating the original contact that already existed.
-- 
-- Strategy: find contacts that share the same phone number (ignoring +91 prefix),
-- and delete the one with the longer mobile string (the E.164 duplicate).

WITH dupes AS (
  SELECT
    LOWER(REGEXP_REPLACE(mobile, '^\+91', '')) AS normalized_mobile,
    COUNT(*)                                    AS cnt,
    ARRAY_AGG(id ORDER BY LENGTH(mobile) ASC)   AS ids
  FROM contact
  GROUP BY LOWER(REGEXP_REPLACE(mobile, '^\+91', ''))
  HAVING COUNT(*) > 1
)
  DELETE FROM contact
WHERE id IN (
  SELECT UNNEST(ids[2:array_length(ids, 1)])  -- keep the first (shorter mobile = original), delete the rest
  FROM dupes
);
