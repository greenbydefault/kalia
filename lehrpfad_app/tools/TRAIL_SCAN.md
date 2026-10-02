# Trail-Scan: Lesetext am Sheet

Verbindliche Spec für `kurzbeschreibung`, `beschreibung` und `besuchshinweise` eines Trails. Das sind die Texte, die man auf dem Sheet liest, nicht hört.
Schwester von [`TRAIL_HOERTEXT.md`](TRAIL_HOERTEXT.md) (Play). Flora/Fauna: [`SPECIES_CONTENT.md`](SPECIES_CONTENT.md) und [`ART_HOERTEXT.md`](ART_HOERTEXT.md), nicht hier.
**Stimme:** [`docs/stimme.md`](../docs/stimme.md) gilt unverändert, hier steht nur Form und Länge. **Belege:** [`docs/archiv/quellen-trail.md`](../docs/archiv/quellen-trail.md).

## Zweck

Eine Familie entscheidet, ob sie hinfährt, und liest dafür selten mehr als den Anfang. Foto und Header-Chips (Typ, Platz, Rundkurs, Eintritt) hat das Auge schon, darunter kommen Fakten-Chips (Länge, Dauer, Region, Markierung), Eignung und Tags. Der Text sagt, was davon nichts sagt: was den Ort besonders macht. Wer nur den Header liest, soll den Ort erkennen. Wer weiterliest, bekommt ein Bild mehr.

Kein Prospekt, kein Stationsinventar, keine Wegbeschreibung, keine zweite Fassung des Hörtexts.

## Stimme in diesem Kanal

Dieselbe Stimme wie im Hörtext, kürzer und nüchterner:

- Keine Anrede. Kein du, ihr, Sie. Der Ort ist Subjekt, Menschen stehen in der dritten Person. Ausnahme: `besuchshinweise` darf Imperativ oder Infinitiv („Wechselsachen mitnehmen“).
- Fakt vor Adjektiv. Zahlen nur, wenn sie in der Config stehen.
- Das Interessanteste zuerst. Satz 1 trägt allein.
- Verben tragen das Bild.
- Wortliste und Lexikon aus [`stimme.md`](../docs/stimme.md).
- Rhythmus ist hier kein Ziel. Er muss nicht klingen, er muss lesbar sein.

## Felder

| Feld | Pflicht | Limit | Herkunft | Job |
|---|---|---|---|---|
| `kurzbeschreibung` | ja | ≤ 180 Zeichen, 1–3 Sätze | Quelle (Outdooractive) | Header unter dem Namen: Ort kenntlich machen |
| `beschreibung` | ja | 400–650 Zeichen (~60–100 Wörter) | Entscheidung | Absatz unter den Chips: was kein Chip sagt |
| `besuchshinweise` | nein | ≤ 280 Zeichen | Entscheidung | Accordion: was den Besuch ändert und nicht schon Tag ist |

Alle Felder: Satzlänge im Schnitt ≤ 15 Wörter, kein Satz über 25 (Content Design London).

Die Limits von `beschreibung` und `besuchshinweise` sind Kalia-Entscheidungen. Outdooractive erlaubt mobil rund 1000 Zeichen. Wir gehen darunter, weil Chips und Tags die Fakten tragen. Wer eine Grenze reißen will, ändert sie erst im Log unten.

### `kurzbeschreibung`

Ein Bild und ein Fakt, der den Ort kenntlich macht. Eintritt, Typ, Platz, Rundkurs stehen schon als Chips im Header und kommen nicht in den Text. Die Länge ist erst weiter unten ein Chip und darf hier vorkommen, wenn sie den Ort kenntlich macht. Überlebt auch, wenn die UI später kürzt (Satz 1 vorne).

### `beschreibung`

Inverted Pyramid: Satz 1 ist das Interessanteste und trägt allein. Danach Charakter und das, was ein Besucher sonst nicht weiß. Die Tags (Kinder, Wagen, Rollstuhl, Hund, Einkehr, Spielplatz) stehen weiter unten im Sheet. Wiederholen darf der Text eine solche Aussage nur, wenn er sie präzisiert („höchstens sechs Prozent Steigung“ statt „barrierefrei“).

Nicht in die Prosa: Stationsinventar, Betreiber, Öffnungszeiten, Anreise, Preise, Dauer, Region, Markierung. Länge nur, wenn sie ein Bild trägt. Wegbeschreibung gehört in die Stationen.

Nicht der `hoertext`. Die Prosa darf dieselbe Sache nennen, aber nicht denselben Satz.

### `besuchshinweise`

Nüchtern. Nur was den Besuch ändert und nicht schon als Tag oder Amenity sichtbar ist. Kein „bitte“. Keine Adjektive. Zeitweilige Lage (Baustelle, Sperrung) gehört in die Öffnungszeiten, nicht hierher.

## Maßstab

**Gold (Usedom):**

