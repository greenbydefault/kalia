-- 0035_import.sql – Content-Import-Pipeline (Spec "Pfade aus Master-Template")
--
-- Dossier-ZIP je Pfad -> Python-Worker (service_role) -> Entwurf in trails
-- (sichtbar = false) -> Review im Admin (Trails, Split-Screen) -> Anlegen.
--
--  1. Erweiterungen (pg_trgm)
--  2. trails: land/bundesland/kreis/ort/schutzgebiet, source_*, locked_fields, field_meta
--  3. Import-Tabellen: candidates, batches, jobs, species_suggestions, trail_sources,
--     import_questions, import_events
--  4. data_version-Trigger: Meta-Spalten zaehlen nicht als Inhaltsaenderung
--  5. Lock-Trigger (trails, stations, trail_species, official images)
--  6. RLS: Import-Tabellen lesen is_admin(), schreiben nur service_role
--  7. images-Policy: Bilder unsichtbarer Trails sind nicht lesbar (Leck-Luecke)
--  8. Queue: claim_import_job (FOR UPDATE SKIP LOCKED)
--  9. Duplikat-Suche (PostGIS + pg_trgm)
-- 10. RPCs fuer das CMS (is_catalog_editor)
-- 11. Storage: privater Bucket imports
-- 12. Realtime auf import_jobs
--
-- Job-Status: wartet | laeuft | bereit | wartet_auf_klaerung | vorschlag |
--             angelegt | verworfen | fehlgeschlagen
--  bereit   = Entwurf liegt als trails-Zeile (sichtbar=false) vor, wartet auf Review
--  vorschlag = Re-Import eines veroeffentlichten Pfads, Aenderungsvorschlag in proposal
-- Job-Modus (modus): import (voller Lauf) | validate (Regeln auf dem DB-Stand neu rechnen)
--                    | apply (angenommene Teile von proposal schreiben)

-- ---------------------------------------------------------------------
-- 1 · Erweiterungen
-- ---------------------------------------------------------------------
create extension if not exists pg_trgm with schema extensions;

-- ---------------------------------------------------------------------
-- 2 · trails
-- ---------------------------------------------------------------------
alter table public.trails
  add column if not exists land text,
  add column if not exists bundesland text,
  add column if not exists kreis text,
  add column if not exists ort text,
  add column if not exists schutzgebiet text,
  add column if not exists source_job_id uuid,
  add column if not exists source_file_hash text,
  add column if not exists locked_fields text[] not null default '{}',
  add column if not exists field_meta jsonb not null default '{}'::jsonb;

alter table public.trails
  drop constraint if exists trails_land_check;
alter table public.trails
  add constraint trails_land_check check (land is null or land in ('DE', 'DK', 'ES'));

