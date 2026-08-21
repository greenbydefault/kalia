# Oberhavel – Kandidaten

Stand: 2026-08-17.
Filter: [`README.md`](../../../README.md).
Kreis-Sweep: OSM + Ortsliste Oranienburg, Gransee, Zehdenick, Fürstenberg, Liebenwalde, Leegebruch, Hohen Neuendorf, Birkenwerder, Velten, Naturpark Stechlin-Ruppiner Land außer Menz.
Kalkmoore-Sweep: [`../_kalkmoore.md`](../_kalkmoore.md).

Tiefen-Research: `*.research.md` je neuem GO.

## GO

### von-moor-zu-moor — HAVE

| Feld | Wert |
|---|---|
| Status | **HAVE** – Seed `assets/seed/trail.json` (`id: von-moor-zu-moor`) |
| `typ` / `form` | `moor` / `linie` |
| Ort | Stechlin OT Menz, Naturpark Stechlin-Ruppiner Land |
| OSM | Rel [`19440967`](https://www.openstreetmap.org/relation/19440967) |
| Region-Feld | Oberhavel (war fälschlich OPR, korrigiert) |
| Config | `tools/trails/von-moor-zu-moor.json` |
| Nicht Scope | NaturParkHaus-Ausstellung (Eintritt); Sinnesgarten (frei, aber Besucherzentrum); Wald- und Wassererlebnispfad (Leihset 5 €) |
| Quellen (nachgetragen) | http://www.kalkmoore.de/weitere-informationen/fuer-kleine-moorforscher/moorlehrpfade.html — Bohlensteg, Radoption, Führungen Revierförster optional; Tipp Waldmuseum Stendenitz (Moorraum) = eigener Trail OPR |

Kein `.research.md` in diesem Ordner — Goldstandard-Texte sitzen in Config/Seed. Traumdatensatz: [`docs/traumdatensatz.md`](../../../docs/traumdatensatz.md).

### eichwerder-moorwiesen — OPEN

| Feld | Wert |
|---|---|
| Status | **OPEN** |
| Research | [`eichwerder-moorwiesen.research.md`](eichwerder-moorwiesen.research.md) |
| vorgeschlagenes `typ` | `moor` |
| `form` | `linie` (zwei Stege Alte Schildower Str. ↔ Jungbornstraße) |
| Ort | Glienicke/Nordbahn / Schildow, Naturpark Barnim |
| Zugang | frei & spontan |
| Angebot | Zwei Moorstege + Plattformen; LIFE-Tafeln: Zeitmaschine Moor / Pflanzen / Tiere / Moorschutz und Renaturierung |
| Nicht parallel | Berliner Eichwerder-Steg (NABU) = [`../../Berlin/Reinickendorf/_kandidaten.md`](../../Berlin/Reinickendorf/_kandidaten.md) |
| OSM-Hinweis | Rel fehlt — Stege vor Seed Overpass; nicht den Lübarser Steg mitziehen |
| Quellen | http://www.kalkmoore.de/weitere-informationen/infomaterial/informationstafeln.html · https://www.barnim-naturpark.de/themen/routen-touren/rundwanderung-durch-die-eichwerder-moorwiesen/ |

### harzungspfad — HAVE

| Feld | Wert |
|---|---|
| Status | **HAVE** – Seed `assets/seed/harzungspfad.json` |
| Research | [`harzungspfad.research.md`](harzungspfad.research.md) |
| `typ` / `form` | `walderlebnispfad` / `linie` |
| Ort | Stolpe (Hohen Neuendorf), Stolper Waldstraße / Revierförsterei Stolpe |
| Länge | OSM-Weg ~0,2 km Rundweg, 8 Arbeitsschritt-Stationen am Baum |
| Zugang | frei & spontan; Führungen Revierförsterei optional |
| OSM | Way [`61318864`](https://www.openstreetmap.org/way/61318864); Nodes [`7999807807`](https://www.openstreetmap.org/node/7999807807)–[`7999807814`](https://www.openstreetmap.org/node/7999807814) |
| Config | `tools/trails/harzungspfad.json` |
| Quellen | https://www.berlin.de/forsten/waldbildung/waldlehrpfade/harzungspfad/ · https://www.berlin.de/forsten/walderlebnis/ausflugstipps/nordwesten/wanderung-zum-harzungspfad-869390.php |

## MAYBE

| Ort | Grund |
|---|---|
| **Gramzow-Seen** (südlich Fürstenberg, Naturpark Stechlin) | LIFE-Einzeltafel, kein Lehrpfad. Nicht Uckermark-Gramzow. [`../_kalkmoore.md`](../_kalkmoore.md) |
| **Waldbegegnungsstätte Krämer** (Oberkrämer OT Neu-Vehlefanz) | Forst: Waldlehrpfad, Arboretum, Fußtastpfad, Lehrtafeln am Rundweg. Waldpädagogik für Kita/Schule; Petition: Gelände oft **gebucht**. Spontan-Zugang nicht klar → wie Karnzow, nicht GO. |
| Naturlehrpfad Sophienstädt Rel [`17457146`](https://www.openstreetmap.org/relation/17457146) | OSM 16 Ways / 9 Nodes; redaktionell dünn. Ortsteil **Marienwerder = Barnim**, nicht Oberhavel. Sitzt in [`../Barnim/_kandidaten.md`](../Barnim/_kandidaten.md). |

## NOGO

| Ort | Grund |
|---|---|
| Barfußpfad Dannenwalde | bekannt, kein Seed (Charakter/Scope offen oder Ticket?) — bisher NOGO aus OPR-Sweep |
| NaturParkHaus Menz Ausstellung / Sinnesgarten | Ausstellung Eintritt; Sinnesgarten am Besucherzentrum |
| Wald- und Wassererlebnispfad Roofensee | Aufgaben nur mit Leihset 5 € |
| Rel `7539905` Geheimnisvolle Moore | NEB-Tageswanderung Kleinzerlang→Bhf Stechlinsee, kein Stationen-Lehrpfad |
| Wasserspielplatz Niederheide (Hohen Neuendorf, Schillerpromenade) | städtischer Spielplatz mit Wasserfeature (Karussell, Kletterturm, Matschtisch) |
| Wasserspielplatz Freiheitsplatz Oranienburg | Stadtspielplatz |
| Spiellandschaft Schlosspark Oranienburg | Schlosspark + laut Spielplatztreff kostenpflichtig; Indoor-Café daneben |
| Tier-/Freizeit-/Saurierpark Germendorf | Zoo, Eintritt |
| Ziegeleipark Mildenberg | Eintritt / Museumsgelände |
| Turm Erlebniscity Oranienburg | Indoor, Ticket |
| Gedenkstätte Sachsenhausen | Gedenkstätte, kein Natur-Lehrpfad |
| Briesetal / 66-Seen Etappe Birkenwerder | Wanderweg; „Naturlehrpfad Briesetal“ nur als Wegpunkt in Blogs, keine Stationenliste |
| Rund um den Großen Stechlin / Himmelpfort-Runde | Tageswanderungen, kein Lehrpfad |
| Naturlehrpfad Bredower Forst | **Havelland**, nicht Oberhavel |

## Kreis-Sweep

OSM + Ortsliste 2026-08-13. Stechlin außer Menz: nur schon bekannte NOGOs (NaturParkHaus, Leihset, Rel 7539905). Oranienburg/Gransee/Zehdenick/Fürstenberg/Liebenwalde/Leegebruch/Velten: kein weiterer frei zugänglicher Lehrpfad mit ≥3 belegten Stationen.

## Onboarding (noch keine neuen Seeds)

1. ~~von-moor-zu-moor~~ — HAVE
2. ~~Harzungspfad Stolpe~~ — HAVE
3. Eichwerder-Moorwiesen — OPEN, Tafelbestand vor Seed
