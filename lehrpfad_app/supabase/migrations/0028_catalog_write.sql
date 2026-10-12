-- 0028_catalog_write.sql – Schreibzugriff fuer das Admin-CMS
-- DB ist Master fuer den Katalog (docs/adr/0002-db-master-admin-write.md).
-- Schreiben duerfen nur Katalog-Editoren: Admin-Rolle UND MFA-Session (aal2).
-- Eine Funktion, ein Ort zum Nachziehen der Regel.
--
-- ACHTUNG: Erst anwenden, wenn der Test-Admin aus 0022 weg ist und der
-- Staff-User MFA hat (Trello admin-account). aal2 schuetzt zusaetzlich,
-- ersetzt das aber nicht.

create or replace function public.is_catalog_editor() returns boolean as $$
  select public.is_admin()
     and coalesce(auth.jwt() ->> 'aal', '') = 'aal2';
$$ language sql stable security definer set search_path = public;

revoke all on function public.is_catalog_editor() from public, anon;
grant execute on function public.is_catalog_editor() to authenticated;

-- Lese-Luecke: trails/stations/amenities waren nur fuer anon lesbar, eingeloggte
-- User (Rolle authenticated) sahen den Katalog nicht.
drop policy if exists "trails public read" on public.trails;
create policy "trails public read" on public.trails
  for select to anon, authenticated using (true);

drop policy if exists "stations public read" on public.stations;
create policy "stations public read" on public.stations
  for select to anon, authenticated using (true);

drop policy if exists "amenities public read" on public.amenities;
create policy "amenities public read" on public.amenities
  for select to anon, authenticated using (true);

-- Schreib-Policies (insert/update/delete) auf alle Katalog-Tabellen.
do $$
declare
  t text;
begin
  foreach t in array array[
    'trails', 'stations', 'amenities',
    'species', 'trail_species', 'merkmale',
    'species_merkmale', 'species_beziehungen',
    'pois', 'trail_pois'
  ]
  loop
    execute format(
      'drop policy if exists %I on public.%I', t || ' editor insert', t);
    execute format(
      'create policy %I on public.%I for insert to authenticated '
      'with check (public.is_catalog_editor())', t || ' editor insert', t);
    execute format(
      'drop policy if exists %I on public.%I', t || ' editor update', t);
    execute format(
      'create policy %I on public.%I for update to authenticated '
      'using (public.is_catalog_editor()) '
      'with check (public.is_catalog_editor())', t || ' editor update', t);
    execute format(
      'drop policy if exists %I on public.%I', t || ' editor delete', t);
    execute format(
      'create policy %I on public.%I for delete to authenticated '
      'using (public.is_catalog_editor())', t || ' editor delete', t);
  end loop;
end $$;
