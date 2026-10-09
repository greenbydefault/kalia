-- 0026_arten_pool.sql
-- Lebensraum und Naturraum am Trail. Nachweisstufe an der Zuordnung.
-- Die App zeigt die Stufe nicht. belegt = Ort/Tafel, typisch = Pool.

alter table trails
  add column if not exists lebensraeume text[] not null default '{}',
  add column if not exists naturraum text not null default '';

alter table trail_species
  add column if not exists nachweis text not null default 'belegt';

alter table trail_species
  drop constraint if exists trail_species_nachweis_check;

alter table trail_species
  add constraint trail_species_nachweis_check
  check (nachweis in ('belegt', 'typisch'));
