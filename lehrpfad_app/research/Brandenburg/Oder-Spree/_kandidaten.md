# Oder-Spree – Kandidaten

Stand: 2026-08-17.
Filter: [`README.md`](../../../README.md).
Kalkmoore-Sweep: [`../_kalkmoore.md`](../_kalkmoore.md).
Kreis-Sweep: OSM + Schlaubetal, Beeskow, Fürstenwalde, Eisenhüttenstadt, Storkow, Erkner Rest, Helenesee (FF-Rand).

HAVE aus der Brandenburg-OSM-26er-Liste. Neue GOs: `*.research.md`. Config unter `tools/trails/`.

## GO

### rauener-berge — HAVE

| Feld | Wert |
|---|---|
| Status | **HAVE** – Seed `assets/seed/rauener-berge.json` (bzw. Output der Config) |
| Config | `tools/trails/rauener-berge.json` |
| OSM | Rel [`9502745`](https://www.openstreetmap.org/relation/9502745) |
| Region | Bad Saarow |

### wupatz — HAVE

| Feld | Wert |
|---|---|
| Status | **HAVE** – Seed `assets/seed/wupatz.json` |
| Config | `tools/trails/wupatz.json` |
| OSM | Rel [`414325`](https://www.openstreetmap.org/relation/414325) Wupatz’ Lehrpfad |
| Region | Erkner |

### planfliess — OPEN

| Feld | Wert |
|---|---|
| Status | **OPEN** |
| Research | [`planfliess.research.md`](planfliess.research.md) |
| vorgeschlagenes `typ` | `wald` |
| Ort | Schlaubetal OT Bremsdorf, Start Parkplatz Jugendherberge Bremsdorfer Mühle |
| Länge | 5,5 km Rundweg, **11 Thementafeln** (Naturpark 2017 erneuert) |
| Zugang | frei, spontan |
| Markierung | diagonale braune Linie auf weißem Quadrat |
| Quellen | https://www.schlaubetal-naturpark.de/themen/routen-touren/naturlehrpfad-am-planfliess/ · https://www.reiseland-brandenburg.de/poi/seenland-oder-spree/wandertouren/planfliess-rundwanderweg/ |

### gross-schauen — OPEN

| Feld | Wert |
|---|---|
| Status | **OPEN** |
| Research | [`gross-schauen.research.md`](gross-schauen.research.md) |
| vorgeschlagenes `typ` | `naturerlebnis` |
| Ort | Storkow OT Groß Schauen, Sielmanns Naturlandschaft |
| Länge | ca. 1,5 km Ufer + Rückweg ≈ 2,9 km; **10 Infotafeln** |
| Zugang | Outdoor-Pfad frei; **Ausstellung Köllnitz geschlossen** (Fischerei insolvent 2026-08-08) — Startgelände vor Seed prüfen. Aussichtsturm Selchow ab 2026-05-20 gesperrt (Holzschaden), Pfad selbst nicht. |
| Nicht Scope | Ausstellung „Eintauchen & Abheben“ |
| Quellen | https://www.dahme-heideseen-naturpark.de/themen/routen-touren/naturlehrpfad-sielmanns-naturlandschaft-gross-schauen/ · https://www.sielmann-stiftung.de/tour/naturlehrpfad-gross-schauen |

### waldpoesie-pfad — OPEN

| Feld | Wert |
|---|---|
| Status | **OPEN** |
| Research | [`waldpoesie-pfad.research.md`](waldpoesie-pfad.research.md) |
| vorgeschlagenes `typ` | `wald` |
| Ort | Erkner, Fangschleusenstraße / Theodor-Fontane-Weg (nördlich, nicht Wupatz-Südschleife) |
| Länge | 1,3 km; **10 Stationen** Baumart + Autor (Flyer Stadt Erkner) |
| Zugang | frei; Südparkplatz Fangschleusenstraße bis Okt 2026 fast gesperrt — Nordparkplatz nutzen |
| Nicht verwechseln | Wupatz’ Lehrpfad (HAVE, andere Richtung/See) |
| Quellen | https://www.erkner.de/freizeit-und-tourismus/naturerlebnisse/wandern/waldpoesie-pfad.html · Flyer: https://www.erkner.de/_Resources/Persistent/b/4/5/0/b45071c2bf90be7246df9cfb78472dca1a7b01a4/Faltblatt%20Waldpoesie-Pfad%20Web.pdf |

## MAYBE

| Ort | Grund |
|---|---|
| **Naturlehrpfad Petersdorfer See** Rel [`2828431`](https://www.openstreetmap.org/relation/2828431) | Bad Saarow OT Petersdorf, ≈ 52.3165, 14.0716. OSM-Hiking-Rel (18 Ways, 0 Stations-Nodes), Markierung NLP. **Nicht** Rel 9502745 Rauener Berge (HAVE, Endmoräne/Bergbau westlich). Keine Stationstexte online → kein GO. |
| **Rosenhügel Eisenhüttenstadt** | Eigentlicher Naturlehrpfad ~1,3 km im Naherholungsgebiet: Teiche, Insektenhotel, „zahlreiche Lehrtafeln“ — Titel fehlen. 8-km-Rundweg ab Rathaus = Stadtspaziergang/Flächendenkmal, kein Seed. |
| **Naturlehrpfad Beeskow** | OSM-Pfadname / NSG-Grenzverlauf „Spreewiesen südlich Beeskow“; Tourismuslisten ohne Stationen. |
| Rel [`16311561`](https://www.openstreetmap.org/relation/16311561) Naturlehrpfad Stadtwald **Rosengarten** | Zentrum ≈ 52.349, 14.456 — **Frankfurt (Oder)**, nicht LOS, nicht Helenesee. |
| **Natter-Pfad Goyatz** Rel [`4082598`](https://www.openstreetmap.org/relation/4082598) | Gemeinde **Schwielochsee = Dahme-Spreewald**, nicht LOS. Sitzt dort. |
| **Melangsee / Kienheide** (+ Tafel Springsee, Storkow) | LIFE-Einzeltafeln, kein Lehrpfad |

## DROP (OSM-26er, Kreis vermutlich hier)

| Rel | Name | Grund |
|---|---|---|
| [19906514](https://www.openstreetmap.org/relation/19906514) | Heidelehrpfad (Schlaubetal) | schwache OSM; thematisch nah `heide-erlebnisweg` — Kreis bestätigen |

## NOGO

| Ort | Grund |
|---|---|
| Helenesee als LOS-Objekt | Stadtgebiet **Frankfurt (Oder)**-Rand / LOS-Gewässer; Wanderwege, kein belegter Lehrpfad. Rel 16311561 = **Rosengarten FF**, nicht Helenesee. |
| Naturlehrpfad Tauersche Eichen | Jänschwalde = **Spree-Neiße** |
| Ausstellung Köllnitz | geschlossen / Gelände Fischerei, nicht der Uferpfad |
| Fahrgastschifffahrt Schwielochsee | Buchung |
| Stadtspielplätze Fürstenwalde/Beeskow/Erkner | Standard-Sets |

Weitere OSM-OPEN ohne Kreis: [`../_unzugeordnet.md`](../_unzugeordnet.md).

## Onboarding (noch keine neuen Seeds)

1. ~~rauener-berge / wupatz~~ — HAVE
2. Naturlehrpfad Planfließ
3. Naturlehrpfad Groß Schauen (Zugang Start prüfen)
4. Waldpoesie-Pfad Erkner
5. Petersdorfer See — nur nach Stationen
