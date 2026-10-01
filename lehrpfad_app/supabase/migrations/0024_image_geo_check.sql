-- Vorpruefung fuer die Moderation: passt der GPS-Ort aus dem Foto zum
-- gewaehlten Trail? Der Client wertet das EXIF lokal aus und schickt nur
-- diese Ampel. Koordinaten werden nie gespeichert.
--   match = am Trail, near = grob in der Gegend, far = klar woanders,
--   none  = kein GPS im Foto / Trail ohne Geometrie.
-- null = Altbestand ohne Pruefung. Nur ein Hinweis, keine Freigabe.

alter table public.images
  add column geo_check text
  check (geo_check in ('match', 'near', 'far', 'none'));
