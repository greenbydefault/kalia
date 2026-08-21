-- 0013_trail_form_area.sql – Flächen-Orte (Wasserspielplatz) neben Linien-Pfaden
-- form: linie | flaeche; area: Polygon [[lat, lon], ...] wie im Seed.

alter table trails
  add column if not exists form text not null default 'linie';

alter table trails
  drop constraint if exists trails_form_check;

alter table trails
  add constraint trails_form_check
  check (form in ('linie', 'flaeche'));

alter table trails
  add column if not exists area jsonb not null default '[]'::jsonb;
