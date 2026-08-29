-- PUBLIC mitnehmen. Owner ist supabase_admin — auf Hosted wirkt
-- das nur, wenn die Rolle den Grant auch wirklich entziehen kann.
revoke all on table public.spatial_ref_sys from public, anon, authenticated;
revoke all on table public.geometry_columns from public, anon, authenticated;
revoke all on table public.geography_columns from public, anon, authenticated;
