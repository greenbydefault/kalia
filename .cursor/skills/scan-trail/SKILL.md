---
name: scan-trail
description: >-
  Writes the visible trail texts (kurzbeschreibung ≤180 characters, beschreibung 400–650 characters, besuchshinweise ≤280 characters, no direct address, same voice as the hoertext) into the trail config and the seed.
  Use when the user asks for Kurzbeschreibung, Beschreibung, Trail-Lesetext, Scan-Trail, or to rework the texts on a trail sheet.
  Not the hoertext (audio-trail), not species, flora, fauna, or device content (audio-art).
---

# Scan · Trail

cwd: `lehrpfad_app/`. `tools/` ist gitignored, Glob leer. `Read` auf den Pfad.

Form, Limits, Maßstab: `tools/TRAIL_SCAN.md`. Stimme und Wortliste: `docs/stimme.md`. Dasselbe Gefühl wie der `hoertext`, kürzer und nüchterner. Rhythmus ist hier kein Ziel, `klang.py` läuft hier nicht.

## 1. Ziel

`id`. Config: `tools/trails/<id>.json`.

Done: Config gelesen. `kurzbeschreibung`, `beschreibung`, `besuchshinweise`, `hoertext`, Stationen, `tags`, `eintritt`, `laengeKm`, `dauerMin` bekannt.

## 2. Stimme und Spec

`Read docs/stimme.md` und `tools/TRAIL_SCAN.md`. Gold und Gegenbeispiel laut im Kopf lesen. Dann den `hoertext` des Trails lesen (falls vorhanden): Das ist die Stimme, an der sich der Lesetext messen lässt.

Done: Profil, Wortliste, Limits, Gold, QA präsent.

## 3. Rohstoff

Notiz, nicht ins JSON. Drei Listen:

- **Schon sichtbar:** Header-Chips (Typ, Platz, Rundkurs, Eintritt), Fakten-Chips (Länge, Dauer, Region, Markierung), Tags, Eignung. Das bleibt aus der Prosa, außer es wird präziser.
- **Schon im `hoertext`:** diese Sätze und Bilder nicht wiederholen. Gleiche Sache ja, gleicher Satz nein.
- **Nur der Text trägt:** Fakten mit Quelle in der Config (Höhe, Geschichte, Besonderheit, Regel), die weder Chip noch Hörtext sagt. Das Interessanteste davon markieren, es wird Satz 1.

Jede Zahl mit Fundstelle in der Config. Keine Zahl ohne.

Done: drei Listen, ein Interessantestes gewählt.

## 4. Schreiben

Reihenfolge: `kurzbeschreibung`, `beschreibung`, `besuchshinweise` nur wenn nötig.

- `kurzbeschreibung`: ein Bild plus ein Fakt, der den Ort kenntlich macht. Kein Chip-Wort (Eintritt, Rundkurs).
- `beschreibung`: Satz 1 ist das Interessanteste und trägt allein. Fakt vor Adjektiv. Verben tragen das Bild. Keine Anrede. Kein Stationsinventar, kein Betreiber, keine Öffnungszeit.
- `besuchshinweise`: nur was den Besuch ändert und nicht schon Tag ist. Imperativ ist ok. Kein „bitte“.

Menschen in der dritten Person („wer sich hineinlegt“). Keine Prognose über Kinder. Wortliste aus `docs/stimme.md` einhalten.

Done: drei Felder (oder zwei), kein du/ihr/Sie, Satz 1 trägt allein.

## 5. Prüfen

```
python3 ../.cursor/skills/scan-trail/scan.py --feld kurz --id <id> <<< "<text>"
python3 ../.cursor/skills/scan-trail/scan.py --feld beschreibung --id <id> <<< "<text>"
python3 ../.cursor/skills/scan-trail/scan.py --feld hinweise --id <id> <<< "<text>"
```

Prüft Zeichenlimit, Satzzahl bei `kurz`, mittlere Satzlänge ≤ 15 und keinen Satz über 25 Wörter, Anrede, Gedankenstrich, Ausrufezeichen, Wortliste (hart = Fehler, Warnung = Beleg nötig), wortgleiche Folgen mit `hoertext` und `kurzbeschreibung`, Zahlen ohne Fundstelle. Warnungen einzeln begründen oder ersetzen.

Done: Exit 0, jede Warnung begründet oder weg.

## 6. Aufräumen

Slop-Muster und Wortliste aus `docs/stimme.md` gegenprüfen. Laut lesen, Stolperer raus. Neben das Gold-Beispiel legen: Gleiche Stimme? Danach `scan.py` nochmal.

Done: QA in `TRAIL_SCAN.md` geht auf (bis auf den App-Punkt, der folgt in 8).

## 7. Ablage

Felder in `tools/trails/<id>.json`, nicht im Seed von Hand.

```
python3 tools/build_seed.py tools/trails/<id>.json
python3 tools/validate_seeds.py
python3 ../.cursor/skills/scan-trail/scan.py <id>
```

Exit 0 bei allem. Rot → Config oder Seed, nicht das Script. Felder danach in `assets/seed/<id>.json` gegen die Config prüfen.

`form: flaeche` ohne Route-Datei: `build_seed.py` bricht ab. Felder dann direkt in den bestehenden Seed schreiben, Fläche und Stationen bleiben. Danach nur `validate_seeds.py`.

Der `hoertext` bleibt unangetastet. `validate_seeds.py` prüft diese Felder nicht.

Done: Felder in Config und Seed gleich, beide Prüfer grün.

## 8. In der App sehen

Sheet des Trails öffnen (DEV-SERVER.md, `flutter run -d web-server --web-port=8080`). Header ohne Abschneiden lesbar? Absatz nicht länger als der Bildschirm daneben? Klingt es wie der Hörtext, nur kürzer? Die Texte laufen im Container, für den sie geschrieben sind. Das Doc zeigt das nicht.

Done: Header, Absatz und Accordion gesehen oder genannt, warum nicht.

## 9. Trello

Board [Kalia/Ako/KiWa](https://trello.com/b/uEjtZKC3/kalia-ako-kiwa): erst suchen, Karte dieser Aufgabe finden, nicht neu anlegen. Nicht das Audio-Board, dort liegt nur der Hörtext. Stand in der Antwort nennen.

Done: Karte gefunden oder bewusst keine, Stand genannt.
