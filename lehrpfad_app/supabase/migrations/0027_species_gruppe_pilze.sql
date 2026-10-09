-- 0027_species_gruppe_pilze.sql
-- Fliegenpilz liegt im Katalog als gruppe pilze (kategorie bleibt flora).

alter table species drop constraint if exists species_gruppe_check;

alter table species
  add constraint species_gruppe_check check (
    gruppe = '' or gruppe in (
      'saeugetiere', 'voegel', 'insekten', 'amphibien', 'reptilien',
      'spinnen', 'baeume', 'straeucher', 'kraeuter', 'moose', 'pilze'
    )
  );
