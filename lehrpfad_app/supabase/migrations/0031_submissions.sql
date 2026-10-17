-- 0031_submissions.sql – Pfad melden und aufnehmen (Spec "Pfad melden & aufnehmen")
-- Beitraege (neuer Pfad, Neuaufnahme, Schnellmeldung) kommen ueber die RPC
-- create_submission. Der Katalog aendert sich nur ueber apply_submission
-- (Admin + MFA). Nutzer lesen nur eigene Beitraege.
--
-- Rollenmodell: profiles.role = 'admin' (is_admin) liest und entscheidet,
-- is_catalog_editor (admin + aal2) wendet an.
--
-- target_point_id (Text): 'station:<id>' | 'amenity:<id>' | 'trail:<id>'
-- (Ort = Startpunkt des Eintrags).

-- ---------------------------------------------------------------------
-- Katalog: Sichtbarkeit und data_version
-- ---------------------------------------------------------------------
alter table public.trails
  add column if not exists sichtbar boolean not null default true,
  add column if not exists data_version integer not null default 1;

-- Neue Pfade aus Beitraegen sind erst nach Moderation sichtbar.
-- stations/amenities bleiben lesbar (Zeilen haengen an der unsichtbaren
-- Trail-ID, ohne Trail nicht erreichbar).
drop policy if exists "trails public read" on public.trails;
create policy "trails public read" on public.trails
  for select to anon, authenticated
  using (sichtbar or public.is_admin());

-- Hinweise (gesperrt, gefaehrlich, ...) aus uebernommenen Meldungen
create table if not exists public.trail_hints (
  id uuid primary key default gen_random_uuid(),
  trail_id text not null references public.trails (id) on delete cascade,
  kind text not null
    check (kind in ('closed', 'danger', 'stairsRoots', 'viewpoint', 'facility', 'other')),
  note text not null default '',
  lat double precision not null,
  lon double precision not null,
  pos geometry(Point, 4326)
    generated always as (ST_SetSRID(ST_MakePoint(lon, lat), 4326)) stored,
  created_at timestamptz not null default now(),
  -- closed/danger laufen nach 60 Tagen ab [TODO: bestaetigen]
  expires_at timestamptz
);
create index if not exists trail_hints_trail_idx on public.trail_hints (trail_id);
create index if not exists trail_hints_pos_idx on public.trail_hints using gist (pos);

alter table public.trail_hints enable row level security;
create policy "trail_hints public read" on public.trail_hints
  for select to anon, authenticated
  using (expires_at is null or expires_at > now());
create policy "trail_hints editor all" on public.trail_hints
  for all to authenticated
  using (public.is_catalog_editor()) with check (public.is_catalog_editor());

-- Moderatoren koennen ein Konto sperren (RPC antwortet wie bei Limit)
alter table public.profiles
  add column if not exists submissions_blocked boolean not null default false;

-- ---------------------------------------------------------------------
-- Tabellen
-- ---------------------------------------------------------------------
create table public.submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete set null,
  client_submission_id uuid not null,
  kind text not null check (kind in ('new_trail', 'revision', 'quick')),
  target_trail_id text references public.trails (id) on delete set null,
  intent text check (intent in ('move_point', 'add_point', 'hint', 'other')),
  status text not null default 'submitted'
    check (status in (
      'submitted', 'in_review', 'needs_info', 'approved',
      'partially_approved', 'rejected', 'withdrawn'
    )),
  title text,
  area text check (area in ('wald', 'heide', 'moor', 'kueste', 'wasser', 'spreewald', 'hof')),
  is_loop boolean,
  stroller text check (stroller in ('yes', 'no', 'unknown')),
  note text,
  track geography(MultiLineString, 4326),
  track_length_m double precision,
  track_point_count integer not null default 0,
  presence_ok boolean not null default true,
  client_created_at timestamptz,
  possible_duplicate_trail_id text,
  consensus_group_id uuid,
  photos_expected integer not null default 0,
  submitted_at timestamptz not null default now(),
  decided_at timestamptz,
  decided_by uuid references auth.users (id) on delete set null,
  decision_reason_code text
    check (decision_reason_code in (
      'duplicate', 'within_gps_noise', 'not_family_suitable', 'not_public',
      'insufficient_data', 'wrong_location', 'other'
    )),
  decision_note text,
  published_at timestamptz,
  app_version text,
  platform text,
  unique (user_id, client_submission_id)
);
create index submissions_status_idx on public.submissions (status, submitted_at);
create index submissions_user_idx on public.submissions (user_id, submitted_at desc);
create index submissions_trail_idx on public.submissions (target_trail_id);
create index submissions_consensus_idx on public.submissions (consensus_group_id)
  where consensus_group_id is not null;
create index submissions_track_idx on public.submissions using gist (track);

create table public.submission_points (
  id uuid primary key,
  submission_id uuid not null references public.submissions (id) on delete cascade,
  type text not null
    check (type in ('start', 'parking', 'station', 'waypoint', 'hint', 'end')),
  intent text check (intent in ('move_point', 'add_point', 'hint', 'other')),
  target_point_id text,
  seq integer not null,
  number integer,
  title text,
  hint_kind text
    check (hint_kind in ('closed', 'danger', 'stairsRoots', 'viewpoint', 'facility', 'other')),
  location geography(Point, 4326) not null,
  accuracy_m double precision not null default 0,
  fix_count integer not null default 1,
  low_accuracy boolean not null default false,
  recorded_on date,
  note text,
  deviation_m double precision,
  deviation_class text check (deviation_class in ('noise', 'borderline', 'candidate')),
  presence_ok boolean not null default true
);
create index submission_points_sub_idx on public.submission_points (submission_id);
create index submission_points_target_idx on public.submission_points (target_point_id)
  where target_point_id is not null;
