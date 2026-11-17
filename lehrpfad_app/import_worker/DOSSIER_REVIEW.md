# Dossier-Review: Regeln für den Recherche-Bot

Abgeleitet aus dem Gegencheck der Entwürfe `naturlehrpfad-muemmelkensee` und `duenen-lehrpfad-klein-schmoelen` (30.10.2026). Gilt zusätzlich zu `VORLAGE_V3.md`, `docs/stimme.md`, `tools/TRAIL_SCAN.md`, `docs/traumdatensatz.md`. Hörtexte sind bewusst nicht Teil des Imports.

> **Übergeordnet:** Der Recherche-Vertrag `docs/recherche/KALIA_RECHERCHE_VERTRAG.md` (Pipeline, Bot-Schnitt, Feldvertrag, Gate-SQL `docs/recherche/gate.sql`) hat Vorrang. Bei Widerspruch gilt der Vertrag. Neu darin: Linien ohne belegbare Route gehen als „Verlauf nicht kartiert“ (`route=[]`) durch, wenn die Bedingungen aus Vertrag Abschnitt 7 erfüllt sind (`ROUTE_NICHT_KARTIERT` statt `GEOMETRIE_FEHLT`).

## 1. Leer ist keine Antwort

Diese Felder sind im CMS hart Pflicht (`rules.py`: `PFLICHT`, `GEOMETRIE_FEHLT`). Steht dort „nicht belegt“, ist der Entwurf nicht anlegbar.

| Feld | Regel |
|---|---|
| `route` (Linie) | Nie `[]`. Fehlt die OSM-Relation, Ways aus OSM (highway=path/track/footway) per BBox zusammensetzen oder Betreiber-/Outdooractive-GPX nehmen. Erst wenn beides scheitert, `GEOMETRIE_FEHLT` offen melden, mit Begründung. |
| `dauer_min` | Schätzen: Länge ÷ 2–3 km/h plus Haltezeit je Station. In `field_meta` als „geschätzt, Rechnung: …“ kennzeichnen. Nicht leer lassen. |
| `betreiber` | Tafel-, Wegweiser- und Bildunterschriften zählen als Beleg (Mümmelkensee: Wegweiser „Naturpark Insel Usedom“ steht in den eigenen Bildunterschriften, `betreiber` blieb leer). Sonst Gemeinde bzw. Eigentümer des Schutzgebiets. |
| `tags` | Auto-Tags aus Amenities und Nearby ableiten (`einkehr`, `picknick` bei Bänken oder Rastplätzen). Weglassen nur, was wirklich unbekannt ist, aber nicht alle vier. |
| `amenities` | Nie 0. Parkplatz, Bänke, Schutzhütte, Rastplätze, Turm, WC aus OSM und Quellen. Beide Entwürfe haben 0. |
| Stationen | ≥ 3, mit `thema`. Auch Rastplätze, Aussichtspunkte, Turm, Schutzhütte sind Stationen, wenn es keine Tafeln gibt. Mümmelkensee hat 1, `thema` leer. |
| `km` je Station | Aus der Route berechnen (Projektion auf die Linie), nie 0. |

## 2. Keine Dossier-Sprache in Nutzerfeldern

„nicht belegt“, „keine Markierung in den Quellen“, „Entscheidung Marc“, `[S1, S3]` stehen in `field_meta`, `trail_sources` und `import_hinweis`. Nie in `markierung`, `anreise`, `besuchshinweise`, `kurztext`, `ort`, `kreis`, `region`, `betreiber`.

Gefunden:

- `markierung`: „keine Markierung in den Quellen“ (Klein Schmölen, Marienfelde). Richtig: „keine“ oder „Pulttafeln am Weg“ (ADR 0004).
- `besuchshinweise` beider Pfade: „Kinderwagen, Rollstuhl, WC, Trinkwasser nicht belegt“. Unbekanntes weglassen.
- `anreise`: „Adresse nicht belegt“, „ÖPNV nicht belegt“.
- Station 1 Mümmelkensee: „Inhalte der Tafeln am Weg: nicht belegt“.
- Marienfelde: Quellenkürzel `[S1, S2]` in `ort`, `kreis`, `region`, `betreiber`.
- `markierung` mit Schlusspunkt („Grüner Diagonalstrich.“). Ohne Punkt.

## 3. Geometrie und Start

- Start und Anreise müssen denselben Punkt meinen. Mümmelkensee: Koordinate = OSM-Wegweiser an der L 266, Anreisetext = Bahnhof Bansin, Fischerweg. Nicht beides.
- `Fischerstraße` (meer-usedom) und `Fischerweg` (bansin.m-vp) nicht in einem Satz mischen. Eine nehmen, die andere in `trail_sources`.
- Zubringer mitzählen. Klein Schmölen: Betreiber und NABU nennen den Parkplatz als Start/Ziel, die Starttafel liegt 450 m östlich. Weder `route` noch `laenge_km` (1,6) enthalten den Zubringer, NABU nennt 2,5 bis 3 km. Entweder Start auf den Parkplatz und Zubringer in die Route, oder `start_name` bleibt die Tafel und `anreise` sagt klar: 450 m zu Fuß bis zur Tafel.
- Streckenweg: `laenge_km` ist einfach oder hin und zurück? Mümmelkensee nennt 3,5 / 5 / 6,2 km. Das passt zusammen, wenn 3,5 einfach und 6,2 hin und zurück sind. Festlegen, in `field_meta` notieren, im Text nur die Config-Zahl, nie „5 bis 6,2 km“.
- OSM-Relation zusammensetzen heißt nicht Sehnen akzeptieren. Klein Schmölen: Rückweg besteht aus Geraden von 329 m, 126 m und 185 m, außerdem ein 8-m-Stichpunkt (Punkte 17 bis 19 doppelt). Vor dem Schreiben: Segmente > 100 m prüfen und mit Zwischenpunkten aus den Ways füllen.
- Station und Route: Reihenfolge entlang der Route prüfen, nicht „OSM-Node-ID absteigend“. Stationen < 10 m auseinander (5/6, 11/12) als Doppeltafel markieren oder zusammenlegen.
- Quellenwiderspruch selbst auflösen: Klein Schmölen Quelle 27 „Parkplatz in OSM gefunden (way 134444718)“, Quelle 34 „Parkplatz in OSM nicht gefunden“. Eines von beiden ist falsch.

