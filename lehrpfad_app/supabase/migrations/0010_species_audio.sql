-- 0010_species_audio.sql – lokaler Asset-Pfad fuer Art-Hoerdokus
alter table species
  add column audio_path text;
