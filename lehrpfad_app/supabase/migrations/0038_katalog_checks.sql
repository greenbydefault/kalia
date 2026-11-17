-- 0038_katalog_checks.sql
-- Recherche-Vertrag (docs/recherche/KALIA_RECHERCHE_VERTRAG.md):
--  1. Neue Trails starten unsichtbar. Sichtbar wird ein Trail erst, wenn
--     seed_supabase.py (neuer Trail) oder das CMS ihn explizit freigibt.
--  2. Katalogfelder bekommen CHECK-Constraints. NOT VALID: Bestand wird
--     nicht gescannt (alle Zeilen sind heute konform), jede neue oder
--     geaenderte Zeile wird geprueft. Listen entsprechen docs/recherche/gate.sql.

alter table public.trails alter column sichtbar set default false;

alter table public.trails drop constraint if exists trails_typ_katalog;
alter table public.trails add constraint trails_typ_katalog check (
  typ = any (array['wald','moor','aue','walderlebnispfad','erlebniswald','naturerlebnis',
    'naturerlebnisraum','waldspielplatz','wasserspielplatz','waldspazierplatz','sinnespfad',
    'barfusspfad','kueste','kinderbauernhof'])
) not valid;

alter table public.trails drop constraint if exists trails_naturraum_katalog;
alter table public.trails add constraint trails_naturraum_katalog check (
  naturraum = any (array['','nordsee','ostsee','norddt-tiefland','mittelgebirge',
    'alpenvorland','katalonien','daenemark'])
) not valid;

alter table public.trails drop constraint if exists trails_tags_katalog;
alter table public.trails add constraint trails_tags_katalog check (
  tags <@ array['kinderfreundlich','kinderwagentauglich','rollstuhltauglich','hunde-erlaubt',
    'einkehr','spielplatz','picknick','barfusspfad']::text[]
) not valid;

alter table public.trails drop constraint if exists trails_lebensraeume_katalog;
alter table public.trails add constraint trails_lebensraeume_katalog check (
  lebensraeume <@ array['buchenwald','kuestenwald-kiefer','kiefernforst','eichen-mischwald',
    'auwald','moor','heide','teich-tuempel','see-ufer','fliessgewaesser','salzwiese-watt',
    'duene-strand','streuobst-hecke','nadelforst','alpen-wald','mediterraner-wald',
    'trockenrasen','hof-nutztier']::text[]
) not valid;

alter table public.stations drop constraint if exists stations_erlebnisse_katalog;
alter table public.stations add constraint stations_erlebnisse_katalog check (
  erlebnisse <@ array['tafel','quiz','steg','bohrkernmodell','mitmach-modell','memory',
    'bestimmung','audio','barfusspfad']::text[]
) not valid;

alter table public.amenities drop constraint if exists amenities_kategorie_katalog;
alter table public.amenities add constraint amenities_kategorie_katalog check (
  kategorie = any (array['wc','parking','bench','picnic','shelter','playground','viewpoint','gastro'])
) not valid;

alter table public.pois drop constraint if exists pois_kategorie_katalog;
alter table public.pois add constraint pois_kategorie_katalog check (
  kategorie = any (array['cafe','restaurant','hofladen','baden','museum','aktivitaet','camping'])
) not valid;

alter table public.images drop constraint if exists images_kind_katalog;
alter table public.images add constraint images_kind_katalog check (
  kind is null or kind = any (array['hero','station','ort','art','placeholder'])
) not valid;

alter table public.images drop constraint if exists images_license_katalog;
alter table public.images add constraint images_license_katalog check (
  license = any (array['','cc-by-sa-4.0','cc-by-sa-3.0','cc-by-sa-2.0','cc-by-4.0','cc-by-3.0',
    'cc-by-2.0','cc0','pd','eigen','freigabe'])
) not valid;