## 4. Texte (Lesetext)

Spec bleibt `TRAIL_SCAN.md`. Typische Verstöße hier:

- Satz 1 von `beschreibung` ist Lage oder Weg („Von Bansin … führt der Naturlehrpfad …“, „Etwa 3 km östlich von Dömitz liegt …“). Er muss das Besondere tragen.
  - Klein Schmölen: wiederangesiedelte Sand-Silberscharte, Düne über 30 m, entstanden nach der Eiszeit.
  - Mümmelkensee: Name von „Mummel“ (plattdeutsch für Gelbe Teichrose), nie entwässert, nie abgetorft (bansin.m-vp.de).
- Füllsätze raus („Unterwegs stehen Infotafeln am Weg.“).
- Stationsinventar raus („Zwölf Pulttafeln erzählen …“). Die Zahl ist ohnehin unsicher: die Presse sagt „zwölf Infotafeln ersetzt, zwei neue Pulttafeln“, OSM zählt 12, der Blog 8.
- Chips nicht wiederholen: Rundkurs und Typ in `kurzbeschreibung` („ein 1,6 km langer Rundweg“, „Moorsee im Naturschutzgebiet“), Rundweg/Streckenweg und Einkehr in `besuchshinweise`.
- Wertwörter („leuchtend“) und Tierverhalten ohne Beleg („kaum zu sehen“). Für die Ödlandschrecke steht in den Quellen nur ein GBIF-Fund.
- Behauptungen, die das eigene Dossier einschränkt: Beobachtungsturm steht als Fakt in `beschreibung`, in `trail_sources` aber „in OSM kein Turm verzeichnet“. Entweder Quelle nennen (bansin.m-vp.de, kreis-vg.de nennen Steg bzw. Aussichtsplattform am östlichen Moorrand) oder Formulierung auf das Belegte begrenzen.
- Satz 1 von `besuchshinweise` bei Klein Schmölen hat 24 Wörter.

## 5. Stationstexte

- `kurztext` wird nicht aus dem Titel zurückgebaut. Klein Schmölen: alle 12 Texte beginnen „Die Tafel …“ und wiederholen nur den Titel („Die Tafel berichtet von unvorhergesehenen Ereignissen, bei denen Trockenrasen unter Wasser standen“). Ohne gelesenen Tafeltext lieber knapp und ehrlich („Tafel zu …“) und in `import_hinweis` vermerken. Die Quellen erlauben aber mehr (Flyer, Presse).
- `titel` vs. `thema` klären: In Quelle 25 ist „Vom Winde verweht“ der Tafeltitel, in der DB steht es als `thema` von Station 5. Das `titel`-Feld dann Tafeltitel, `thema` die Unterzeile.
- Kein Schlusspunkt im Titel (Station 12), keine Unsicherheitsmarker im Titel (Station 7: „Titel unsicher (OSM: Elbtünen)“). Unklarer Titel: Station zurückhalten oder mit dem sicheren Namen führen, Unsicherheit nur in `steckbrief.status`.
- `erlebnisse` nicht nur `tafel`. Aussichtsplattform, Steg, Rast gehören dazu, wo physisch vorhanden.

## 6. Arten

`belegt` heißt: steht auf der Tafel oder im Betreibertext. GBIF ist laut Skill `have-trail` nur Plausibilität (`typisch`).

- Beide Entwürfe markieren fast alles `belegt`: Klein Schmölen 21 von 21 (Quelle: GBIF-Rechteck 2 × 2 km), Mümmelkensee 21 von 22 (Quelle: 6 GBIF-Funde, 15 Arten ohne jede Quelle; `trail_sources` sagt selbst „Infotafel-Arten nicht belegt“).
- Folge: der Cap (weich 14, hart 16) greift nicht. 21 und 22 Arten.
- Wiedehopf (Klein Schmölen) steht in keiner Quelle. Rotkehlchen, Waldmistkäfer, Falkenlibelle sind Füller ohne Ortsbezug.
- Was die Quellen nennen und fehlt:
  - Klein Schmölen: Blauschillergras (Presse), Brenndolde und Habichtskraut (Station 7), Soldatensegge und Tripmadam (Station 11), Ameisenlöwe/Ameisenjungfer (Station 9, „Ein Löwe wird zur Jungfer“), Schaf (Station 12, im Katalog als `schaf`).
  - Mümmelkensee: Eisvogel (meer-usedom, im Katalog), Graugans und Zwergtaucher (bansin.m-vp.de, Graugans im Katalog), Sumpfporst und Sonnentau sind da, die Blasenbinse fehlt im Katalog (Lücke über `tools/art_anlegen.py`).
- Reihenfolge: Mümmelkensee `sortierung` hat Lücken (18, 19).

## 7. Bilder

