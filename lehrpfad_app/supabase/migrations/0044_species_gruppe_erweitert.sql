-- 0044_species_gruppe_erweitert.sql
-- Fische, Flechten und weitere Wirbellose (Assel, Regenwurm, Schnecke) als eigene Gruppen.

alter table species drop constraint if exists species_gruppe_check;

alter table species
  add constraint species_gruppe_check check (
    gruppe = '' or gruppe in (
      'saeugetiere', 'voegel', 'insekten', 'amphibien', 'reptilien',
      'spinnen', 'fische', 'wirbellose', 'baeume', 'straeucher', 'kraeuter',
      'moose', 'flechten', 'pilze'
    )
  );
