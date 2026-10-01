# Trail-Hörtext: Overview zum Einsprechen

Verbindliche Spec für Trail-`hoertext` — Studio-Vorlage für Play am Trail-Sheet, nicht Lesetext.
Feld und Player sind **nicht v1** ([`docs/golive/GRUND.md`](../docs/golive/GRUND.md) → TTS); Texte werden trotzdem jetzt produziert, wie bei Species-`hoertext`.
Schwester-Specs: [`ART_HOERTEXT.md`](ART_HOERTEXT.md) und [`SPECIES_CONTENT.md`](SPECIES_CONTENT.md) (Flora/Fauna), [`GERAETE_CONTENT.md`](GERAETE_CONTENT.md) (Geräte).
**Form, Ton, Länge:** diese Datei. Belege: [`docs/audio/quellen-ort.md`](../docs/audio/quellen-ort.md).
**Aus [`docs/audio/GRUND.md`](../docs/audio/GRUND.md) gilt hier:** laut lesen, Zahlen runden, keine Klammern, Unslop. Die fünf Art-Schläge und das Art-Register gelten hier nicht.

## Zweck

Eine Familie überlegt, ob sie hinfährt, oft mit wenig Zeit. Karte, Foto, Tags und Amenities hat das Auge schon. Play erzählt ihr, wie sich der Besuch anfühlt, und danach weiß sie, ob er zu ihr passt.

Kein Steckbrief, kein Merkblatt, kein Werbespot, kein Teaser, keine Anleitung.

## Ton

Eine Mischung aus Radio-Reisefeature, Doku-Off und gutem Vorleser. Das Feature bringt Bild und Rhythmus, die Doku Ruhe, Genauigkeit und ein bisschen Staunen, der Vorleser Wärme und Spannung.

- **Keine direkte Anrede.** Kein ihr, du, Sie. Subjekt ist der Ort: der Steg, die Bretter, das Netz, das Wasser. Menschen nur in der dritten Person („wer sich hineinlegt …“, „kleine Hände“). „Man“ höchstens einmal.
- **Erzählen, nicht anleiten.** Der Text zeigt, was der Ort tut und was mit den Menschen darin passiert. Keine Kette aus „ihr geht, ihr legt euch, ihr guckt“.
- **Wärme durch Blick, nicht durch Kumpelsprache.** Ein Bild, das ein bisschen schmunzelt („und er hat es nicht eilig“), trägt mehr als „super“ oder „bestimmt“.

## Klang

- **Rhythmus.** Kurze, mittlere und mindestens ein langer, tragender Satz, der die Bewegung des Ortes nachbaut: der Aufstieg, das fließende Wasser. Nie drei Sätze gleicher Länge hintereinander. Ein kurzer Satz setzt einen Schlag.
- **Verben tragen das Bild.** steigen, sich winden, federn, sprudeln, aufhalten, münden statt ist, gibt, fängt an, geht, guckt. Adjektive sparsam.
- **Sinne über das Auge hinaus,** wo sie sicher stimmen: rauschen, federn, Wasser auf der Haut. Nichts Erfundenes, keine Geruchs- oder Tierbehauptung ohne Beleg in der Config.
- **Satzanfänge wechseln.** Kein „Da“ und kein „Dann“ als Satzanfang, keine zwei Sätze mit gleichem Anfangswort.
- **Andocken.** Jeder Satz beginnt bei dem Bild, das der Hörer schon im Kopf hat, und führt von dort weiter.
- **Keine Prognosen über Kinder** („bestimmt“, „jedes Kind“). Stattdessen das, was der Ort mit ihnen macht.

## Bau

Ein Gang durch den Besuch, kein Raster:

1. **Einstieg am Ort.** Wo es anfängt, mit einem Bild. Kein Name als erstes Wort, kein „dieser Pfad ist“.
2. **Unterwegs.** Ein, zwei Dinge, die man spürt, nicht das Stationsinventar.
3. **Der Moment, für den man herkommt.** Darf der lange Satz sein oder direkt danach kommen.
4. **Höchstens ein Tipp,** den weder Tag noch Amenity zeigt und der den Besuch ändert (Wechselsachen, letzter Einlass, Wasser nur im Sommer). Im selben Erzählton, nicht als Regel.

