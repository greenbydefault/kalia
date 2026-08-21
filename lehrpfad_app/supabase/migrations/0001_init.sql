-- 0001_init.sql – Lehrpfad-App: Basis-Schema
-- Trails, Stationen und Amenities. Oeffentlich lesbar (anon-Role),
-- geschrieben wird nur via service_role (Seed-Script) oder Dashboard.

create extension if not exists postgis;

create table trails (
  id text primary key,                -- z. B. 'von-moor-zu-moor'
  name text not null,
  typ text not null,
  kurzbeschreibung text not null default '',
  beschreibung text not null default '',
  laenge_km double precision,
  dauer_min integer,
  rundkurs boolean not null default false,
  markierung text not null default '',
  betreiber text not null default '',
  region text not null default '',
  website text,
  anreise text not null default '',
  start_name text not null default '',
  arten text[] not null default '{}',
  route jsonb not null,               -- [[lat, lon], ...] identisch zum Seed-Format der App
  start_lat double precision,
  start_lon double precision,
  -- geometry statt geography: ST_MakePoint/ST_SetSRID sind garantiert immutable,
  -- der geography-Cast nicht. Meter-genaue Abfragen per start_pos::geography.
  start_pos geometry(Point, 4326)
    generated always as (ST_SetSRID(ST_MakePoint(start_lon, start_lat), 4326)) stored,
  updated_at timestamptz not null default now()
);

create table stations (
  id bigint generated always as identity primary key,
  trail_id text not null references trails (id) on delete cascade,
  osm_id bigint,
  lat double precision not null,
  lon double precision not null,
  pos geometry(Point, 4326)
    generated always as (ST_SetSRID(ST_MakePoint(lon, lat), 4326)) stored,
  km double precision not null default 0,
  reihenfolge integer not null,
  titel text not null,
  thema text not null default '',
  kurztext text not null default '',
  erlebnisse text[] not null default '{}',
  barrierefrei boolean not null default false,
  steckbrief jsonb,                   -- optionale Felder, 1:1 das Steckbrief-JSON der App
  unique (trail_id, reihenfolge)
);

create table amenities (
  id bigint generated always as identity primary key,
  trail_id text not null references trails (id) on delete cascade,
  osm_id bigint,
  lat double precision not null,
  lon double precision not null,
  pos geometry(Point, 4326)
    generated always as (ST_SetSRID(ST_MakePoint(lon, lat), 4326)) stored,
  kategorie text not null,
  name text
);

create index stations_pos_idx on stations using gist (pos);
create index amenities_pos_idx on amenities using gist (pos);
create index trails_start_pos_idx on trails using gist (start_pos);

-- updated_at automatisch pflegen (Grundlage fuer spaetere Cache-Invalidierung)
create or replace function set_updated_at() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trails_set_updated_at before update on trails
  for each row execute function set_updated_at();

alter table trails enable row level security;
alter table stations enable row level security;
alter table amenities enable row level security;

-- Oeffentliche Lese-App ohne Login: anon darf nur lesen
create policy "trails public read" on trails for select to anon using (true);
create policy "stations public read" on stations for select to anon using (true);
create policy "amenities public read" on amenities for select to anon using (true);
