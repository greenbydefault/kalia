-- 0011_species_geraete.sql – Kategorie geraete + icon_key fuer Spielgeraete
-- Species-Katalog: flora | fauna | geraete; Icons via App-Katalog (icon_key).

alter table species drop constraint if exists species_kategorie_check;

alter table species
  add constraint species_kategorie_check
  check (kategorie in ('flora', 'fauna', 'geraete'));

alter table species
  add column if not exists icon_key text not null default '';
