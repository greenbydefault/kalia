-- 0015_trail_besuch.sql – Eintritt, Preise, Öffnungszeiten, Besuchshinweise
-- Für bezahlte / zeitlich geöffnete Orte (Kinderbauernhof u. a.).
-- website existiert schon; Header-Chip nur bei eintritt = true.

alter table trails
  add column if not exists eintritt boolean not null default false;

alter table trails
  add column if not exists eintritt_preise text;

alter table trails
  add column if not exists oeffnungszeiten text;

alter table trails
  add column if not exists besuchshinweise text;
