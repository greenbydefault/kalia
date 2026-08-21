# Wald-Erlebnispfad Serrahn – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `wald-erlebnispfad-serrahn` |
| Name | Wald-Erlebnispfad Serrahn |
| `typ` | `walderlebnispfad` |
| `form` | `linie` |
| Region | Zinow / Serrahn / Carpin, Mecklenburgische Seenplatte, NP Müritz, UNESCO-Welterbe Alte Buchenwälder |
| Länge | 6,5 km (OSM Rel; NP: Zinow–Serrahn–Dianenhof). Familientour oft ~8 km inkl. Rückweg Radweg |
| `dauerMin` | 150 |
| `rundkurs` | false |
| `markierung` | Grünes Buchenblatt auf weißem Grund |
| `betreiber` | Nationalparkamt Müritz |
| `website` | https://www.mueritz-nationalpark.de/erleben-erholen/aktiv-in-der-natur/erlebnispfade/wald-erlebnispfad-serrahn |
| `startName` | Wanderparkplatz / Eingangsbereich Zinow |
| OSM | Rel [`13633929`](https://www.openstreetmap.org/relation/13633929) · Ways u. a. [`76619082`](https://www.openstreetmap.org/way/76619082) `Wald-Erlebnis-Pfad Zinow-Serrahn` · Parkplatz Way [`1155986668`](https://www.openstreetmap.org/way/1155986668) · Eingang Node [`9391620829`](https://www.openstreetmap.org/node/9391620829) |
| BBox | 13.171–13.231 / 53.344–53.363 |

Ausstellung „Im Reich der Buchen“ / Forsthaus Serrahn: **nicht Scope** (Öffnungszeiten). Outdoor-Tafeln und Café-Nähe ja.

## Texte (Config)

**kurzbeschreibung:** Vom Kiefernforst in den Buchen-Urwald: Erlebnispfad Zinow–Serrahn mit Tafeln, Moorsteg und Turm am Serrahnsee. Frei, ohne Ticket.

**beschreibung:** Der Wald-Erlebnispfad verbindet Zinow mit Serrahn und weiter zum Parkplatz Dianenhof. Am Anfang stehen Wirtschaftswald und Pionierbäume, am Ende mächtige Buchen im UNESCO-Welterbe – jahrzehntelang kaum mehr genutzt, weil Jagdgebiet der Großherzöge. Entlang des Weges stehen viele Stationen: Fichte, Eiche, Kiefer, „Waldgärtner“, Lichtkonkurrenz, Rotbuche, Moor. Literatur nennt eine Lauschecke im Totholz und Hängematten; die OSM-Tafeln tragen die Baum- und Prozess-Themen. Am Großen Serrahnsee liegt ein Aussichtspunkt/Vogelbeobachtung. Ein Holzsteg führt durch Moor. In Serrahn gibt es Gartencafé (Saison) und die Ausstellung – die Ausstellung ist optional, der Pfad nicht. Empfehlung NP: Start Zinow, Richtung Dianenhof. Rückweg Radweg „Grüner Radfahrer“ oder Bus 619. Teil Dianenhof–Serrahn laut NP barrierearm (Kinderwagen/Rollstuhl, Steigungen möglich). Hunde an der Leine. Wege nicht verlassen – Welterbe/Totalreservat-Nähe.

**anreise:** Auto: B 198 Neustrelitz–Feldberg, Abzweig Zinow, nach ca. 150 m Wanderparkplatz rechts (kostenlos). Weitere Parkplätze Dianenhof und Carpin. Bus 619 (MVVG) Haltestelle Welterbe Zinow / Dianenhof / Carpin. Rad: von Neustrelitz Symbol „Grüner Radfahrer“, ca. 10 km.

**tags:** `kinderfreundlich`, `picknick`, `einkehr`, `hunde-erlaubt`

`kinderwagentauglich` nur wenn Seed die Dianenhof–Serrahn-Variante nutzt – Default-Route Zinow unbefestigt: **nicht** setzen.

## Geometrie

Linie Zinow (Parkplatz ~53.36135, 13.17446) → Boards nach Osten/Südosten → Turm Serrahnsee → Serrahn Dorf → optional Dianenhof (parking n5375851320 53.3539025, 13.2298273). Rel 13633929 from Zinow to Carpin, 13 members. Nächster Schritt: Ways entlang Rel + benannte Pfad-Ways zu Route stitchen, Start Eingangs-Node.

## Stationen

Kuratierte Auswahl entlang Zinow → Serrahn (OSM-Boards). Lauschecke/Hängematten: in Text erwähnen, GPS nur wenn Feldcapture – nicht als Fake-OSM-Tafel.

| slug | lat | lon | OSM | titel | thema | erlebnisse | barrierefrei | Quelle |
|---|---|---|---|---|---|---|---|---|
| start-zinow | 53.3613708 | 13.1745291 | n9391620829 / n6589742877 | Eingang Zinow | Start Welterbe-Pfad | tafel | false | OSM „Eingangsbereich Zinow“, Board „Wald-Erlebnis-Pfad Serrahn“ |
| fichte | 53.3615519 | 13.1759677 | n9407236826 | Die Fichte ist hier nicht verwurzelt | Pionier / Fehlstandort | tafel, bestimmung | false | OSM Board |
| pioniere | 53.3615435 | 13.1778512 | n9407285659 | Pioniere! | Erste Bäume nach Störung | tafel | false | OSM Board |
| junge-baeume | 53.3613621 | 13.1781094 | n9407285660 | Welche jungen Bäume wachsen hier? | Verjüngung | tafel, bestimmung | false | OSM Board |
| traubeneiche | 53.3603171 | 13.1814657 | n9407285661 | Traubeneiche – nur ein Durchläufer? | Eiche im Wandel | tafel, bestimmung | false | OSM Board |
| kiefern-brotbaum | 53.3570065 | 13.1882854 | n9407326253 | Gemeine Kiefer – der Brotbaum | Wirtschaftswald | tafel, bestimmung | false | OSM Board |
| waldgaertner | 53.3545776 | 13.1921873 | n9407326255 | Der gefiederte Waldgärtner | Tiere pflanzen Wald | tafel | false | OSM Board |
| turm-serrahnsee | 53.3534676 | 13.1990094 | n903187001 | Großer Serrahnsee | Aussicht, Adler, Kranich | tafel | false | OSM viewpoint/bird_hide |
| rotbuche | 53.3493763 | 13.2003116 | n6589742878 | Rotbuche – die Dominante | Urwald / Welterbe | tafel, bestimmung | false | OSM Board |
| moor | 53.3467817 | 13.20229 | n9407349005 | Ein lebendiges Moor ist baumfrei | Moorsteg-Thema | tafel, steg | false | OSM Board; Steg laut NP/Literatur |
| unesco | 53.3484349 | 13.1945904 | n9407374565 | UNESCO-Welterbe | Alte Buchenwälder | tafel | false | OSM Board |
| dorfstelle-saran | 53.3482422 | 13.2005317 | n11740701491 | Dorfstelle Saran | Menschliche Spur im Wald | tafel | false | OSM Board |
| serrahn-forsthaus | 53.3442857 | 13.2020332 | n903187161 | Forsthaus Serrahn | Zielort / Pause | tafel | false | OSM Board (Ausstellung daneben = nicht Scope) |
| dianenhof | 53.3539025 | 13.2298273 | n5375851320 | Parkplatz Dianenhof | Alternative Ankunft / barrierearmer Ast | tafel | true | OSM parking + map n5375851322 |

Seed-Minimum entlang einer Richtung: start-zinow, pioniere, kiefern-brotbaum, turm-serrahnsee, rotbuche, moor (6). Dianenhof nur wenn Route bis dorthin geht.

**kurztexte:**

- start-zinow: Parkplatz am Waldrand, Tafeln zum Welterbe. Ab hier führt das Buchenblatt vom Forst in den Urwald. Bleib auf dem markierten Weg.
- fichte: Die Fichte steht, ist hier aber fehl am Platz. Warum, sagt die Tafel – und der Boden darunter.
- pioniere: Nach Sturm oder Hieb kommen zuerst die Schnellen. Welche Art siehst du in den ersten Metern?
- junge-baeume: Kein Museumswald: unten wächst die nächste Generation. Bestimm die Jungpflanzen, bevor die Krone zu macht.
- traubeneiche: Eiche zwischen Kiefer und Buche. Durchläufer oder Bleiber? Rinde und Blatt vergleichen.
- kiefern-brotbaum: Die Kiefer hat den Forst ernährt. Hier beginnt der Kontrast zum Buchenwald, der später kommt.
- waldgaertner: Wer hat die kleinen Bäume gepflanzt? Oft ein Vogel. Die nächste Tafel nennt ihn.
- turm-serrahnsee: Blick über Moor und See. Seeadler, Fischadler, Kranich – Glückssache. Glas und Abstand.
- rotbuche: Die Dominante des Welterbes. Totholz, Lichtflecken, Jungbuchen. So sieht Wald aus, den niemand mehr aufräumt.
- moor: Lebendiges Moor bleibt offen. Der Steg schützt die Fläche – und dich vor nassen Füßen. Tafeln zu Torf und Bäumen, die nicht gehören.
- unesco: Seit 2011 Teil der Alten Buchenwälder Deutschlands. Kein Extra-Ticket, aber Regeln: Weg, Leine, keine Souvenirs aus dem Reservat.
- dorfstelle-saran: Hier lag eine Siedlung. Der Wald hat sie übernommen. Menschliche Spuren unter Buchen.
- serrahn-forsthaus: Dorf im Wald. Café in der Saison, Ausstellung hinter der Tür – der Pfad endet draußen.
- dianenhof: Zweiter Parkplatz. Von hier nach Serrahn der barriereärmere Ast laut Nationalpark.

## Amenities

| OSM | lat | lon | kategorie | name |
|---|---|---|---|---|
| w1155986668 | 53.36136 | 13.17446 | parking | Wanderparkplatz Zinow |
| n5375851320 | 53.3539025 | 13.2298273 | parking | Dianenhof |
| n5375851321 | 53.3538485 | 13.2301363 | shelter | Dianenhof |
| n903187001 | 53.3534676 | 13.1990094 | viewpoint | Großer Serrahnsee |
| n3661836852 | 53.3446057 | 13.2032381 | gastro | Gartencafe Serrahn |
| n903186329 | 53.34561 | 13.2002851 | bench | Serrahn |
| n13711523823 | 53.3442146 | 13.2019766 | picnic | Serrahn |

WC: nicht belegt am Pfad – nicht erfinden. Ausstellungstoilette ≠ Spontan-Amenity.

## Arten

| nameDe | Status | vor Ort |
|---|---|---|
| Kiefer | in `species.json` | „Brotbaum“, Forstbeginn |
| Stieleiche | in `species.json` | Eichen-Tafeln (Traubeneiche thematisch nah; Seed-Alias oder Stieleiche) |
| Kranich | in `species.json` | Serrahnsee / Moor |
| Torfmoos | in `species.json` | Moorsteg |
| Wollgras | in `species.json` | Moor |
| Rote Waldameise | in `species.json` | Waldboden |
| Rotbuche | **neu** flora | Welterbe-Dominante |
| Seeadler | **neu** fauna | Serrahnsee, Glück |
| Fischadler | **neu** fauna | Serrahnsee / NP-Thema |

## Go / No-Go

**Go:** frei, Rel + dichte OSM-Tafeln, klarer Start Zinow.

**No-Go:** Ausstellung als Pflicht; naiver Rel-Stitch bis Carpin ohne Stationsabgleich; Hängematten als Station ohne GPS.

## Pipeline

1. Rel 13633929 + benannte Ways → `tools/osm/wald-erlebnispfad-serrahn_route.json`
2. Config `tools/trails/wald-erlebnispfad-serrahn.json`
3. `build_seed.py` → `validate_seeds.py`
4. Neue Arten Rotbuche/Adler beim Seed