create index submission_points_location_idx on public.submission_points using gist (location);

create table public.submission_photos (
  id uuid primary key,
  submission_id uuid not null references public.submissions (id) on delete cascade,
  point_id uuid references public.submission_points (id) on delete cascade,
  storage_path text not null,
  width integer,
  height integer,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected'))
);
create index submission_photos_sub_idx on public.submission_photos (submission_id);

create table public.submission_events (
  id bigint generated always as identity primary key,
  submission_id uuid not null references public.submissions (id) on delete cascade,
  actor_id uuid references auth.users (id) on delete set null,
  event text not null,
  payload jsonb not null default '{}'::jsonb,
  -- false = interne Moderatoren-Notiz, Nutzer sieht sie nicht
  visible_to_user boolean not null default true,
  created_at timestamptz not null default now()
);
create index submission_events_sub_idx on public.submission_events (submission_id, created_at);

create table public.trail_revisions (
  id uuid primary key default gen_random_uuid(),
  trail_id text not null,
  submission_id uuid references public.submissions (id) on delete set null,
  snapshot jsonb not null,
  created_at timestamptz not null default now()
);
create index trail_revisions_trail_idx on public.trail_revisions (trail_id, created_at desc);

-- ---------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------
alter table public.submissions enable row level security;
alter table public.submission_points enable row level security;
alter table public.submission_photos enable row level security;
alter table public.submission_events enable row level security;
alter table public.trail_revisions enable row level security;

create policy "submissions read own or admin" on public.submissions
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

create policy "submissions admin update" on public.submissions
  for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "submission_points read" on public.submission_points
  for select to authenticated
  using (
    public.is_admin()
    or exists (
      select 1 from public.submissions s
      where s.id = submission_id and s.user_id = auth.uid()
    )
  );

create policy "submission_points admin update" on public.submission_points
  for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "submission_photos read" on public.submission_photos
  for select to authenticated
  using (
    public.is_admin()
    or exists (
      select 1 from public.submissions s
      where s.id = submission_id and s.user_id = auth.uid()
    )
  );

create policy "submission_photos admin update" on public.submission_photos
  for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "submission_events read" on public.submission_events
  for select to authenticated
  using (
    public.is_admin()
    or (
      visible_to_user
      and exists (
        select 1 from public.submissions s
        where s.id = submission_id and s.user_id = auth.uid()
      )
    )
  );

create policy "submission_events admin insert" on public.submission_events
  for insert to authenticated
  with check (public.is_admin());

create policy "trail_revisions admin read" on public.trail_revisions
  for select to authenticated using (public.is_admin());

-- Nutzer schreiben nie direkt: nur ueber die RPCs unten.
revoke insert, update, delete on public.submissions from anon, authenticated;
revoke insert, update, delete on public.submission_points from anon, authenticated;
revoke insert, update, delete on public.submission_photos from anon, authenticated;
revoke insert, update, delete on public.submission_events from anon, authenticated;
revoke insert, update, delete on public.trail_revisions from anon, authenticated;
revoke all on public.submissions, public.submission_points,
  public.submission_photos, public.submission_events,
  public.trail_revisions from anon;
grant update on public.submissions, public.submission_points,
  public.submission_photos to authenticated;
grant insert on public.submission_events to authenticated;

-- ---------------------------------------------------------------------
-- Storage: privater Bucket, Pfad user_id/submission_id/photo_id.jpg
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('submission-photos', 'submission-photos', false)
on conflict (id) do nothing;

create policy "submission-photos insert own prefix" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'submission-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "submission-photos update own prefix" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'submission-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'submission-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "submission-photos read own or admin" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'submission-photos'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin())
  );

-- ---------------------------------------------------------------------
-- Hilfsfunktionen
-- ---------------------------------------------------------------------

-- Ort eines Katalog-Ziels. 'station:12', 'amenity:5', 'trail:<id>'.
create or replace function public.catalog_point_geog(target text)
returns geography as $$
  select case split_part(target, ':', 1)
    when 'station' then (
      select pos::geography from public.stations
      where id = nullif(split_part(target, ':', 2), '')::bigint)
    when 'amenity' then (
      select pos::geography from public.amenities
      where id = nullif(split_part(target, ':', 2), '')::bigint)
    when 'trail' then (
      select start_pos::geography from public.trails
      where id = substr(target, 7))
    else null
  end;
$$ language sql stable security definer set search_path = public;

-- Verlauf eines Eintrags als Linie (route jsonb = [[lat, lon], ...]).
-- Flaechen ohne route fallen auf den Startpunkt zurueck.
create or replace function public.trail_route_geog(p_trail_id text)
returns geography as $$
  select coalesce(
    (
      select ST_MakeLine(
               ST_SetSRID(ST_MakePoint((pt ->> 1)::float8, (pt ->> 0)::float8), 4326)
               order by ord
             )::geography
      from public.trails t,
           jsonb_array_elements(t.route) with ordinality as r(pt, ord)
      where t.id = p_trail_id
      having count(*) >= 2
    ),
    (select start_pos::geography from public.trails where id = p_trail_id)
  );
