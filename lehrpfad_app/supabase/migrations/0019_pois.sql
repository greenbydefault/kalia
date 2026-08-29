-- 0019_pois.sql – Orte in der Nähe (Café, Restaurant, Camping, …)
-- Katalog-Familie: öffentlich lesbar, Writes nur via service_role / Dashboard.
-- Zugehörigkeit zum Trail ist geografisch (App-Ableitung), kein Join.

create table pois (
  id text primary key,
  name text not null,
  kategorie text not null,
  kurztext text not null default '',
  lat double precision not null,
  lon double precision not null,
  pos geometry(Point, 4326)
    generated always as (ST_SetSRID(ST_MakePoint(lon, lat), 4326)) stored,
  website text,
  oeffnungszeiten text,
  telefon text
);

create index pois_pos_idx on pois using gist (pos);
create index pois_kategorie_idx on pois (kategorie);

alter table pois enable row level security;

create policy "pois public read" on pois
  for select to anon, authenticated using (true);