- Alle 13 Bilder `pending` (normal bis zur Freigabe), aber 9 davon `geo_check = none` (Mümmelkensee 7 von 7). Ohne Geo-Beleg Ortszuordnung aus der Commons-Kategorie dokumentieren.
- `kind = station` ohne `station_id`: 10 von 11 hängen an keiner Station. Entweder zuordnen oder `kind` ändern.
- Mümmelkensee: Hero ist ein Waldweg mit Wegweiser, 3 weitere sind Schilder. Der See mit Seerosen (Bild 5) ist das Hero-Motiv.
- CC BY-SA: Namensnennung steht im `credit`, in der App sichtbar halten.

## 8. Nearby

Auto-Fahrzeit ≤ 20 min, alle Kategorien (`have-trail` Schritt 6). Mümmelkensee: `baden-strand-heringsdorf` (4,0 km Luftlinie), `seebruecke-heringsdorf`, `camping-mobilcamp-heringsdorf` liegen im Katalog und sind nicht verknüpft. Vermutlich `nearby_zeiten.py --trail` nicht nochmal gelaufen. Außerdem existiert OstseeTherme als zwei Orte (`ostseetherme-usedom`, `ostseetherme-ahlbeck`), Duplikat prüfen. Ein Strand fehlt in der Kategorie `baden`, obwohl Bansin 2 km entfernt liegt.

## 9. Selbstcheck vor „fertig“

1. Hat jede Pflichtspalte aus `rules.py` einen echten Wert?
2. Steht irgendwo „nicht belegt“ außerhalb von `field_meta`/`trail_sources`?
3. Start, Anreise, `start_name` und erste Routen-Koordinate: ein Ort?
4. Route: kein Segment > 100 m ohne Grund, kein Spike, Länge ±10 % zur Config?
5. Jede Station: Titel, Thema, Kurztext aus einer Quelle, `km` > 0 (außer Start)?
6. Arten: `belegt` nur mit Tafel/Betreiber-Beleg, Anzahl ≤ 16, tafelgenannte Arten drin?
7. Satz 1 der Beschreibung allein tragfähig, keine Chip-Wiederholung, `scan.py` grün?
8. Nearby gegen `nearby_zeiten.py --report`, nicht nach Gefühl?

---

# Runde 2 (31.10.2026): Rugard, Fuhlendorf, Schuenhagen, Ribnitz

Gegencheck der CMS-Entwürfe `walderlebnispfad-rugard`, `naturerlebnispfad-fuhlendorf`, `baumschatz-schuenhagen`, `naturpfad-ribnitzer-grosses-moor`. Gilt zusätzlich zu Runde 1.

## Was aus Runde 1 angekommen ist

Arten ≤ 16 und `typisch` wird genutzt. `dauer_min` ist gefüllt und in `field_meta` gerechnet. Amenities nie 0. Stationen ≥ 3. Keine Quellenkürzel `[S1]` in Nutzerfeldern. Nearby verknüpft. Ribnitz: Fläche gezeichnet, Bild an Station gehängt. Das so lassen.

## R2-1 Route fehlt weiter (3 von 3 Linien-Pfaden)

Rugard, Fuhlendorf, Schuenhagen haben `route = []`, alle 33 Stationen `km = 0`. Begründung in `field_meta`: „Overpass nicht erreichbar“. Das ist kein Grund. Beim Ribnitz-Pfad kam die Fläche aus der **OSM-API** (way/191741306), die API war also erreichbar. Regel 1 aus Runde 1 gilt unverändert: Overpass down → OSM-API per BBox (`/api/0.6/map?bbox=…`, highway=path/track/footway) → Betreiber-/Outdooractive-GPX → erst dann `GEOMETRIE_FEHLT` offen melden. „Overpass nicht erreichbar“ ist kein Abschluss, sondern der Auftrag, den nächsten Weg zu nehmen. Ohne Route sind `km`, Reihenfolge, Zubringer und Start-Konsistenz nicht prüfbar. Die Entwürfe sind damit nicht anlegbar.

## R2-2 Dossier-Sprache in Nutzerfeldern (Regel 2 wiederholt)

Gefunden:

- `eintritt_preise` Rugard: „nicht belegt: Quellen nennen nur die kostenpflichtige Turmbesteigung …“. Fuhlendorf: „nicht belegt: keine Angabe zu Eintritt in den Quellen.“ → Feld leer lassen, Begründung in `field_meta`.
- `betreiber` Rugard und Fuhlendorf: „Kontakt: … Träger unbekannt.“ Das ist eine Bot-Notiz („Kontakt-Regel“), kein Betreiber. Rugard: Die Quelle titelt „Walderlebnispfad Rugard der **Stadt Bergen auf Rügen**“, der Dossier-Abschnitt 4 nennt die Projektbeschreibung der Stadt Bergen. Betreiber ist also Stadt Bergen, Forstamt Rügen ist Partner. Fuhlendorf: Revierförsterei Fuhlendorf (Landesforst MV) oder Gemeinde prüfen, sonst Eigentümer der Fläche.
- `anreise` Fuhlendorf: „Parken am Start nicht belegt.“ → Satz streichen.
- `besuchshinweise` Ribnitz: „Eignung für Kinderwagen und Rollstuhl nicht belegt.“ → streichen.
- `eintritt_preise` Schuenhagen, Ribnitz: „(Stand 2026-10-31)“. Datum gehört in `field_meta`.

Selbsttest vor dem Speichern: Suche in allen Nutzerfeldern nach `nicht belegt`, `unbekannt`, `Stand 20`, `Kontakt:`, `Platzhalter`, `Quelle`.

## R2-3 `markierung` leer (Pflicht)

Schuenhagen und Ribnitz haben `markierung = ''`. `field_meta` sagt „keine Wegmarkierung belegt (leer)“. Die Schuenhagen-Quelle sagt aber „Folge den blauen Infotafeln“ → `blaue Infotafeln`. Ribnitz: „Hinweisschilder am Weg“ (Quelle: Hinweisschilder und Schautafeln) oder „keine“. Rugard: „nicht ausgeschildert“ steht schon in `markierung`, dann nicht noch einmal am Anfang von `besuchshinweise`.

