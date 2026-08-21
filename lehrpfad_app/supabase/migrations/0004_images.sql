-- 0004_images.sql – Bilder fuer Trails und Stationen + Storage-Bucket
-- Offizielle Bilder (source='official', uploader_id null) sind sofort
-- approved; User-Uploads starten als pending und werden von Admins
-- freigeschaltet. Pro Bild liegen drei AVIF-Varianten im Storage:
--   {trail_id}/{image_id}/thumb.avif  (200 px)
--   {trail_id}/{image_id}/small.avif  (600 px)
--   {trail_id}/{image_id}/medium.avif (1600 px)
-- Daher reicht die Bild-ID als Pfad-Prefix, keine URL-Spalten noetig.

create table images (
  id uuid primary key default gen_random_uuid(),
  trail_id text not null references trails (id) on delete cascade,
  station_id bigint references stations (id) on delete cascade,  -- null = ganzer Trail
  uploader_id uuid references auth.users (id) on delete set null, -- null = offiziell
  source text not null default 'user' check (source in ('official', 'user')),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  credit text not null default '',
  width integer,
  height integer,
  created_at timestamptz not null default now()
);

create index images_trail_idx on images (trail_id, status);
create index images_station_idx on images (station_id) where station_id is not null;
create index images_pending_idx on images (status) where status = 'pending';

-- Bucket: public (Auslieferung via CDN ohne Signed URLs). Pending-Bilder
-- sind nur ueber ihre UUID-Pfade erreichbar und werden nirgends gelistet.
insert into storage.buckets (id, name, public)
values ('trail-images', 'trail-images', true)
on conflict (id) do nothing;

-- Storage-Policies: hochladen duerfen nur angemeldete User,
-- loeschen nur der eigene Upload oder Admins.
create policy "trail-images insert authenticated" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'trail-images');

create policy "trail-images delete own or admin" on storage.objects
  for delete to authenticated
  using (bucket_id = 'trail-images'
         and (owner_id = auth.uid()::text or is_admin()));

alter table images enable row level security;

-- Lesen: oeffentlich nur freigegebene Bilder
create policy "images public read approved" on images
  for select to anon using (status = 'approved');

-- Angemeldete: freigegebene + eigene (jeden Status) + Admins alles
create policy "images read authenticated" on images
  for select to authenticated
  using (status = 'approved' or uploader_id = auth.uid() or is_admin());

-- Hochladen: nur als eigener User-Upload, immer pending
create policy "images insert own pending" on images
  for insert to authenticated
  with check (uploader_id = auth.uid() and source = 'user' and status = 'pending');

-- Freigabe/Ablehnung nur durch Admins
create policy "images admin update" on images
  for update to authenticated
  using (is_admin()) with check (is_admin());

-- Uploader darf eigenes pending-Bild noch korrigieren (z. B. Credit)
create policy "images uploader update pending" on images
  for update to authenticated
  using (uploader_id = auth.uid() and status = 'pending')
  with check (uploader_id = auth.uid() and status = 'pending');

-- Loeschen: eigene Bilder oder Admin
create policy "images delete own or admin" on images
  for delete to authenticated
  using (uploader_id = auth.uid() or is_admin());
