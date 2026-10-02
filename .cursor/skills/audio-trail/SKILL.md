---
name: audio-trail
description: >-
  Writes a trail overview hoertext (70–110 words, narrated without direct address, feature/doku tone) into the trail config and the seed.
  Use when the user asks for a Trail-Hörtext, Overview, or Play text on a trail sheet.
  Not species, flora, fauna, or device content.
---

# Audio · Trail

cwd: `lehrpfad_app/`. `tools/` ist gitignored — Glob leer. `Read` auf den Pfad.

Form, Ton, Klang, Länge: `tools/TRAIL_HOERTEXT.md`, 70–110 Wörter. Stimme und Wortliste: `docs/stimme.md`. Aus `docs/audio/GRUND.md` nur laut lesen, Zahlen, Klammern. Die fünf Art-Schläge und das Art-Register gelten hier nicht. `validate_seeds.py` prüft diese Wortzahl nicht, `klang.py` schon.

## 1. Ziel

`id`. Config: `tools/trails/<id>.json`.

Done: Config gelesen. `kurzbeschreibung`, `beschreibung`, Stationen, `besuchshinweise`, `tags` bekannt.

## 2. Spec

`Read tools/TRAIL_HOERTEXT.md`. Gold- und Gegenbeispiel laut im Kopf lesen, bevor du schreibst.

Done: Ton, Klang, Bau, Maßstab, QA präsent.

## 3. Rohstoff

Notiz, nicht ins JSON. Pro Abschnitt aus „Bau“ (Einstieg, unterwegs, Moment, Tipp):

- was dort passiert, mit Quelle in der Config
- ein starkes Verb, das es zeigt (steigt, federt, sprudelt, mündet)
- ein Sinneseindruck, nur wenn die Config ihn hergibt (rauscht, federt, nass)

Menschen als dritte Person notieren („wer sich hineinlegt“), nie als Befehl. Keine Prognose, was Kinder tun werden.

Done: vier Abschnitte, jeder mit Quelle und Verb.

## 4. Erzählen

Entwurf als Erzähler ohne Anrede: Der Ort ist Subjekt, der Text geht einmal durch den Besuch. Ein Satz trägt die Bewegung des Ortes und darf lang sein. Der Tipp kommt im selben Ton. Nicht auf Länge achten.

Done: ein durchgehender Entwurf, kein ihr/du/Sie, kein Satz wie ein Stichpunkt.

## 5. Klang

```
python3 ../.cursor/skills/audio-trail/klang.py <<< "<text>"
```

Prüft Wortzahl 70–110, mindestens einen Satz ≥ 20 und einen ≤ 7 Wörter, keine drei Sätze in Folge mit < 4 Wörtern Unterschied, verschiedene Satzanfänge, kein Da/Dann vorne, keine Anrede, „man“ ≤ 1, keine Kinder-Prognose. Markiert schwache Verben (ist, hat, gibt, geht, macht …). Jede markierte Stelle ersetzen, außer das Verb ist dort das genaueste.

Done: Exit 0, schwache Verben begründet oder ersetzt.

## 6. Aufräumen

Slop-Muster und Wortliste aus `docs/stimme.md` gegenprüfen. Laut lesen, Stolperer raus. Neben das Gold-Beispiel legen: Hält es im Ton mit? Danach `klang.py` nochmal.

Done: QA in `TRAIL_HOERTEXT.md` geht ganz auf, `klang.py` grün.

## 7. Ablage

`hoertext` in `tools/trails/<id>.json`.

```
python3 tools/build_seed.py tools/trails/<id>.json
python3 tools/validate_seeds.py
```

Exit 0. Rot → Config oder Seed, nicht das Script. Feld danach in `assets/seed/<id>.json` gegen die Config prüfen.

`form: flaeche` ohne Route-Datei: `build_seed.py` bricht ab. `hoertext` in den bestehenden Seed. Fläche und Stationen bleiben. Danach nur `validate_seeds.py`.

Done: Feld in Config und Seed gleich, Validator grün.

## 8. Trello

[Kalia · Audio](https://trello.com/b/7dzAKbdB/kalia-audio): erst suchen. Karte dieses Seeds, Checkliste Produktion, Punkt Hörtext. Haken erst nach Commit. Ist er schon gesetzt und der Text neu, das in der Antwort sagen.

Done: Punkt gefunden, Stand genannt.
