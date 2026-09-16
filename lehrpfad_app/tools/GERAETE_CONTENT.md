# Geräte-Content: Outdoor-Interpretation

Verbindliche Spec für `assets/seed/species.json` mit `kategorie: "geraete"`.
Content-Shape und Limits wie [`SPECIES_CONTENT.md`](SPECIES_CONTENT.md) (gleicher Validator).
**Stimme:** [`docs/audio/GRUND.md`](../docs/audio/GRUND.md). Belege: [`docs/audio/quellen.md`](../docs/audio/quellen.md).
Icons: `iconKey` → `geraeteKatalog` in `lib/shared/catalogs/icon_catalog.dart` (nie IconData im JSON).

## Haltung

1. Eine Kernidee pro Gerät — kein Herstellerkatalog.
2. Handeln vor Beschreiben: pumpen, stauen, folgen, matschen.
3. Besucher:in als Entdecker:in am Ort.
4. Kein Zeigefinger; Nässe/Aufsicht max. ein kurzer `hinweis`.
5. Ort zuerst: Wittstock / Wasserspielplatz — was man *tun* kann.
6. Plain Language, aktiv, konkrete Verben.

## Aufnahmefilter

| Rein | Raus |
|---|---|
| Wasserlauf, Pumpe+Rinne, Wehr, Quellstein, Themen-Installation | Standard-Schaukel, Standard-Rutsche, Wipptier, Sandkasten allein |

## Felder (`content`) — gleiche Keys, Gerätesemantik

| Feld | Pflicht | Limit | Job bei Geräten |
|---|---|---|---|
| `hook` | ja | 1 Satz, 12–22 Wörter | Was macht das Gerät spannend |
| `erkennung` | ja | 2–4 Bullets, je ≤ 12 Wörter | Woran erkennen / wo steht es |
| `lebensraum` | ja | ≤ 40 Wörter | Kontext: wo auf dem Platz / wie nutzen |
| `funFacts` | ja | 2–3 Bullets | Motorik / Physik / Design |
| `hinweis` | nein | ≤ 15 Wörter oder `""` | Nässe, Aufsicht, Saison |
| `hoertext` | ja | 90–120 Wörter | Einsprech-Skript (Play), nicht UI |

## Meta

| Feld | Pflicht | Hinweis |
|---|---|---|
| `kategorie` | ja | immer `geraete` |
| `iconKey` | nein | Key aus `geraeteKatalog`; leer → Fallback `geraet` |
| `nameLat` | nein | oft `""` bei Geräten |

## QA

- [ ] Kein DIN-Standardspielgerät ohne motorischen/Wasser-Mehrwert
- [ ] Hook allein spannend (kein „Das Gerät ist ein …“)
- [ ] Mind. ein Handlungsauftrag in `erkennung` oder Hook
- [ ] `iconKey` bekannt oder weggelassen
- [ ] `hoertext` Einsprech-Skript, eine Geschichte ([`docs/audio/GRUND.md`](../docs/audio/GRUND.md))
