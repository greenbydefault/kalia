# Trail-Hörtext: Overview zum Einsprechen

Verbindliche Spec für Trail-`hoertext` — Studio-Vorlage für Play am Trail-Sheet, nicht Lesetext.
Feld und Player sind **nicht v1** ([`docs/golive/GRUND.md`](../docs/golive/GRUND.md) → TTS); Texte werden trotzdem jetzt produziert, wie bei Species-`hoertext`.
Schwester-Specs: [`SPECIES_CONTENT.md`](SPECIES_CONTENT.md) (Flora/Fauna), [`GERAETE_CONTENT.md`](GERAETE_CONTENT.md) (Geräte).
**Stimme:** [`docs/audio/GRUND.md`](../docs/audio/GRUND.md). Belege: [`docs/audio/quellen.md`](../docs/audio/quellen.md). Limits bleiben hier.

## Zweck

Ein Hörtext pro Trail: 1–2 Kernpunkte, die man vor Ort wirklich braucht. Kein Steckbrief, keine Inhaltsangabe, keine gekürzte `beschreibung`.

## Haltung

1. Ohr zuerst: gesprochene Sprache, atembare Sätze. Probehören muss flüssig klingen.
2. Szene vor Fakten: wo bin ich, was trägt den Ort.
3. 1–2 Must-knows, nicht mehr: z. B. Rundkurs oder Platz, das eine Highlight, die eine Regel.
4. Nicht `kurzbeschreibung` einsprechen. Die ist fürs Auge (Card/Peek), der Hörtext für Play.
5. Kein Zeigefinger; Regeln als Tipp, nicht als Verbot.

## Feld

| Feld | Pflicht | Limit | Job |
|---|---|---|---|
| `hoertext` | ja | 40–70 Wörter, ~20–35 s | Einsprech-Skript für Play (Overview) |

Struktur: Einstieg (wo bin ich / was ist das) → 1–2 Kernpunkte → Cue-out, der hierher gehört. Eine Geschichte, nicht drei hörbare Kapitel ([`docs/audio/GRUND.md`](../docs/audio/GRUND.md)).

## Ablage

- Text: im Seed am Trail (`hoertext`; kommt mit dem Player-Feature ins Datenmodell, siehe [`docs/datenmodell.md`](../docs/datenmodell.md)).
- Datei: `assets/audio/trails/{id}.opus` (Konvention; Ordner und `pubspec.yaml`-Zeile kommen mit den ersten Dateien).
- Tracking: Trello-Board **Kalia · Audio** — 1 Karte pro Trail, Checkliste Hörtext/Sound. Abhaken erst nach Repo-Commit.

## QA (manuell)

- [ ] Probehören < 35 s, ohne Stolpern
- [ ] Kernpunkte ohne Karte oder Schild verständlich
- [ ] Kein „Dieser Lehrpfad ist …"
- [ ] Keine wörtliche Wiederholung der `kurzbeschreibung`
- [ ] Mindestens ein konkreter Tipp oder eine Regel steckt drin
