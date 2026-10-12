-- 0030_catalog_media.sql – Katalog-Medien aus dem CMS
-- Trail-Hero: Zeilen in images mit source='official' (approved, uploader null),
-- Dateien im bestehenden Bucket trail-images ({trail}/{image}/{variant}.avif).
-- Art-Bild/-Audio: Bucket catalog-media, species.image_path / audio_path
-- zeigen als 'storage:catalog-media/<pfad>' darauf.

alter table public.images
  add column if not exists caption text not null default '',
  add column if not exists license text not null default '',
  add column if not exists license_url text not null default '',
  add column if not exists source_url text not null default '',
  add column if not exists kind text,
  add column if not exists sort integer not null default 0;

create index if not exists images_official_idx
  on public.images (trail_id, sort) where source = 'official';

-- Editoren legen offizielle Bilder an (User-Policy erzwingt source=user/pending)
create policy "images editor insert official" on public.images
  for insert to authenticated
  with check (
    public.is_catalog_editor()
    and source = 'official'
    and status = 'approved'
    and uploader_id is null
  );

-- Bucket fuer Art-Bild und Audio (public read, Auslieferung per CDN)
insert into storage.buckets (id, name, public)
values ('catalog-media', 'catalog-media', true)
on conflict (id) do nothing;

create policy "catalog-media editor insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'catalog-media' and public.is_catalog_editor());

create policy "catalog-media editor update" on storage.objects
  for update to authenticated
  using (bucket_id = 'catalog-media' and public.is_catalog_editor())
  with check (bucket_id = 'catalog-media' and public.is_catalog_editor());

create policy "catalog-media editor delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'catalog-media' and public.is_catalog_editor());
