# Kinderbauernhof Pinke-Panke – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `kinderbauernhof-pinke-panke` |
| Name | Kinderbauernhof Pinke-Panke |
| typ | `kinderbauernhof` |
| `form` | **`flaeche`** |
| Region | Pankow, Berlin |
| Adresse | Am Bürgerpark 15–18, 13156 Berlin |
| Zugang | Spontan in den Öffnungszeiten; **kein Ticket**, Spende willkommen |
| Status | **HAVE** – Seed `assets/seed/kinderbauernhof-pinke-panke.json` |
| OSM | Way [`219699293`](https://www.openstreetmap.org/way/219699293) playground/farmyard ≈ 52.56888, 13.38868 |

Quelle: [`_kandidaten.md`](_kandidaten.md). Filter: [`README.md`](../../../README.md).

## Quellen

- Hof: http://www.kinderbauernhof-pinke-panke.de/
- FAQ: http://www.kinderbauernhof-pinke-panke.de/erwachsene/kontakt/fragen.html
- Öffnungszeiten: http://www.kinderbauernhof-pinke-panke.de/wordpress/wichtige-infos
- Berlin.de / visitBerlin (70+ Tiere, Mitfüttern)

Träger: Spielraum Pankow e.V., Homeyer Str. 27, 13156 Berlin.

## Filter / Abgrenzung

| Ort | Einstufung |
|---|---|
| Offener Hof Mi–Fr + Wochenende/Ferien | **GO** — Familien-Spontanbesuch |
| Fütterung 16 Uhr, Streicheln 11/15 Uhr mit Betreuer | **GO** — Umgang, nicht Zoo-Schaulauf |
| Dienstag nur Schulkinder | Hinweis, nicht NOGO für den Ort |
| Kita/Hort/Klasse ab 9 Uhr | **NOGO** — Anmeldung; nicht der Seed-Zugang |

visitBerlin: „mehr als 70 Tiere“ — nicht winzig, aber betreut, kein Mastbetrieb.

## Besuch

| Feld | Wert |
|---|---|
| `eintritt` | `false` (Header-Chip aus) |
| `eintrittPreise` | frei, Spende willkommen |
| `oeffnungszeiten` | Sommer (1. Apr–31. Okt): Mo Ruhetag; Di nur Schulkinder 12–18; Mi–Fr 12–18:30; Wochenende/Ferien 10–18:30. Winter: jeweils 1 h früher |
| `besuchshinweise` | Nicht frei füttern. Fütterung 16 Uhr, alle dürfen mit. Streicheln nur mit Betreuer 11 und 15 Uhr |

## Geometrie

- `form: flaeche`, `rundkurs: false`, `laengeKm: 0`
- Marker = Centroid am Hof (Bürgerpark / Panke)

## Stationen (≥3)

| Station | Thema |
|---|---|
| Tiere / Streichelzeiten | Umgang nur mit Betreuer |
| Fütterung 16 Uhr | Mitmachen, nicht zwischendurch füttern |
| Werkstatt / Sonntagsbacken | Handwerk; So ab 11 Uhr backen |

## Go / No-Go

**Go:** Spontan in Öffnungszeiten, Outdoor, Pflege/Umgang, ≥3 Stationen.

**No-Go:** Seed als gebuchte Kita-Fahrt; Zoo ohne Mitmachen.

## Seed (HAVE)

Flächen-Seed direkt `assets/seed/kinderbauernhof-pinke-panke.json`. Hof-Fauna in `arten[]` + `species.json`. In `_seedPaths`.
