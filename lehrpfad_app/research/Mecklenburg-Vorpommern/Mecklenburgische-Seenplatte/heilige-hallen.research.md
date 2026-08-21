# Heilige Hallen – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `heilige-hallen` |
| Name | Heilige Hallen |
| `typ` | `wald` |
| `form` | `linie` |
| Region | Lüttenhagen, Feldberger Seenlandschaft, Mecklenburgische Seenplatte |
| Länge | 5,7 km Rundtour (Tourismusverband; Höhenmeter 18) |
| `dauerMin` | 120 |
| `rundkurs` | true |
| `markierung` | Wanderweg Heilige Hallen / lokale Forst-Wegweisung |
| `betreiber` | Forstamt / Naturpark Feldberger Seenlandschaft (NSG seit 1938; Schonung seit ~19. Jh.) |
| `website` | https://www.mecklenburgische-seenplatte.de/wandertour-heilige-hallen |
| `startName` | Wanderparkplatz Ortsausgang Lüttenhagen (L 341) |
| OSM | Attraction [`2320465249`](https://www.openstreetmap.org/node/2320465249) · Parkplatz Way [`234766592`](https://www.openstreetmap.org/way/234766592) · Board [`2429041495`](https://www.openstreetmap.org/node/2429041495) · Lehrpfad-Board [`2429041428`](https://www.openstreetmap.org/node/2429041428) · NSG Rel [`12662886`](https://www.openstreetmap.org/relation/12662886) · Paradiesgarten [`14040235616`](https://www.openstreetmap.org/node/14040235616) |
| BBox | 13.372–13.386 / 53.323–53.339 |

Waldmuseum **Lütt Holthus**: Eintritt → **nicht Scope**. Führungen Forstamt Juli/August optional.

## Texte (Config)

**kurzbeschreibung:** Alter Buchenwald als Totalreservat bei Lüttenhagen – Pfad durch Wildnis, Arboretum Paradiesgarten am Start. Frei, Museum extra.

**beschreibung:** Großherzog Georg ließ den hallenartigen Buchenwald schonen; 1908 Naturdenkmal, heute NSG und Referenzwald ohne Bewirtschaftung. Die „Hallen“ aus 350-jährigen Säulen sind teilweise zusammengebrochen – Jungbuchen und Totholz bestimmen das Bild. Tour: Parkplatz Lüttenhagen → Paradiesgarten (Arboretum, 19. Jh., wieder gepflegt) → alte Pflasterstraße ca. 2 km → Infotafel Schutzgebiet → 1,5 km Pfad quer durchs Reservat → Forstweg zurück. Daneben OSM-Baumlehrpfad/Obstbaum-Lehrpfad am Parkplatz (Ways `1258341178`, `1258341179`, `581872266`) – dem Trail zuschlagen als Stationen, nicht als zweiter Ort. Frei, kein Ticket für Wald und Arboretum. Wege nicht verlassen. Bus 619 Haltestelle Lüttenhagen–Museum (Museum selbst raus).

**anreise:** Auto: L 341, Wanderparkplatz Ortsausgang Lüttenhagen (Way 234766592, ~53.3336, 13.3725). Bus 619 Neustrelitz–Feldberg, Halt Lüttenhagen Museum, dann zum Parkplatz/Wald.

**tags:** `kinderfreundlich`, `hunde-erlaubt`

## Geometrie

Rundkurs laut GPX der Destinationsseite (gps-track_heilige_hallen.gpx). OSM hat **keine** Hiking-Relation mit dem Namen; Route kuratieren: Parkplatz → Pflaster → Board 2429041428 (53.3328793, 13.3847518) → Pfad durch NSG → zurück. Baumlehrpfad-Ways am Start in die erste Schleife oder als Station Paradiesgarten.

## Stationen

| slug | lat | lon | OSM | titel | thema | erlebnisse | barrierefrei | Quelle |
|---|---|---|---|---|---|---|---|---|
| parkplatz | 53.33360 | 13.37252 | w234766592 | Wanderparkplatz Lüttenhagen | Start | tafel | false | OSM parking |
| paradiesgarten | 53.3338778 | 13.3727533 | n14040235616 | Paradiesgarten | Arboretum | tafel, bestimmung | false | OSM Board |
| wanderweg-tafel | 53.3334458 | 13.3725761 | n2429041495 | Wanderweg Heilige Hallen | Orientierung | tafel | false | OSM Board |
| baumlehrpfad | 53.3341863 | 13.3748208 | w1258341178 | Baumlehrpfad | Gehölze am Rand | tafel, bestimmung | false | OSM path (Zentrum Way) |
| nsg-tafel | 53.3328793 | 13.3847518 | n2429041428 | Lehrpfad Heilige Hallen | Fakten Schutzgebiet | tafel | false | OSM Board |
| reservat | 53.3337101 | 13.3726561 | n2320465249 | Im Totalreservat | Buchen-Wildnis | tafel | false | Attraction-Node am Eingang; **Pfadmitte redaktionell** entlang Route Richtung 13.38 – beim Seed auf Polyline schieben, nicht den Eingangs-Node doppelt nutzen |

Für Seed die Station `reservat` **nicht** auf denselben Punkt wie Start legen. Redaktionell auf der Strecke zwischen wanderweg-tafel und nsg-tafel, z. B. 53.3332, 13.3785 (Mitte Pflaster/Pfad, *redaktionell / nicht OSM-Tafel*).

Zusatz-Kurzstation:

| slug | lat | lon | OSM | titel | thema | erlebnisse | barrierefrei | Quelle |
|---|---|---|---|---|---|---|---|---|
| totholz | 53.3332 | 13.3785 | — | Totholz und Jungbuchen | Hallen zerfallen | tafel | false | redaktionell auf Route |

**kurztexte:**

- parkplatz: Ortsausgang, kostenlos parken. Gegenüber der Straße liegt der Wald, den niemand mehr aufräumt.
- paradiesgarten: Arboretum des alten Oberförsters, wieder in Pflege. Exoten und Heimische – bestimmen, nicht pflücken.
- wanderweg-tafel: Die Runde ist ausgeschildert. Pflasterstraße zuerst, dann quer durchs Reservat.
- baumlehrpfad: Kurzer Lehrbogen am Rand, bevor es in die Wildnis geht.
- nsg-tafel: Schutzgeschichte, Totalreservat, was erlaubt ist: gucken, Weg bleiben.
- totholz: Die Säulenhallen kippen. Dazwischen stehen junge Buchen. Das ist kein Schaden, das ist der Plan seit 160 Jahren ohne Axt.
- reservat: Kern des NSG. Referenzwald – so sähe vieles aus, wenn wir aufhören zu wirtschaften.

## Amenities

| OSM | lat | lon | kategorie | name |
|---|---|---|---|---|
| w234766592 | 53.33360 | 13.37252 | parking | Wanderweg Heilige Hallen |
| n2429041429 | 53.3332054 | 13.3729713 | shelter | am Parkplatz |
| n3514977296 | 53.3337259 | 13.3726569 | shelter | am Parkplatz |
| n3673682137 | 53.3380866 | 13.3834323 | playground | Dorf (Amenity, nicht Ort) |

WC/Gastro: Museum/Forstamt – nicht als Spontan-Amenity ohne Beleg.

## Arten

| nameDe | Status | vor Ort |
|---|---|---|
| Kiefer | in `species.json` | Mischwald Anmarsch |
| Stieleiche | in `species.json` | Rand |
| Igel | in `species.json` | Unterholz |
| Rote Waldameise | in `species.json` | Waldboden |
| Rotbuche | **neu** flora | Kern des Reservats |
| Wollgras | in `species.json` | Kesselmoor/Bruch laut Wanderbeschreibungen |

## Go / No-Go

**Go:** Wald+Arboretum frei; ≥3 Stationen mit GPS (Parkplatz, Paradiesgarten, NSG-Tafel + redaktionell Totholz).

**No-Go:** Lütt Holthus als Station; geführte Sommerwanderung als Pflicht.

## Pipeline

1. GPX Destinationsseite + OSM-Ways Baumlehrpfad → `tools/osm/heilige-hallen_route.json` (kuratiert, keine Hiking-Rel)
2. Config `tools/trails/heilige-hallen.json`
3. `build_seed.py` → validate
