-- PostGIS-Kataloge sind intern. Kein RLS (bricht PostGIS),
-- aber Clients brauchen keinen Zugriff. PUBLIC mitnehmen —
-- sonst bleiben die Default-Grants der Extension stehen.
revoke all on table public.spatial_ref_sys from public, anon, authenticated;
revoke all on table public.geometry_columns from public, anon, authenticated;
revoke all on table public.geography_columns from public, anon, authenticated;
