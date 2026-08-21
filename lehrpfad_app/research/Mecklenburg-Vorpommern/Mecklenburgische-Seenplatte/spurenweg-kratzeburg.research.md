# Spurenweg Kratzeburg – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `spurenweg-kratzeburg` |
| Name | Spurenweg Kratzeburg |
| `typ` | `sinnespfad` |
| `form` | `linie` |
| Region | Kratzeburg–Dambeck, Mecklenburgische Seenplatte, NP Müritz |
| Länge | 3,5 km Rundweg |
| `dauerMin` | 90 |
| `rundkurs` | true |
| `markierung` | Spuren-Weg; taktile Baumstämme rechts am Boden, Relief-Tafeln |
| `betreiber` | Nationalparkamt Müritz |
| `website` | https://www.mueritz-nationalpark.de/erleben-erholen/aktiv-in-der-natur/erlebnispfade/spurenweg-kratzeburg |
| `startName` | Ortsausgang Kratzeburg Richtung Dalmsdorf / Dambeck |
| OSM | Rel [`1099709`](https://www.openstreetmap.org/relation/1099709) · Ways `Spuren-Weg` u. a. [`68286926`](https://www.openstreetmap.org/way/68286926) · Start-Board [`832379444`](https://www.openstreetmap.org/node/832379444) |
| BBox | 12.932–12.939 / 53.429–53.442 |

Flatterhus / Fledermausausstellung Kratzeburg: **nicht Scope**. Brailleheft leihen optional.

## Texte (Config)

**kurzbeschreibung:** Barrierefreier Rundweg zwischen Kratzeburg und Dambeck – Spuren von Mensch und Natur, taktil markiert, frei begehbar.

**beschreibung:** Der SpurenWeg folgt dem, was Menschen im Wald hinterlassen haben – und dem, was die Natur daraus macht. Betonfundamente aus den 1950ern tragen Moose und Flechten. Alte Siedlungsplätze sind heute Revier von Greifvögeln und Füchsen. Schrift am Stamm bleibt, weil der Baum weiterwächst. Stationen kommentieren das mit Zitaten von Anwohnern. Der Rundweg ist 3,5 km, barrierearm und für Kinderwagen gedacht; für blinde Menschen mit Begleitung: Reliefkarte am Start, Braille, Wegmarkierung als waagerechte Stämme knapp über dem Boden. Start Ortsausgang Kratzeburg Richtung Dalmsdorf (ca. 400 m vom Bahnhof). In Dambeck Pause möglich, zweite Infotafel, Rückweg mit weiteren Stationen. Frei, ganzjährig Outdoor. Hunde an der Leine.

**anreise:** Bahn: RE Berlin–Rostock, Bahnhof Kratzeburg, 400 m Fußweg Richtung Dalmsdorf/Dambeck. Auto: B 193 Neustrelitz–Penzlin, Abzweig Kratzeburg, kostenlose Parkplätze im Ort. Rad: ab Neustrelitz-Tannenhof „Gelber Radfahrer“, ca. 13 km.

**tags:** `kinderfreundlich`, `kinderwagentauglich`, `rollstuhltauglich`, `hunde-erlaubt`, `picknick`

## Geometrie

Rundkurs Rel 1099709 (10 members, `roundtrip=yes`). Start Board n832379444 (53.4295435, 12.9379185) nördlich des Orts, dann Ways nach Dambeck und zurück. Nächster Schritt: Rel-Ways → `spurenweg-kratzeburg_route.json`.

## Stationen

OSM-Boards entlang des Spuren-Wegs (Namen = Tafeltitel).

| slug | lat | lon | OSM | titel | thema | erlebnisse | barrierefrei | Quelle |
|---|---|---|---|---|---|---|---|---|
| start-relief | 53.4295435 | 12.9379185 | n832379444 | Spuren-Weg Start | Reliefkarte, Braille | tafel | true | OSM Board „Spuren-Weg“ |
| fundamente | 53.4311054 | 12.9370064 | n6419446488 | Fundamente im Wald | Beton, Moos, Flechten | tafel | true | OSM Board |
| die-bahn | 53.431229 | 12.9383124 | n6419456292 | Die Bahn | Verkehrsspur | tafel | true | OSM Board |
| sportplatz | 53.433186 | 12.9353558 | n9320201256 | Sportplatz | Verschwundene Nutzung | tafel | true | OSM Board |
| schirmeiche | 53.4352437 | 12.932275 | n9320200385 | Schirmeiche | Baum als Zeuge | tafel, bestimmung | true | OSM Board |
| postkutsche | 53.4366061 | 12.9323664 | n6419446487 | Postkutschen-Haltestelle | Alte Wege | tafel | true | OSM Board |
| pause-dambeck | 53.4377021 | 12.9354718 | n6419446486 | Eine Pause | Dambeck, zweite Tafel | tafel | true | OSM Board |
| honigleitung | 53.4380102 | 12.9331699 | n6259510928 | Honigleitung | Menschliche Infrastruktur | tafel | true | OSM Board |
| harzung | 53.4379858 | 12.9370816 | n6419446284 | Harzung | Waldnutzung | tafel | true | OSM Board |
| grenze | 53.4370358 | 12.9381743 | n6419456294 | Halt – hier Grenze! | Territorium / Geschichte | tafel | true | OSM Board |
| siedlungen | 53.4364961 | 12.938279 | n6419456293 | Ehemalige Siedlungsplätze | Natur übernimmt | tafel | true | OSM Board |
| gestruepp | 53.4407362 | 12.9368117 | n6419446283 | Gestrüpp | Sukzession | tafel | true | OSM Board |
| ural | 53.4418844 | 12.9375508 | n6259510954 | URAL 72 | Fahrzeugspur / Relikt | tafel | true | OSM Board |
| ufer | 53.4409782 | 12.9377988 | n6419456295 | Am Ufer entlang | See / Havelquelle-Nähe | tafel | true | OSM Board |

Seed-Minimum: start-relief, fundamente, schirmeiche, pause-dambeck, siedlungen, ural.

**kurztexte:**

- start-relief: Relief und Großdruck zeigen den Rundweg. Nach links in den Wald; rechts unten die Stamm-Markierung zum Ertasten.
- fundamente: 1950er-Beton, darauf Moos. Der Mensch ging, die Kruste bleibt, das Leben zieht ein.
- die-bahn: Schienen und Takt haben den Ort geprägt. Heute hörst du den Wald dazwischen.
- sportplatz: Wo gespielt wurde, wächst Wald. Nutzung ist kurz, Bäume sind lang.
- schirmeiche: Eine Eiche als Dach. Tast die Rinde, miss den Schatten.
- postkutsche: Bevor Autos: Haltepunkt im Wald. Der Weg ist älter als der Nationalpark.
- pause-dambeck: Dorf im Grünen. Hier kannst du wenden oder den zweiten Abschnitt beginnen – zweite Infotafel analog zum Start.
- honigleitung: Eine Leitung, die nicht ins Schema Wald passt – und genau deshalb erklärt wird.
- harzung: Harz wurde geerntet. Narben am Stamm sind Archiv.
- grenze: Eine Linie, die für Tiere nichts bedeutet. Für Menschen tat sie es.
- siedlungen: Fundamente, dann Fuchs und Greif. NP-Text: Natur auf den Spuren der Menschen.
- gestruepp: Dicht, unbequem, lebendig. Sukzession sieht unordentlich aus – und ist Arbeit.
- ural: Ein Relikt mit Namen. Technik rostet langsamer als Erinnerung.
- ufer: Wasser, Schilf, vielleicht Eisvogel. Bleib auf dem Weg, das Ufer ist weich.

## Amenities

| OSM | lat | lon | kategorie | name |
|---|---|---|---|---|
| n5206653875 | 53.427743 | 12.9422982 | parking | Kratzeburg |
| w1011130268 | — | — | parking | (Way, beim Stitch zentrieren) |
| n459520206 | 53.4293014 | 12.9374117 | picnic | — |
| n12124964790 | 53.437451 | 12.935683 | picnic | Dambeck |
| n832375570 | 53.4291318 | 12.9453615 | gastro | NP-Info (nur Hinweis, Ausstellung nicht Scope) |
| w389359404 | — | — | gastro | Lütte Meierie (Dambeck, Saison prüfen beim Seed) |
| w1014467136 | — | — | playground | Dambeck (Amenity am Ort, nicht Trail-Typ) |

WC nicht belegt – nicht erfinden.

## Arten

| nameDe | Status | vor Ort |
|---|---|---|
| Stieleiche | in `species.json` | Schirmeiche / Waldbäume |
| Kiefer | in `species.json` | Wald |
| Igel | in `species.json` | Unterholz |
| Eisvogel | in `species.json` | Ufer-Station |
| Hummel | in `species.json` | Honig/Blüte |
| Rotfuchs | **neu** fauna | Siedlungsplätze laut NP-Text |
| Moos / Flechten | thematisch; kein Pflicht-Species wenn nicht im Katalog – optional neu oder nur Tafeltext |

## Go / No-Go

**Go:** frei, barrierefrei belegt, Rel + benannte Tafeln.

**No-Go:** Fledermausausstellung als Station; Brailleheft als Zugangsvoraussetzung.

## Pipeline

1. Rel 1099709 → `tools/osm/spurenweg-kratzeburg_route.json`
2. Config `tools/trails/spurenweg-kratzeburg.json`
3. `build_seed.py` → validate
