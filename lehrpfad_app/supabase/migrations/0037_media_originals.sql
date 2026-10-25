-- 0037_media_originals.sql
-- Privater Bucket für die Quelle, aus der Varianten neu erzeugt werden.
-- Auslieferung bleibt trail-images. ThumbHash und Dominanzfarbe liegen
-- an der bestehenden images-Zeile, nicht in einer neuen photos-Tabelle.

insert into storage.buckets (id, name, public)
values ('media-originals', 'media-originals', false)
on conflict (id) do nothing;

drop policy if exists "media-originals editor insert" on storage.objects;
create policy "media-originals editor insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'media-originals' and public.is_catalog_editor());

drop policy if exists "media-originals editor read" on storage.objects;
create policy "media-originals editor read" on storage.objects
  for select to authenticated
  using (bucket_id = 'media-originals' and public.is_catalog_editor());

drop policy if exists "media-originals editor update" on storage.objects;
create policy "media-originals editor update" on storage.objects
  for update to authenticated
  using (bucket_id = 'media-originals' and public.is_catalog_editor())
  with check (bucket_id = 'media-originals' and public.is_catalog_editor());

drop policy if exists "media-originals editor delete" on storage.objects;
create policy "media-originals editor delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'media-originals' and public.is_catalog_editor());

alter table public.images
  add column if not exists thumbhash text,
  add column if not exists dominant_color text;
