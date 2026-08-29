-- Anonymer Test-Upload: jeder darf pending-Bilder in `images` und
-- den Bucket `trail-images` schreiben. Oeffentlich lesbar bleibt nur
-- status = approved (bestehende SELECT-Policy).

grant insert on table public.images to anon;

create policy "images insert anon pending" on public.images
  for insert to anon
  with check (
    uploader_id is null
    and source = 'user'
    and status = 'pending'
  );

create policy "trail-images insert anon" on storage.objects
  for insert to anon
  with check (bucket_id = 'trail-images');