## R2-4 Start, Anreise, Station 1: ein Punkt

- Schuenhagen: `start_name` = „Eingangstafel an der alten Eiche“, Koordinate = Schwerpunkt des Forstamt-Gebäudes (54,25188 / 12,82429). Station 1 (Eingangstafel) liegt 160 m davon entfernt. Entweder Start auf die Eingangstafel setzen oder `start_name` = Forstamt.
- Rugard: Start = Waldbühne. Die Quelle lässt die Runde am Parkplatz beginnen: Parkplatz → Turm → Wiese → Waldbühne. Parkplatz liegt 460 m Luftlinie vom Start, `anreise` sagt aber „rund 200 m vor dem Turm“ und nicht, wie weit es bis zur Waldbühne ist. Zubringer in `anreise` nennen („ca. 500 m Fußweg bis zur Waldbühne“).
- Rugard Station 1 „Start Walderlebnispfad Rugard“ ist ein Füller (kein Tafelinhalt). Die Willkommenstafel (Station 3) liegt 100 m daneben, obwohl die Quelle sagt, der Pfad beginne dort an der Waldbühne mit der Willkommenstafel. Station 1 und 3 zusammenlegen. Der Turm (Station 2) liegt 255 m abseits der Runde und ist kostenpflichtig: entweder raus (Amenity `viewpoint` reicht) oder als Zubringer-Station markieren und „Besteigung kostenpflichtig“ in `besuchshinweise` aufnehmen. Die Quelle zählt 14 Lehrpfad-Stationen, wir haben 16.

## R2-5 Stationen, die keine sind

- Ribnitz: 7 von 9 Stationen liegen auf **einer** Koordinate (Flächen-Schwerpunkt), auf der Karte ein Pin. Vier davon sind Themen („Schautafeln Gehölze“, „… Pilze, Pflanzen und Insekten“, „… Wald- und Forstgeschichte“, „Nistkästen und Vogeltafeln“), keine Orte. `reihenfolge` „vom Bot gesetzt, nicht belegt“ passt nicht zu `besuchshinweise` „kein Rundweg mit fester Reihenfolge“. Auf die belegbaren Orte reduzieren: Infotafel NSG, Ökoteich, Insektenhotel, Bienenstock, Rastplatz (5), Tafeln als ein Eintrag „Schautafeln (über 30)“. Koordinaten aus OSM (information=board, Insektenhotel, Bienenstand) oder Foto-EXIF holen.
- Ribnitz: Fläche hat 0,4 ha (Umfang 256 m). Ökoteich liegt 107 m, Rastplatz 33 m **außerhalb** der Fläche. `dauer_min` rechnet mit 0,5 km Wegen. Die Fläche ist offenbar nur das Kernstück (OSM `leisure=park`). Fläche gegen die Stationen prüfen und erweitern oder Stationen ehrlich als „außerhalb“ kennzeichnen.
- Fuhlendorf: Die Quelle zählt 7 Stationen auf 2,2 km. „Pfad der Rätseltiere“ (860 m) und „Pfad des Waldauges“ (800 m) sind **Erweiterungen**, die Buchenhalle liegt rund 900 m abseits. `laenge_km` 2,2 gilt für 1–7, `dauer_min` 105 rechnet 10 Stationen × 5 min dazu. Das passt nicht zusammen: Entweder Länge und Dauer für 1–10 neu rechnen (mit Erweiterungen) oder 8–10 als Erweiterung mit eigenem Hinweis führen. Stationen 8 und 9 stehen als Platzhalter auf dem Startpunkt. `besuchshinweise` nennt nur die 860 m, nicht die 800 m.
- Doppeltafeln (Schuenhagen 5 und 6 auf einer Koordinate) sind laut Quelle richtig (zwei Baumgeister an Station 5). Im Titel oder `steckbrief` als Doppeltafel markieren.

## R2-6 Arten: `belegt` ≠ `typisch`

Quelle lesen, dann einstufen:

- Rugard: Jagdtafel nennt Reh, Rot-, Dam- und Schwarzwild. Alle vier stehen als `typisch`, müssen `belegt` sein. Buntspecht steht in keiner Quelle, raus. Fehlen, obwohl im Katalog und auf einer Tafel: **Robinie** (Station 4), **Spitzahorn** (14), **Edelkastanie** (= Esskastanie, 15), **Vogelkirsche** (16). 8 Flora + 4 neue + 4 Wild = 16 (harte Grenze). Nicht im Katalog, aber auf Tafeln oder Maskottchen: Haselmaus (Henni), Blauglockenbaum, Schwarznuss, Roteiche, Orientbuche, Baumhasel. Haselmaus über `art_anlegen.py`, die Bäume als `species_suggestions` melden.
- Fuhlendorf: Station 2 nennt Wolf, Rotfuchs, Wildschwein, Rothirsch, Reh, Eichelhäher. Wildschwein, Rothirsch, Reh stehen als `typisch`, müssen `belegt` sein. Douglasie (Märchen vom Douglasienzapfen, Station 3) ebenfalls `belegt`. **Wolf fehlt** (nicht im Katalog, keine `species_suggestions`-Zeile). Stieleiche und Eichhörnchen haben keine Quelle (Eichhörnchen nur im Buchenhallen-Zitat). Außerdem: `trail_species` hat 12 Zeilen, `sortierung` springt bei 6 und 9. Zwei Arten sind unterwegs verloren gegangen, nach Dossier sollten es 13 sein.
- Schuenhagen: Leitart ist der **Schreiadler** (Station 7 „Finde Schreiadler Tobi“, Schreiadler-Wissensparcours, Schreiadler-Projekt des Forstamts) und fehlt, nicht im Katalog. Station 1 nennt Holzameisen (`rote-waldameise` prüfen). Die sechs Fauna-Arten sind reiner Pool (`typisch`), das ist ok, sollte aber `field_meta` so sagen.
- Ribnitz: 13 von 14 `typisch`, nur Honigbiene `belegt`. `lebensraeume` enthält `moor`, daher Sonnentau, Sumpfporst, Moosbeere, Torfmoos, Moorfrosch, Moorbirke, Kranich. Die Quelle (Abschnitt 4) führt diese Arten unter „Arten NSG Ribnitzer Großes Moor“, und der Dossier-Abschnitt 1 sagt selbst, dass die Fläche **1,7 km außerhalb** des NSG liegt. Der Besucher sieht auf dem Pfad kein Moor. `moor` aus `lebensraeume` nehmen, Moorarten raus (höchstens 1–2 mit Verweis auf die NSG-Tafel). Passend zum Beleg: `kuestenwald-kiefer` (Revierteil nadelholzdominiert, Kiefer; Roterle und Birke in Sümpfen), `teich-tuempel` (Ökoteich), Insektenhotel → Wildbiene (im Katalog), Nistkästen → Kohlmeise, Blaumeise, Kleiber (im Katalog). Seeadler, Waldeidechse, Zauneidechse haben keine Quelle.

