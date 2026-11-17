-- 0042_species_illustration.sql – Illustration pro Art aus dem CMS
-- Eine SVG pro Art im Bucket catalog-media (species/<id>/illu-<ts>.svg),
-- species.illustration_path zeigt als 'storage:catalog-media/<pfad>' darauf.
-- Landingpage und App lesen dieselbe Spalte. Foto bleibt in image_path.
-- Schreibrechte: bestehende Editor-Policies auf species und catalog-media.

alter table public.species
  add column if not exists illustration_path text;

comment on column public.species.illustration_path is
  'storage:catalog-media/species/<id>/illu-<ts>.svg (Illustration, nicht Foto)';