> **kurzbeschreibung** (139 Zeichen)
> Ein Holzsteg steigt 1350 Meter durch Buchen und Kiefern auf den Präsidentenberg in Heringsdorf. Der 33 Meter hohe Turm trägt oben ein Netz.
>
> **beschreibung** (536 Zeichen, 90 Wörter)
> Der Präsidentenberg ist der höchste Punkt der Insel. Auf ihm steht der Turm, dort, wo früher die Bismarckwarte stand. Von oben reicht der Blick über die Kaiserbäder und die Ostsee, bei klarer Sicht bis Swinemünde. Die Rampe kommt ohne Stufe aus und steigt höchstens sechs Prozent. Bis zu 23 Meter über dem Boden führt der Steg durch den Mischwald. Das Totholz bleibt, denn Specht und Seeadler brauchen die Löcher. Tafeln am Geländer erzählen von den Tieren und Pflanzen der Insel, die Comic-Rallye mit dem Seeadler gibt es an der Kasse.
>
> **besuchshinweise** (264 Zeichen)
> Kinder unter 14 nur mit Erwachsenem. Hunde nicht auf den Steg, Assistenzhunde ausgenommen; Hundeboxen an der Kasse. Rollstuhl und Rollator nach Anmeldung, Einstieg mit Aufzug. Letzter Einlass eine Stunde vor Schluss. Bei Gewitter, Hagel, Sturm und Eis geschlossen.

Satzlängen `beschreibung` 8 · 11 · 16 · 11 · 13 · 10 · 21. Satz 1 trägt allein (höchster Punkt der Insel). Jede Zahl steht in der Config. Der Hörtext erzählt dasselbe Gelände als Aufstieg („Gleich neben dem Bahnhof …“). Der Lesetext liefert, was der Hörtext weglässt: Höhe, Bismarckwarte, Totholz, Rallye.

**Gegenbeispiel (Usedom, bisherige `beschreibung`, so nicht):**

> Neben dem Bahnhof Heringsdorf führt der Baumwipfelpfad vom Einstiegsturm durch Mischwald auf den Präsidentenberg. 1350 Meter inkl. Rampe, der Steg bis 23 Meter, der Turm 33 Meter – oben ein Netz von 50 Quadratmetern, alles ohne Stufen, höchstens sechs Prozent, Einstieg mit Aufzug. Dazwischen Balancier und Tafeln zur Insel, Buchen und Kiefern. Die Comic-Rallye mit dem Seeadler holst du an der Kasse. Betreiberin ist die Erlebnis Akademie AG. Hunde bleiben in Boxen, Assistenzhunde ausgenommen. Kinder unter 14 nur mit Erwachsenem. Futterkrippe und Spielplatz sind unten, nicht der Steg. Eine bis zwei Stunden.

Inventar statt Ort: eine Zahlenkette mit Gedankenstrich als Konnektor. Betreiber, Dauer, Hunde und Kinder doppeln `besuchshinweise`, Länge und Dauer sind Chips. Kein Interessantestes zuerst, Satz 1 beschreibt den Weg zum Turm. „holst du“ ist Anrede. Telegrammstil ohne Verben („Dazwischen Balancier und Tafeln“).

## Ablage

- Quelle der Wahrheit: Trail-Config [`tools/trails/<id>.json`](trails/), von dort per `build_seed.py` in den Seed. Nicht im Seed von Hand.
- Nicht in `validate_seeds.py`. Sonst wird der Katalog rot, bevor ein Bestand umgeschrieben ist. Geprüft wird mit [`scan.py`](../../.cursor/skills/scan-trail/scan.py).
- Tracking: Karte auf dem Board Arbeit (kein Audio-Board, kein Hörtext).

## QA

Automatisch: `python3 .cursor/skills/scan-trail/scan.py <id>` grün (Längen, Anrede, Wortliste, Satzlänge, Doppelung zu `hoertext`).

Von Hand:

- [ ] Satz 1 von `beschreibung` trägt allein
- [ ] `kurzbeschreibung` nennt keinen Chip (Typ, Platz, Rundkurs, Eintritt)
- [ ] Jede Zahl steht in der Config
- [ ] Nichts, was ein Tag oder Fakt-Chip schon sagt, außer präzisiert
- [ ] Keine Anrede (in `besuchshinweise` Imperativ ok)
- [ ] Laut gelesen: nichts stolpert, nichts klingt nach Prospekt
- [ ] Gleiche Stimme wie der Hörtext: Neben dem Gold-Beispiel hält es stand
- [ ] **Im laufenden App gesehen**: Header ohne Abschneiden lesbar, Absatz nicht länger als der Bildschirm daneben
- [ ] Slop-Muster aus `stimme.md` geprüft

## Log

| Datum | Entscheidung |
|---|---|
| 2026-10-02 | Limits: `kurzbeschreibung` ≤180, `beschreibung` 400–650, `besuchshinweise` ≤280 Zeichen. Keine Anrede. |
| 2026-10-02 | `kollhorst` (nur im Seed, Config ohne Texte): Lesetexte neu nach dieser Spec, `scan.py` fällt für Seed-only Trails auf den Seed zurück. `hoertext` ist mit 55 Wörtern unter dem Limit und im Telegrammstil, Backlog für `audio-trail`. |
| 2026-10-02 | Altbestand: 17 von 84 Configs mit `beschreibung` enthalten Anrede (du/ihr/Sie). Nicht umgeschrieben, Backlog. Alte Configs und Seeds nie als Textvorlage nehmen, nur Usedom-Gold. |