Faustregel: Steht die Art auf der Tafel, auf der Betreiberseite oder im Stationsthema, ist sie `belegt`. `typisch` nur aus dem Pool des tatsächlichen Standorts, nicht aus einem Schutzgebiet nebenan. Nach dem Schreiben `sortierung` auf Lücken prüfen und Anzahl gegen das Dossier zählen.

## R2-7 Texte

- Stationsinventar steckt in allen vier `beschreibung`: Schuenhagen Sätze 3–7 sind eine Station-für-Station-Liste, Rugard nennt Tafel um Tafel, Fuhlendorf Specht, Fuchs, Geschenke, Verzauberter Wald, Ribnitz Bienenstock, Insektenhotel, Ökoteich, Nistkästen. TRAIL_SCAN: „Kein Stationsinventar.“ Nach Satz 1 steht das, was ein Besucher sonst nicht weiß.
- `kurzbeschreibung` doppelt Satz 1 der `beschreibung` fast wörtlich (Schuenhagen: Baumgeister/Tresor, Fuhlendorf: Edelsteine/Lösungswort/Junge). Zwei Texte, zwei Aussagen. Satz 1 der `beschreibung` soll nicht der Inhalt der `kurzbeschreibung` sein.
- `kurzbeschreibung` nennt den Typ (Chip): Rugard „Der Walderlebnispfad …“, Fuhlendorf „Auf dem Naturerlebnispfad …“, Ribnitz „der eingezäunte Naturlehrpfad … über 30 Schautafeln, einen Ökoteich, ein Insektenhotel und einen Bienenstock“ (Typ plus Inventar).
- Stations-`kurztext` nach Schablone: Schuenhagen 6 von 7 „Die Infotafel des Baumgeists X handelt von der Y …“, Fuhlendorf 7 von 10 „Die Infotafel …“, Rugard 9 von 16 „Die Tafel …“. Das ist Runde 1 Abschnitt 5 wieder. Mit dem Inhalt beginnen („Robinie, Blauglockenbaum und Schwarznuss als klimastabile Bäume …“).
- Schuenhagen `beschreibung` Satz 1: „wohnt an jedem Baum ein Baumgeist“ ist größer als der Beleg (sieben Bäume).
- Ribnitz `beschreibung`: „rund 1,7 km entfernte“ ist eine Bot-Messung, keine Quellenangabe (Regel 3 stimme.md: Zahlen nur aus Config oder Beleg). „gut zu sehen“ ist ein Wertwort ohne Fakt.
- `besuchshinweise` doppeln Chips oder Amenities: Rugard „Nicht ausgeschildert“ (markierung), „WC am Rugard“ (Amenity), Ribnitz „Rastplatz … zum Picknicken und Grillen“ (Tag `picknick`), Schuenhagen „Bänke an der ersten Station und an der Barthe“ (sollte Amenity sein, siehe R2-8).
- Fehlt, obwohl es den Besuch ändert: Rugard Turmbesteigung kostenpflichtig. Schuenhagen: Der Pfad beginnt im Anschluss an den Schreiadler-Wissensparcours hinter dem Forstamt, direkt gegenüber liegt ein eingezäunter Spielplatz mit Rasenfläche. Beides kommt in keinem Feld vor.
- `region` „Nordvorpommern“ gibt es als Landkreis seit 2011 nicht mehr, `kreis` sagt Vorpommern-Rügen. Region aus dem Kreis, Naturraum oder Reiseregion (Rügen, Fischland-Darß-Zingst) bilden.

## R2-8 Amenities und Tags

- Radius 300 m um den Start ist kein „am Weg“. Ribnitz: Nico’s Wildgrill 190 m vom Start, Bank 260 m südlich, außerhalb der Fläche. Vier Parkplatz-Punkte auf rund 320 m Straße sind wahrscheinlich ein Parkstreifen in vier Wegen, zu einem zusammenfassen.
- Rugard: sechs der zehn Ausstattungen sind Bänke, davon vier auf 5 m (eine Sitzgruppe) am Turm und zwei an der Friedenseiche, alle am Zubringer, keine an der Runde. Eine Sitzgruppe = eine Amenity.
- Schuenhagen: „4 Bänke an Station 1“ und „1 Bank an Station 3“ stehen in der Quelle, wurden nicht angelegt, weil „ohne Koordinate“. Die Stationskoordinate ist die Koordinate. Spielplatz (Quelle: schräg gegenüber dem Forstamt) fehlt.
- Tags (Runde 1, Regel 1): Rugard, Fuhlendorf und Schuenhagen haben nur `kinderfreundlich`. Rugard: Café 2 Min, Bänke → `einkehr`, `picknick`. Fuhlendorf: Nordlicht Harmonie 1 Min und Redensee 2 Min → `einkehr`. Schuenhagen: Bank, Rasenfläche, Spielplatz → `picknick`, `spielplatz`. Ribnitz hat `picknick`, aber kein `einkehr` trotz Amenity `gastro`.

