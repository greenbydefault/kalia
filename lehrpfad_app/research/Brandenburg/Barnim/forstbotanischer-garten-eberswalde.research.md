# Forstbotanischer Garten Eberswalde – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `forstbotanischer-garten-eberswalde` |
| Name | Forstbotanischer Garten Eberswalde |
| `typ` / `form` | `naturerlebnis` / `flaeche` |
| Region | Eberswalde, Barnim, LSG Schwärzetal |
| OSM | Hiking-Rel fehlt; Anker Am Zainhammer 5 (HNEE) |
| Zugang | täglich bis Dämmerung, Eintritt frei, ohne Anmeldung |
| Status | **OPEN** |

Quelle: [`_kandidaten.md`](_kandidaten.md). Filter: [`README.md`](../../../README.md).

## Filter / Abgrenzung

| Ort | Einstufung |
|---|---|
| Forstbotanischer Garten (Arboretum, Quellmoor, Lehrpfade) | **GO** |
| Waldbodenlehrpfad (4 Profile, Fachpfad) | **MAYBE** — eigener Eintrag |
| Zoo Eberswalde (1,4 km) | **NOGO** — Zoo + Ticket |
| Familiengarten Wasserspielplatz | **NOGO** — Eintritt |

Führungen nach Absprache = optional, nicht Pflicht für Spontanbesuch.

## Geometrie

- `form: flaeche`, Gartenpolygon (8 ha Solitär-Arboretum, Standort seit 1868–74 nördlich der Zainhammer-Straße)
- Hiking-Relation: **fehlt**
- Marker = Garteneingang Am Zainhammer 5
- Kein Fake-Rundkurs; interne Wege vor Ort

## Stationen (≥3)

1. **Quellmoor** — Riesen-Schachtelhalm (*Equisetum telmateia*), Schwärzefließ
2. **Ostasiaten-Quartier** — chinesischer Pavillon, Blick ins Gelände
3. **Kräuter-, Heil- und Giftpflanzenanlage** — hinter Pergola, beschildert
4. **Geologischer Lehrpfad** — Leitgeschiebe der Weichsel-Kaltzeit (1992 eröffnet, Auswahl aus 72 Geschieben)

## Arten

Nur belegt: Riesen-Schachtelhalm, Trompetenbaum, Amberbaum, Zucker-Ahorn, Zaubernuss (amerikanisch/asiatisch), Berberitze, Weißdorn. ~1.200 Gehölzarten gesamt — Einzelarten nicht erfinden.

## Quellen

- Reiseland: https://www.reiseland-brandenburg.de/poi/barnimer-land/gaerten-und-parkanlagen/forstbotanischer-garten/
- Tourismus Eberswalde: https://tourismus-eberswalde.de/entdecken-und-erleben/natur-und-aktiv/naturerlebnisse/forst-botanischer-garten/
- Naturpark Barnim: https://www.barnim-naturpark.de/themen/info-ausstellung/forstbotanischer-garten-eberswalde/
- Geologischer Lehrpfad (PDF Stadt/Verwaltung): https://daten2.verwaltungsportal.de/dateien/seitengenerator/c016459b5adaee13961f696bc26a5b9764975/bot_garten.pdf
- HNEE: https://www.hnee.de/hochschule/organisation/einrichtungen/forstbotanischer-garten

## Pipeline

Nächster Schritt: Seed-Config (`form: flaeche`, Area um Garten, Stationen als POIs). **Nicht bauen** in diesem Sweep.