$$ language sql stable security definer set search_path = public;

create or replace function public.submission_error(code text)
returns void as $$
begin
  raise exception '%', code using errcode = 'P0001';
end;
$$ language plpgsql immutable;

-- ---------------------------------------------------------------------
-- create_submission(payload jsonb) -> submission_id
-- Idempotent ueber client_submission_id. Fehler (message): limit_open,
-- limit_daily, invalid_payload, too_large.
-- ---------------------------------------------------------------------
create or replace function public.create_submission(payload jsonb)
returns uuid as $$
declare
  uid uuid := auth.uid();
  csid uuid;
  existing uuid;
  v_kind text;
  v_target text;
  v_area text;
  v_title text;
  v_track geography;
  v_track_len double precision;
  v_track_pts integer := 0;
  v_points jsonb := coalesce(payload -> 'points', '[]'::jsonb);
  v_npoints integer;
  v_photos integer := coalesce((payload ->> 'photos_expected')::integer, 0);
  v_sub uuid;
  v_dup text;
  v_start geography;
  v_presence boolean := true;
  p jsonb;
  v_loc geography;
  v_target_pt text;
  v_target_geog geography;
  v_dev double precision;
  v_class text;
  v_pp boolean;
  v_group uuid;
begin
  if uid is null then
    raise exception 'unauthorized' using errcode = '28000';
  end if;
  if exists (select 1 from public.profiles where id = uid and submissions_blocked) then
    perform public.submission_error('limit_open');
  end if;

  begin
    csid := (payload ->> 'client_submission_id')::uuid;
  exception when others then
    perform public.submission_error('invalid_payload');
  end;
  if csid is null then
    perform public.submission_error('invalid_payload');
  end if;

  select id into existing from public.submissions
  where user_id = uid and client_submission_id = csid;
  if existing is not null then
    return existing;
  end if;

  if (select count(*) from public.submissions
      where user_id = uid and status in ('submitted', 'in_review', 'needs_info')) >= 5 then
    perform public.submission_error('limit_open');
  end if;
  if (select count(*) from public.submissions
      where user_id = uid and submitted_at > now() - interval '1 day') >= 10 then
    perform public.submission_error('limit_daily');
  end if;

  v_kind := payload ->> 'kind';
  v_target := nullif(payload ->> 'target_trail_id', '');
  v_area := nullif(payload ->> 'area', '');
  v_title := nullif(btrim(coalesce(payload ->> 'title', '')), '');
  if v_kind not in ('new_trail', 'revision', 'quick') then
    perform public.submission_error('invalid_payload');
  end if;
  if v_kind in ('revision', 'quick') and (
       v_target is null
       or not exists (select 1 from public.trails where id = v_target)
     ) then
    perform public.submission_error('invalid_payload');
  end if;
  if v_kind = 'new_trail' and (
       v_title is null or char_length(v_title) < 3 or char_length(v_title) > 80
       or v_area is null
     ) then
    perform public.submission_error('invalid_payload');
  end if;
  if jsonb_typeof(v_points) <> 'array' then
    perform public.submission_error('invalid_payload');
  end if;

  v_npoints := jsonb_array_length(v_points);
  if v_npoints > 60 or v_photos > 20 then
    perform public.submission_error('too_large');
  end if;

  -- Track: segments = [[[lng, lat, acc], ...], ...]
  select count(*) into v_track_pts
  from jsonb_array_elements(coalesce(payload -> 'track' -> 'segments', '[]'::jsonb)) s(seg),
       jsonb_array_elements(s.seg) pt;
  if v_track_pts > 20000 then
    perform public.submission_error('too_large');
  end if;

  if v_track_pts >= 2 then
    select ST_Multi(ST_Collect(line))::geography into v_track
    from (
      select ST_MakeLine(
               ST_SetSRID(ST_MakePoint((pt ->> 0)::float8, (pt ->> 1)::float8), 4326)
               order by pord
             ) as line
      from jsonb_array_elements(payload -> 'track' -> 'segments')
             with ordinality as s(seg, sord),
           jsonb_array_elements(s.seg) with ordinality as q(pt, pord)
      group by sord
      having count(*) >= 2
    ) lines;
    v_track_len := case when v_track is null then null else ST_Length(v_track) end;
  end if;

  if v_kind <> 'quick' and v_npoints < 2
     and (v_track_len is null or v_track_len < 100) then
    perform public.submission_error('invalid_payload');
  end if;
  if v_kind = 'quick' and v_npoints <> 1 then
    perform public.submission_error('invalid_payload');
  end if;

  -- Dublette: Start eines neuen Pfads nahe einem bestehenden (150 m)
  if v_kind = 'new_trail' then
    select ST_SetSRID(ST_MakePoint((p0 ->> 'lng')::float8, (p0 ->> 'lat')::float8), 4326)::geography
      into v_start
    from jsonb_array_elements(v_points) with ordinality as x(p0, o)
    order by (p0 ->> 'seq')::int nulls last, o
    limit 1;
    if v_start is not null then
      select t.id into v_dup from public.trails t
      where t.start_pos is not null
        and ST_DWithin(t.start_pos::geography, v_start, 150)
      order by ST_Distance(t.start_pos::geography, v_start)
      limit 1;
    end if;
  end if;

  insert into public.submissions (
    user_id, client_submission_id, kind, target_trail_id, intent, title, area,
    is_loop, stroller, note, track, track_length_m, track_point_count,
    client_created_at, possible_duplicate_trail_id, photos_expected,
    app_version, platform
  ) values (
    uid, csid, v_kind, v_target, nullif(payload ->> 'intent', ''), v_title, v_area,
    (payload ->> 'is_loop')::boolean, nullif(payload ->> 'stroller', ''),
    nullif(left(coalesce(payload ->> 'note', ''), 500), ''),
    v_track, v_track_len, v_track_pts,
    now(), v_dup, v_photos,
    left(payload ->> 'app_version', 32), left(payload ->> 'platform', 16)
  ) returning id into v_sub;

  for p in select * from jsonb_array_elements(v_points) loop
    v_loc := ST_SetSRID(ST_MakePoint((p ->> 'lng')::float8, (p ->> 'lat')::float8), 4326)::geography;
    v_target_pt := nullif(p ->> 'target_point_id', '');
    v_dev := null;
    v_class := null;
    v_pp := true;

    if v_target_pt is not null then
      v_target_geog := public.catalog_point_geog(v_target_pt);
      if v_target_geog is not null then
        v_dev := ST_Distance(v_loc, v_target_geog);
        v_class := case
          when v_dev < 20 then 'noise'
          when v_dev < 25 then 'borderline'
          else 'candidate' end;
        v_pp := ST_Distance(v_loc, v_target_geog) <= 500;
      end if;
    elsif v_kind = 'quick' then
      v_target_geog := public.trail_route_geog(v_target);
      if v_target_geog is not null then
        v_pp := ST_Distance(v_loc, v_target_geog) <= 500;
      end if;
    end if;
    if not v_pp then v_presence := false; end if;

    insert into public.submission_points (
      id, submission_id, type, intent, target_point_id, seq, number, title,
      hint_kind, location, accuracy_m, fix_count, low_accuracy, recorded_on,
      note, deviation_m, deviation_class, presence_ok
    ) values (
      (p ->> 'id')::uuid, v_sub, p ->> 'type', nullif(p ->> 'intent', ''),
      v_target_pt, coalesce((p ->> 'seq')::int, 0), (p ->> 'number')::int,
      nullif(left(coalesce(p ->> 'title', ''), 80), ''), nullif(p ->> 'hint_kind', ''),
      v_loc, coalesce((p ->> 'accuracy_m')::float8, 0),
      coalesce((p ->> 'fix_count')::int, 1),
      coalesce((p ->> 'low_accuracy')::boolean, false),
      (p ->> 'recorded_on')::date,
      nullif(left(coalesce(p ->> 'note', ''), 300), ''),
      v_dev, v_class, v_pp
    );

    -- Konsens: andere offene Meldung zum selben Punkt, anderer Nutzer, 25 m
    if v_target_pt is not null then
      select s2.consensus_group_id into v_group
      from public.submission_points p2
      join public.submissions s2 on s2.id = p2.submission_id
      where p2.target_point_id = v_target_pt
        and p2.submission_id <> v_sub
        and s2.user_id is distinct from uid
        and s2.status in ('submitted', 'in_review', 'needs_info')
        and ST_DWithin(p2.location, v_loc, 25)
      order by s2.submitted_at
      limit 1;
      if found then
        v_group := coalesce(v_group, gen_random_uuid());
        update public.submissions set consensus_group_id = v_group
        where id = v_sub
           or id in (
             select s3.id
             from public.submission_points p3
             join public.submissions s3 on s3.id = p3.submission_id
             where p3.target_point_id = v_target_pt
               and s3.user_id is distinct from uid
               and s3.status in ('submitted', 'in_review', 'needs_info')
               and ST_DWithin(p3.location, v_loc, 25)
           );
      end if;
    end if;
  end loop;

  update public.submissions set presence_ok = v_presence where id = v_sub;

  insert into public.submission_events (submission_id, actor_id, event, payload)
  values (v_sub, uid, 'submitted', jsonb_build_object('kind', v_kind));

  return v_sub;