-- ---------------------------------------------------------------------
-- 3 · Import-Tabellen
-- ---------------------------------------------------------------------
create table if not exists public.trail_candidates (
  id text primary key,                         -- Slug
  name text not null,
  land text,
  bundesland text,
  kreis text,
  ort text,
  quelle text not null default '',             -- Liste/Datei, aus der der Kandidat stammt
  status text not null default 'offen'
    check (status in ('offen', 'dossier', 'entwurf', 'freigegeben', 'verworfen')),
  verworfen_grund text,
  notiz text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.import_batches (
  id uuid primary key default gen_random_uuid(),
  name text not null default '',
  status text not null default 'laeuft'
    check (status in ('laeuft', 'pausiert', 'fertig')),
  kosten_usd numeric(10, 4) not null default 0,
  kosten_deckel_usd numeric(10, 2),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.import_jobs (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid references public.import_batches (id) on delete set null,
  trail_id text,                               -- Slug aus dem Dossier (nach dem Parsen)
  file_name text not null,
  file_hash text not null,                     -- sha256 des ZIP
  storage_path text not null,                  -- imports/<hash>.zip
  status text not null default 'wartet'
    check (status in ('wartet', 'laeuft', 'bereit', 'wartet_auf_klaerung', 'vorschlag',
                      'angelegt', 'verworfen', 'fehlgeschlagen')),
  modus text not null default 'import'
    check (modus in ('import', 'validate', 'apply')),
  stage text,                                  -- zuletzt abgeschlossene Stufe
  priority integer not null default 0,
  attempts integer not null default 0,
  next_run_at timestamptz not null default now(),
  locked_at timestamptz,
  locked_by text,
  template_version integer,
  parsed jsonb,                                -- geparstes Dossier, inkl. Abschnitt 5 roh
  report jsonb not null default '[]'::jsonb,   -- Pruefmeldungen, siehe import_worker/rules.py
  proposal jsonb,                              -- Re-Import: Aenderungsvorschlag je Feld/Block
  error text,                                  -- Klartext fuer die Oberflaeche
  error_detail text,                           -- Log, eingeklappt
  kosten_usd numeric(10, 4) not null default 0,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  finished_at timestamptz
);

-- Datei-Identitaet = Hash. Gleicher Hash = nichts zu tun.
create unique index if not exists import_jobs_hash_uniq on public.import_jobs (file_hash);
create index if not exists import_jobs_queue_idx
  on public.import_jobs (priority desc, created_at) where status = 'wartet';
create index if not exists import_jobs_trail_idx on public.import_jobs (trail_id);
create index if not exists import_jobs_batch_idx on public.import_jobs (batch_id);
create index if not exists import_jobs_status_idx on public.import_jobs (status);

alter table public.trails
  drop constraint if exists trails_source_job_fk;
alter table public.trails
  add constraint trails_source_job_fk
  foreign key (source_job_id) references public.import_jobs (id) on delete set null;

create table if not exists public.species_suggestions (
  id bigserial primary key,
  job_id uuid references public.import_jobs (id) on delete cascade,
  trail_id text not null,
  name_de text not null,
  name_lat_guess text,
  nachweis text not null default 'typisch' check (nachweis in ('belegt', 'typisch')),
  quelle text,
  species_id text references public.species (id) on delete set null,   -- gesetzt, wenn zugeordnet/angelegt
  status text not null default 'offen' check (status in ('offen', 'zugeordnet', 'verworfen')),
  created_at timestamptz not null default now()
);
create index if not exists species_suggestions_trail_idx on public.species_suggestions (trail_id);

create table if not exists public.trail_sources (
  id bigserial primary key,
  trail_id text not null references public.trails (id) on delete cascade,
  abschnitt integer not null,
  angabe text not null default '',
  url text not null default '',
  abgerufen_am date,
  created_at timestamptz not null default now()
);
create index if not exists trail_sources_trail_idx on public.trail_sources (trail_id, abschnitt);

create table if not exists public.import_questions (
  id bigserial primary key,
  job_id uuid references public.import_jobs (id) on delete set null,
  trail_id text not null,
  field text,                                  -- null = ganzer Pfad
  frage text not null,
  adressat text not null check (adressat in ('recherche', 'person')),
  person_id uuid references auth.users (id) on delete set null,
  status text not null default 'offen' check (status in ('offen', 'beantwortet', 'erledigt')),
  antwort text,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  answered_at timestamptz,
  updated_at timestamptz not null default now()
);
create index if not exists import_questions_trail_idx on public.import_questions (trail_id, status);

create table if not exists public.import_events (
  id bigserial primary key,
  trail_id text,
  job_id uuid references public.import_jobs (id) on delete set null,
  typ text not null,                           -- import | aenderung | uebersteuert | frage | antwort | angelegt | rueckgaengig | verworfen | ...
  feld text,
  daten jsonb not null default '{}'::jsonb,
  user_id uuid,
  created_at timestamptz not null default now()
);
create index if not exists import_events_trail_idx on public.import_events (trail_id, created_at desc);
create index if not exists import_events_job_idx on public.import_events (job_id);

create or replace function public.import_touch() returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

do $$
declare
  t text;
begin
  foreach t in array array['trail_candidates', 'import_jobs', 'import_questions']
  loop
    execute format('drop trigger if exists %I on public.%I', t || '_touch', t);
    execute format(
      'create trigger %I before update on public.%I for each row execute function public.import_touch()',
      t || '_touch', t);
  end loop;
end $$;

-- Interner Helfer: Verlaufseintrag. Nur aus Trigger-Funktionen und RPCs.
create or replace function public.import_log_event(
  p_trail text, p_job uuid, p_typ text, p_feld text, p_daten jsonb
) returns void
language sql
security definer
set search_path = public
as $$
  insert into public.import_events (trail_id, job_id, typ, feld, daten, user_id)
  values (p_trail, p_job, p_typ, p_feld, coalesce(p_daten, '{}'::jsonb), auth.uid());
$$;
revoke all on function public.import_log_event(text, uuid, text, text, jsonb) from public, anon, authenticated;
grant execute on function public.import_log_event(text, uuid, text, text, jsonb) to service_role;

-- ---------------------------------------------------------------------
-- 4 · data_version: Meta-Spalten sind keine Inhaltsaenderung
-- ---------------------------------------------------------------------
-- sichtbar bleibt drin: false -> true ist ein neues Paket fuer die App.
create or replace function public.trails_bump_data_version()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_ignore text[] := array[
    'updated_at', 'data_version', 'start_pos',
    'field_meta', 'locked_fields', 'source_job_id', 'source_file_hash'
  ];
begin
  if new.data_version is not distinct from old.data_version
     and (to_jsonb(new) - v_ignore) is distinct from (to_jsonb(old) - v_ignore) then
    new.data_version := old.data_version + 1;
  end if;
  return new;
end;
$$;

-- ---------------------------------------------------------------------
-- 5 · Lock-Trigger
-- ---------------------------------------------------------------------
-- Wer im CMS (auth.uid() gesetzt) ein Feld eines importierten Trails aendert, sperrt es:
-- ein Re-Import ueberschreibt es nicht. service_role (Worker) sperrt nichts.
-- Der Worker setzt beim Anwenden eines Vorschlags zusaetzlich kalia.import_apply = 1.
-- Ausgenommen: sichtbar (Anlegen), Meta-Spalten, start_pos (generiert), arten (aus trail_species).
create or replace function public.trails_lock_fields()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_excluded text[] := array[
    'sichtbar', 'updated_at', 'data_version', 'locked_fields', 'field_meta',
    'source_job_id', 'source_file_hash', 'start_pos', 'arten'
  ];
  v_changed text[];
  v_feld text;
begin
  if auth.uid() is null
     or coalesce(current_setting('kalia.import_apply', true), '') = '1'
     or old.source_job_id is null then
    return new;
  end if;

  select coalesce(array_agg(n.key order by n.key), '{}')
    into v_changed
  from jsonb_each(to_jsonb(new)) n
  join jsonb_each(to_jsonb(old)) o on o.key = n.key
  where n.value is distinct from o.value
    and n.key <> all (v_excluded);

  if cardinality(v_changed) = 0 then
    return new;
  end if;

  new.locked_fields := array(
    select distinct x from unnest(coalesce(old.locked_fields, '{}') || v_changed) x order by x
  );

  v_feld := array_to_string(v_changed, ',');
  if not exists (
    select 1 from public.import_events e
    where e.trail_id = new.id and e.typ = 'aenderung' and e.feld = v_feld
      and e.user_id = auth.uid() and e.created_at > now() - interval '10 minutes'
  ) then
    insert into public.import_events (trail_id, job_id, typ, feld, daten, user_id)
    values (new.id, old.source_job_id, 'aenderung', v_feld, '{}'::jsonb, auth.uid());
  end if;
  return new;
end;
$$;
revoke all on function public.trails_lock_fields() from public, anon, authenticated;

drop trigger if exists trails_lock_fields on public.trails;
create trigger trails_lock_fields
  before update on public.trails
  for each row execute function public.trails_lock_fields();

-- Bloecke: stations -> 'stationen', trail_species -> 'arten', offizielle images -> 'bilder'.
create or replace function public.import_lock_block()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_trail text;
  v_block text;
  v_row jsonb;
begin
  if auth.uid() is null or coalesce(current_setting('kalia.import_apply', true), '') = '1' then
    return coalesce(new, old);
  end if;

  v_row := to_jsonb(coalesce(new, old));
  v_trail := v_row ->> 'trail_id';
  v_block := case tg_table_name
    when 'stations' then 'stationen'
    when 'trail_species' then 'arten'
    when 'images' then 'bilder'
  end;

  if tg_table_name = 'images' and (v_row ->> 'source') is distinct from 'official' then
    return coalesce(new, old);
  end if;

  update public.trails
     set locked_fields = array(select distinct x from unnest(locked_fields || v_block) x order by x)
   where id = v_trail
     and source_job_id is not null
     and not (v_block = any (locked_fields));

  return coalesce(new, old);
end;
$$;
revoke all on function public.import_lock_block() from public, anon, authenticated;

do $$
declare
  t text;
begin
  foreach t in array array['stations', 'trail_species', 'images']
  loop
    execute format('drop trigger if exists %I on public.%I', t || '_import_lock', t);
    execute format(
      'create trigger %I after insert or update or delete on public.%I '
      'for each row execute function public.import_lock_block()', t || '_import_lock', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 6 · RLS
-- ---------------------------------------------------------------------
do $$
declare
  t text;
begin
  foreach t in array array[
    'trail_candidates', 'import_batches', 'import_jobs', 'species_suggestions',
    'trail_sources', 'import_questions', 'import_events'
  ]
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
    execute format('grant select on public.%I to authenticated', t);
    execute format('drop policy if exists %I on public.%I', t || ' admin read', t);
    execute format(
      'create policy %I on public.%I for select to authenticated using (public.is_admin())',
      t || ' admin read', t);
  end loop;
end $$;

-- Sequenzen fuer service_role (bigserial)
grant usage, select on all sequences in schema public to service_role;

-- ---------------------------------------------------------------------
-- 7 · images: Bilder unsichtbarer Trails nicht lesbar
-- ---------------------------------------------------------------------
drop policy if exists "images public read approved" on public.images;
create policy "images public read approved" on public.images
  for select to anon
  using (status = 'approved' and public.trail_is_visible(trail_id));

drop policy if exists "images read authenticated" on public.images;
create policy "images read authenticated" on public.images
  for select to authenticated
  using (
    (status = 'approved' and public.trail_is_visible(trail_id))
    or uploader_id = auth.uid()
    or public.is_admin()
  );

-- ---------------------------------------------------------------------
-- 8 · Queue
-- ---------------------------------------------------------------------
create or replace function public.claim_import_job(p_worker text, p_timeout_seconds integer default 900)
returns setof public.import_jobs
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  select j.id into v_id
  from public.import_jobs j
  left join public.import_batches b on b.id = j.batch_id
  where (
      (j.status = 'wartet' and j.next_run_at <= now())
      or (j.status = 'laeuft' and j.locked_at < now() - make_interval(secs => p_timeout_seconds))
    )
    and coalesce(b.status, 'laeuft') = 'laeuft'
  order by j.priority desc, j.created_at
  limit 1
  for update of j skip locked;

  if v_id is null then
    return;
  end if;

  return query
  update public.import_jobs
     set status = 'laeuft', locked_at = now(), locked_by = p_worker,
         attempts = attempts + 1, updated_at = now()
   where id = v_id
  returning *;
end;
$$;
revoke all on function public.claim_import_job(text, integer) from public, anon, authenticated;
grant execute on function public.claim_import_job(text, integer) to service_role;

-- ---------------------------------------------------------------------
-- 9 · Duplikat-Suche
-- ---------------------------------------------------------------------
-- 'nah'      = Start naeher als p_nah_m (egal wie der Name klingt)
-- 'moeglich' = Namens-Aehnlichkeit >= p_trigram und Start naeher als p_moeglich_m
create or replace function public.find_trail_duplicates(
  p_slug text,
  p_name text,
  p_lat double precision,
  p_lon double precision,
  p_nah_m integer default 150,
  p_moeglich_m integer default 500,
  p_trigram real default 0.6
) returns table (id text, name text, distanz_m double precision, aehnlichkeit real, art text)
language sql
stable
security definer
set search_path = public, extensions
as $$
  with kandidaten as (
    select t.id, t.name,
           ST_Distance(t.start_pos, ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326)::geography) as dist,
           similarity(lower(t.name), lower(p_name)) as sim
    from public.trails t
    where t.id is distinct from p_slug
      and t.start_pos is not null
      and ST_DWithin(t.start_pos, ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326)::geography,
                     greatest(p_nah_m, p_moeglich_m))
  )
  select k.id, k.name, k.dist, k.sim::real,
         case when k.dist < p_nah_m then 'nah' else 'moeglich' end
  from kandidaten k
  where k.dist < p_nah_m or (k.sim >= p_trigram and k.dist < p_moeglich_m)
  order by k.dist;
$$;
revoke all on function public.find_trail_duplicates(text, text, double precision, double precision, integer, integer, real)
  from public, anon, authenticated;
grant execute on function public.find_trail_duplicates(text, text, double precision, double precision, integer, integer, real)
  to service_role;

-- ---------------------------------------------------------------------
-- 10 · RPCs fuer das CMS
-- ---------------------------------------------------------------------
-- Wer darf? Katalog-Editor (CMS) oder service_role (Worker/CLI).
create or replace function public.import_guard() returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not (public.is_catalog_editor() or coalesce(auth.role(), '') = 'service_role') then
    raise exception 'forbidden' using errcode = '42501';
  end if;
end;
$$;
revoke all on function public.import_guard() from public, anon, authenticated;
grant execute on function public.import_guard() to authenticated, service_role;

-- Offene Hart-/Uebersteuerbar-Meldungen eines Reports zaehlen.
-- Meldung: {code, severity, feld, status, override: {reason, by, at}}
create or replace function public.import_open_blockers(p_report jsonb)
returns table (hart integer, uebersteuerbar integer)
language sql
immutable
as $$
  select
    count(*) filter (where e ->> 'severity' = 'hart'
                       and coalesce(e ->> 'status', 'offen') = 'offen')::integer,
    count(*) filter (where e ->> 'severity' = 'uebersteuerbar'
                       and coalesce(e ->> 'status', 'offen') = 'offen'
                       and coalesce(e -> 'override' ->> 'reason', '') = '')::integer
  from jsonb_array_elements(coalesce(p_report, '[]'::jsonb)) e;
$$;

create or replace function public.import_batch_create(p_name text default '')
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  perform public.import_guard();
  insert into public.import_batches (name, created_by) values (coalesce(p_name, ''), auth.uid())
  returning id into v_id;
  return v_id;
end;
$$;

-- Vorabpruefung fuer die Dropzone: [{name, hash}] -> [{name, hash, status, job_id, trail_id}]
-- status: neu | bereits_importiert | update (Dateiname-Stem ist ein bekannter Slug)
create or replace function public.import_precheck(p_files jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_out jsonb := '[]'::jsonb;
  f jsonb;
  j public.import_jobs;
  v_stem text;
begin
  perform public.import_guard();
  for f in select * from jsonb_array_elements(coalesce(p_files, '[]'::jsonb))
  loop
    select * into j from public.import_jobs where file_hash = f ->> 'hash';
    if found then
      v_out := v_out || jsonb_build_object(
        'name', f ->> 'name', 'hash', f ->> 'hash', 'status', 'bereits_importiert',
        'job_id', j.id, 'trail_id', j.trail_id);
      continue;
    end if;
    v_stem := lower(regexp_replace(f ->> 'name', '\.zip$', '', 'i'));
    if exists (select 1 from public.trails where id = v_stem) then
      v_out := v_out || jsonb_build_object(
        'name', f ->> 'name', 'hash', f ->> 'hash', 'status', 'update', 'trail_id', v_stem);
    else
      v_out := v_out || jsonb_build_object('name', f ->> 'name', 'hash', f ->> 'hash', 'status', 'neu');
    end if;
  end loop;
  return v_out;
end;
$$;

-- Job anlegen, nachdem das ZIP im Bucket imports liegt. Gleicher Hash = vorhandener Job.
create or replace function public.import_enqueue(
  p_file_name text,
  p_file_hash text,
  p_storage_path text,
  p_batch uuid default null,
  p_priority integer default 0
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  j public.import_jobs;
begin
  perform public.import_guard();
  select * into j from public.import_jobs where file_hash = p_file_hash;
  if found then
    return jsonb_build_object('status', 'bereits_importiert', 'job_id', j.id, 'trail_id', j.trail_id);
  end if;
  insert into public.import_jobs (batch_id, file_name, file_hash, storage_path, priority, created_by)
  values (p_batch, p_file_name, p_file_hash, p_storage_path, coalesce(p_priority, 0), auth.uid())
  returning * into j;
  perform public.import_log_event(null, j.id, 'import', null,
    jsonb_build_object('datei', p_file_name, 'hash', p_file_hash));
  return jsonb_build_object('status', 'neu', 'job_id', j.id);
end;
$$;

create or replace function public.import_publish(p_job uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  j public.import_jobs;
  b record;
  v_next uuid;
begin
  perform public.import_guard();
  select * into j from public.import_jobs where id = p_job for update;
  if not found then
    raise exception 'job_not_found' using errcode = 'P0002';
  end if;
  if j.status not in ('bereit', 'wartet_auf_klaerung') or j.trail_id is null then
    raise exception 'job_not_publishable: %', j.status using errcode = 'P0001';
  end if;

  select * into b from public.import_open_blockers(j.report);
  if b.hart > 0 then
    raise exception 'import_blocked_hart' using errcode = 'P0001';
  end if;
  if b.uebersteuerbar > 0 then
    raise exception 'import_blocked_uebersteuerbar' using errcode = 'P0001';
  end if;

  update public.trails set sichtbar = true where id = j.trail_id;
  update public.import_jobs set status = 'angelegt', finished_at = now() where id = p_job;
  update public.trail_candidates set status = 'freigegeben' where id = j.trail_id;
  perform public.import_log_event(j.trail_id, p_job, 'angelegt', null, '{}'::jsonb);

  select id into v_next from public.import_jobs
   where status = 'bereit' and id <> p_job
   order by priority desc, created_at limit 1;
  return jsonb_build_object('trail_id', j.trail_id, 'next_job_id', v_next);
end;
$$;

-- Rueckgaengig (10-s-Fenster im CMS) und "Unsichtbar schalten" fuer Importe.
create or replace function public.import_unpublish(p_job uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  j public.import_jobs;
begin
  perform public.import_guard();
  select * into j from public.import_jobs where id = p_job for update;
  if not found or j.status <> 'angelegt' then
    raise exception 'job_not_published' using errcode = 'P0001';
  end if;
  update public.trails set sichtbar = false where id = j.trail_id;
  update public.import_jobs set status = 'bereit', finished_at = null where id = p_job;
  update public.trail_candidates set status = 'entwurf' where id = j.trail_id;
  perform public.import_log_event(j.trail_id, p_job, 'rueckgaengig', null, '{}'::jsonb);
end;
$$;

create or replace function public.import_discard(p_job uuid, p_grund text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  j public.import_jobs;
begin
  perform public.import_guard();
  if coalesce(btrim(p_grund), '') = '' then
    raise exception 'grund_fehlt' using errcode = 'P0001';
  end if;
  select * into j from public.import_jobs where id = p_job for update;
  if not found then
    raise exception 'job_not_found' using errcode = 'P0002';
  end if;
  if j.trail_id is not null then
    update public.trails set sichtbar = false where id = j.trail_id;
    update public.trail_candidates
       set status = 'verworfen', verworfen_grund = p_grund where id = j.trail_id;
  end if;
  update public.import_jobs set status = 'verworfen', finished_at = now() where id = p_job;
  perform public.import_log_event(j.trail_id, p_job, 'verworfen', null,
    jsonb_build_object('grund', p_grund));
end;
$$;

-- Uebersteuerbare Meldung bewusst durchlassen (Begruendung Pflicht, wird protokolliert).
create or replace function public.import_override(
  p_job uuid, p_code text, p_feld text, p_grund text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  j public.import_jobs;
  v_new jsonb;
  v_hit integer;
begin
  perform public.import_guard();
  if coalesce(btrim(p_grund), '') = '' then
    raise exception 'grund_fehlt' using errcode = 'P0001';
  end if;
  select * into j from public.import_jobs where id = p_job for update;
  if not found then
    raise exception 'job_not_found' using errcode = 'P0002';
  end if;

  select count(*) into v_hit
  from jsonb_array_elements(j.report) e
  where e ->> 'code' = p_code and coalesce(e ->> 'feld', '') = coalesce(p_feld, '')
    and e ->> 'severity' = 'uebersteuerbar';
  if v_hit = 0 then
    raise exception 'nicht_uebersteuerbar' using errcode = 'P0001';
  end if;

  select coalesce(jsonb_agg(
    case
      when e ->> 'code' = p_code and coalesce(e ->> 'feld', '') = coalesce(p_feld, '')
           and e ->> 'severity' = 'uebersteuerbar'
      then e || jsonb_build_object('override', jsonb_build_object(
             'reason', p_grund, 'by', auth.uid(), 'at', now()))
      else e
    end order by ord), '[]'::jsonb)
  into v_new
  from jsonb_array_elements(j.report) with ordinality as t(e, ord);

  update public.import_jobs set report = v_new where id = p_job;
  perform public.import_log_event(j.trail_id, p_job, 'uebersteuert', p_feld,
    jsonb_build_object('code', p_code, 'grund', p_grund));
  return v_new;
end;
$$;

create or replace function public.import_retry(p_job uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.import_guard();
  update public.import_jobs
     set status = 'wartet', modus = 'import', attempts = 0, next_run_at = now(),
         error = null, error_detail = null, locked_at = null, locked_by = null
   where id = p_job and status in ('fehlgeschlagen', 'bereit', 'wartet_auf_klaerung');
  if not found then
    raise exception 'job_not_retryable' using errcode = 'P0001';
  end if;
  perform public.import_log_event(null, p_job, 'neu_gestartet', null, '{}'::jsonb);
end;
$$;

-- Regeln auf dem aktuellen DB-Stand des Entwurfs neu rechnen (nach Aenderungen im CMS).
create or replace function public.import_revalidate(p_job uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.import_guard();
  update public.import_jobs
     set status = 'wartet', modus = 'validate', attempts = 0, next_run_at = now(),
         locked_at = null, locked_by = null
   where id = p_job and status in ('bereit', 'wartet_auf_klaerung')
     and trail_id is not null;
end;
$$;

-- Neue Datei fuer einen Job ("Datei ersetzen"). Hash und Pfad neu, Lauf von vorn.
create or replace function public.import_replace_file(
  p_job uuid, p_file_name text, p_file_hash text, p_storage_path text
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.import_guard();
  update public.import_jobs
     set file_name = p_file_name, file_hash = p_file_hash, storage_path = p_storage_path,
         status = 'wartet', modus = 'import', attempts = 0, next_run_at = now(),
         error = null, error_detail = null, locked_at = null, locked_by = null
   where id = p_job and status in ('fehlgeschlagen', 'bereit', 'wartet_auf_klaerung');
  if not found then
    raise exception 'job_not_replaceable' using errcode = 'P0001';
  end if;
  perform public.import_log_event(null, p_job, 'datei_ersetzt', null,
    jsonb_build_object('datei', p_file_name));
end;
$$;

create or replace function public.import_pause_batch(p_batch uuid, p_pause boolean default true)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.import_guard();
  update public.import_batches
     set status = case when p_pause then 'pausiert' else 'laeuft' end
   where id = p_batch and status <> 'fertig';
end;
$$;

-- Angenommene Teile eines Re-Import-Vorschlags: Worker schreibt sie (service_role, keine Sperre).
-- p_teile: Spaltennamen oder Bloecke (stationen, arten, bilder). null = alles.
create or replace function public.import_apply_proposal(p_job uuid, p_teile text[] default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  j public.import_jobs;
begin
  perform public.import_guard();
  select * into j from public.import_jobs where id = p_job for update;
  if not found or j.status <> 'vorschlag' or j.proposal is null then
    raise exception 'kein_vorschlag' using errcode = 'P0001';
  end if;
  update public.import_jobs
     set proposal = proposal || jsonb_build_object('accepted', to_jsonb(p_teile)),
         modus = 'apply', status = 'wartet', attempts = 0, next_run_at = now()
   where id = p_job;
  perform public.import_log_event(j.trail_id, p_job, 'vorschlag_angenommen', null,
    jsonb_build_object('teile', to_jsonb(p_teile)));
end;
$$;

-- Vorschlag verwerfen: Entwurf/Live bleibt unveraendert.
create or replace function public.import_reject_proposal(p_job uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  j public.import_jobs;
begin
  perform public.import_guard();
  select * into j from public.import_jobs where id = p_job for update;
  if not found or j.status <> 'vorschlag' then
    raise exception 'kein_vorschlag' using errcode = 'P0001';
  end if;
  update public.import_jobs set status = 'verworfen', finished_at = now() where id = p_job;
  perform public.import_log_event(j.trail_id, p_job, 'vorschlag_abgelehnt', null, '{}'::jsonb);
end;
$$;

-- Klaeren: Frage anlegen, Job parkt in "wartet_auf_klaerung".
create or replace function public.import_ask(
  p_job uuid, p_field text, p_frage text, p_adressat text, p_person uuid default null
) returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  j public.import_jobs;
  v_id bigint;
begin
  perform public.import_guard();
  if coalesce(btrim(p_frage), '') = '' then
    raise exception 'frage_fehlt' using errcode = 'P0001';
  end if;
  select * into j from public.import_jobs where id = p_job for update;
  if not found or j.trail_id is null then
    raise exception 'job_not_found' using errcode = 'P0002';
  end if;
  insert into public.import_questions (job_id, trail_id, field, frage, adressat, person_id, created_by)
  values (p_job, j.trail_id, nullif(p_field, ''), p_frage, p_adressat, p_person, auth.uid())
  returning id into v_id;
  if j.status = 'bereit' then
    update public.import_jobs set status = 'wartet_auf_klaerung' where id = p_job;
  end if;
  perform public.import_log_event(j.trail_id, p_job, 'frage', p_field,
    jsonb_build_object('frage', p_frage, 'adressat', p_adressat, 'person', p_person));
  return v_id;
end;
$$;

-- Frage beantworten / erledigen. Sind alle erledigt, kehrt der Job nach "bereit" zurueck.
create or replace function public.import_question_set(
  p_question bigint, p_status text, p_antwort text default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  q public.import_questions;
begin
  perform public.import_guard();
  if p_status not in ('offen', 'beantwortet', 'erledigt') then
    raise exception 'status_ungueltig' using errcode = 'P0001';
  end if;
  update public.import_questions
     set status = p_status,
         antwort = coalesce(p_antwort, antwort),
         answered_at = case when p_status = 'offen' then null else coalesce(answered_at, now()) end
   where id = p_question
  returning * into q;
  if not found then
    raise exception 'frage_nicht_gefunden' using errcode = 'P0002';
  end if;
  perform public.import_log_event(q.trail_id, q.job_id, 'antwort', q.field,
    jsonb_build_object('status', p_status, 'antwort', p_antwort));
  if q.job_id is not null and not exists (
    select 1 from public.import_questions
    where job_id = q.job_id and status = 'offen'
  ) then
    update public.import_jobs set status = 'bereit'
     where id = q.job_id and status = 'wartet_auf_klaerung';
  end if;
end;
$$;

-- Auswertung je Batch: welche Meldung bei wie vielen Pfaden.
create or replace function public.import_batch_stats(p_batch uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_total integer;
  v_codes jsonb;
begin
  perform public.import_guard();
  select count(*) into v_total from public.import_jobs where batch_id = p_batch;
  select coalesce(jsonb_agg(jsonb_build_object(
           'code', code, 'severity', severity, 'pfade', pfade,
           'prozent', case when v_total = 0 then 0 else round(100.0 * pfade / v_total, 1) end
         ) order by pfade desc, code), '[]'::jsonb)
    into v_codes
  from (
    select e ->> 'code' as code, max(e ->> 'severity') as severity, count(distinct j.id) as pfade
    from public.import_jobs j, jsonb_array_elements(j.report) e
    where j.batch_id = p_batch
    group by e ->> 'code'
  ) s;
  return jsonb_build_object(
    'jobs', v_total,
    'fehlgeschlagen', (select count(*) from public.import_jobs where batch_id = p_batch and status = 'fehlgeschlagen'),
    'bereit', (select count(*) from public.import_jobs where batch_id = p_batch and status = 'bereit'),
    'angelegt', (select count(*) from public.import_jobs where batch_id = p_batch and status = 'angelegt'),
    'meldungen', v_codes
  );
end;
$$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'import_batch_create(text)', 'import_precheck(jsonb)',
    'import_enqueue(text, text, text, uuid, integer)', 'import_publish(uuid)',
    'import_unpublish(uuid)', 'import_discard(uuid, text)',
    'import_override(uuid, text, text, text)', 'import_retry(uuid)',
    'import_revalidate(uuid)', 'import_replace_file(uuid, text, text, text)',
    'import_pause_batch(uuid, boolean)', 'import_apply_proposal(uuid, text[])',
    'import_reject_proposal(uuid)', 'import_ask(uuid, text, text, text, uuid)',
    'import_question_set(bigint, text, text)', 'import_batch_stats(uuid)'
  ]
  loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated, service_role', f);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 11 · Storage: privater Bucket imports
-- ---------------------------------------------------------------------
-- Originale (ZIP). Nur Katalog-Editoren laden hoch und lesen; der Worker nutzt service_role.
insert into storage.buckets (id, name, public)
values ('imports', 'imports', false)
on conflict (id) do nothing;

drop policy if exists "imports editor insert" on storage.objects;
create policy "imports editor insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'imports' and public.is_catalog_editor());

drop policy if exists "imports editor read" on storage.objects;
create policy "imports editor read" on storage.objects
  for select to authenticated
  using (bucket_id = 'imports' and public.is_catalog_editor());

-- Die Review-Oberflaeche zeigt Entwurfs-Bilder aus dem oeffentlichen Bucket trail-images.
-- Ein Editor darf dort auch Offiziell-Bilder des Imports ersetzen (siehe 0030).

-- ---------------------------------------------------------------------
-- 12 · Realtime
-- ---------------------------------------------------------------------
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'import_jobs'
     ) then
    alter publication supabase_realtime add table public.import_jobs;
  end if;
end $$;
