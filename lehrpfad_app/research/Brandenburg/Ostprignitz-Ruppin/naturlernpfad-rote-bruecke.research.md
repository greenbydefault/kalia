# Naturlernpfad Rote Brücke – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `naturlernpfad-rote-bruecke` |
| Name | Naturlernpfad Rote Brücke |
| `typ` | `walderlebnispfad` |
| `form` | `linie` |
| Region | Heiligengrabe, Stiftswald, Ostprignitz-Ruppin |
| Adresse | Zur Roten Brücke / Stiftswald, 16909 Heiligengrabe |
| Länge | 2,9 km; Gemeinde: 9 Stationen; Reiseland: 20 Bilderrahmen + Tafeln |
| Zugang | ganzjährig frei, ohne Anmeldung; Führungen Förster optional |
| Status | **OPEN** – kein Seed in dieser Runde |
| OSM | Geometrie fehlt (keine Hiking-Rel unter dem Namen) |

Quelle: [`_kandidaten.md`](_kandidaten.md). Filter: [`README.md`](../../../README.md).

## Filter / Abgrenzung

| Ort | Einstufung |
|---|---|
| Naturlernpfad Rote Brücke (Stiftswald, Mitmach + Bilderrahmen) | **GO** |
| Nonnenpfad 17 km | **NOGO** als eigener Trail — Themenrunde, Kern = dieser Pfad |
| Waldolympiade / Waldrallye / Klassenzimmer Wald | Buchung, nicht Scope |
| Kloster Stift Ausstellung / Eintritt | nicht Scope |

Tag `barfusspfad` an Station Barfußstrecke, nicht `typ: barfusspfad`.

## Geometrie

- `form: linie`, Rundweg Stiftswald / Nadelbach
- OSM-Rel/Way für den Pfad: **fehlt** — vor Seed Overpass BBox Heiligengrabe + Betreiberkarte
- Start: Straße nach Heidelberg / Zur Roten Brücke

## Stationen (≥3)

Gemeinde: 9 Stationen. Reiseland/Stift: 20 Bilderrahmen mit je einer Erläuterungstafel. Genannte Mitmach- und Rahmen-Themen:

1. Labyrinth
2. Baumtelefon
3. Tierweitsprunganlage
4. Barfußstrecke
5. Bilderrahmen Mehrgenerationenwald / Pflugstreifen
6. Bilderrahmen Zukunftsbaum / Rückegasse
7. Bilderrahmen Waldbach / Totholz
8. Bilderrahmen Fitnessarena / Schulwald
9. Bilderrahmen Buchenunterbau (Klimawandel)

GPS der Einzelstationen öffentlich nicht gelistet — vor Seed Feld oder Flyer-Karte.

## Arten

Wald/Forstthemen belegt (Totholz, Buche, Waldbach). Keine belastbare Artenliste auf den Betreiberseiten — nicht erfinden. Seed: aus Tafeltexten / `species.json` nachziehen.

## Quellen

- https://www.heiligengrabe.de/verzeichnis/visitenkarte.php?mandat=54944
- https://www.klosterstift-heiligengrabe.de/kloster/stiftsforst/erholung/
- https://www.reiseland-brandenburg.de/poi/prignitz/gaerten-und-parkanlagen/naturlernpfad-rote-bruecke/

## Pipeline

Nächster Schritt: OSM-BBox + Stations-GPS → `tools/trails/naturlernpfad-rote-bruecke.json` → `build_seed.py`. **Nicht** in dieser Runde.