## R2-9 Nearby: gedeckelt statt gerechnet

Alle vier haben genau 8 bis 9 Orte. Der Cap von 8 ist eine **Anzeige**-Regel, die Zuordnung hat keinen (Datenmodell). Ältere Trails liegen bei 1 bis 10. Unverknüpft, aber nach Luftlinie klar im Bereich (Fahrzeit nicht gerechnet, mit `nearby_zeiten.py --trail … --report` prüfen):

- Ribnitz: Caféstübchen Witt (4,2 km), Windflüchter (5,6), Heimatmuseum Graal-Müritz (6,5), Ostseecamp Rostocker Heide (7,2), Köhlerhof Wiethagen (9,3), Strand Markgrafenheide (12,8) und weitere in Graal-Müritz. Das sind die naheliegendsten Ziele, die Zuordnung hat sie gekappt.
- Fuhlendorf: Bernsteinreiter Barth (10,2), Treffpunkt Saatel (12,4).
- Rugard: Strand Prora (8,7), Dokumentationszentrum Prora (8,4), Camping Prora (8,2).
- Schuenhagen: Badestelle Barth (13,8, Grenzfall).
- Rugard: Start wird für die Fahrzeit 281 m auf die Straße gesnappt. Fahrzeit ab Parkplatz rechnen, nicht ab Waldbühne.

## R2-10 Selbstcheck zusätzlich

9. Gibt es einen Pfad ohne Route? Dann steht in `field_meta` der Weg, den du nach Overpass noch probiert hast (OSM-API, GPX). „Overpass nicht erreichbar“ allein zählt nicht.
10. `markierung` und `betreiber` echt, ohne Bot-Notiz? Jedes Nutzerfeld auf `nicht belegt`, `unbekannt`, `Kontakt:`, `Stand` durchsucht?
11. Stationen: Gibt es zwei oder mehr auf derselben Koordinate (außer Doppeltafel laut Quelle)? Gibt es Füllstationen (Start ohne Tafel, Themen-Sammler)? Liegen alle Stationen in der Fläche bzw. am Weg?
12. Länge, Dauer und Stationszahl beziehen sich auf dasselbe Stück Weg (Hauptrunde oder mit Erweiterung)?
13. Arten: jede Art, die auf einer Tafel oder im Stationsthema steht, ist `belegt`. Jede Tafelart, die nicht im Katalog ist, steht in `species_suggestions`. `trail_species` zählt so viele Zeilen, wie das Dossier Arten hat.
14. Lebensräume: kein Lebensraum, der nur im Schutzgebiet nebenan liegt.
15. Nearby: Zuordnung = alle ≤ 20 Min, nicht die ersten 8.
16. Beschreibung: kein Stationsinventar, kein Typ in der `kurzbeschreibung`, Satz 1 der `beschreibung` ≠ Inhalt der `kurzbeschreibung`.

---

# Runde 3 (31.10.2026): Trebeltal, Bremerhagen, Teterow, Dargun

Gegencheck der CMS-Entwürfe `erlebnispfad-trebeltal`, `naturlehrpfad-bremerhagen`, `walderlebnispfad-teterow`, `scrofipfad-dargun`. Gilt zusätzlich zu Runde 1 und 2.

## Was aus Runde 2 angekommen ist

- Tafelarten sind `belegt` (Bremerhagen: Reh, Rot-, Damhirsch, Biber, Nutria, Bisamratte, Honigbiene).
- Katalog-Lücken sind angelegt: Wolf, Haselmaus, Schreiadler, Rotmilan, Bisamratte.
- `eintritt_preise` und `oeffnungszeiten` sind `null` statt „nicht belegt: …“.
- Keine Stationen auf einer gemeinsamen Koordinate mehr, keine Füllstation „Start“.
- Teterow trennt Hauptweg und Erweiterung sauber (Länge, Dauer und Stationszahl gelten nur für den Hauptweg). So soll es sein.
- Dargun: Stationen sind echte OSM-Knoten, `titel` = Tafeltitel, `thema` = Unterzeile, `km` steigt monoton.
- Bremerhagen: Bild mit `geo_check = match`, Nearby gerechnet und offen begründet (nächstes Ziel 1292 s), Routenverzicht begründet.

## R3-1 `betreiber` leer, obwohl die Quelle ihn nennt

Alle vier haben `betreiber = ''` mit „nur Kontaktstelle belegt“. Die eigenen Quellenzeilen sagen aber:

- Trebeltal, Abschnitt 4: „Betreiber Landesforst MV, Forstamt Poggendorf“. Abschnitt 1: Gemeinschaftsprojekt der Gemeinden des Amtes Recknitz-Trebeltal und der Landesforst MV.
- Bremerhagen, Abschnitt 4: „Betreiber Landesforst MV, Forstamt Poggendorf“. Abschnitt 1: angelegt vom Staatlichen Forstwirtschaftsbetrieb Stralsund (heute Landesforst MV).
- Dargun, Abschnitt 4: „Betreiber Forstamt Dargun“.
- Teterow: Walderlebnisgebiet auf teterow.de, waldpädagogische Angebote des Forstamts Dargun. Stadt Teterow und/oder Landesforst MV, Forstamt Dargun.

