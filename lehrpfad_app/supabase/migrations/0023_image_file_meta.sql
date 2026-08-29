-- Dateiformat und Byte-Groessen der drei Storage-Varianten, damit die
-- Moderation pruefen kann, ob die AVIF-Umwandlung geklappt hat.

alter table public.images
  add column mime_type text,
  add column thumb_bytes integer,
  add column small_bytes integer,
  add column medium_bytes integer;

with files as (
  select
    split_part(name, '/', 2)::uuid as image_id,
    split_part(split_part(name, '/', 3), '.', 1) as variant,
    metadata->>'mimetype' as mime,
    (metadata->>'size')::integer as bytes
  from storage.objects
  where bucket_id = 'trail-images'
    and name like '%/%/%.avif'
)
update public.images i
set
  mime_type = coalesce(
    (select f.mime from files f where f.image_id = i.id and f.variant = 'medium' limit 1),
    (select f.mime from files f where f.image_id = i.id limit 1)
  ),
  thumb_bytes = (select f.bytes from files f where f.image_id = i.id and f.variant = 'thumb' limit 1),
  small_bytes = (select f.bytes from files f where f.image_id = i.id and f.variant = 'small' limit 1),
  medium_bytes = (select f.bytes from files f where f.image_id = i.id and f.variant = 'medium' limit 1);