Tags bleiben auf dem Sheet (`tagKatalog`): Kinder, Wagen, Rollstuhl, Hund, Einkehr, Spielplatz, Picknick, Barfuß, Parkplatz, WC.

## Maßstab

**Gold (Usedom, 100 Wörter):**

> Gleich neben dem Bahnhof von Heringsdorf beginnt ein Holzsteg, und er hat es nicht eilig. Ganz allmählich steigt er durch Buchen und Kiefern, bis die Kronen auf Augenhöhe rauschen. An einer Stelle federn die Bretter. Auf dem Präsidentenberg wartet der Turm, und um ihn windet sich der Weg, Runde um Runde und ohne eine einzige Stufe, bis er hoch oben in ein Netz mündet. Wer sich hineinlegt, sieht durch die Maschen hinunter in den Wald. Und wer den Kopf hebt, hat die Ostsee vor sich. Spät sollte man allerdings nicht kommen, denn eine Stunde vor Schluss schließt unten die Kasse.

Satzlängen 15 · 14 · 6 · 29 · 11 · 10 · 15. Der lange Satz ist der Aufstieg. Der kurze ist das Federn. „Wer … / Und wer …“ ist die einzige gewollte Wiederholung.

**Gegenbeispiel (Usedom v2, so nicht):**

> Wenn ihr auf Usedom seid und mal einen Nachmittag nicht am Strand liegen wollt, fahrt nach Heringsdorf. Gleich am Bahnhof fängt ein Holzsteg an, der euch immer höher in die Buchen und Kiefern führt. Unterwegs federn an einer Stelle die Bretter unter euch, da laufen die Kinder bestimmt zweimal drüber. Am Ende dreht sich der Weg um einen Turm nach oben, und oben ist ein Netz gespannt. Da legt ihr euch rein und guckt durch die Maschen runter in den Wald. …

Befehlskette (fahrt, legt euch, guckt). „Da“ als Anfang, zweimal. Allerweltsverben (fängt an, führt, ist gespannt, guckt). Sieben Sätze mit 12–19 Wörtern, alle gleich gebaut. Prognose („bestimmt zweimal“). „oben … oben“.

## Feld

| Feld | Pflicht | Limit | Job |
|---|---|---|---|
| `hoertext` | ja | 70–110 Wörter, ~35–50 s | Einsprech-Skript für Play (Overview) |

## Ablage

- Text: im Seed am Trail (`hoertext`; kommt mit dem Player-Feature ins Datenmodell, siehe [`docs/datenmodell.md`](../docs/datenmodell.md)).
- Datei: `assets/audio/trails/{id}.opus` (Konvention; Ordner und `pubspec.yaml`-Zeile kommen mit den ersten Dateien).
- Tracking: Trello-Board **Kalia · Audio** — 1 Karte pro Trail, Checkliste Hörtext/Sound. Abhaken erst nach Repo-Commit.

## QA

Automatisch: `.cursor/skills/audio-trail/klang.py` grün (Wortzahl, Satzlängen-Mix, Gleichtakt, Satzanfänge, Da/Dann, Anrede, „man“, Kinder-Prognose).

Von Hand:

- [ ] Laut gelesen klingt es wie erzählt, nicht wie vorgelesen und nicht wie eine Anleitung
- [ ] Der lange Satz trägt die Bewegung des Ortes
- [ ] Jedes Hauptverb zeigt etwas, schwache Verben nur, wo nichts Besseres stimmt
- [ ] Jedes Bild und jeder Sinneseindruck steht so in der Config
- [ ] Ein Moment, für den man herkommt
- [ ] Höchstens ein Tipp, und das Sheet zeigt ihn nicht
- [ ] Kein Stationsinventar, kein Tag eingesprochen, keine wörtliche `kurzbeschreibung`
- [ ] Hält neben dem Gold-Beispiel stand