`betreiber` ist Pflicht (`rules.py`). Ein Satz in Abschnitt 4 „Betreiber …“ ist ein Beleg. Nicht in R2 „Kontakt: …, Träger unbekannt“ ausweichen und nicht leer lassen. Wer das Wort „Betreiber“ in der eigenen Quellenzeile schreibt, trägt es ins Feld ein.

## R3-2 Route: gleiche Messlatte, andere Methode

- Der Bot routet per **Kürzester-Weg-Graph** von Stationsmarker zu Stationsmarker. Das erzeugt Umwege und Sehnen, wenn der OSM-Graph Waldwege nicht kennt (Fangabstand Bremerhagen 168 m, Dargun 251 m). Der Bot hat selbst gemerkt, dass Bremerhagen +188 % hat. Er hat es bei Trebeltal (+32 %) und Dargun (+18 %) trotzdem importiert und bei Teterow (+48 %) verworfen. Die Schwelle ist ±10 % (Selbstcheck 4). Gilt für alle gleich.
- Trebeltal: 3,96 km gegen `laenge_km` 3,0. Station 4 → 5 liegt 570 m Luftlinie auseinander, die Route braucht 1,55 km. Das ist der Umweg, den `field_meta` selbst nennt. 12 Segmente > 100 m, größtes 381 m.
- Dargun: 3,55 km gegen `laenge_km` 3,0 (Quellen sagen 1,5 / 2 / 3 / 4 / 5 km). 10 Segmente > 100 m, größtes 512 m. `dauer_min` 130 rechnet mit 3,0 km.
- Teterow: Der Bot hatte eine **Outdooractive-Linie** (1,6 km) und hat sie nicht übernommen, sondern „jeden 4. Punkt“ per Graph neu geroutet. Dabei kamen 2,37 km heraus. Das Ergebnis liegt plausibel an der Linie plus Philosophenweg (knapp 1 km). Das ist eine Vermutung von mir, bitte prüfen. Die Linie selbst nehmen, nicht neu routen.
- Reihenfolge ab jetzt: (1) Betreiber- oder Outdooractive-Linie als Geometrie, ausdünnen statt neu routen; (2) OSM-Ways als Geometrie (Way-Knoten, nicht Graph-Pfad); (3) Graph-Routing nur als Zubringer zwischen zwei sicheren Teilen; (4) `GEOMETRIE_FEHLT` melden mit Liste der probierten Quellen. Länge der Route ±10 % zur Config, sonst Config oder Route klären und `dauer_min` neu rechnen. Nicht „Quellwert 3.0 behalten“, wenn die Route 3,55 sagt.
- Bremerhagen: nicht angelegt. Die Begründung ist ehrlich, aber `field_meta` nennt kein Betreiber-GPX und keine Outdooractive-Linie. Beides vor dem Aufgeben prüfen.

## R3-3 Nutzerfelder: Reste

- `besuchshinweise`: Trebeltal „Ein Eintritt ist nicht belegt.“, Dargun „Die Eignung für Kinderwagen ist nicht belegt.“ Streichen (Runde 1 Abschnitt 2, Runde 2 R2-2).
- „(Stand 2026)“ in `anreise` Dargun und Teterow, „(Stand Oktober 2026)“ in `besuchshinweise` Teterow. Datum in `field_meta`.
- Teterow: Sperrung des Ehrenmals gehört nach TRAIL_SCAN („Zeitweilige Lage gehört in die Öffnungszeiten, nicht hierher“) in `oeffnungszeiten`, nicht in `besuchshinweise`. Die `kurzbeschreibung` beginnt außerdem mit dem gesperrten Ehrenmal („Am Fuß des Ehrenmals …“). Anfang ändern.
- `markierung` Dargun leer („in den Quellen nicht genannt“). Pflichtfeld. Eintrag: „Stationstafeln mit Scrofi“, wenn belegt, sonst „keine“.
- `region` „Nordvorpommern“ wieder bei Trebeltal und Bremerhagen (R2-7 nicht umgesetzt). Landkreis gibt es seit 2011 nicht mehr.
- Trebeltal: `trail_sources` Abschnitt 1 sagt „Schutzgebiet keins“, das Feld sagt GGB 1941-301. Alte Quellenzeile nachziehen.

## R3-4 Stations-`kurztext`

- Dargun, alle 15: Meta statt Inhalt. „… nach ihrem Titel“, „… laut Titel“, „… wie der Titel andeutet“, „… das die Quelle als Tafelthema nennt“, „aus dem Faltblatt“. Der Nutzer liest über die Quelle, nicht über die Station. Runde 1 Abschnitt 5 sagt dazu: ohne gelesenen Tafeltext knapp und ehrlich („Tafel zu Tarnung“) und in `import_hinweis` vermerken. Der Bot hat 15-mal Titel-Meta geschrieben und `import_hinweis` nicht gesetzt.
- Bremerhagen Station 8: „… laut Quelle gut erreichbar in den Pfad integriert“ (Dossier-Sprache). Station 7: „… ist das Thema dieser Station“ (Füllsatz).
- Teterow Stationen 5, 8, 9: „die fünfte Station“, „vorletzte“, „letzte“. Ordnungszahlen im Text brechen, sobald sich die Reihenfolge ändert. Inhalt statt Position. Station 5 „Klimawandel“ sagt nur das Thema.
- Teterow `erlebnisse` leer bei 8 von 9, obwohl „Sehen wie die Waldtiere“ (mitmach-modell), Abenteuerspielplatz, „Alle übe'n Graben“, „Gleichgewicht“ und Totholz Mitmach-Stationen sind (Runde 1 Abschnitt 5).

