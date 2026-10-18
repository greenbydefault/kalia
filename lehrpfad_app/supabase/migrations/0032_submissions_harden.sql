-- 0032_submissions_harden.sql – Hilfsfunktionen aus 0031 nicht ueber die API erreichbar.
-- Die RPCs (create_submission usw.) rufen sie als Owner auf, Clients brauchen sie nicht.
revoke execute on function public.catalog_point_geog(text) from public, anon, authenticated;
revoke execute on function public.trail_route_geog(text) from public, anon, authenticated;
revoke execute on function public.delete_open_submissions_of_user() from public, anon, authenticated;
revoke execute on function public.submission_error(text) from public, anon, authenticated;
alter function public.submission_error(text) set search_path = public;
