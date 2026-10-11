-- 0025_trail_pois.sql – Auto-Fahrzeit Trail-Start → Ort in der Nähe
-- Quelle: assets/seed/nearby_zeiten.json (tools/nearby_zeiten.py, OSRM).
-- Nur Paare bis 20 Min (1200 s). Kein FK auf trails: Katalog-Familie wie pois,
-- Zeilen pro Trail werden von tools/seed_pois.py komplett ersetzt.
-- Public read, Writes nur via service_role / Dashboard.

create table trail_pois (
  trail_id text not null,
  poi_id text not null references pois (id) on delete cascade,
  sek integer not null check (sek >= 0 and sek <= 1200),
  primary key (trail_id, poi_id)
);

create index trail_pois_poi_idx on trail_pois (poi_id);

alter table trail_pois enable row level security;

create policy "trail_pois public read" on trail_pois
  for select to anon, authenticated using (true);
