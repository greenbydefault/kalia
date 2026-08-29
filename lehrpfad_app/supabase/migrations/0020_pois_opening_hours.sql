-- OSM-Subset-String für „Jetzt geöffnet“-Badge (optional).
-- Anzeige-Freitext bleibt oeffnungszeiten.

alter table pois add column if not exists opening_hours text;