end;
$$ language plpgsql security definer set search_path = public;

revoke all on function public.create_submission(jsonb) from public, anon;
grant execute on function public.create_submission(jsonb) to authenticated;

-- ---------------------------------------------------------------------
-- attach_photo
-- ---------------------------------------------------------------------
create or replace function public.attach_photo(
  p_submission_id uuid,
  p_point_id uuid,
  p_path text,
  p_width integer,
  p_height integer
) returns void as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'unauthorized' using errcode = '28000';
  end if;
  if not exists (
    select 1 from public.submissions where id = p_submission_id and user_id = uid
  ) then
    perform public.submission_error('invalid_payload');
  end if;
  if (storage.foldername(p_path))[1] is distinct from uid::text
     or (storage.foldername(p_path))[2] is distinct from p_submission_id::text then
    perform public.submission_error('invalid_payload');
  end if;
  if (select count(*) from public.submission_photos
      where submission_id = p_submission_id) >= 20 then
    perform public.submission_error('too_large');
  end if;
  if p_point_id is not null and not exists (
    select 1 from public.submission_points
    where id = p_point_id and submission_id = p_submission_id
  ) then
    perform public.submission_error('invalid_payload');
  end if;

  insert into public.submission_photos (id, submission_id, point_id, storage_path, width, height)
  values (
    coalesce(nullif(regexp_replace(p_path, '^.*/|\.jpg$', '', 'g'), '')::uuid, gen_random_uuid()),
    p_submission_id, p_point_id, p_path, p_width, p_height
  )
  on conflict (id) do nothing;
