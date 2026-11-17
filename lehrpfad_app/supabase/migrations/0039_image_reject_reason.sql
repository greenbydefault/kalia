-- 0039_image_reject_reason.sql
-- Abgelehnte Nutzerfotos bleiben als Zeile erhalten (Status rejected),
-- damit der Uploader im Konto Status und Grund sieht. Die grossen
-- Varianten werden beim Ablehnen aus dem Storage entfernt, das Thumb
-- bleibt bis zur Aufraeum-Aktion in der Moderation (> 30 Tage).

alter table public.images
  add column if not exists reject_reason text,
  add column if not exists decided_at timestamptz;

alter table public.images drop constraint if exists images_reject_reason_check;
alter table public.images add constraint images_reject_reason_check check (
  reject_reason is null
  or reject_reason in ('blurry', 'off_topic', 'people', 'rights', 'other')
);

create index if not exists images_uploader_idx
  on public.images (uploader_id, created_at desc)
  where uploader_id is not null;
