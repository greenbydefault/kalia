-- Kalia Gate-SQL. Nur lesen. Eine Zeile = ein Verstoss. Leeres Ergebnis = Gate bestanden.
-- Trail-IDs unten in `p` eintragen (mehrere moeglich: values ('a'),('b')).
-- FEHLER blockiert den Import bzw. die Abgabe an Marc. WARNUNG wird im Import-Log begruendet.
-- Vertrag: docs/recherche/KALIA_RECHERCHE_VERTRAG.md, Abschnitt "Gate-SQL".
with p(id) as (values ('TRAIL_ID')),
t as (select tr.* from trails tr join p on p.id = tr.id),
st as (select s.* from stations s join p on p.id = s.trail_id),
ts as (select x.*, sp.kategorie from trail_species x join p on p.id = x.trail_id left join species sp on sp.id = x.species_id),
am as (select a.* from amenities a join p on p.id = a.trail_id),
im as (select i.* from images i join p on p.id = i.trail_id and i.source = 'official'),
tg as (select t.id, x as tag from t, unnest(t.tags) x),
-- Nutzertexte. prosa = Fliesstext (Hype- und Anredepruefung)
nutzer as (
  select id as trail_id, 'trails.kurzbeschreibung' as feld, kurzbeschreibung as txt, true as prosa from t
  union all select id, 'trails.beschreibung', beschreibung, true from t
  union all select id, 'trails.anreise', anreise, true from t
  union all select id, 'trails.besuchshinweise', besuchshinweise, true from t
  union all select id, 'trails.markierung', markierung, false from t
  union all select id, 'trails.betreiber', betreiber, false from t
  union all select id, 'trails.region', region, false from t
  union all select id, 'trails.start_name', start_name, false from t
  union all select id, 'trails.eintritt_preise', eintritt_preise, false from t
  union all select id, 'trails.oeffnungszeiten', oeffnungszeiten, false from t
  union all select trail_id, 'stations['||reihenfolge||'].titel', titel, false from st
  union all select trail_id, 'stations['||reihenfolge||'].thema', thema, false from st
  union all select trail_id, 'stations['||reihenfolge||'].kurztext', kurztext, true from st
),
-- Routenlaenge (Haversine ueber die Polyline)
pts as (
  select t.id, e.ord, (e.v->>0)::float8 as lat, (e.v->>1)::float8 as lon
  from t, jsonb_array_elements(t.route) with ordinality e(v, ord)
),
routelen as (
  select id, sum(6371.0 * 2 * asin(sqrt(
      power(sin(radians(lat - plat) / 2), 2) +
      cos(radians(plat)) * cos(radians(lat)) * power(sin(radians(lon - plon) / 2), 2)))) as km
  from (select id, ord, lat, lon, lag(lat) over (partition by id order by ord) plat,
               lag(lon) over (partition by id order by ord) plon from pts) q
  where plat is not null group by id
),
v as (
  -- 1 Sichtbarkeit
  select id as trail_id, 'SICHTBAR' as code, 'FEHLER' as schwere, 'sichtbar muss false sein (Freigabe macht nur Marc im CMS)' as detail from t where sichtbar

  -- 2 Kataloge
  union all select id, 'KAT_TYP', 'FEHLER', 'typ=' || typ from t
    where typ <> all(array['wald','moor','aue','walderlebnispfad','erlebniswald','naturerlebnis','naturerlebnisraum','waldspielplatz','wasserspielplatz','waldspazierplatz','sinnespfad','barfusspfad','kueste','kinderbauernhof'])
  union all select id, 'KAT_FORM', 'FEHLER', 'form=' || form from t where form <> all(array['linie','flaeche'])
  union all select id, 'KAT_NATURRAUM', 'FEHLER', 'naturraum=' || naturraum from t
    where naturraum <> all(array['nordsee','ostsee','norddt-tiefland','mittelgebirge','alpenvorland','katalonien','daenemark'])
  union all select id, 'KAT_LAND', 'FEHLER', 'land=' || coalesce(land, 'NULL') from t where land is null or land <> all(array['DE','DK','ES'])
  union all select id, 'KAT_TAG', 'FEHLER', 'tag=' || tag from tg
    where tag <> all(array['kinderfreundlich','kinderwagentauglich','rollstuhltauglich','hunde-erlaubt','einkehr','spielplatz','picknick','barfusspfad'])
  union all select t.id, 'KAT_LEBENSRAUM', 'FEHLER', 'lebensraum=' || x from t, unnest(t.lebensraeume) x
    where x <> all(array['buchenwald','kuestenwald-kiefer','kiefernforst','eichen-mischwald','auwald','moor','heide','teich-tuempel','see-ufer','fliessgewaesser','salzwiese-watt','duene-strand','streuobst-hecke','nadelforst','alpen-wald','mediterraner-wald','trockenrasen','hof-nutztier'])
  union all select id, 'LEBENSRAUM_ANZAHL', 'FEHLER', 'mehr als 3 Lebensraeume' from t where cardinality(lebensraeume) > 3
  union all select id, 'LEBENSRAUM_LEER', 'WARNUNG', 'keine Lebensraeume (nur ok bei Spielplatz/Geopfad, Grund in field_meta)' from t where cardinality(lebensraeume) = 0
  union all select st.trail_id, 'KAT_ERLEBNIS', 'FEHLER', 'station ' || st.reihenfolge || ': ' || x from st, unnest(st.erlebnisse) x
    where x <> all(array['tafel','quiz','steg','bohrkernmodell','mitmach-modell','memory','bestimmung','audio','barfusspfad'])
  union all select trail_id, 'KAT_AMENITY', 'FEHLER', 'kategorie=' || kategorie from am
    where kategorie <> all(array['wc','parking','bench','picnic','shelter','playground','viewpoint','gastro'])
  union all select tp.trail_id, 'KAT_POI', 'FEHLER', po.id || ': ' || po.kategorie from trail_pois tp join p on p.id = tp.trail_id join pois po on po.id = tp.poi_id
    where po.kategorie <> all(array['cafe','restaurant','hofladen','baden','museum','aktivitaet','camping'])
  union all select trail_id, 'KAT_BILD_LIZENZ', 'FEHLER', 'bild ' || id || ': license=' || license from im
    where license <> all(array['cc-by-sa-4.0','cc-by-sa-3.0','cc-by-sa-2.0','cc-by-4.0','cc-by-3.0','cc-by-2.0','cc0','pd','eigen','freigabe'])
  union all select trail_id, 'KAT_BILD_KIND', 'FEHLER', 'bild ' || id || ': kind=' || coalesce(kind, 'NULL') from im
    where kind is null or kind <> all(array['hero','station'])

  -- 3 Pflichtfelder, NULL
  union all select t.id, 'PFLICHT_LEER', 'FEHLER', f.n || ' ist leer' from t
    cross join lateral (values ('name', t.name), ('kurzbeschreibung', t.kurzbeschreibung), ('beschreibung', t.beschreibung),
      ('markierung', t.markierung), ('betreiber', t.betreiber), ('region', t.region), ('anreise', t.anreise), ('start_name', t.start_name)) f(n, val)
    where coalesce(btrim(f.val), '') = ''
  union all select id, 'PFLICHT_NULL', 'FEHLER', 'laenge_km ist NULL' from t where laenge_km is null
  union all select id, 'PFLICHT_NULL', 'FEHLER', 'dauer_min ist NULL' from t where dauer_min is null
  union all select id, 'PFLICHT_NULL', 'FEHLER', 'start_lat/start_lon fehlt' from t where start_lat is null or start_lon is null
  union all select id, 'ORT_FEHLT', 'WARNUNG', 'bundesland/kreis/ort fehlt' from t where coalesce(bundesland, '') = '' or coalesce(kreis, '') = '' or coalesce(ort, '') = ''
  union all select id, 'MARKIERUNG_PUNKT', 'FEHLER', 'markierung endet auf Punkt' from t where markierung ~ '\.\s*$'
  union all select id, 'REGION_FORMAT', 'WARNUNG', 'region braucht mindestens 2 Teile: Ort, Kreis oder Gebiet' from t where region !~ ','
  union all select id, 'REGION_ALTKREIS', 'FEHLER', 'Altkreis in region: ' || region from t
    where region ~* '(nordvorpommern|ostvorpommern|bad doberan|uecker-randow|mecklenburg-strelitz|nordwestmecklenburg|landkreis m[üu]ritz)'
  union all select id, 'DAUER_RECHNUNG', 'FEHLER', 'field_meta.dauer_min fehlt (Rechnung dokumentieren)' from t where not (field_meta ? 'dauer_min')
  union all select t.id, 'DAUER_FORMEL', 'WARNUNG', 'dauer_min=' || t.dauer_min || ', Formel ergibt ' || (round((t.laenge_km / 2.5 * 60 + (select count(*) from st where st.trail_id = t.id) * 4) / 5) * 5)
    from t where t.form = 'linie' and t.dauer_min is not null and t.laenge_km > 0
      and abs(t.dauer_min - round((t.laenge_km / 2.5 * 60 + (select count(*) from st where st.trail_id = t.id) * 4) / 5) * 5) > 10

  -- 4 Geometrie
  union all select id, 'FLAECHE_AREA', 'FEHLER', 'form=flaeche braucht area mit mindestens 3 Punkten' from t where form = 'flaeche' and jsonb_array_length(area) < 3
  union all select id, 'FLAECHE_LAENGE', 'FEHLER', 'form=flaeche: laenge_km muss 0 und rundkurs false sein' from t where form = 'flaeche' and (coalesce(laenge_km, 0) <> 0 or rundkurs)
  union all select id, 'ROUTE_NICHT_KARTIERT', 'INFO', 'Linie ohne Route (Verlauf nicht kartiert)' from t where form = 'linie' and jsonb_array_length(route) < 2
  union all select id, 'ROUTE_LEER_UNZULAESSIG', 'FEHLER', 'Linie ohne Route, aber Bedingungen fuer "Verlauf nicht kartiert" nicht erfuellt (field_meta.route fehlt oder weniger als 3 Stationen mit eigener Koordinate)' from t
    where form = 'linie' and jsonb_array_length(route) < 2
      and (not (field_meta ? 'route') or (select count(distinct (lat, lon)) from st where st.trail_id = t.id) < 3)
  union all select t.id, 'ROUTE_LAENGE', 'FEHLER', 'Route ' || round(r.km::numeric, 2) || ' km gegen laenge_km ' || t.laenge_km || ' (' || round((100 * abs(r.km - t.laenge_km) / nullif(t.laenge_km, 0))::numeric) || ' %)'
    from t join routelen r on r.id = t.id
    where t.form = 'linie' and t.laenge_km > 0 and abs(r.km - t.laenge_km) / t.laenge_km > 0.10
      and coalesce(t.field_meta->'laenge_km'->>'exakt', '') = 'ja'
  union all select s.trail_id, 'KM_NICHT_MONOTON', 'FEHLER', 'station ' || s.reihenfolge || ': km ' || s.km || ' < Vorgaenger ' || s.pk
    from (select x.*, lag(km) over (partition by trail_id order by reihenfolge) pk from st x) s join t on t.id = s.trail_id
    where jsonb_array_length(t.route) >= 2 and s.pk is not null and s.km < s.pk
  union all select s.trail_id, 'KM_NULL', 'FEHLER', 'station ' || s.reihenfolge || ': km=0 bei vorhandener Route' from st s join t on t.id = s.trail_id
    where jsonb_array_length(t.route) >= 2 and s.reihenfolge > 1 and s.km = 0

  -- 5 Stationen
  union all select id, 'STATIONEN_MIN', 'FEHLER', (select count(*) from st where st.trail_id = t.id) || ' Stationen, mindestens 3' from t where (select count(*) from st where st.trail_id = t.id) < 3
  union all select trail_id, 'STATION_KOORD_DOPPELT', 'FEHLER', 'Stationen ' || string_agg(reihenfolge::text, ',') || ' liegen auf derselben Koordinate'
    from st group by trail_id, lat, lon having count(*) > 1
  union all select s.trail_id, 'STATION_PLATZHALTER', 'FEHLER', 'station ' || s.reihenfolge || ' liegt auf der Startkoordinate' from st s join t on t.id = s.trail_id
    where s.reihenfolge > 1 and s.lat = t.start_lat and s.lon = t.start_lon
  union all select trail_id, 'STATION_OSM_ID', 'FEHLER', 'station ' || reihenfolge || ': osm_id NULL (synthetisch negativ vergeben)' from st where osm_id is null
  union all select trail_id, 'STATION_LEER', 'FEHLER', 'station ' || reihenfolge || ': thema oder kurztext leer' from st where coalesce(btrim(thema), '') = '' or coalesce(btrim(kurztext), '') = ''
  union all select trail_id, 'STATION_SCHABLONE', 'FEHLER', 'station ' || reihenfolge || ': kurztext beginnt mit Die (Info)Tafel' from st where kurztext ~ '^Die (Info|Pult)?[Tt]afel'
  union all select trail_id, 'STATION_ORDINAL', 'FEHLER', 'station ' || reihenfolge || ': Positionsangabe im kurztext' from st
    where kurztext ~* '\m(erste|zweite|dritte|vierte|f[üu]nfte|sechste|siebte|achte|neunte|zehnte|vorletzte|letzte)[nrms]? (Station|Halt|Tafel)\M'
  union all select s.trail_id, 'STATION_STECKBRIEF_TYP', 'FEHLER', 'station ' || s.reihenfolge || ': steckbrief.' || e.key || ' muss JSON-Zahl sein'
    from st s, jsonb_each(coalesce(s.steckbrief, '{}'::jsonb)) e
    where e.key in ('groesseHa', 'alterJahre', 'tiefeM') and jsonb_typeof(e.value) <> 'number'
  union all select a.trail_id, 'STATION_ANFANG', 'WARNUNG', 'mehr als 30 % der kurztexte beginnen mit "' || a.anfang || '"'
    from (select trail_id, (regexp_match(kurztext, '^(\S+\s+\S+)'))[1] as anfang, count(*) c, sum(count(*)) over (partition by trail_id) n
          from st group by 1, 2) a where a.n >= 3 and a.anfang is not null and a.c > 0.3 * a.n
  -- 6 Texte
  union all select id, 'LAENGE_KURZ', 'FEHLER', length(kurzbeschreibung) || ' Zeichen, hoechstens 180' from t where length(kurzbeschreibung) > 180
  union all select id, 'LAENGE_BESCHREIBUNG', 'FEHLER', length(beschreibung) || ' Zeichen, erlaubt 400 bis 650' from t where length(beschreibung) not between 400 and 650
  union all select id, 'LAENGE_BESUCH', 'FEHLER', length(besuchshinweise) || ' Zeichen, hoechstens 280' from t where length(besuchshinweise) > 280
  union all select trail_id, 'BOT_SPRACHE', 'FEHLER', feld || ': "' || (regexp_match(txt, '(nicht belegt|(ist|bleibt|sind|war|waren) unbekannt|unbekannt\.|kein beleg|keine angabe|kontakt:|laut (quelle|titel|angabe)|tafelthema|unsicher|gesch[äa]tzt|vermutlich|stand \d{4}|\(stand|\[(s|q)?\d+|platzhalter|nach dem titel|wie der titel|gro[ßs] und klein|\mTr[äa]ger\M)', 'i'))[1] || '"'
    from nutzer where txt ~* '(nicht belegt|(ist|bleibt|sind|war|waren) unbekannt|unbekannt\.|kein beleg|keine angabe|kontakt:|laut (quelle|titel|angabe)|tafelthema|unsicher|gesch[äa]tzt|vermutlich|stand \d{4}|\(stand|\[(s|q)?\d+|platzhalter|nach dem titel|wie der titel|gro[ßs] und klein)'
       or txt ~ '\mTr[äa]ger\M'
  union all select trail_id, 'HYPE', 'FEHLER', feld || ': "' || (regexp_match(txt, '(atemberaubend|unvergesslich|einzigartig|einmalig|idyllisch|malerisch|traumhaft|spektakul[äa]r|magisch|m[äa]rchenhaft|paradiesisch|naturparadies|highlight|ein muss|f[üu]r jeden etwas|spa[ßs] f[üu]r die ganze familie|eintauchen|auszeit|genuss|oase)', 'i'))[1] || '"'
    from nutzer where prosa and txt ~* '(atemberaubend|unvergesslich|einzigartig|einmalig|idyllisch|malerisch|traumhaft|spektakul[äa]r|magisch|m[äa]rchenhaft|paradiesisch|naturparadies|highlight|ein muss|f[üu]r jeden etwas|spa[ßs] f[üu]r die ganze familie|eintauchen|auszeit|genuss|oase)'
  union all select trail_id, 'ANREDE', 'WARNUNG', feld || ': "' || (regexp_match(txt, '\m(du|dich|dir|dein|deine|deinen|deinem|euch|ihr|Sie|Ihnen|Ihre|Ihren)\M'))[1] || '" (pruefen: direkte Anrede?)'
    from nutzer where prosa and feld <> 'trails.besuchshinweise' and txt ~ '\m(du|dich|dir|dein|deine|deinen|deinem|euch|ihr|Sie|Ihnen|Ihre|Ihren)\M'
  union all select id, 'BESCHREIBUNG_STATIONEN', 'FEHLER', 'beschreibung nennt Station(en): Inventar gehoert nicht hinein' from t where beschreibung ~* '\mStationen?\M'
  union all select id, 'BESUCH_AUSSTATTUNG', 'WARNUNG', 'besuchshinweise nennt ' || x.was || ', Amenity fehlt' from t
    cross join lateral (values ('Bank/Sitzgruppe', '\m(B[äa]nke|Bank|Sitzgruppe)\M', 'bench'), ('Huette/Unterstand', '(H[üu]tte|Unterstand|Schutzh)', 'shelter'),
      ('WC', '\m(WC|Toilette)', 'wc'), ('Spielplatz', 'Spielplatz', 'playground')) x(was, re, kat)
    where t.besuchshinweise ~* x.re and not exists (select 1 from am where am.trail_id = t.id and am.kategorie = x.kat)

  -- 7 Ausstattung und Tags
  union all select id, 'AMENITY_NULL', 'FEHLER', 'keine Ausstattung (mindestens 1: Parkplatz, WC, Bank, Huette, Turm)' from t where not exists (select 1 from am where am.trail_id = t.id)
  union all select trail_id, 'AMENITY_OSM_ID', 'FEHLER', 'amenity ' || id || ': osm_id NULL (synthetisch negativ vergeben)' from am where osm_id is null
  union all select t.id, 'AMENITY_BAENKE', 'WARNUNG', 'mehr als die Haelfte der Ausstattung sind Baenke (Sitzgruppen zusammenfassen)' from t
    where (select count(*) from am where am.trail_id = t.id) > 0 and (select count(*) filter (where kategorie = 'bench') from am where am.trail_id = t.id) * 2 > (select count(*) from am where am.trail_id = t.id)
  union all select id, 'EINKEHR_OHNE_GASTRO', 'FEHLER', 'Tag einkehr ohne Amenity gastro (Karte zeigt das Merkmal nur mit gastro)' from t
    where 'einkehr' = any(tags) and not exists (select 1 from am where am.trail_id = t.id and kategorie = 'gastro')
  union all select id, 'GASTRO_OHNE_TAG', 'WARNUNG', 'Amenity gastro ohne Tag einkehr' from t
    where not ('einkehr' = any(tags)) and exists (select 1 from am where am.trail_id = t.id and kategorie = 'gastro')
  union all select id, 'SPIELPLATZ_TAG', 'WARNUNG', 'Tag spielplatz und Amenity playground passen nicht zusammen' from t
    where ('spielplatz' = any(tags)) <> exists (select 1 from am where am.trail_id = t.id and kategorie = 'playground')
  union all select id, 'PICKNICK_TAG', 'WARNUNG', 'Tag picknick ohne Amenity picnic oder bench' from t
    where 'picknick' = any(tags) and not exists (select 1 from am where am.trail_id = t.id and kategorie in ('picnic', 'bench'))
  union all select id, 'TAGS_LEER', 'WARNUNG', 'keine Tags (kinderfreundlich nur mit Beleg, sonst Grund in field_meta.tags)' from t where cardinality(tags) = 0

  -- 8 Arten
  union all select id, 'ARTEN_ANZAHL', 'FEHLER', (select count(*) from ts where ts.trail_id = t.id) || ' Arten, erlaubt 8 bis 16' from t where (select count(*) from ts where ts.trail_id = t.id) not between 8 and 16
  union all select id, 'ARTEN_FLORA', 'WARNUNG', (select count(*) from ts where ts.trail_id = t.id and kategorie = 'flora') || ' Flora, Ziel mindestens 4' from t where (select count(*) from ts where ts.trail_id = t.id and kategorie = 'flora') < 4
  union all select id, 'ARTEN_FAUNA', 'WARNUNG', (select count(*) from ts where ts.trail_id = t.id and kategorie = 'fauna') || ' Fauna, Ziel mindestens 6' from t where (select count(*) from ts where ts.trail_id = t.id and kategorie = 'fauna') < 6
  union all select id, 'ARTEN_SYNC', 'FEHLER', 'trails.arten (' || cardinality(arten) || ') passt nicht zu trail_species (' || (select count(*) from ts where ts.trail_id = t.id) || '). trails.arten nie von Hand schreiben' from t
    where cardinality(arten) <> (select count(*) from ts where ts.trail_id = t.id)
  union all select id, 'ARTEN_SORTIERUNG', 'WARNUNG', 'sortierung hat Luecken oder Doppelte' from t
    where (select count(*) from ts where ts.trail_id = t.id) > 0 and (select count(distinct sortierung) from ts where ts.trail_id = t.id) <> (select count(*) from ts where ts.trail_id = t.id)

  -- 9 Quellen, Orte, Bilder
  union all select id, 'QUELLEN_LEER', 'FEHLER', 'keine trail_sources' from t where not exists (select 1 from trail_sources q where q.trail_id = t.id)
  union all select q.trail_id, 'QUELLE_UNVOLLSTAENDIG', 'WARNUNG', 'quelle ' || q.id || ' (Abschnitt ' || q.abschnitt || '): url oder abgerufen_am fehlt'
    from trail_sources q join p on p.id = q.trail_id where coalesce(q.url, '') = '' or q.abgerufen_am is null
  union all select t.id, 'QUELLEN_ABSCHNITT', 'WARNUNG', 'keine Quelle fuer Abschnitt ' || a from t, generate_series(1, 4) a
    where not exists (select 1 from trail_sources q where q.trail_id = t.id and q.abschnitt = a)
  union all select id, 'POIS_LEER', 'WARNUNG', 'keine Orte in der Naehe und kein field_meta.pois (Pruefung dokumentieren)' from t
    where not exists (select 1 from trail_pois tp where tp.trail_id = t.id) and not (field_meta ? 'pois')
  union all select tp.trail_id, 'POI_KURZTEXT', 'WARNUNG', 'poi ' || po.id || ': kurztext leer' from trail_pois tp join p on p.id = tp.trail_id join pois po on po.id = tp.poi_id
    where coalesce(btrim(po.kurztext), '') = ''
  union all select trail_id, 'BILD_STATION_OHNE_ID', 'FEHLER', 'bild ' || id || ': kind=station ohne station_id' from im where kind = 'station' and station_id is null
  union all select trail_id, 'BILD_CREDIT', 'FEHLER', 'bild ' || id || ': credit leer' from im where coalesce(btrim(credit), '') = ''
  union all select trail_id, 'BILD_HERO_KLEIN', 'WARNUNG', 'bild ' || id || ': Hero kleiner als 2000 px an der langen Kante' from im
    where kind = 'hero' and greatest(coalesce(width, 0), coalesce(height, 0)) < 2000
  union all select trail_id, 'BILD_GEO', 'WARNUNG', 'bild ' || id || ': geo_check=' || coalesce(geo_check, 'NULL') || ' (Ortsbeleg in caption oder field_meta.bilder)' from im
    where coalesce(geo_check, 'none') in ('none', 'far')
  union all select id, 'BILD_HERO_FEHLT', 'INFO', 'kein Hero-Bild (ohne Pfadmotiv bleibt bilder leer, Begruendung in field_meta.bilder)' from t
    where not exists (select 1 from im where im.trail_id = t.id and kind = 'hero')
)
select * from v order by trail_id, case schwere when 'FEHLER' then 0 when 'WARNUNG' then 1 else 2 end, code, detail;
