# Species-Content: Outdoor-Interpretation

Verbindliche Spec für `assets/seed/species.json` → Feld `content` (`kategorie: flora` / `fauna`).
Für `kategorie: geraete` siehe [`GERAETE_CONTENT.md`](GERAETE_CONTENT.md) (gleiche Limits, andere Semantik).
Erzwungen durch `tools/validate_seeds.py`. Quellen: NPS Wayside, Museum Labels, Tilden, Writing-for-the-ear.

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
| `hoertext` | ja | 90–120 Wörter | Vorlese-/Einsprech-Vorlage |

`kurztext` bleibt als Fallback (meist = Hook oder Kurzfassung) für alte Caches.

## Register

- **Scan-Felder** (`hook` … `funFacts`): Auge, stehend, Outdoor.
- **`hoertext`**: eigenes mündliches Skript — nicht Konkatenation der Scan-Felder.
  Szene/Frage → Beobachtungstipp → Wow-Fakt → warmer Ausklang.
  Atembare Sätze, laut vorlesen muss flüssig klingen (~45–60 s).

## QA (manuell, zusätzlich zum Validator)

- [ ] Kernidee in einem Satz
- [ ] Hook allein spannend (kein „Der X ist ein …“)
- [ ] Mind. ein Beobachtungsauftrag in `erkennung`
- [ ] So-what: warum *hier* interessant?
- [ ] Kein Predigen / keine Floskeln
- [ ] Hook+Erkennung+Lebensraum laut < 45 s
- [ ] `hoertext` klingt gesprochen
