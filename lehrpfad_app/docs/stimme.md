# Kalia-Stimme

Eine Stimme für alles, was die App sagt, im Lesetext und im Hörtext. Der Ton verschiebt sich nach Kanal, die Persönlichkeit nicht. Profil und Wortschatz stehen nur hier.

Form und Limits stehen woanders: Ohr in [`audio/GRUND.md`](audio/GRUND.md) und den Hörtext-Specs, Trail-Lesetext in [`../tools/TRAIL_SCAN.md`](../tools/TRAIL_SCAN.md) (dort auch das Limit-Log). Belege liegen in [`archiv/`](archiv/).

Maßstab ist der Usedom-Hörtext in [`TRAIL_HOERTEXT.md`](../tools/TRAIL_HOERTEXT.md). Das Profil ist aus ihm gelesen, nicht erfunden. Ändert sich das Gold, ändert sich hier etwas.

---

## Profil (vier Achsen, NN/g)

| Achse | Wir | Nicht |
|---|---|---|
| förmlich – locker | gepflegte Umgangssprache, Mitte | Amtsdeutsch, aber auch kein Kumpel („halt lieber Abstand“) |
| ernst – lustig | ernst, ein trockenes Schmunzeln, wenn es wörtlich stimmt („und er hat es nicht eilig“) | Witze, Wortspiele, Ausrufezeichen |
| respektvoll – respektlos | respektvoll gegenüber Ort, Tier und Besucher | belehrend, Predigt, Moral am Schluss |
| sachlich – begeistert | sachlich mit leisem Staunen | Werbebegeisterung, Superlative, Wertwörter |

Das ist die Stimme eines Interpreters neben der Familie: kundig, ruhig, genau. Er weiß etwas und sagt es einmal.

Gegenlicht: In der NN/g-Studie zur Markenwirkung schnitten lockere, gesprächige und moderat begeisterte Töne am besten ab. Wir stehen bewusst auf der sachlichen Seite der Mitte. Das ist eine Entscheidung, kein Befund ([`archiv/quellen-trail.md`](archiv/quellen-trail.md)).

## Kanal verschiebt den Ton, nicht die Stimme

| Kanal | Verschiebung |
|---|---|
| `kurzbeschreibung` | knapp und sachlich, ein Bild, das den Ort kenntlich macht |
| `beschreibung` | ein Bild mehr, was kein Chip und kein Tag sagt |
| `besuchshinweise` | nüchtern, Imperativ/Infinitiv erlaubt |
| `hoertext` (Trail) | erzählt, Rhythmus, langer Satz trägt die Bewegung |
| Art-Scan und Art-`hoertext` | folgen ihren Specs, Stimme gilt, Umstellung später |

## Regeln (Imperative)

1. Fakt vor Adjektiv. Steht die Sache da, braucht sie kein Wertwort.
2. Das Interessanteste zuerst. Satz 1 muss allein tragen, auch wenn der Rest abgeschnitten wird.
3. Zahlen nur, wenn sie in der Config oder im Beleg stehen. Nichts runden, was am Schild genau steht (Scan). Im Hörtext runden (GRUND).
4. Verben tragen das Bild. steigen, federn, münden statt ist, gibt, hat.
5. Ein Begriff pro Ding (Lexikon unten). Nicht abwechseln, um schöner zu klingen.
6. Keine Anrede in Trail-Texten. Der Ort ist Subjekt. Menschen in der dritten Person („wer sich hineinlegt“).
7. Nichts behaupten, was man nicht prüfen kann: keine Prognose über Kinder, keine erfundene Sinneswahrnehmung.
8. Laut lesen. Stolpert der Mund, umbauen.
9. Vor dem Speichern gegen die Muster unten prüfen (Wortliste und Slop-Muster).

## Wortliste

Als Gate in `scan.py` (hart = Fehler, Warnung = prüfen). Namen sind ausgenommen („Erlebnispfad“ im Titel ist kein Verstoß).

**Hart (nie in Fließtext):** atemberaubend, unvergesslich, einzigartig, einmalig, idyllisch, malerisch, traumhaft, spektakulär, magisch, märchenhaft, paradiesisch, Naturparadies, Highlight, „ein Muss“, „für jeden etwas“, „Spaß für die ganze Familie“, „für Groß und Klein“, eintauchen, Auszeit, Genuss, Oase.

**Warnung (nur mit Beleg):** Erlebnis, Abenteuer, entdecken, bestimmt, jedes Kind, zahlreich, vielfältig, perfekt, ideal, wunderschön, herrlich, wunderbar, lohnt sich.

Slop-Muster (aus dem Skill `unslop`, hier reicht diese Liste): Bedeutungsaufblähung, „nicht nur X, sondern Y“, Dreiergruppen ohne drei Dinge, Gedankenstrich als Konnektor, Doppelpunkt als Krücke.

## Lexikon (ein Wort pro Ding)

| Ding | Wort | Nicht daneben |
|---|---|---|
| begehbare Holzkonstruktion in der Höhe | Steg | Brücke, Pfad (wenn es der Steg ist), Laufsteg |
| Boden- oder Waldweg | Weg | Pfad, Route (außer als Eigenname) |
| Aussichtsbauwerk | Turm | Warte, Aussichtsplattform (außer die Plattform ist gemeint) |
| Punkt mit Tafel oder Spiel | Station | Posten, Stopp, Punkt |
| ganzer Pfad als Ort | Name des Ortes („der Baumwipfelpfad“) | wechselnd „die Anlage“, „das Areal“ |

Entwurf, ergänzt sich beim Schreiben. Neues Wort nur mit Eintrag hier.

## Log

| Datum | Entscheidung |
|---|---|
| 2026-10-02 | Gemeinsame Stimme für Lese- und Hörtext. Profil aus Usedom-Hörtext-Gold, vier Achsen nach NN/g. Trail-Lesetext ohne Anrede. |
