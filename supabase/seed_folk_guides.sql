INSERT INTO public.folk_guide_id (phone, folk_guide_id, name)
VALUES
  ('9686768989', 'HRCD', 'HRCD'),
  ('9901519203', 'PVND', 'PVND')
ON CONFLICT (phone) DO UPDATE
  SET folk_guide_id = EXCLUDED.folk_guide_id,
      name = EXCLUDED.name;
