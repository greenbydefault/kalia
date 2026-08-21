-- 0008_species_content.sql – Outdoor-Steckbrief als jsonb an species
-- Shape und Limits: tools/SPECIES_CONTENT.md + validate_seeds.py

alter table species
  add column content jsonb not null default '{}'::jsonb;
