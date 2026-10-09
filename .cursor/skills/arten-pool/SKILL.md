---
name: arten-pool
description: >-
  Hängt Flora und Fauna an einen Trail über den Arten-Pool (Lebensraum × Naturraum),
  nicht freihändig. Legt fehlende Arten als Kurzprofil an.
  Use when the user asks for Arten, Flora, Fauna, Lebensraum, Naturraum, or a species pool on a trail.
---

# Arten-Pool

cwd: `lehrpfad_app/`. `tools/` ist gitignored — `Read` auf den Pfad. Spec: `tools/SPECIES_CONTENT.md`. Modell: `docs/datenmodell.md`.

Die App kennzeichnet `belegt` und `typisch` nicht. Sortierung und Cap nutzen die Stufe intern.

## 1. Tags

`lebensraeume`: 1–3 Keys aus `datenmodell.md` (`kuestenwald-kiefer`, `buchenwald`, `eichen-mischwald`, `kiefernforst`, `auwald`, `moor`, `heide`, `streuobst-hecke`, `teich-tuempel`, `fliessgewaesser`, `see-ufer`, `salzwiese-watt`, `duene-strand`, `trockenrasen`, `nadelforst`, `hof-nutztier`, `mediterraner-wald`, `alpen-wald`).

`naturraum`: `nordsee`, `ostsee`, `norddt-tiefland`, `mittelgebirge`, `alpenvorland`, `katalonien`, `daenemark`. Vorschlag: `tools/naturraum.py` (Küstenabstand, dann Zone). Wort „Dänemark“ oder „Alpen“ im Text ist kein Standort.

Wasserspielplatz, Geo- und Steinpfad: `lebensraeume` leer. Keine erfundenen Tiere.

Neuer Lebensraum oder neue Region: zuerst Pool-Zeile, dann Trail.

## 2. Vorschlag

```
python3 tools/arten_vorschlag.py --trail <id>
python3 tools/arten_vorschlag.py --trail <id> --gbif
python3 tools/arten_vorschlag.py --apply
```

Pool-Match: Lebensraum des Trails steckt im Pool und `naturraum` in `naturraeume`. Nur Küste (`ostsee`/`nordsee`) fällt auf `norddt-tiefland` zurück.

Cap: bestehende Flora/Fauna bleiben. Nacht (`sichtbarkeit: nacht`) nur wenn der Text Fledermaus, Nacht, Eule oder Kauz trägt, oder die Art übers Stationsthema gepinnt ist. Sortierung: Pin, dann Defizit (Flora &lt; 4, Fauna &lt; 6), dann Rolle leit &lt; typisch &lt; bonus. Weich 14, hart 16. Geräte zählen nicht mit und bleiben stehen.

`artenNachweis`: Bestand und Stations-Pin = `belegt`. Rest = `typisch`. `--apply` wirft vorher alles mit `typisch` raus und rechnet neu, damit eine falsche Zone nicht kleben bleibt.

GBIF 25 km ist nur „im Umkreis gesehen?“, nie die Quelle. Report: `research/arten-pool-report.md`.

## 3. Neue Art

Lücke (im Pool oder als Beleg genannt, nicht in `species.json`) → nicht von Hand.

```
python3 tools/art_anlegen.py
```

Kandidaten stehen in `tools/art_katalog_data.py`. Das Skript holt GBIF-Taxonomie und ein Commons-Bild (CC0/CC-BY/CC-BY-SA), schreibt Kurzprofil (`tiefe: kurz`) und `assets/seed/art_pools.json`. Hörtext bleibt leer. Hörtext später nur für Highlights, Skill `audio-art`, Trello-Sammelkarte Flora/Fauna.

Mensch prüft den Kurzprofil-Entwurf. Pool-Review pro Lebensraum × Naturraum ist der Schritt, der nicht automatisch ist.

## 4. Validate und DB

```
python3 tools/validate_seeds.py
```

Exit 0. Dünn (Flora &lt; 4 oder Fauna &lt; 6) ist eine Info, kein Abbruch. Spielplätze bleiben dünn.

Migration `supabase/migrations/0026_arten_pool.sql` muss auf dem Projekt liegen, bevor die App `lebensraeume` und `naturraum` aus Supabase liest. Danach `python3 tools/seed_supabase.py assets/seed/<id>.json` (braucht `SUPABASE_URL` und `SUPABASE_SERVICE_KEY`).

Done: Pool-Treffer im Seed, Lücken im Katalog, Validator grün, `nachweis` gesetzt.
