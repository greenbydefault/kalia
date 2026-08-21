# Naturlehrpfad Hullerbusch / Hauptmannsberg – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `hullerbusch` |
| Name | Naturlehrpfad Hullerbusch und Hauptmannsberg |
| `typ` | `wald` |
| `form` | `linie` |
| Region | Carwitz / Hullerbusch / Wittenhagen, Naturpark Feldberger Seenlandschaft |
| Länge | 6 km Rundweg (OSM Rel); Literatur 4–6 km je nach Ast Schäferei vs. lang |
| `dauerMin` | 150 |
| `rundkurs` | true |
| `markierung` | Naturlehrpfad-Wegweiser (2023–2026 erneuert) |
| `betreiber` | Naturpark Feldberger Seenlandschaft |
| `website` | https://www.nordkurier.de/regional/neustrelitz/zwischen-teufelsstein-und-kesselmoor-modernes-wandern-im-hullerbusch-4441941 |
| `startName` | Parkplatz Fuß Hauptmannsberg / Carwitz |
| OSM | Rel [`9082794`](https://www.openstreetmap.org/relation/9082794) · Start-Board [`4874943445`](https://www.openstreetmap.org/node/4874943445) · Peak [`320742133`](https://www.openstreetmap.org/node/320742133) · Teufelsstein [`434649534`](https://www.openstreetmap.org/node/434649534) |
| BBox | 13.439–13.459 / 53.305–53.328 |

Eiszeitlehrpfad Wittenhagen: **dieselbe Landschaftsrunde**, kein zweiter Seed.

Luzinfähre (handbetriebene Seilfähre): Saison-Amenity / Anreise-Tipp, nicht Stationspflicht.

## Texte (Config)

**kurzbeschreibung:** Rundweg über Hauptmannsberg und Hullerbusch – 13 Tafeln, Kesselmoor-Steg, Teufelsstein. Frei, 2023ff. erneuert.

**beschreibung:** Zwischen Carwitzer See, Zansen und Schmalem Luzin liegt der modernisierte Naturlehrpfad. Start typisch: Parken am Fuß des Hauptmannsbergs in Carwitz, hinauf zur Aussicht, dann zum Zansen, Schäferwiese, optional kurz über die Schäferei oder lang durch den Hullerbusch. 13 Informationstafeln, Sitzbänke mit Dachs-/Pilz-/Sonnentau-Relief, Schutzhütte, Moorsteg ins Kesselmoor (EU-Mittel, Steg allein ~55.000 €). Der Teufelsstein ist ein Findling mit Tafel. Naturpark-Leiterin: kein Spielplatz, kein Tastpfad – Natur zuerst, Kinder sollen sich trotzdem nicht langweilen (Brettspiel an der Schäferei, Figuren selbst sammeln). Nicht kinderwagen- oder rollstuhltauglich (Steilhänge). Frei, kein Ticket. Gästebuch am Weg. Hotel/Schäferladen Hullerbusch = Einkehr optional.

**anreise:** Auto: Carwitz, Parkplatz am Fuß des Hauptmannsbergs (OSM parking Ways `457680599`, `1155984990`, `250777731` nahe 53.305, 13.441). Saison: Anreise Feldberg + Luzinfähre über den Schmalen Luzin. Bus in die Feldberger Seenlandschaft, dann Fußweg.

**tags:** `kinderfreundlich`, `picknick`, `einkehr`, `hunde-erlaubt`

Nicht: `kinderwagentauglich`, `rollstuhltauglich`.

## Geometrie

Rundkurs Rel 9082794. Empfohlene Seed-Richtung: Carwitz-Parkplatz → Hauptmannsberg → Schäferwiese → Hullerbusch-Tafel → Waldgeschichte → Kesselmoor → Teufelsstein → zurück über Luzin-Ufer/Pflaster (Literatur). Ways u. a. `151051802`, `1302586359` Hullerbusch.

## Stationen

| slug | lat | lon | OSM | titel | thema | erlebnisse | barrierefrei | Quelle |
|---|---|---|---|---|---|---|---|---|
| start-nsg | 53.3056144 | 13.4410754 | n4933401303 | Naturschutzgebiet Hauptmannsberg | Einstieg Carwitz | tafel | false | OSM Board |
| hauptmannsberg | 53.3082835 | 13.4428084 | n320742133 / n14089666111 | Hauptmannsberg | Aussicht Carwitzer See | tafel | false | Peak + Board „Geschichte des Hauptmannberges“ 53.3081593, 13.443112 |
| magerasen | 53.3081844 | 13.4431115 | n14089640722 | Mager- und Trockenrasen | Offenland | tafel, bestimmung | false | OSM Board |
| spurensuche | 53.3117247 | 13.443129 | n14089735303 | Auf Spurensuche | Wild / Boden | tafel, bestimmung | false | OSM Board |
| seen | 53.3134433 | 13.4447416 | n6924781515 | Seen der Feldberger Seenlandschaft | Zansen-Blick | tafel | false | OSM Board + viewpoint n336751153 |
| schaeferwiese | 53.3151891 | 13.4450432 | n14089732235 | Die Schäferwiese | Weide, Brettspiel-Nähe | tafel | false | OSM Board |
| start-huller | 53.3219789 | 13.4435602 | n4874943445 | Naturlehrpfad Hullerbusch | Dorf Hullerbusch / Fähre | tafel | false | OSM Board |
| waldgeschichte | 53.3197959 | 13.4503852 | n14089738514 | Waldgeschichte des Hullerbuschs | Waldwandel | tafel | false | OSM Board |
| kesselmoor | 53.3255356 | 13.4548817 | n14089744650 | Das Kesselmoor | Eiszeit, Sonnentau, Steg | tafel, steg | false | OSM Board |
| huehnenfriedhof | 53.3215916 | 13.454988 | n13712489099 | Hühnenfriedhof | Blockpackung / Sage | tafel | false | OSM Board |
| teufelsstein | 53.3220247 | 13.4585681 | n13712533301 / n434649534 | Der Teufelsstein | Findling | tafel | false | OSM Board + natural=stone |
| pilze | 53.3236047 | 13.4579237 | n14089764549 | Im Reich der Pilze | Totholz | tafel, bestimmung | false | OSM Board |
| huenenwall | 53.327708 | 13.4493371 | n4874943452 | Der Hünenwall | Satzendmoräne | tafel | false | OSM Board |
| geotopf | 53.326556 | 13.4418616 | n13123343613 | Nationaler Geotop | Feldberger Seenlandschaft | tafel | false | OSM Board |

Seed-Minimum: start-nsg, hauptmannsberg, schaeferwiese, kesselmoor, teufelsstein, pilze.

**kurztexte:**

- start-nsg: Unten am Berg. Tafel zum Schutzgebiet, dann hoch – der See kommt später ins Bild.
- hauptmannsberg: Endmoräne, Blick auf den Carwitzer See. Geschichte des Berges auf der Nachbartafel.
- magerasen: Trocken, mager, blütenreich wenn die Pflege stimmt. Nicht betreten, vom Weg lesen.
- spurensuche: Suhle, Schalen, Kot – Wildschwein und Reh schreiben auf den Boden.
- seen: Zansen und Schmaler Luzin sind Rinnenseen der Eiszeit. Vom Hang wirkt das Wasser schmal und tief.
- schaeferwiese: Offenland, Schafe, Rast. Literatur: Schnitzerei und Brettspiel – Figuren aus der Umgebung, kein Spielplatz-Set.
- start-huller: Siedlung Hullerbusch, Luzinfähre in der Saison. Hier teilt sich oft kurz und lang.
- waldgeschichte: Wer hier holzte, jagte, aufforstete. Der Hullerbusch ist Kultur und Wildnis in einem Satz.
- kesselmoor: Toteisloch, Steg, Sonnentau winzig und selten. Moor trocknet – Birken rücken nach. Bleib auf dem Steg.
- huehnenfriedhof: Blockpackung, Sage, kein Friedhof zum Buddeln.
- teufelsstein: Findling mit Schrammen. Die Tafel erklärt Eis, nicht den Teufel – die Schrammen bleiben trotzdem unheimlich.
- pilze: Totholz als Speisekammer. Bestimmen ohne zu pflücken.
- huenenwall: Satzendmoräne, Eiszeit im Anschnitt. Nicht mit dem Hühnenfriedhof verwechseln.
- geotopf: Einordnung der ganzen Seenplatte als Geotop – Abschluss am Luzin.

## Amenities

| OSM | lat | lon | kategorie | name |
|---|---|---|---|---|
| w1155984990 / w457680599 | ~53.305 | ~13.441 | parking | Carwitz / Hauptmannsberg |
| n897625559 | 53.3220789 | 13.4435392 | parking | Hullerbusch |
| n7158168076 | 53.3246191 | 13.4420809 | shelter | Hullerbusch |
| n336751148 | 53.3134258 | 13.444716 | shelter | Hauptmannsberg |
| n7804797229 | 53.3259406 | 13.4412126 | gastro | Fährladen |
| w154995558 | — | — | gastro | Hotel Hullerbusch |
| n14032064574 | 53.303238 | 13.4432586 | wc | Carwitz (am Parkplatz-Komplex) |

## Arten

| nameDe | Status | vor Ort |
|---|---|---|
| Kiefer | in `species.json` | Wald |
| Stieleiche | in `species.json` | Wald |
| Torfmoos | in `species.json` | Kesselmoor |
| Wollgras | in `species.json` | Moor (Restvorkommen) |
| Knabenkraut | in `species.json` | Feucht/Trockenrand – nur wenn Tafel/Habitat passt; sonst weglassen |
| Rotbuche | **neu** flora | Hullerbusch-Hang |
| Sonnentau | **neu** flora | Kesselmoor, schwer zu sehen |
| Dachs | **neu** fauna | Bänke/Thema, Sicht selten |

## Go / No-Go

**Go:** frei, Rel, viele benannte OSM-Tafeln nach Sanierung.

**No-Go:** Hotelgelände als Trail; Fähre als Pflicht; Wittenhagen als zweiter Seed.

## Pipeline

1. Rel 9082794 → `tools/osm/hullerbusch_route.json`
2. Config `tools/trails/hullerbusch.json`
3. `build_seed.py` → validate
