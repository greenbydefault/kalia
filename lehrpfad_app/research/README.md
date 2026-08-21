# Research: Lehrpfade nach Landkreis

Ordnerbaum: **Deutschland → Bundesland → Landkreis / kreisfreie Stadt / Bezirk**.
Leerer Kreis = noch nicht recherchiert. Gefüllter Kreis = `_kandidaten.md` + optional `*.research.md`.

Masterliste zum Abhaken: [`STATUS.md`](STATUS.md).

Kreisliste (Destatis/Wikipedia, 418 Einheiten): [`_kreise.json`](_kreise.json). Baum neu anlegen/rollup:

```
python3 tools/gen_research_tree.py
```

Überschreibt keine existierende Kreis-`STATUS.md`. Schreibt `STATUS.md` (Land + Bund) neu.

## Ablauf

1. Nächsten `leer`-Kreis in [`STATUS.md`](STATUS.md) nehmen.
2. OSM + Betreiber → `_kandidaten.md` (GO / NOGO / MAYBE).
3. Pro GO: `<id>.research.md` (Go-Bar wie bisher).
4. Seed wie bisher: Config `tools/trails/<id>.json` → `python3 tools/build_seed.py` → `assets/seed/`. OSM-Roh bleibt in `tools/osm/`.
5. Checkbox in der Kreis-`STATUS.md`; Status `offen` oder `done`. Danach Generator fürs Rollup.

Status-Werte: `leer` · `offen` (Kandidaten da, nicht durch) · `done` (Sweep + GO/NOGO entschieden).

## Filter (Familienorte)

| Kriterium | Regel |
|---|---|
| Zugang | Spontanbesuch **in den Öffnungszeiten**, ohne Anmeldung. Eintritt ist kein Auto-NOGO mehr — Preise + Hinweise ins Seed, Header-Chip wenn `eintritt: true` |
| Charakter | Wald / Waldrand / Naturerlebnis **oder** Motorik-/Wasserspielplatz **oder** `kinderbauernhof` — kein Zoo, kein Indoor, kein Produktionsstall |
| Arboretum | Beschilderter Baumgarten / Arboretum = Naturerlebnis, `typ: naturerlebnis`, i. d. R. `form: flaeche`. Kein eigener Typ-Key. Cluster-Stationen, kein Fake-Rundkurs. Buchungs-Forstgarten, Ticket-Showgarten, Baumlehrpfad ohne Stationstitel = MAYBE |
| Raus | Waldpädagogik / Hof nur mit Buchung (Kita/Schule/Ferienlager); betreute Spielplätze ohne Outdoor-Charakter; **reine Stadtspielplätze** |
| Alte NOGOs | Ticket-NOGOs von vor dem Filterwechsel **nicht** wieder öffnen. Nur neue Funde dürfen Eintritt haben |

### `kinderbauernhof`

GO: Familien-Spontanbesuch, Kinder lernen Umgang/Pflege (Zaun-Streicheln ok), selektive Haltung, kein Mast-/Produktionsbetrieb. Eintritt ok, dann Chip + `eintrittPreise` / `oeffnungszeiten` / `besuchshinweise` Pflicht.

NOGO: nur Kita/Schulklassen (z. B. Gussow); reiner Zoo/Heimtierpark ohne Mitmachen.

Brandenburg-Sweep: [`Brandenburg/_kinderbauernhoefe.md`](Brandenburg/_kinderbauernhoefe.md). LIFE-Kalkmoore (Archiv 2010–2015): [`Brandenburg/_kalkmoore.md`](Brandenburg/_kalkmoore.md).

Unterscheidung Stadtspielplatz vs. Motorik-/Wasserspielplatz nach **Charakter des Angebots**, nicht nach „liegt in der Stadt“. Reine Standard-Sets (Schaukel, Rutsche, Klettergerüst) sind kein eigener Trail. Details: [`docs/datenmodell.md`](../docs/datenmodell.md).

`typ`-Keys: `typKatalog` in `lib/shared/catalogs/icon_catalog.dart`.

## Wo schon Inhalt liegt

Brandenburg: **alle 18** Kreise/kreisfreien Städte haben `_kandidaten.md` (2026-08-13). 16 OSM-Relationen zugeordnet — [`Brandenburg/_unzugeordnet.md`](Brandenburg/_unzugeordnet.md) OPEN-Liste leer.

Mecklenburg-Vorpommern: Mecklenburgische Seenplatte, Ludwigslust-Parchim, Landkreis Rostock, Vorpommern-Rügen (nur ein NOGO).

Berlin: Pankow — Pinke-Panke HAVE (`kinderbauernhof`). Reinickendorf — Eichwerder-Steg MAYBE (NABU-Tafeln, Titel-Lücke).

Dahme-Spreewald: Kinderwald Märkisch Buchholz HAVE; Natter-Pfad Goyatz HAVE (`walderlebnispfad`).

## Was nicht hier liegt

| Was | Wo |
|---|---|
| Trail-Configs | `tools/trails/<id>.json` |
| OSM-Roh | `tools/osm/` |
| App-Seeds | `assets/seed/` |
| Qualitäts-Go-Bar | [`docs/traumdatensatz.md`](../docs/traumdatensatz.md) |
