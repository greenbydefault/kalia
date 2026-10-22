-- 0034_offline_fundament.sql – Offline-First Phase 1 (Spec "Offline-First & Inhalte laden")
--
-- Versionsabgleich statt Zeitstempel: trails.data_version ist die Paket-Version
-- eines Ortes, species.version die einer Art. Kindtabellen brauchen weder
-- updated_at noch deleted_at; die App vergleicht get_catalog_versions() lokal.
--
--  1. trails.hoertext        (ging bisher beim Sync verloren)
--  2. species.version        + Trigger
--  3. data_version-Trigger   auf trails und den trail-bezogenen Kindtabellen
--  4. images.hash            (sha256 der Medium-Datei, Integritaet/Immutability)
--  5. get_catalog_versions() (security definer, nur sichtbar = true)
--  6. RLS: Kindtabellen nur lesbar, wenn der Trail sichtbar ist

-- ---------------------------------------------------------------------
-- 1 · Trail-Hoertext
-- ---------------------------------------------------------------------
alter table public.trails
  add column if not exists hoertext text;

-- ---------------------------------------------------------------------
-- 2 · Arten-Version
-- ---------------------------------------------------------------------
alter table public.species
  add column if not exists version integer not null default 1;

create or replace function public.species_bump_version()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  -- Explizit gesetzte Version (Import) bleibt; sonst bei Inhaltsaenderung +1.
  if new.version is not distinct from old.version
     and to_jsonb(new) is distinct from to_jsonb(old) then
    new.version := old.version + 1;
  end if;
  return new;
end;
$$;

drop trigger if exists species_bump_version on public.species;
create trigger species_bump_version
  before update on public.species
  for each row execute function public.species_bump_version();

-- ---------------------------------------------------------------------
-- 3 · data_version
-- ---------------------------------------------------------------------
-- Trails: Inhaltsaenderung erhoeht die Version, solange niemand sie explizit
-- setzt (apply_submission tut das) und nicht nur updated_at wechselt.
create or replace function public.trails_bump_data_version()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  -- start_pos ist eine Generated Column und im BEFORE-Trigger noch nicht berechnet.
  if new.data_version is not distinct from old.data_version
     and (to_jsonb(new) - 'updated_at' - 'data_version' - 'start_pos')
         is distinct from (to_jsonb(old) - 'updated_at' - 'data_version' - 'start_pos') then
    new.data_version := old.data_version + 1;
  end if;
  return new;
end;
$$;

drop trigger if exists trails_bump_data_version on public.trails;
create trigger trails_bump_data_version
  before update on public.trails
  for each row execute function public.trails_bump_data_version();

-- Kindtabellen: jede Aenderung zieht die Version des Trails mit.
-- images zaehlt nur fuer redaktionelle Bilder (source = 'official'); Community-
-- Fotos sind kein Teil des Ortspakets.
create or replace function public.bump_trail_data_version()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_trail text;
begin
  if tg_op = 'DELETE' then
    v_trail := to_jsonb(old) ->> 'trail_id';
    if tg_table_name = 'images' and (to_jsonb(old) ->> 'source') is distinct from 'official' then
      return old;
    end if;
  else
    v_trail := to_jsonb(new) ->> 'trail_id';
    if tg_table_name = 'images' and (to_jsonb(new) ->> 'source') is distinct from 'official' then
      return new;
    end if;
  end if;

  if v_trail is not null then
    update public.trails set data_version = data_version + 1 where id = v_trail;
  end if;

  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;

-- Nur Trigger-Funktion, kein RPC.
revoke all on function public.bump_trail_data_version() from public, anon, authenticated;

do $$
declare
  t text;
begin
  foreach t in array array['stations', 'amenities', 'trail_species', 'trail_pois', 'trail_hints', 'images']
  loop
    execute format('drop trigger if exists %I on public.%I', t || '_bump_trail_version', t);
    execute format(
      'create trigger %I after insert or update or delete on public.%I '
      'for each row execute function public.bump_trail_data_version()',
      t || '_bump_trail_version', t
    );
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 4 · images.hash
-- ---------------------------------------------------------------------
alter table public.images
  add column if not exists hash text;

-- ---------------------------------------------------------------------
-- 5 · Versionsliste fuer den Katalog-Sync
-- ---------------------------------------------------------------------
-- Schlank (wenige KB): {trails: [{id, data_version, closed}], species: [{id, version}]}.
-- closed = aktiver Hinweis "closed"/"danger" (Warnung hat auch offline Vorrang).
create or replace function public.get_catalog_versions()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'trails', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', t.id,
          'data_version', t.data_version,
          'closed', exists (
            select 1 from public.trail_hints h
            where h.trail_id = t.id
              and h.kind in ('closed', 'danger')
              and (h.expires_at is null or h.expires_at > now())
          )
        ) order by t.id
      )
      from public.trails t
      where t.sichtbar
    ), '[]'::jsonb),
    'species', coalesce((
      select jsonb_agg(jsonb_build_object('id', s.id, 'version', s.version) order by s.id)
      from public.species s
    ), '[]'::jsonb)
  );
$$;

revoke all on function public.get_catalog_versions() from public;
grant execute on function public.get_catalog_versions() to anon, authenticated;

-- ---------------------------------------------------------------------
-- 6 · RLS: Kindtabellen nur bei sichtbarem Trail
-- ---------------------------------------------------------------------
create or replace function public.trail_is_visible(p_trail_id text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_admin() or exists (
    select 1 from public.trails t where t.id = p_trail_id and t.sichtbar
  );
$$;

revoke all on function public.trail_is_visible(text) from public;
grant execute on function public.trail_is_visible(text) to anon, authenticated;

create index if not exists stations_trail_idx on public.stations (trail_id);
create index if not exists amenities_trail_idx on public.amenities (trail_id);
create index if not exists trail_species_trail_idx on public.trail_species (trail_id);

drop policy if exists "stations public read" on public.stations;
create policy "stations public read" on public.stations
  for select to anon, authenticated
  using (public.trail_is_visible(trail_id));

drop policy if exists "amenities public read" on public.amenities;
create policy "amenities public read" on public.amenities
  for select to anon, authenticated
  using (public.trail_is_visible(trail_id));

drop policy if exists "trail_species public read" on public.trail_species;
create policy "trail_species public read" on public.trail_species
  for select to anon, authenticated
  using (public.trail_is_visible(trail_id));

drop policy if exists "trail_pois public read" on public.trail_pois;
create policy "trail_pois public read" on public.trail_pois
  for select to anon, authenticated
  using (public.trail_is_visible(trail_id));