end;
$$ language plpgsql security definer set search_path = public;

revoke all on function public.attach_photo(uuid, uuid, text, integer, integer) from public, anon;
grant execute on function public.attach_photo(uuid, uuid, text, integer, integer) to authenticated;

-- ---------------------------------------------------------------------
-- withdraw_submission: nur aus 'submitted'
-- ---------------------------------------------------------------------
create or replace function public.withdraw_submission(p_submission_id uuid)
returns void as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'unauthorized' using errcode = '28000';
  end if;
  update public.submissions set status = 'withdrawn'
  where id = p_submission_id and user_id = uid and status = 'submitted';
  if not found then
    perform public.submission_error('invalid_payload');
  end if;
  insert into public.submission_events (submission_id, actor_id, event)
  values (p_submission_id, uid, 'withdrawn');
end;
$$ language plpgsql security definer set search_path = public;

revoke all on function public.withdraw_submission(uuid) from public, anon;
grant execute on function public.withdraw_submission(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- reply_submission: Antwort auf eine Rueckfrage (Status bleibt needs_info)
-- ---------------------------------------------------------------------
create or replace function public.reply_submission(p_submission_id uuid, p_text text)
returns void as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'unauthorized' using errcode = '28000';
  end if;
  if not exists (
    select 1 from public.submissions
    where id = p_submission_id and user_id = uid and status = 'needs_info'
  ) or coalesce(btrim(p_text), '') = '' then
    perform public.submission_error('invalid_payload');
  end if;
  insert into public.submission_events (submission_id, actor_id, event, payload)
  values (p_submission_id, uid, 'user_reply', jsonb_build_object('text', left(p_text, 500)));
end;
$$ language plpgsql security definer set search_path = public;

revoke all on function public.reply_submission(uuid, text) from public, anon;
grant execute on function public.reply_submission(uuid, text) to authenticated;

-- ---------------------------------------------------------------------
-- Beim Oeffnen durch Moderation: submitted -> in_review
-- ---------------------------------------------------------------------
create or replace function public.open_submission(p_submission_id uuid)
returns void as $$
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  update public.submissions set status = 'in_review'
  where id = p_submission_id and status = 'submitted';
  if found then
    insert into public.submission_events (submission_id, actor_id, event)
    values (p_submission_id, auth.uid(), 'in_review');
  end if;
end;
$$ language plpgsql security definer set search_path = public;

revoke all on function public.open_submission(uuid) from public, anon;
grant execute on function public.open_submission(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- apply_submission(submission_id, decisions jsonb)
--
-- decisions = {
--   "status": "approved" | "partially_approved" | "rejected" | "needs_info",
--   "reason_code": "...",            -- bei rejected
--   "note": "...",                   -- Notiz an den Nutzer
--   "question": "...",               -- bei needs_info
--   "consensus_mean": true | false,  -- Mittelwert der Konsens-Gruppe
--   "points": [ { "id": uuid, "accept": bool, "lat": f, "lng": f,
--                 "type": "...", "number": n, "title": "..." } ],
--   "track": { "segments": [[[lng, lat, acc], ...]] }   -- bearbeitet, optional
-- }
-- Schreibt zuerst trail_revisions, aendert dann den Katalog, erhoeht
-- data_version und setzt den Status.
-- ---------------------------------------------------------------------
create or replace function public.apply_submission(
  p_submission_id uuid,
  decisions jsonb
) returns void as $$
declare
  uid uuid := auth.uid();
  s public.submissions%rowtype;
  v_status text := decisions ->> 'status';
  v_trail text;
  v_snapshot jsonb;
  pt record;
  dj jsonb;
  v_lat double precision;
  v_lng double precision;
  v_geom geometry;
  v_route jsonb;
  v_len double precision;
  v_station bigint;
  v_num integer;
  v_slug text;
  v_base text;
  v_n integer := 0;
  v_typ text;
  v_group_mean record;
  v_applied integer := 0;
  v_hint_kind text;
  v_track geography;
begin
  if not public.is_catalog_editor() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select * into s from public.submissions where id = p_submission_id for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;
  if s.status in ('approved', 'partially_approved', 'rejected', 'withdrawn') then
    raise exception 'already_decided' using errcode = 'P0001';
  end if;
  if v_status not in ('approved', 'partially_approved', 'rejected', 'needs_info') then
    raise exception 'invalid_decision' using errcode = 'P0001';
  end if;

  if v_status = 'needs_info' then
    if coalesce(btrim(decisions ->> 'question'), '') = '' then
      raise exception 'question_required' using errcode = 'P0001';
    end if;
    update public.submissions set status = 'needs_info' where id = s.id;
    insert into public.submission_events (submission_id, actor_id, event, payload)
    values (s.id, uid, 'needs_info',
            jsonb_build_object('question', decisions ->> 'question'));
    return;
  end if;

  if v_status = 'rejected' then
    if coalesce(decisions ->> 'reason_code', '') = '' then
      raise exception 'reason_required' using errcode = 'P0001';
    end if;
    update public.submissions set
      status = 'rejected',
      decision_reason_code = decisions ->> 'reason_code',
      decision_note = nullif(decisions ->> 'note', ''),
      decided_at = now(), decided_by = uid
    where id = s.id;
    insert into public.submission_events (submission_id, actor_id, event, payload)
    values (s.id, uid, 'decided',
            jsonb_build_object('status', 'rejected',
                               'reason_code', decisions ->> 'reason_code'));
    return;
  end if;

  -- ----- Uebernahme -----
  -- Track: bearbeitete Fassung aus decisions, sonst Original
  if decisions -> 'track' -> 'segments' is not null then
    select ST_Multi(ST_Collect(line))::geography into v_track
    from (
      select ST_MakeLine(
               ST_SetSRID(ST_MakePoint((pt2 ->> 0)::float8, (pt2 ->> 1)::float8), 4326)
               order by pord
             ) as line
      from jsonb_array_elements(decisions -> 'track' -> 'segments')
             with ordinality as sg(seg, sord),
           jsonb_array_elements(sg.seg) with ordinality as q(pt2, pord)
      group by sord
      having count(*) >= 2
    ) lines;
  else
    v_track := s.track;
  end if;

  if s.kind = 'new_trail' then
    v_base := regexp_replace(
      lower(translate(coalesce(s.title, 'neuer-pfad'),
        'äöüßÄÖÜ', 'aousAOU')),
      '[^a-z0-9]+', '-', 'g');
    v_base := btrim(v_base, '-');
    if v_base = '' then v_base := 'neuer-pfad'; end if;
    v_slug := v_base;
    while exists (select 1 from public.trails where id = v_slug) loop
      v_n := v_n + 1;
      v_slug := v_base || '-' || v_n;
    end loop;
    v_trail := v_slug;
    v_typ := case s.area
      when 'wald' then 'wald'
      when 'moor' then 'moor'
      when 'spreewald' then 'spreewald'
      when 'kueste' then 'kueste'
      when 'wasser' then 'wasserspielplatz'
      when 'hof' then 'kinderbauernhof'
      else 'naturerlebnis' end;
  else
    v_trail := s.target_trail_id;
    select jsonb_build_object(
      'trail', to_jsonb(t),
      'stations', coalesce((select jsonb_agg(to_jsonb(st)) from public.stations st where st.trail_id = t.id), '[]'::jsonb),
      'amenities', coalesce((select jsonb_agg(to_jsonb(a)) from public.amenities a where a.trail_id = t.id), '[]'::jsonb)
    ) into v_snapshot
    from public.trails t where t.id = v_trail;
    if v_snapshot is null then
      raise exception 'trail_missing' using errcode = 'P0001';
    end if;
    insert into public.trail_revisions (trail_id, submission_id, snapshot)
    values (v_trail, s.id, v_snapshot);
  end if;

  -- Geometrie fuer new_trail und revision (vereinfacht, 2 m ~ 0.000018 Grad)
  if s.kind in ('new_trail', 'revision') and v_track is not null then
    v_geom := ST_SimplifyPreserveTopology(v_track::geometry, 0.000018);
    select jsonb_agg(jsonb_build_array(ST_Y(d.geom), ST_X(d.geom)) order by d.path)
      into v_route
    from ST_DumpPoints(v_geom) d;
    v_len := ST_Length(v_track) / 1000.0;
  end if;

  if s.kind = 'new_trail' then
    -- Startpunkt: Start-Marker, sonst erster Marker, sonst erster Trackpunkt
    select ST_Y(location::geometry), ST_X(location::geometry) into v_lat, v_lng
    from public.submission_points
    where submission_id = s.id
    order by (type = 'start') desc, seq
    limit 1;
    if v_lat is null and v_route is not null then
      v_lat := (v_route -> 0 ->> 0)::float8;
      v_lng := (v_route -> 0 ->> 1)::float8;
    end if;
    insert into public.trails (
      id, name, typ, rundkurs, route, start_lat, start_lon, laenge_km, sichtbar
    ) values (
      v_trail, s.title, v_typ, coalesce(s.is_loop, false),
      coalesce(v_route, '[]'::jsonb), v_lat, v_lng, v_len, false
    );
  elsif s.kind = 'revision' and v_route is not null then
    update public.trails set
      route = v_route,
      laenge_km = v_len,
      rundkurs = coalesce(s.is_loop, rundkurs)
    where id = v_trail;
  end if;

  -- Konsens-Mittelwert: gewichtet mit 1 / Genauigkeit^2
  if coalesce((decisions ->> 'consensus_mean')::boolean, false)
     and s.consensus_group_id is not null then
    for pt in
      select p.target_point_id as tp
      from public.submission_points p
      where p.submission_id = s.id and p.target_point_id is not null
    loop
      select
        sum(ST_Y(p.location::geometry) / power(greatest(p.accuracy_m, 1), 2))
          / sum(1 / power(greatest(p.accuracy_m, 1), 2)) as lat,
        sum(ST_X(p.location::geometry) / power(greatest(p.accuracy_m, 1), 2))
          / sum(1 / power(greatest(p.accuracy_m, 1), 2)) as lng
      into v_group_mean
      from public.submission_points p
      join public.submissions s2 on s2.id = p.submission_id
      where s2.consensus_group_id = s.consensus_group_id
        and p.target_point_id = pt.tp
        and ST_DWithin(
          p.location,
          (select location from public.submission_points
            where submission_id = s.id and target_point_id = pt.tp limit 1),
          25);
      if v_group_mean.lat is not null then
        if split_part(pt.tp, ':', 1) = 'station' then
          update public.stations set
            lat = v_group_mean.lat, lon = v_group_mean.lng
          where id = split_part(pt.tp, ':', 2)::bigint;
        elsif split_part(pt.tp, ':', 1) = 'amenity' then
          update public.amenities set
            lat = v_group_mean.lat, lon = v_group_mean.lng
          where id = split_part(pt.tp, ':', 2)::bigint;
        elsif split_part(pt.tp, ':', 1) = 'trail' then
          update public.trails set
            start_lat = v_group_mean.lat, start_lon = v_group_mean.lng
          where id = substr(pt.tp, 7);
        end if;
        v_applied := v_applied + 1;
      end if;
    end loop;
    update public.submissions set
      status = 'approved',
      decision_note = 'Gemeinsam mit einer weiteren Meldung übernommen',
      decided_at = now(), decided_by = uid, published_at = now()
    where consensus_group_id = s.consensus_group_id
      and id <> s.id
      and status in ('submitted', 'in_review', 'needs_info');
  end if;

  -- Punkte einzeln anwenden (nur akzeptierte)
  for pt in
    select p.id, p.type, p.target_point_id, p.number, p.title, p.hint_kind,
           p.note, ST_Y(p.location::geometry) as lat, ST_X(p.location::geometry) as lng,
           p.location
    from public.submission_points p
    where p.submission_id = s.id
    order by p.seq
  loop
    select d into dj
    from jsonb_array_elements(coalesce(decisions -> 'points', '[]'::jsonb)) d
    where (d ->> 'id')::uuid = pt.id
    limit 1;
    -- Ohne Angabe gilt akzeptiert bei approved, abgelehnt bei partial
    if coalesce((dj ->> 'accept')::boolean, v_status = 'approved') is not true then
      continue;
    end if;
    v_lat := coalesce((dj ->> 'lat')::float8, pt.lat);
    v_lng := coalesce((dj ->> 'lng')::float8, pt.lng);

    if s.kind = 'quick' and pt.target_point_id is not null then
      -- Position verschieben (Konsens-Mittel hat evtl. schon gesetzt, dann
      -- ueberschreibt die Einzelposition nur ohne Konsens)
      if not (coalesce((decisions ->> 'consensus_mean')::boolean, false)
              and s.consensus_group_id is not null) then
        if split_part(pt.target_point_id, ':', 1) = 'station' then
          update public.stations set lat = v_lat, lon = v_lng
          where id = split_part(pt.target_point_id, ':', 2)::bigint;
        elsif split_part(pt.target_point_id, ':', 1) = 'amenity' then
          update public.amenities set lat = v_lat, lon = v_lng
          where id = split_part(pt.target_point_id, ':', 2)::bigint;
        elsif split_part(pt.target_point_id, ':', 1) = 'trail' then
          update public.trails set start_lat = v_lat, start_lon = v_lng
          where id = substr(pt.target_point_id, 7);
        end if;
        v_applied := v_applied + 1;
      end if;
    elsif pt.type = 'hint' then
      v_hint_kind := coalesce(dj ->> 'hint_kind', pt.hint_kind, 'other');
      insert into public.trail_hints (trail_id, kind, note, lat, lon, expires_at)
      values (
        v_trail, v_hint_kind, coalesce(pt.note, ''), v_lat, v_lng,
        case when v_hint_kind in ('closed', 'danger')
             then now() + interval '60 days' end
      );
      v_applied := v_applied + 1;
    elsif pt.type = 'parking' then
      insert into public.amenities (trail_id, lat, lon, kategorie, name)
      values (v_trail, v_lat, v_lng, 'parking', pt.title);
      v_applied := v_applied + 1;
    elsif pt.type in ('station', 'waypoint', 'start', 'end') then
      if pt.type <> 'station' then
        continue; -- Start/Ende/Wegpunkt sind im Katalog keine Stationen
      end if;
      v_num := coalesce((dj ->> 'number')::int, pt.number);
      v_station := null;
      if s.kind = 'revision' then
        -- gleiche Nummer, sonst naechste Station innerhalb 30 m, sonst neu
        select id into v_station from public.stations
        where trail_id = v_trail and reihenfolge = v_num;
        if v_station is null then
          select id into v_station from public.stations
          where trail_id = v_trail
            and ST_DWithin(pos::geography, pt.location, 30)
          order by ST_Distance(pos::geography, pt.location)
          limit 1;
        end if;
      end if;
      if v_station is not null then
        update public.stations set lat = v_lat, lon = v_lng
        where id = v_station;
      else
        if v_num is null
           or exists (select 1 from public.stations
                      where trail_id = v_trail and reihenfolge = v_num) then
          select coalesce(max(reihenfolge), 0) + 1 into v_num
          from public.stations where trail_id = v_trail;
        end if;
        insert into public.stations (trail_id, lat, lon, reihenfolge, titel)
        values (
          v_trail, v_lat, v_lng, v_num,
          coalesce(nullif(dj ->> 'title', ''), pt.title, 'Station ' || v_num)
        );
      end if;
      v_applied := v_applied + 1;
    end if;
  end loop;

  -- Fotos: bei Uebernahme freigeben, sonst ablehnen
  update public.submission_photos set
    status = case when v_applied > 0 then 'approved' else 'rejected' end
  where submission_id = s.id and status = 'pending';

  if s.kind <> 'new_trail' then
    update public.trails set data_version = data_version + 1 where id = v_trail;
  end if;

  update public.submissions set
    status = v_status,
    target_trail_id = coalesce(target_trail_id, v_trail),
    decision_note = nullif(decisions ->> 'note', ''),
    decided_at = now(), decided_by = uid, published_at = now()
  where id = s.id;

  insert into public.submission_events (submission_id, actor_id, event, payload)
  values (s.id, uid, 'decided',
          jsonb_build_object('status', v_status, 'trail_id', v_trail,
                             'applied', v_applied));
end;
$$ language plpgsql security definer set search_path = public;

revoke all on function public.apply_submission(uuid, jsonb) from public, anon;
grant execute on function public.apply_submission(uuid, jsonb) to authenticated;

-- ---------------------------------------------------------------------
-- nearby_trails(lat, lon, radius_m): Dublette-Karte in R4 (Start innerhalb
-- von 300 m). Nur sichtbare Eintraege, Name und Abstand.
-- ---------------------------------------------------------------------
create or replace function public.nearby_trails(
  p_lat double precision,
  p_lon double precision,
  p_radius_m double precision default 300
) returns table (id text, name text, distance_m double precision) as $$
  select t.id, t.name,
         ST_Distance(t.start_pos::geography,
                     ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326)::geography)
  from public.trails t
  where t.sichtbar
    and t.start_pos is not null
    and ST_DWithin(t.start_pos::geography,
                   ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326)::geography,
                   p_radius_m)
  order by 3
  limit 3;