## R3-5 Arten

- Trebeltal: 3 Arten, begründet mit „Mindestwerte nicht erreicht“. Das ist kein Grund, bei 3 zu bleiben. `typisch` aus dem Pool (buchenwald, streuobst-hecke) ist erlaubt (Runde 2 R2-6). Station 5 behandelt die Kirsche (Vogelkirsche im Katalog) → `belegt`. Station 4 vergleicht Flügelspannweiten von Greifvögeln (Rotmilan im Katalog) → `typisch`. Ziel 10 bis 14.
- Teterow: 3 Arten. Rotmilan steht im Pfadtext („fliegen wie ein Rotmilan“) und ist im Katalog → `belegt`. Marder („balancieren wie ein Marder“) fehlt im Katalog → `species_suggestions`. `lebensraeume` ist nur `moor`, der Pfad liegt aber im Laub-Nadel-Mischwald, das Moor ist Station 7. `eichen-mischwald` ergänzen (Freigabe Marc bleibt offen, aber nicht deshalb nur `moor`), dann Pool.
- Dargun: 5 Fauna, 1 Flora. Froschgeräusch (Bohlenstege) und Spinne (Fortbewegungstafel) sind genannt, Grasfrosch und Gartenkreuzspinne liegen im Katalog → `typisch`. Pool Buchenwald für Flora.
- Bremerhagen: 0 Baumarten, obwohl Laubbäume-Tafel und Nadelbäume-Tafel. Statt Efeu und Brombeere passen Stieleiche, Rotbuche, Kiefer (`typisch`). Station 21 nennt Wildbienen (`wildbiene` im Katalog), Station 11 die Fledermaus (`zwergfledermaus` im Katalog) → beide fehlen.

## R3-6 Texte

- Bremerhagen `beschreibung` Satz 1 ist Inventar („Spielplatz mit Kletterparcours, Pavillon voller Pilze, Wald-Imkerei“). Das Besondere steht in Abschnitt 1 und wird nicht benutzt: seit 1968 von Staatlichem Forstwirtschaftsbetrieb, Schulen und Schullandheim angelegt. „Pavillon voller Pilze“ ist nicht belegt, die Quelle sagt „Pilz-Pavillon“.
- `kurzbeschreibung` mit Inventar und Zahl: Bremerhagen („23 teils interaktiven Tafeln, einem Spielplatz, einer Imkerei und einem Teich“), Teterow („Mitmachstationen, einem Spielplatz und einem Bohlenweg“), Trebeltal („QR-Codes, Adlerhorst, Streuobstwiese, Bienenkästen“).
- „3 km“ in der `kurzbeschreibung` bei Trebeltal und Dargun, obwohl Route und Quellen etwas anderes sagen (R3-2). Zahl erst nennen, wenn sie feststeht.
- Teterow Satz 1: „messen sich Groß und Klein“ ist die Floskel „für Groß und Klein“ aus der Wortliste (hart).
- Lexikon: Teterow `beschreibung` „Wildschweinkuhle“, Station „Wildschweinkessel“. Ein Begriff pro Ding. Trebeltal „an jedem Halt“, Lexikon sagt „Station“.
- Inventar in allen vier `beschreibung` ab Satz 2 (Runde 2 R2-7 weiter offen).

## R3-7 Amenities und Tags

- Trebeltal: nur der Parkplatz. `besuchshinweise` nennt „viele Bänke und Sitzplätze“ und den überdachten Schulungsraum. Das gehört als Amenities (`bench`, `shelter`) an die Stationskoordinaten, dann raus aus dem Text.
- Bremerhagen: Hubertus-Hütte (Rast, Station 13) fehlt als `shelter`.
- Dargun: Gaststätte 95 m am Start als Amenity, Café 3 Min Auto, aber Tags nur `kinderfreundlich`. `einkehr` fehlt (Runde 1 Regel 1, Runde 2 R2-8). Trebeltal: ebenfalls nur `kinderfreundlich`.
- Teterow: Tag `spielplatz`, aber keine Amenity `playground`.

## R3-8 Nearby

- Bremerhagen mit 0 Orten ist plausibel und transparent begründet. Nächster Ort ist Hofladen Zandershagen (14,6 km Luftlinie, 21,5 Min).
- Dargun hat wieder genau 8 Orte. Der Verchen-Cluster bei 6 km Luftlinie fehlt (Peenetal Safari, Minigolfanlage, Café im Brauhaus, Badestelle, Abenteuer Peenetal, Piratenkanone). Dazwischen liegt der Kummerower See, die Fahrzeit kann über 20 Min liegen. Mit `nearby_zeiten.py --trail scrofipfad-dargun --report` prüfen, nicht kappen.

## R3-9 Selbstcheck zusätzlich

17. Steht in einer eigenen Quellenzeile „Betreiber …“? Dann steht er im Feld.
18. Route: alle Pfade gegen ±10 % gemessen, nicht nur der, der gerade knapp danebenliegt. Wurde die Betreiber- oder Outdooractive-Linie als Geometrie genommen, bevor der Graph geroutet wurde? Segmente > 100 m gezählt?
19. Kein Stations-`kurztext` spricht über Titel, Quelle, Faltblatt oder Position („laut“, „nach dem Titel“, „vorletzte“).
20. Arten: nicht unter 8 bleiben, weil Mindestwerte nicht erreicht sind. Pool füllen, `typisch` setzen.
21. Hat jeder Lebensraum in `lebensraeume` einen Beleg am Pfad (Station oder Quelle)? Fehlt ein Hauptlebensraum im Katalog, nächstpassenden eintragen und melden, nicht den Nebenlebensraum allein.
