# Natur- und Lehrpfad Tornowsee – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `tornowsee` |
| Name | Rundwanderweg / Natur- und Lehrpfad Tornowsee |
| `typ` | `wald` |
| `form` | `linie` |
| Region | Neuruppin OT Gühlen-Glienicke, Ruppiner Schweiz, Ostprignitz-Ruppin |
| Start | Parkplatz Boltenmühle, Boltenmühle 1, 16818 Neuruppin |
| Länge | ca. 8 km Rundweg |
| Zugang | frei; Start Parkplatz Boltenmühle |
| Status | **OPEN** – Tafel-Titel öffentlich dünn, Seed erst mit GPS der 6 Infotafeln |
| OSM | Ways `Natur-und Lehrpfad` um 53.02–53.03, 12.74–12.76 (u. a. [32637017](https://www.openstreetmap.org/way/32637017)); eine Brücke `access=no` (baufällig) |

Quelle: [`_kandidaten.md`](_kandidaten.md). Filter: [`README.md`](../../../README.md).

## Filter / Abgrenzung

| Ort | Einstufung |
|---|---|
| Wald-/Lehrpfad um den Tornowsee, 6 Infotafeln | **GO** (Stationen-GPS fehlt) |
| Boltenmühle Gastro / Wellness / Spielplatz / Eselwiese | Amenity, nicht Scope |
| Naturlehrpfad Tornower See bei Teupitz | **anderer Kreis** (Dahme-Spreewald) |

## Geometrie

- `form: linie`, Rundkurs ~8 km
- OSM-Ways vorhanden, Rel fehlt; Brücke `access=no` vor Seed prüfen (Umgehung)
- Markierung: 18 Wegweiser, keine durchgehende Wegemarkierung (Reiseland)

## Stationen (≥3)

Reiseland: Übersichtstafel am Start + **6 Infotafeln** am Weg, Titel nicht online. Landschaftsanker aus derselben Quelle:

1. Start Boltenmühle — Übersichtskarte / Streckenverlauf
2. Zanderblick — Aussicht auf den See
3. Quellen an den Hanglagen / Binenbach-Mündung
4. Kunster-Mündung

Tafeltexte und exakte GPS: vor Seed Feld oder Flyer. Ohne die 6 Tafel-Titel bleibt die Go-Bar für den Seed knapp.

## Arten

Buche, Nadel-/Mischwald (Reiseland). Tiere „mit etwas Glück“ — nicht als `arten[]` erfinden.

## Quellen

- https://www.reiseland-brandenburg.de/poi/ruppiner-seenland/wandertouren/rundwanderweg-um-den-tornowsee/

## Pipeline

Nächster Schritt: OSM-Ways stitchen, baufällige Brücke klären, 6 Tafeln GPS → Config. **Nicht** in dieser Runde.
