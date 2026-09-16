# Species-Content: Outdoor-Interpretation

Verbindliche Spec für `assets/seed/species.json` → Feld `content` (`kategorie: flora` / `fauna`).
Für `kategorie: geraete` siehe [`GERAETE_CONTENT.md`](GERAETE_CONTENT.md) (gleiche Limits, andere Semantik).
Erzwungen durch `tools/validate_seeds.py`.

**Stimme:** [`docs/audio/GRUND.md`](../docs/audio/GRUND.md). Belege: [`docs/audio/quellen.md`](../docs/audio/quellen.md). Limits und Felder bleiben hier.

## Haltung

1. Eine Kernidee pro Art — kein Lexikon.
2. Provokation (Neugier) vor Belehrung.
3. Besucher:in als Entdecker:in.
4. Kein Zeigefinger; Schutzhinweise max. ein kurzer Satz.
5. Ort zuerst: Brandenburg / Trail — was man sehen oder tun kann.
6. Plain Language, aktiv, konkrete Verben.

## Felder (`content`)

| Feld | Pflicht | Limit | Job |
|---|---|---|---|
| `hook` | ja | 1 Satz, 12–22 Wörter | Stärkster Satz zuerst |
| `erkennung` | ja | 2–4 Bullets, je ≤ 12 Wörter | Beobachtungsfirst |
| `lebensraum` | ja | ≤ 40 Wörter | Hier unterwegs |
| `funFacts` | ja | 2–3 Bullets | Staunen, merkbar |
| `hinweis` | nein | ≤ 15 Wörter oder `""` | Nur wenn relevant |
| `hoertext` | ja | 90–120 Wörter | Einsprech-Skript (Play), nicht UI |

`kurztext` bleibt als Fallback (meist = Hook oder Kurzfassung) für alte Caches.

## Register

- **Scan-Felder** (`hook` … `funFacts`): Auge, stehend, Outdoor. In der App.
- **`hoertext`**: Studio-Vorlage. Nutzer drückt Play. Nicht Konkatenation der Scan-Felder, nicht Lesetext.
  Shape (eine Geschichte, Scaffold vs. Stück) und QA: [`docs/audio/GRUND.md`](../docs/audio/GRUND.md).
  ~45–60 s. Probehören muss flüssig klingen.

## Profil (flora/fauna)

Zusätzlich zum Steckbrief: `gruppe`, `seltenheit`, `gefahr`, `nahrung`, `taxonomie`, `masse`, `merkmale`, `beziehungen`.

- **Seltenheit** = wie oft Kinder die Art auf den Trails in der App treffen, nicht IUCN.
- **Gefahr** = „darf ich nah ran?“ (1 sehr gering … 5 nicht annähern).
- **Maße** = Ranges, kindgerechte Einheiten (`3–50 g`, nicht `0.003 kg`).
- **Merkmale** = 4–8 IDs aus `assets/seed/merkmale.json`; nur was stimmt.
- **Beziehungen** = `frisst` / `bestaeubt` / `wohnt_an`; Katalog-Art (`toSpeciesId`) oder Freitext (`nameDe`).

Erzwungen durch `tools/validate_seeds.py`.

## QA (manuell, zusätzlich zum Validator)

- [ ] Kernidee in einem Satz
- [ ] Hook allein spannend (kein „Der X ist ein …“)
- [ ] Mind. ein Beobachtungsauftrag in `erkennung`
- [ ] So-what: warum *hier* interessant?
- [ ] Kein Predigen / keine Floskeln
- [ ] Hook+Erkennung+Lebensraum laut < 45 s
- [ ] `hoertext` klingt wie eine Geschichte, Probehören ([`docs/audio/GRUND.md`](../docs/audio/GRUND.md))
