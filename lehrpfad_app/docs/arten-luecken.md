# Arten-Lücken HAVE

Stand 2026-09-19 (Link-Pass + Katalog-Welle 1). Inventar bleibt die Nachweis-Quelle. `arten[]` der Link-Lücken, Ist-prüfen-Streichungen und Welle-1-Joins stehen in den Seeds.

Arbeit: [arten-link](https://trello.com/c/uiRVDUk0) · Katalog: [arten-katalog](https://trello.com/c/fzqOiK3a). Inventar: [arten-der-trails](https://trello.com/c/0H25mOgs) (Review).

## Was das ist

Inventar: welcher HAVE-Trail welche Art **am Ort belegt** noch nicht hat. Link-Pass 2026-09-19 hat Katalogarten in `arten[]` gehängt, wo die Leiter schon grün war. Welle 1 hängt fünf Mehrfach-Arten (Kultur-Apfel, Hainbuche, Kammmolch, Bekassine, Weißtanne). Median Flora/Fauna **4**. Summe Zuordnungen ~303 (inkl. Geräte). Katalog: **27 Flora / 45 Fauna**.

## Nachweis-Leiter

Aufnahme nur, wenn **dieser Ort** die Art trägt **und** eine Familie sie auf dem Weg sehen, hören oder antreffen kann ([`SPECIES_CONTENT.md`](../tools/SPECIES_CONTENT.md): Ort zuerst).

1. Trail-eigen: Stationstexte, Betreiber-Site/PDF, Research „Arten“, Tafeln
2. Schutzgebiet, in dem der Pfad liegt: NP-/Naturpark-Liste, NSG-VO, Natura-2000-SDF, Landesforst — nur wenn der Text den **Ort** meint, nicht das Bundesland
3. Nicht: „typischer deutscher Wald“, iNaturalist/GBIF-Dump, ein Punkt 8 km daneben, Maskottchen, Comic, andere Schleife desselben Parks

Kalia ist kein iNaturalist ([`oeffentlich/GRUND.md`](oeffentlich/GRUND.md)).

## Quellenkanon (HAVE Schritt 6)

| Region | Quelle | Wann |
|---|---|---|
| Überall | Betreiber-Seite, Flyer, Tafel-Titel dieses Pfads | immer zuerst |
| DE in NP/NSG/FFH | Natura-2000-SDF (EEA/BfN); NP-Seiten | Pfad liegt im Gebiet |
| DE Forst | Landesforst / Stadtforst-Reviertext **dieses** Reviers | Waldpfad |
| SH NER | Stadt-/Naturpark-Faltblatt des NER | Kollhorst, Schwartautal, Untereider, … |
| DK | GeoCenter / Naturstyrelsen-Gebietsseite; Arter.dk nur wenn der Trail im Gebiet liegt | Møns Klint |
| ES/CAT | Parc / Diputació-Flyer **dieser** Route; nicht FloraCat-Dump | Collserola, Montnegre |

Wiederkehrende URLs:

- NP Hainich: https://www.nationalpark-hainich.de/de/nationalpark/natur.html
- NP Bayerischer Wald: https://www.nationalpark-bayerischer-wald.de/natur/tiere/index.htm
- NP Jasmund: https://www.nationalpark-jasmund.de/wissen-verstehen/natur-landschaft/tiere
- NP Müritz: https://www.mueritz-nationalpark.de/wissen-verstehen/natur/saeugetiere
- NP Wattenmeer SH / NER SPO: https://www.nationalpark-wattenmeer.de/sh/naturerlebnisraum-spo/
- Collserola Itinerari: https://parcnaturalcollserola.cat/itinerais/passejada-per-les-fonts/
- Montnegre SL-C 73 Flyer: https://parcs.diba.cat/documents/75109/15894269/p05d072.pdf

## Felder

| Feld | Bedeutung |
|---|---|
| **Ist** | `arten[]` flora/fauna jetzt |
| **Link-Lücke** | schon in `species.json`, am Ort belegt, nicht in `arten[]` |
| **Katalog-Kandidat** | Name + Lat + Quelle, noch nicht im Katalog |
| **Nicht** | geprüft, verworfen (Grund) |
| **Ist prüfen** | aktueller Eintrag ohne Ortsquelle oder falsch gemappt |

Geräte in `arten[]` sind hier ignoriert.

## Stand

60 HAVE-Trails. Link-Pass drin. Dünn bleiben: Everstorf, Harzungspfad, Usedom, Pflanzenschutz, Wasserspielplätze, Pinke-Panke (Hof), Trails ohne öffentliche Artliste.

Gold (Tafeln nennen die Arten): Heide-Erlebnisweg, Von Moor zu Moor, Raddusch.

---

## Priorität zum Nachziehen

Link-Pass erledigt (inkl. Leiter-2 Himmel an Spurenweg/Stendenitz/Serrahn). Gestrichen: Bechstein Prora, Stieleiche Vallvidrera, Buntspecht Saarschleife.

Offen = Unikate / Rest-Kandidaten, harte Ortsquelle + Familie. Welle 1 (Apfel, Hainbuche, Kammmolch, Bekassine, Weißtanne) ist im Katalog und gelinkt.

1. `kollhorst` → Teichmolch
2. `archaeologischer-wanderpfad-fischbek` → Heidschnucke
3. `lehrpfad-sandhof` → Wacholder
4. `baumkronenpfad-ivenack` → Damhirsch (Park, nicht Steg)
5. `naturerlebnisraum-spo` → Strandhafer, Silbermöwe, Strandwermut, Salzmelde
6. `sl-c-73-alzines-can-portell` → Erdbeerbaum
7. `spurenweg-kratzeburg` → Rotfuchs
8. `wolfspfad-zwenzow` → Wolf
9. `wupatz` → Hängebirke, Schwarzspecht
10. `raddusch` → Kiebitz, Weißstorch, Kalmus
11. `zweiseitenweg-rambow` → Rohrdommel
12. `kaeflingsberg-speck` → Sommerlinde
13. `fonts-vallvidrera` → Platane, Aleppokiefer

Feldliste vor Ort, nicht raten: Kinderwald-Schilder, Dreetz-Schilder, Ellerbek 35 Tafeln, Pflanzenschutz 10 Tafeln, Silberbergen, Wahrberge-Arboretum.

---

## Katalog-Kandidaten (über Trails)

Welle-1-IDs sind im Katalog. Hier der Rest plus die fünf, die schon drin sind (markiert).

| Name | Lat | Trails |
|---|---|---|
| Strandhafer | *Ammophila arenaria* | spo |
| Strandwermut | *Artemisia maritima* | spo |
| Salzmelde | *Halimione portulacoides* | spo |
| Silbermöwe | *Larus argentatus* | spo |
| Brandgans | *Tadorna tadorna* | spo |
| Weißtanne | *Abies alba* | schwarzwald, bayerischer-wald — **Katalog, gelinkt** |
| Erdbeerbaum | *Arbutus unedo* | sl-c-73 |
| Platane | *Platanus × hispanica* | fonts-vallvidrera |
| Aleppokiefer | *Pinus halepensis* | fonts-vallvidrera |
| Kultur-Apfel | *Malus domestica* | kollhorst, braumannswiesen, dreetz, schwartautal — **Katalog, gelinkt** |
| Kammmolch | *Triturus cristatus* | kollhorst, schwartautal (FFH) — **Katalog, gelinkt** |
| Teichmolch | *Lissotriton vulgaris* | kollhorst |
| Heidschnucke | *Ovis aries* (Landrasse, nicht in `schaf` aufgehen) | fischbek |
| Bekassine | *Gallinago gallinago* | rambow, raddusch — **Katalog, gelinkt** |
| Rohrdommel | *Botaurus stellaris* | rambow |
| Kiebitz | *Vanellus vanellus* | raddusch |
| Weißstorch | *Ciconia ciconia* | raddusch |
| Kalmus | *Acorus calamus* | raddusch |
| Wacholder | *Juniperus communis* | sandhof |
| Hängebirke | *Betula pendula* | wupatz |
| Hainbuche | *Carpinus betulus* | wupatz, hainich, ivenack, naturwaldpfad — **Katalog, gelinkt** |
| Esche | *Fraxinus excelsior* | hainich, ivenack, naturwaldpfad |
| Sommerlinde | *Tilia platyphyllos* | kaeflingsberg-speck |
| Schwarzspecht | *Dryocopus martius* | wupatz, hainich |
| Mittelspecht | *Dendrocoptes medius* | hainich, heilige-hallen |
| Rotfuchs | *Vulpes vulpes* | spurenweg-kratzeburg |
| Wolf | *Canis lupus* | wolfspfad-zwenzow; bayerischer-wald nur Freigelände |
| Damhirsch | *Dama dama* | ivenack (Park), jasmund NP-weit |
| Rothirsch | *Cervus elaphus* | müritz NP, bayerischer-wald Freigelände |
| Hausesel | *Equus asinus* | pinke-panke |
| Hausschwein | *Sus scrofa domesticus* | pinke-panke |
| Hausgans | *Anser anser domesticus* | pinke-panke |
| Liguster | *Ligustrum vulgare* | natter-pfad |
| Traubenkirsche | *Prunus padus* | natter-pfad |
| Salweide | *Salix caprea* | natter-pfad |
| Lorbeer | *Laurus nobilis* | sl-c-73 |
| Leberblümchen | *Hepatica nobilis* | fossilruten |
| Manns-Knabenkraut | *Orchis mascula* | fossilruten (Klinteskov, nicht Høvblege) |
| Elsbeere | *Sorbus torminalis* | hainich |
| Luchs | *Lynx lynx* | bayerischer-wald **Freigelände Lusen**, nicht Steg |
| Braunes Langohr u. a. | *Plecotus auritus* … | bossow (Abend/Bunker, Thema des Pfads) |
| Aronstab | *Arum maculatum* | ploener-seeufer |
| Wildschwein | *Sus scrofa* | fonts-vallvidrera (Spur sicher) |
| Zauneidechse | schon Katalog | heide, kollhorst, ravensberge, fischbek — **gelinkt** |
| Graureiher | *Ardea cinerea* | staditzwald (Kolonie am Teich, Faltblatt Station 1) |
| Blässhuhn | *Fulica atra* | staditzwald (Teich, Faltblatt Station 1) |
| Feldahorn | *Acer campestre* | staditzwald (19 m, Station 5) |
| Mistel | *Viscum album* | staditzwald (auf Pappeln, Station 4) |
| Winterlinde | *Tilia cordata* | staditzwald (Pflanzgut Fasanerie, Station 9) |
| Rotmilan | *Milvus milvus* | auwald-erlebnispfad (App-Station, Ahoi-Reportage) |
| Märzenbecher | *Leucojum vernum* | auwald-erlebnispfad (Frühjahr auf dieser Runde, Ahoi) |
| Schlehe | *Prunus spinosa* | auwald-erlebnispfad (Marmeladen-Tafel am Weg, Ahoi) |

Nicht bauen ohne Ortsquelle: Reh/Fuchs/Kohlmeise als Default-Wald; Seehund am SPO-NER; Bechstein in Prora; Stieleiche in Vallvidrera; Traubeneiche wo nur „Eiche“ steht.

---

# Trails

## Wipfel / Kronen

### baumkronenpfad-hainich — Baumkronenpfad Hainich

`erlebniswald` · Thiemsburg, NP Hainich

**Ist:** Rotbuche, Bergahorn, Stieleiche, Schwarzerle, Hainbuche / Wildkatze, Bechsteinfledermaus, Buntspecht, Großer Schillerfalter

**Link-Lücke:** —

**Katalog-Kandidat:** Gemeine Esche *Fraxinus excelsior*; Elsbeere *Sorbus torminalis*; Mittelspecht *Dendrocoptes medius* (NP: häufigste Beobachtung an Thiemsburger Wegen); Schwarzspecht *Dryocopus martius*.

**Nicht:** Orchideen-Liste; Neuntöter (Offenland); Wildkatze bleibt Charakterart, Sicht = Hütscheroda-Gehege extra.

Quellen: https://www.nationalpark-hainich.de/de/nationalpark/natur.html · https://www.nationalpark-hainich.de/de/ausflugsziele/baumkronenpfad/rundgang.html · https://www.nationalpark-hainich.de/de/nationalpark/natur/tiere/spechte.html

### baumkronenpfad-ivenack — Ivenacker Eichen

`erlebniswald` · Ivenack, NNM

**Ist:** Stieleiche, Rotbuche, Bergahorn, Hainbuche / Konik

**Link-Lücke:** —

**Katalog-Kandidat:** Damhirsch *Dama dama* (~70–100, Hutewald-Verbiss) — **Park/Boden**, Hunde/Tiere auf dem Pfad verboten. Esche — FFH-Mischung.

**Nicht:** Eremit (FFH, unsichtbar); Turopolje nur wenn Hof-Logik wie Pinke-Panke gewollt; Mittelspecht ohne Besucherseite.

Quellen: https://www.wald-mv.de/landingpage/ivenacker-eichen/ · https://www.wald-mv.de/landingpage/baumkronenpfad/ · https://www.ivenacker-eichen.de/

### baumwipfelpfad-bayerischer-wald — Neuschönau / Lusen

`erlebniswald` · NP Bayerischer Wald

**Ist:** Rotbuche, Fichte, Bergahorn, Weißtanne

**Link-Lücke:** Eichhörnchen — nur Seed-Text/Comic, **kein** Betreiber-Satz → eher Nicht.

**Katalog-Kandidat:** Luchs, Auerhuhn, Rothirsch, Wolf — **wild selten**; Familie sieht sie im **Freigelände Lusen** nebenan (Eintritt extra). Nicht als Steg-Wildarten führen, höchstens mit Label Freigelände.

**Nicht:** Bär/Wisent (Freigelände, historisch); Dreizehenspecht (NP-Besonderheit, nicht Wipfel-Alltag).

Quellen: https://www.nationalpark-bayerischer-wald.de/natur/lebensraeume/index.htm · https://treetop-walks.com/bayerischer-wald/

### skywalk-allgaeu — Scheidegg / Oberschwenden

`erlebniswald` · skywalk allgäu gGmbH (KJF Augsburg), Plenterwald

**Ist:** Weißtanne, Fichte, Rotbuche

**Link-Lücke:** —

**Katalog-Kandidat:** —

**Nicht:** Streichelzoo; Boden-Pfade (Barfuß, Entdecker); Lärche Bauholz; Rotmilan nur Tafel.

Quellen: https://www.waldwelt-allgaeu.de/erlebnisse/skywalk-baumwipfelpfad/ · https://de.wikipedia.org/wiki/Skywalk_Allgäu

### baumkronenweg-ziegelwies — Füssen / Pinswang

`erlebniswald` · Trägerverein Ostallgäu-Außerfern, AELF Kaufbeuren, Lech-Auwald

**Ist:** Grauerle

**Link-Lücke:** —

**Katalog-Kandidat:** —

**Nicht:** Auwaldpfad-Fauna (Floß extra); Ausstellung „Mein Wald“ indoor; Lärche nur Bauholz.

Quellen: https://www.walderlebniszentrum.eu/baumkronenweg/ · https://aelf-kf.bayern.de/forstwirtschaft/wald/072604/index.php · https://www.ganz-meine-natur.bayern.de/hot-spots-uebersicht/falkenstein/

### baumwipfelpfad-steigerwald — Ebrach / Ebracher Forst

`erlebniswald` · BaySF, Naturpark Steigerwald

**Ist:** Rotbuche

**Link-Lücke:** —

**Katalog-Kandidat:** Traubeneiche *Quercus petraea* (Hoher Buchener Wald / Forstbetrieb Ebrach, nicht Stieleiche).

**Nicht:** Rothirsch, Reh, Mufflon (Wildgehege extra); Eichhörnchen nur Kronen-Ökologie ohne Ortsbeobachtung.

Quellen: https://www.baysf.de/baumwipfelpfad-steigerwald/ · https://www.baumwipfelpfadsteigerwald.de/ · https://www.baysf.de/ebrach/

### baumwipfelpfad-ruegen — Prora

`erlebniswald`

**Ist:** Rotbuche, Schwarzerle / Seeadler

**Ist prüfen:** Bechsteinfledermaus — **gestrichen** (DBU-Fläche ohne Fledermausart, Katalog-Text Hainich).

**Link-Lücke:** keine belastbare weitere Katalog-Art am Steg.

**Nicht:** DBU-Offenland (Knabenkraut, Wollgras) = Feuersteinfelder, nicht der Steg. Eichhörnchen Comic.

Quellen: https://treetop-walks.com/ruegen/baumwipfelpfad/ · https://www.dbu.de/naturerbeflaechen/prora/

### baumwipfelpfad-usedom — Heringsdorf

`erlebniswald`

**Ist:** Rotbuche, Kiefer / Seeadler

**Link-Lücke / Katalog-Kandidat:** keine weitere Betreiber-Art. Kiefer bleibt Mischwald-Proxy.

**Nicht:** Lärche/Douglasie = **Bauholz** des Stegs.

Quelle: https://treetop-walks.com/usedom/baumwipfelpfad/

### baumwipfelpfad-saarschleife — Orscholz

`erlebniswald`

**Ist:** Rotbuche, Douglasie

**Ist prüfen:** Buntspecht — **gestrichen** (Betreiber nennt ihn nicht).

**Katalog-Kandidat:** Eiche ohne Art — nicht auf Stieleiche/Traubeneiche mappen.

**Nicht:** Wildkatze (Naturpark, Dämmerung, nicht Wipfel-Tag); Traubeneiche erfunden; Eichhörnchen Comic.

Quelle: https://treetop-walks.com/saarschleife/baumwipfelpfad/

### baumwipfelpfad-schwarzwald — Sommerberg

`erlebniswald` · Bad Wildbad

**Ist:** Rotbuche, Fichte, Weißtanne

**Katalog-Kandidat:** —

**Nicht:** Rothirsch (nicht auf der Pfadseite); Auerhahn (Tafelthema Naturpark, nicht Tagwalk-Sicht); Eichhörnchen Comic.

Quellen: https://treetop-walks.com/schwarzwald/baumwipfelpfad/ · https://naturparkschwarzwald.de/aktiv_unterwegs/erlebnispfade/baumwipfelpfad/

---

## Küste

### naturerlebnisraum-spo — St. Peter-Ording

`kueste` · NP Wattenmeer SH

**Ist:** Strandflieder, Queller / Austernfischer

**Katalog-Kandidat:** Strandhafer *Ammophila arenaria*; Strandwermut *Artemisia maritima*; Salzmelde *Halimione portulacoides* — Flowering Five, „im NER findbar“. Silbermöwe *Larus argentatus*; Brandgans *Tadorna tadorna* — Flying Five. Optional Alpenstrandläufer (Rast, nicht Brut).

**Nicht:** Seehund/Kegelrobbe — NER-Seiten nennen sie nicht (Park allgemein / andere Sandbank). Ringelgans — Flying Five sagt ausdrücklich selten im SPO-Vorland. Small Five nur wenn Wirbellose gewollt.

Quellen: https://www.nationalpark-wattenmeer.de/sh/naturerlebnisraum-spo/ · https://www.nationalpark-wattenmeer.de/sh/naturerlebnisraum-spo/flowering-five/

### erlebnisrundweg-friedrichskoog — Spitze

`kueste`

**Ist:** Strandflieder, Queller / Austernfischer

**Ist prüfen:** Strandflieder — Gemeinde nennt ihn explizit für den **Salzwiesenpfad Schwienskopp**, nicht für den Pricken-Loop. Habitat Station 4 ja, Claim schwächer.

**Katalog-Kandidat:** keine für *diese* Runde.

**Nicht:** Seehund (Seehundstation = Gehege extra). Wattarten ohne Stationsnamen.

Quelle: https://www.friedrichskoog.de/urlaub/urlaub-aktiv/wandern/

### fossilruten-moens-klint — Møns Klint

`kueste` · DK

**Ist:** Rotbuche, Knabenkraut / Wanderfalke

**Ist prüfen:** Katalog-Knabenkraut = eher *Dactylorhiza*. NST für **Klinteskov** (Rückweg dieser Runde): Manns-Knabenkraut *Orchis mascula*. GeoCenter-Orchideenpage = Høvblege/Jydelejet, **anderer** Naturraum.

**Katalog-Kandidat:** Leberblümchen *Hepatica nobilis*; Manns-Knabenkraut *Orchis mascula*; Rotes Waldvögelein *Cephalanthera rubra* — Klinteskov, Naturstyrelsen.

**Nicht:** Ravn (nicht auf NST/GeoCenter); Sortplettet blåfugl = Høvblege.

Quellen: https://moensklint.dk/vandreruter/ · https://naturstyrelsen.dk/find-et-naturomraade/naturguider/oevrige-sjaelland-og-sydhavsoeerne/moens-klint/dyr-og-planter

### stubbenkammer-koenigsstuhl — Jasmund

`kueste` · NP Jasmund

**Ist:** Rotbuche, Knabenkraut / Wanderfalke, Seeadler, Kranich

**Link-Lücke:** Sumpf-Schwertlilie / Sumpfblutauge / Wollgras — Moore des NP, nicht der Skywalk-Alltag → nur wenn die gewählte Runde am Moor liegt.

**Katalog-Kandidat:** Uferschwalbe *Riparia riparia* (Kreidekliff); Waldeidechse *Zootoca vivipara*; Esche, Bergahorn, Eibe am Hangwald.

**Nicht:** Kormoran — Kolonie Heuwiese = NP Boddenlandschaft, nicht Jasmund-Tiere-Seite. Kegelrobbe = Küste Abstand, nicht Königsstuhl-Steg.

Quellen: https://www.nationalpark-jasmund.de/wissen-verstehen/natur-landschaft/tiere · https://www.nationalpark-jasmund.de/wissen-verstehen/natur-landschaft/waelder

---

## Moor / Spreewald / Heide

### von-moor-zu-moor — Stechlin

`moor`

**Ist:** Torfmoos, Wollgras, Sumpf-Schwertlilie, Sumpfblutauge, Knabenkraut, Schwarzerle / Ringelnatter, Kleiner Fuchs, Sumpfschrecke, Distelfalter, Große Moosjungfer, Biber

**Link-Lücke:** —

**Nicht:** Mopsfledermaus, Hirschkäfer, Kleine Maräne — NSG Stechlin, nicht der Lehrpfad.

Quellen: Stationstexte Seed · https://www.stechlin-ruppiner-land-naturpark.de/themen/tiere/elbebiber/

### raddusch — Moorlehrpfad

`moor`

**Ist:** Wollgras, Sumpfblutauge, Sumpf-Schwertlilie, Schwarzerle, Sumpfdotterblume / Moorfrosch, Rotbauchunke, Großer Feuerfalter, Große Moosjungfer, Kranich, Schwarzstorch, Fischotter, Bekassine

**Katalog-Kandidat:** Kiebitz *Vanellus vanellus*; Weißstorch *Ciconia ciconia*; Kalmus *Acorus calamus* — Betreiber [moore.php](https://www.raddusch-spreewald.de/aktivitaeten/moorlehrpfad/moore.php/) dieser Weg.

**Nicht:** Wachtelkönig (nacht/scheu); Reh/Wildschwein ohne Lehrpfad-Fokus; Birke/Schilf als Gattung.

### zweiseitenweg-rambow — Rambower Moor

`moor` · Biosphäre Elbe

**Ist:** Wollgras, Knabenkraut, Schwarzerle / Kranich, Großer Feuerfalter, Bekassine

**Katalog-Kandidat:** Rohrdommel *Botaurus stellaris* — Rohrdommelturm + NABU-Steckbrief.

**Nicht:** Seeadler — Seed/Hörtext, **kein** Biosphäre-/Reiseland-Satz für diesen Weg. FFH-Liste (Eisvogel, Neuntöter) = Gebiet, nicht Pfadtext.

Quellen: https://www.elbe-brandenburg-biosphaerenreservat.de/erleben-lernen/aktiv-in-der-natur/wandern/zweiseitenweg-rund-um-das-rambower-moor/ · https://www.reiseland-brandenburg.de/poi/prignitz/wandertouren/der-zweiseitenweg/

### lehde — Rund um Lehde

`spreewald`

**Ist:** Schwarzerle, Sumpfdotterblume / Eisvogel, Biber, Kranich, Fischotter, Rotbauchunke

**Link-Lücke / Katalog-Kandidat:** keine neue Namensquelle. Biosphäre: Tafeln zu „typischen Pflanzen, Tieren“ ohne Namen.

**Nicht:** Storch/Reiher auf Dorfseite; Biosphäre-Artseiten ohne diesen Rundweg.

Quelle: https://www.spreewald-biosphaerenreservat.de/themen/routen-touren/lehder-rundweg/

### natter-pfad-goyatz

`walderlebnispfad`

**Ist:** Heckenrose, Haselnuss / Ringelnatter

**Katalog-Kandidat:** Liguster *Ligustrum vulgare*; Traubenkirsche *Prunus padus*; Salweide *Salix caprea* — Hecke am Weg, Naturwelt Lieberose.

**Nicht:** Knabenkraut (Wiese nur Blick). Biber/Kranich/Otter/Reh = **andere** Loops (Biber-, Kranich-, Otter-, Rehpfad). Seed-Text Biber/Kranich nicht auf diesen Pfad mappen.

Quelle: https://www.naturwelt-lieberose.de/highlights/naturlehrpfad-ludwig-leichhardt

### heide-erlebnisweg — Kyritz-Ruppiner Heide

`wald`

**Ist:** Besenheide, Kiefer / Wiedehopf, Heidelerche, Ziegenmelker, Rote Röhrenspinne, Heidekraut-Seidenbiene, Braunkehlchen, Neuntöter, Steinschmätzer, Konik, Seeadler, Fischadler, Zauneidechse

**Link-Lücke:** —

**Katalog-Kandidat:** Brachpieper *Anthus campestris* — Leitbild/Heide-Knigge, familien-schwach.

**Nicht:** Wolf (2008, keine Familienbeobachtung); Ziegenmelker schon drin und nachtaktiv.

Quellen: https://www.sielmann-stiftung.de/natur-erleben/kyritz-ruppiner-heide · Leitbild SNL

---

## NP Müritz (außer Wipfel)

### spurenweg-kratzeburg

`sinnespfad`

**Ist:** Stieleiche, Kiefer / Igel, Eisvogel, Hummel, Seeadler, Fischadler

**Link-Lücke:** —

**Katalog-Kandidat:** Rotfuchs *Vulpes vulpes* — NP-Text zu ehemaligen Siedlungen am Spurenweg. Rothirsch/Reh/Wildschwein — Spuren ja, Tier selten.

**Nicht:** Kleiner Fuchs (Falter) mit Rotfuchs verwechseln.

Quelle: https://www.mueritz-nationalpark.de/erleben-erholen/aktiv-in-der-natur/erlebnispfade/spurenweg-kratzeburg

### wald-erlebnispfad-serrahn

`walderlebnispfad` · UNESCO Buchenwald

**Ist:** Kiefer, Stieleiche, Rotbuche, Torfmoos, Wollgras / Kranich, Seeadler, Fischadler

**Link-Lücke:** Fichte — Seed-Vergleichstext, nicht Betreiber-Hauptart.

**Nicht:** Traubeneiche statt Stieleiche ohne Tafel-Art.

Quelle: https://www.mueritz-nationalpark.de/erleben-erholen/aktiv-in-der-natur/erlebnispfade/wald-erlebnispfad-serrahn

### wolfspfad-zwenzow

`walderlebnispfad`

**Ist:** Kiefer, Stieleiche / Rote Waldameise, Igel

**Katalog-Kandidat:** Wolf *Canis lupus* — Thema, Stationen, Sicht = Fotofalle. Trotzdem der Pfad existiert dafür.

**Nicht:** Wolf als „gesehen auf dem Spaziergang“ verkaufen.

Quelle: https://www.mueritz-nationalpark.de/erleben-erholen/aktiv-in-der-natur/erlebnispfade/wolfspfad-zwenzow

### kaeflingsberg-speck

`wald`

**Ist:** Stieleiche, Kiefer, Rotbuche, Torfmoos / Kranich, Eisvogel, Fischadler

**Katalog-Kandidat:** Sommerlinde *Tilia platyphyllos* — 800-jährige Linde ist der Start, Seed-Beschreibung. Huteeiche = Stieleiche schon.

**Nicht:** Wildschwein (Wegmarkierung); Rothirsch NP-weit ohne Turm-Tafel hier.

Quelle: Seed + https://www.mueritz-nationalpark.de/erleben-erholen/aktiv-in-der-natur/wandern

### heilige-hallen — Lüttenhagen

`wald` · NSG Totalreservat

**Ist:** Kiefer, Stieleiche, Rotbuche / Igel, Rote Waldameise

**Link-Lücke:** Wollgras — Kesselmoor-Blick im NSG, nicht Hallen-Kern.

**Katalog-Kandidat:** Mittelspecht *Dendrocoptes medius* — STALU Höhlenbrüter.

**Nicht:** Eremit; Igel/Ameise ohne stärkere Quelle vermehren.

Quellen: https://metaver.de/trefferanzeige?docuuid=963A190C-65CC-11D3-A355-BE3BE1E79139 · STALU FFH-Text Hallen

### hullerbusch

`wald`

**Ist:** Kiefer, Stieleiche, Rotbuche, Torfmoos, Wollgras / Schaf

**Link-Lücke:** Schwarzerle — Ufer Luzin/Zansen.

**Katalog-Kandidat:** Sonnentau *Drosera rotundifolia* — Tafel dieses Pfads, aber 2–3 cm, Familie sieht ihn kaum → nur wenn Tafel-Art gewollt. Sumpf-Calla *Calla palustris* — NSG-Moor.

**Nicht:** Dachs (Bank-Relief); Kranich/Eisvogel Wikipedia „vereinzelt“.

Quellen: https://de.wikipedia.org/wiki/Naturschutzgebiet_Hullerbusch_und_Schmaler_Luzin · Nordkurier Sanierung Hullerbusch

### lehrpfad-sandhof

`wald` · Nossentiner/Schwinzer Heide

**Ist:** Kiefer, Stieleiche / Fischotter, Kranich, Libelle, Seeadler, Fischadler

**Link-Lücke:** —

**Katalog-Kandidat:** Wacholder *Juniperus communis* — Station NSG Kieferndünen Wacholderwald.

**Nicht:** ~100 Park-Gehölze ohne Schildliste.

Quelle: https://www.wald-mv.de/static/WALDMV/Inhalte/Landesforst%20MV/Struktur%20und%20Organisation/Forstämter/Sandhof/Waldbesucher%20Sandhof.pdf

### fledermauspfad-bossow

`walderlebnispfad`

**Ist:** Kiefer / Igel, Hummel

**Ist prüfen:** Bechstein **nicht** für Bossow (Bunker-Liste ohne Bechstein).

**Katalog-Kandidat:** Braunes Langohr *Plecotus auritus*; Fransenfledermaus *Myotis nattereri*; Wasserfledermaus *Myotis daubentonii*; Großes Mausohr *Myotis myotis* — Bunker Bossow, Naturparkmagazin. Thema des Pfads, **Abend/Führung**, nicht Mittagsspaziergang. Hängebirke — Stiftung Reepsholt Wald bei Bossow. Wanderfalke — dieselbe Fläche, nicht der Lehrpfad-Kern.

**Nicht:** acht Fledermausarten alle seeden; Tag-Default-Waldtiere.

Quellen: https://www.naturpark-nossentiner-schwinzer-heide.de/fledermaus-lehrpfad · https://www.naturparkmagazin.de/nossentiner-schwinzer-heide/die-heimlichen-bunkerbewohner-von-bossow/

---

## Lübeck / SH Wald

### waldhusen

`wald`

**Ist:** Rotbuche, Stieleiche

**Link-Lücke:** —

**Nicht:** Kiefer/Fichte aus „Nadelholz“; Seeadler/Schwarzstorch = Revier Behlendorf.

Quelle: https://www.luebeck.de/de/rathaus/verwaltung/stadtwald/stadtwald · Research: Station 6 Waldwirtschaft = Buche

### naturwaldpfad — Lauerholz

`walderlebnispfad`

**Ist:** Douglasie, Rotbuche, Fichte, Stieleiche, Bergahorn, Hainbuche

**Link-Lücke:** —

**Katalog-Kandidat:** Esche *Fraxinus excelsior*.

**Nicht:** Torfmoos ohne Artname an Station Moor; Kiefer = Ost-Lauerholz, nicht dieser West-Pfad.

### rittbrookpfad — Lauerholz

`walderlebnispfad`

**Ist:** Rotbuche, Stieleiche, Bergahorn / Buntspecht

**Link-Lücke:** —

**Nicht:** Eichhörnchen (Holzfiguren/Seed, keine Betreiber-Art).

### moislinger-aue

`naturerlebnis`

**Ist:** Rotbuche, Schwarzerle / Libelle

**Nicht:** alles Neue — Stadt-NER-Text ohne Artnamen.

Quelle: https://www.luebeck.de/de/stadtleben/freizeit/natur-erleben/erholung-naturerleben/naturerlebnisraeume/index.html

### schwartautal

`walderlebnispfad` · Natura 2000

**Ist:** Schwarzerle, Rotbuche, Kultur-Apfel / Libelle, Honigbiene, Wildbiene, Igel, Kammmolch

**Link-Lücke:** —

**Katalog-Kandidat:** —

**Nicht:** Fischotter (FFH, unsichtbar); Eichhörnchen/Reh als Holzfiguren; Zaunkönig = Markierung.

Quellen: https://www.bad-schwartau.de/Kultur-Natur/Natur-erleben/Naturerlebnisraum-Natura-2000/ · https://www.bfn.de/natura-2000-gebiet/schwartautal-und-curauer-moor

### oher-graeberfeld

`wald`

**Ist:** Rotbuche / Buntspecht

**Nicht:** Tanne aus Flurname „Oher Tannen“; Billi = Maskottchen der Tafeln, Specht schon in `arten[]`.

Quelle: https://www.reinbek.de/leben-und-erleben/freizeit-und-tourismus/oher-graeberfeld-rundwanderweg

### naturerlebnis-grabau

`walderlebnispfad`

**Ist:** Schwarzerle, Rotbuche / Buntspecht

**Nicht:** Eichhörnchen Muck = Maskottchen (Eichhörnchenweg). Seeadler in Seed-Text ohne Betreiber. Obstlehrpfad = anderer Weg.

Quelle: https://naturerlebnis-grabau.de/angebote-familien/natuerlich-erholt/

### naturerlebnispfad-eutin

`naturerlebnis`

**Ist:** Rotbuche, Schwarzerle / Libelle

**Nicht:** Libellenlarven = gebuchtes Programm; Apfel-Bildungsspaß extra.

Quelle: https://www.naturpark-holsteinische-schweiz.de/poi/naturerlebnispfad-eutin

### naturerlebnispfad-ellerbek

`naturerlebnis`

**Ist:** Heckenrose / Igel, Hummel

**Nicht:** 35 Tafeln ohne öffentliche Artliste — vor Ort abschreiben, nicht raten.

Quelle: https://lifegarten-kiel.de/naturlehrpfad/

### naturerlebnisweg-ploener-seeufer

`naturerlebnis`

**Ist:** Schwarzerle, Rotbuche / Stockente, Seeadler

**Link-Lücke:** —

**Katalog-Kandidat:** Aronstab *Arum maculatum* — Tafel Prinzeninsel.

**Nicht:** Ulme/Esche (Tafel Sterben); Eisvogel im EGV ohne Tafelübersicht.

Quelle: https://www.naturpark-holsteinische-schweiz.de/poi/naturerlebnisweg-ploener-seeufer

### kollhorst — Kiel

`naturerlebnis`

**Ist:** Rotbuche, Kultur-Apfel / Honigbiene, Libelle, Hummel, Zauneidechse, Kammmolch

**Link-Lücke:** —

**Katalog-Kandidat:** Teichmolch *Lissotriton vulgaris*; Wasserfrosch *Pelophylax* — Faltblatt Kleingewässer.

**Nicht:** Birne/Kirsche extra; Rinder als Konik-Analog.

Quellen: https://www.kiel.de/de/umwelt_verkehr/umwelt_naturschutz/_dokumente_faltblaetter_kieler_naturschutzgebiete/Faltblatt_Kollhorst.pdf · https://nez-kollhorst.de/verein/naturerlebnisraum

### untereider — Rendsburg

`naturerlebnis`

**Ist:** Schwarzerle, Haselnuss / Libelle, Eisvogel

**Link-Lücke:** —

**Katalog-Kandidat:** Bruch-Weide / Korb-Weide, Eberesche *Sorbus aucuparia*, Holunder *Sambucus nigra* — Plakat Pflanzwald, nur wenn der Informationspfad ihn trifft.

**Nicht:** Stieleiche/Kiefer/Birke der 11-km-Binnendüne extra; Austernfischer FFH Tönning = anderes Teilgebiet.

Quelle: https://www.rendsburg.de/fileadmin/Aktueller_Upload/Politik_und_Verwaltung/Fachbereiche_und_Sachgebiete/Nachhaltigkeit_und_Zukunft/Umwelt/20_Umwelt_Naturerlebnisraum-Untereider-Plakat.pdf

### lehrpfad-pflanzenschutz-schwentinental

`naturerlebnis`

**Ist:** — / Honigbiene, Hummel

**Nicht:** Marienkäfer/Florfliege raten. Flyer ohne Artnamen. Tafeltexte vor Ort.

Quelle: https://www.e-nema.de/de/lehrpfad

### waldlehrpfad-silberbergen

`wald`

**Ist:** Rotbuche, Stieleiche / Buntspecht

**Nicht:** Wald-Default. Outdooractive ohne Liste.

### everstorfer-forst

`wald`

**Ist:** Rotbuche

**Nicht:** alles außer Buche. Grevesmühlen-Seite = Archäologie, keine Flora.

Quelle: https://www.grevesmuehlen.de/leben/kultur/grosssteingraeber.html

---

## Brandenburg / Berlin / HH / HE / BY (Rest)

### archaeologischer-wanderpfad-fischbek — Fischbeker Heide

`wald`

**Ist:** Besenheide, Kiefer / Heidelerche, Zauneidechse

**Link-Lücke:** —

**Katalog-Kandidat:** Heidschnucke — Herde täglich Infohaus, analog Konik, **nicht** in `schaf` aufgehen.

**Nicht:** Ziegenmelker (nacht, auch wenn FFH); Sonnentau/Lungenenzian = Quellmoore, nicht Archäologie-Pfad.

Quelle: https://www.hamburg.de/politik-und-verwaltung/behoerden/bukea/themen/naturschutz/naturschutzgebiete/nsg-fischbeker-heide-173266

### harzungspfad — Stolpe

`walderlebnispfad`

**Ist:** Kiefer

**Nicht:** Rehwild Revier Tegel; Mischbaumarten Waldumbau ohne Namen am 300-m-Pfad.

Quelle: https://www.berlin.de/forsten/waldbildung/waldlehrpfade/harzungspfad/

### kinderwald-maerkisch-buchholz

`waldspielplatz`

**Ist:** Stieleiche, Kiefer / Honigbiene, Zauneidechse, Wildbiene, Igel, Rote Waldameise (+ Geräte)

**Nicht:** „über zwanzig Baumarten“ ohne Namensliste. Schilder vor Ort.

Quelle: https://forst.brandenburg.de/lfb/de/ueber-uns/oberfoerstereien/oberfoersterei-koenigs-wusterhausen/kinderwald-maerkisch-buchholz/

### kinderbauernhof-pinke-panke

`kinderbauernhof`

**Ist:** — / Ziege, Schaf, Haushuhn, Hauskaninchen

**Katalog-Kandidat:** Hausesel, Hausschwein, Hausgans — Betreiber-Tierseite, analog Haushuhn.

**Nicht:** Hausente als Stockente; Katze/Meerschweinchen; Apfel als Futterspende.

Quelle: http://kinderbauernhof-pinke-panke.de/erwachsene/programm/tiere.html

### arboretum-dreetz

`naturerlebnis`

**Ist:** Stieleiche, Rotbuche, Edelkastanie, Kultur-Apfel

**Katalog-Kandidat:** —

**Nicht:** 15 Eichenarten, 100 Gehölze aus der Zahl. Nur Schild am Baum.

Quelle: https://arboretum-dreetz.de/

### wahrberge

`naturerlebnis`

**Ist:** Kiefer, Stieleiche, Bergahorn / Rote Waldameise, Igel, Hummel

**Nicht:** 200 Arboretum-Schilder aus der Zahl. Feldliste.

Quelle: https://www.wahrberge.de/waldlehrpark.html

### stendenitz

`walderlebnispfad`

**Ist:** Kiefer, Stieleiche, Rotbuche / Biber, Kranich, Rote Waldameise, Igel, Seeadler, Fischadler

**Link-Lücke:** —

**Nicht:** Waldauge-Suchspiel (Kolkrabe, Waldohreule, Wanderfalke, Eichhörnchen) = Puzzle, kein Vorkommen.

### wupatz — Erkner

`wald`

**Ist:** Kiefer, Stieleiche, Schwarzerle, Hainbuche / Rote Waldameise, Eisvogel, Igel, Distelfalter, Kleiner Fuchs

**Katalog-Kandidat:** Schwarzspecht *Dryocopus martius* — Stadt 2026, Tafel Rufweite. Hängebirke *Betula pendula* — Station Baumarten.

Quelle: https://www.erkner.de/rathaus-und-buergerservice/buergerinformationen/aktuelles/neuigkeiten/2026-1/erneuerungen-auf-wupatz-lehrpfad.html

### rauener-berge

`wald`

**Ist:** Europäische Lärche, Stieleiche, Kiefer, Robinie, Bergahorn / Rote Waldameise

**Ist prüfen:** Fichte nur Vergleichstext „unterscheiden“, nicht Bestand.

**Link-Lücke:** Libelle — nur wenn Grubensee-Tafel das sagt (Seenland-Text nicht).

### ravensberge — Potsdam

`wald`

**Ist:** Kiefer, Stieleiche / Rote Waldameise, Wildbiene, Hummel, Igel, Honigbiene, Libelle, Zauneidechse, Buntspecht

**Link-Lücke:** —

Quelle: https://www.potsdam.de/de/content/ravensberge-und-forst-potsdam

### braumannswiesen — Taunus

`wald`

**Ist:** Rotbuche, Stieleiche, Fichte, Schwarzerle, Kiefer, Kultur-Apfel / Schaf

**Katalog-Kandidat:** —

Quelle: http://www.taunuswelten.de/wandern/naturlehrpfad-braumannswiesen/

### erlebe-bruder-wald — Bamberg

`walderlebnispfad`

**Ist:** Rotbuche, Stieleiche, Kiefer, Europäische Lärche, Bergahorn

**Link-Lücke:** —

**Nicht:** Wolf Lupi; Reh an der Sprunggrube als Artstation.

Quelle: https://www.erlebe-bruder-wald.de/walderlebnispfad/uebersicht/station-5.html

### entdeckerpfad-biologische-vielfalt — Wiethagen

`walderlebnispfad` · Rostocker Heide

**Ist:** Kiefer, Rotbuche, Stieleiche / Eisvogel

**Nicht:** Fledermaus-Kurbelkasten = Gerät, keine Art. Bechstein nicht reuse. Stationen um den Hof, keine Heide-Artenliste.

Quelle: https://www.rostock.de/tour/entdeckerpfad-biologische-vielfalt

### libellen-wasserspielplatz-wittstock

`wasserspielplatz`

**Ist:** — / Libelle, Biber (+ Geräte)

**Nicht:** Biber ist Glinze/Dosse-Kontext, nicht das Becken. Keine Wildarten ausweiten. Libellen-Installation = Gerät.

### wasserspielplatz-roebel

`wasserspielplatz`

**Ist:** — / Libelle, Eisvogel

**Nicht:** Seeadler Müritz, Hafen-Vögel ohne Betreiber-Art.

---

## Katalonien

### fonts-vallvidrera — Collserola

`naturerlebnis`

**Ist:** Steineiche, Pinie, Robinie

**Ist prüfen:** Stieleiche — **gestrichen** (Set-Bisbes = *Quercus × cerrioides* / Flaumeichenkreis). Pinie *P. pinea* schwächer als Aleppokiefer am Hang.

**Link-Lücke:** —

**Katalog-Kandidat:** Platane *Platanus × hispanica* — Allee dieser Runde. Aleppokiefer *Pinus halepensis* — totnens + Habitat. Wildschwein *Sus scrofa* — Park-Monitoring; auf der Runde sicher die Spur-Skulptur.

**Nicht:** Eichhörnchen (Park ja, diese Runde nein); Fuchs nur Taststein.

Quellen: https://parcnaturalcollserola.cat/itinerais/passejada-per-les-fonts/ · https://totnens.cat/que-fem/passejada-per-les-fonts-baixador-vallvidrera/

### sl-c-73-alzines-can-portell — Hortsavinyà

`wald` · Montnegre

**Ist:** Steineiche, Haselnuss, Schwarzerle, Korkeiche

**Link-Lücke:** Stieleiche im Seed-Text ist falsch für Alzina.

**Katalog-Kandidat:** Erdbeerbaum *Arbutus unedo* (Arboç); Lorbeer *Laurus nobilis* (Llorer, Sot de Can Pica).

**Nicht:** Waldkauz/Gamarús (nacht, Flyer „früher“); Schwarzstorch Parktext; Wildschwein ohne Flyer.

Quelle: https://parcs.diba.cat/documents/75109/15894269/p05d072.pdf

### parc-forestal-mataro

`waldspielplatz`

**Ist:** Pinie, Steineiche, Korkeiche / Eichhörnchen

**Ist prüfen:** Korkeiche/Steineiche/Eichhörnchen — aktuelles totnens nennt vor allem Pins; Parkstartseite Pinienwälder Hang. Halten als Küstenhang, nicht vermehren.

**Nicht:** Wildschwein Regionsliste.

Quellen: https://totnens.cat/que-fem/parc-forestal-de-mataro/ · https://parcs.diba.cat/ca/web/montnegre

### can-jalpi-arenys

`naturerlebnis`

**Ist:** Stieleiche, Steineiche / Stockente

**Ist prüfen:** Stieleiche — Roure de Gernika ist gepflanzter *Q. robur*, ok. Stockente — See „Vögel“, Art nicht genannt, schwach.

**Nicht:** Schildkröten (oft Neozoen); Wildschwein/Eichhörnchen ohne Seiten-Satz.

Quelle: https://totnens.cat/que-fem/parc-i-castell-de-jalpi/

---

## Nächster Schritt (nicht diese Datei)

1. Link-Pass: erledigt (Configs, Seeds, Validator, `trail_species`)
2. Welle 1: erledigt in Seed + DB (Apfel, Hainbuche, Kammmolch, Bekassine, Weißtanne). Audio-Haken nach Commit.
3. Unikate nach SPECIES_CONTENT (Heidschnucke, Strandhafer, Wolf, …)
4. Ist prüfen: Bechstein Prora / Stieleiche Vallvidrera / Buntspecht Saarschleife gestrichen

HAVE-Skill Schritt 6 folgt derselben Leiter.

### baumwipfelpfad-bad-iburg

`erlebniswald`

**Ist:** Rotbuche, Stieleiche, Weißtanne, Fichte

**Katalog-Kandidat:** Vogelkirsche (FAQ „Kirsche“); Gemeine Esche *Fraxinus excelsior* (FAQ „Esche“).

**Nicht:** Ahorn ohne Art (Bergahorn vs. Spitzahorn, FAQ unterscheidet nicht). Lärche ist Laufbelag. Fünf Fledermausarten, Spechte, Steinpilz, Marone, Pfifferling nur als Tafelthema, keine Art am Ort. Hirschkäfer und Wildschwein nur in der AR-App.

Quelle: https://www.baumwipfelpfad-badiburg.de/faq/

### auwald-erlebnispfad

`walderlebnispfad` · NSG Burgaue, Lützschena

**Ist:** Eisvogel, Moorfrosch

**Katalog-Kandidat:** Rotmilan *Milvus milvus* (Station); Märzenbecher *Leucojum vernum*; Schlehe *Prunus spinosa* (Tafel am Weg). Quelle Ahoi-Reportage dieser Runde.

**Nicht:** Fledermäuse unbestimmt. Kein Arten-Dump für den Leipziger Auwald.

Quelle: https://ahoi-leipzig.de/artikel/wald-digital-erleben-1375/

### naturlehrpfad-grabschuetzer-see

`naturerlebnis` · Grabschützer See, Zwochau, NSG Werbeliner See

**Ist:** Braunkehlchen, Neuntöter, Wiedehopf, Kammmolch

**Katalog-Kandidat:** Schwarzkehlchen, Grauammer, Raubwürger, Wechselkröte. NABU-Beweidung Grabschütz, dieselbe Seite wie die Ist-Arten.

**Nicht:** Schottisches Hochlandrind (Beweidung, Gerät). Seeadler, Rohrdommel und Saatgans nur als Gebietsbeispiel, nicht als Fund auf dem Rundweg.

Quelle: https://sachsen.nabu.de/naturundlandschaft/landschaftspflege/beweidung/19145.html

### geopfad-markkleeberg

`naturerlebnis` · Ostufer Markkleeberger See / Störmthaler See

**Ist:** Geopfad-Stele (Gerät)

**Nicht:** Fische, Seekühe, Meeresschildkröten auf Stele 15 sind fossile Funde, keine Tiere am Ufer.

Quelle: OSM-Tafeltexte der 16 Stelen, Node 2476685956.