$$ language sql stable security definer set search_path = public;

revoke all on function public.nearby_trails(double precision, double precision, double precision)
  from public, anon;
grant execute on function public.nearby_trails(double precision, double precision, double precision)
  to authenticated;

-- ---------------------------------------------------------------------
-- Konto loeschen: offene Beitraege und Rohdaten weg, uebernommene bleiben
-- anonymisiert (user_id wird durch on delete set null leer).
-- ---------------------------------------------------------------------
create or replace function public.delete_open_submissions_of_user()
returns trigger as $$
begin
  delete from public.submissions
  where user_id = old.id
    and status in ('submitted', 'in_review', 'needs_info', 'withdrawn', 'rejected');
  return old;
end;
$$ language plpgsql security definer set search_path = public;

create trigger auth_users_delete_submissions
  before delete on auth.users
  for each row execute function public.delete_open_submissions_of_user();

-- ---------------------------------------------------------------------
-- admin_submission_detail: Beitrag fuer die Moderation als ein JSON.
-- Marker und Track als Koordinaten (PostgREST liefert geography nur als
-- EWKB), Zielposition und bestehender Verlauf fuer den Vergleich.
-- ---------------------------------------------------------------------
create or replace function public.admin_submission_detail(p_submission_id uuid)
returns jsonb as $$
declare
  s public.submissions%rowtype;
  v_track jsonb;
  v_route jsonb;
  v_target text;
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select * into s from public.submissions where id = p_submission_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0001';
  end if;
  if s.track is not null then
    v_track := (ST_AsGeoJSON(s.track::geometry)::jsonb) -> 'coordinates';
  end if;
  if s.target_trail_id is not null then
    select t.route, t.name into v_route, v_target
    from public.trails t where t.id = s.target_trail_id;
  end if;
  return jsonb_build_object(
    'submission', to_jsonb(s) - 'track',
    'track', coalesce(v_track, '[]'::jsonb),
    'trail_route', coalesce(v_route, '[]'::jsonb),
    'trail_name', v_target,
    'points', coalesce((
      select jsonb_agg(
        to_jsonb(p) - 'location'
        || jsonb_build_object(
             'lat', ST_Y(p.location::geometry),
             'lng', ST_X(p.location::geometry),
             'target_lat', ST_Y(public.catalog_point_geog(p.target_point_id)::geometry),
             'target_lng', ST_X(public.catalog_point_geog(p.target_point_id)::geometry)
           )
        order by p.seq)
      from public.submission_points p where p.submission_id = s.id), '[]'::jsonb),
    'photos', coalesce((
      select jsonb_agg(to_jsonb(f) order by f.id)
      from public.submission_photos f where f.submission_id = s.id), '[]'::jsonb),
    'events', coalesce((
      select jsonb_agg(to_jsonb(e) order by e.id)
      from public.submission_events e where e.submission_id = s.id), '[]'::jsonb)
  );
end;
$$ language plpgsql stable security definer set search_path = public;

revoke all on function public.admin_submission_detail(uuid) from public, anon;
grant execute on function public.admin_submission_detail(uuid) to authenticated;
