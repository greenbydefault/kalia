# LinkedIn — Kanal

Index: [`GRUND.md`](GRUND.md). Graph/Eltern: [`netzwerk.md`](netzwerk.md).

---

## Spielregeln

1. **Deutsch, du, konkret.** Kein „wir disruptiven Outdoor“. Kein „excited to share“.
2. Erste Zeile = Hook vor „mehr anzeigen“. Rest darf länger sein.
3. Immer ein Bild oder Clip aus der echten App oder vom echten Weg. Kein Mockup-Canva.
4. Region nennen (Brandenburg / Müritz / wo ihr wirklich seid), nicht „Deutschland“.
5. Kind: Geschichte ja. Gesicht nur wenn ihr das wollt und es auch in 5 Jahren noch ok ist. Rücken, Stiefel, Hand an einer Tafel reicht.
6. Nicht „Launch“ sagen, solange nichts installierbar ist. Wort: *bauen* / *testen* / *ersten Stand zeigen*.
7. Tags: 3–8, **Eltern-/Ort-Signal**, kein Dev-Signal. `#Familie` `#MitKindern` `#Brandenburg` `#Natur` `#Rausgehen`. Nicht `#Webflow` `#NoCode` `#Flutter` an diesen Posts — das zieht denselben Graph nochmal.
8. Nach dem Post 30–60 min Kommentare selbst beantworten. Der Algorithmus füttert Gespräche, nicht Likes.

**Wen wir uns wünschen in den DMs:** Eltern mit demselben Problem. Leute aus Naturparken / Ranger / Umweltbildung. Andere Builder. Jemand der sagt „bei uns im Landkreis fehlt genau das“.

**Wen wir nicht jagen:** VCs im ersten Post. Influencer mit 200k. Presse.

---

## Post 1 — Origin (Entwurf)

Hook muss sitzen. Drei Varianten, eine nehmen, rest löschen wenn gepostet.

CTA immer so, dass ein *Elternteil* antworten kann — nicht „was haltet ihr vom Stack?“.

### A — Problem zuerst (empfohlen)

> Sonntagmorgen, Kind ist bereit, ich google 40 Minuten „Lehrpfad mit Kind Brandenburg“.
>
> Ergebnis: PDFs von 2014, Wanderportale mit 14 km und 300 Höhenmetern, und drei Foren-Threads ohne Koordinaten.
>
> Genau das bauen wir gerade selbst. Eine App, die in der Nähe zeigt, was mit Familie wirklich geht — kurzer Rundweg, Waldspielplatz, Lehrpfad mit Stationen, nicht die Königsdisziplin für Trailrunner.
>
> Anlass ist egoistisch: wir sind selbst mit unserer Tochter draußen und es gab das Ding nicht.
>
> Stand: Karte, Trails, Arten zum Entdecken, ohne Konto nutzbar. Noch nicht im Store. Katalog wächst, Region ist ehrlich begrenzt (Brandenburg, Müritz und ein paar Ausreißer), nicht „ganz Deutschland“.
>
> Kennt ihr das Google-am-Sonntag-Problem? Oder habt ihr einen Ort, der in so eine Karte gehört, und niemand hat ihn sauber erfasst?

Bild: Screenshot der Karte mit echten Pins in eurer Gegend, oder ihr zwei von hinten am Weg (ohne Gesicht, falls unsicher).

### B — Produkt zuerst

> Wir bauen eine App für Familien, die rauswollen und in 30 Sekunden sehen wollen, was in der Nähe geht.
>
> Lehrpfade, Waldspielplätze, kurze Runden. Mit Karte, Stationen, Arten. Ohne Konto.
>
> Gebaut, weil wir sie selbst brauchen — mit unserer Tochter. Den Rest erzähle ich, wenn jemand fragt.
>
> Screenshot unten. Wer das Problem auch hat: schreiben.

Nur nehmen, wenn A zu lang wirkt. Schwächerer Hook.

### C — Katalog als Plot

> Das Produkt ist eine Karte. Die eigentliche Arbeit ist der Katalog.
>
> Naturlehrpfade hängen an Bäumen, in Flyern und in OSM-Fragmenten. Sonntagmorgen hilft das einer Familie mit Kind nicht.
>
> Wir ziehen das gerade in eine App, die man ohne Konto aufmachen und in der Nähe filtern kann.
>
> Wenn du einen Pfad kennst, der gut ist und digital schlecht: DM.

Gut als Post 3, nicht als Erstauftritt — zu insiderig.

---

## Serie danach (nicht alles in Post 1)

Ungefähre Reihenfolge, nicht Kalender. Ein Post, wenn etwas Neues da ist — nicht „jeden Dienstag Content“.

| # | Thema | Womit |
|---|---|---|
| 1 | Origin / Sonntagmorgen | Screenshot Karte oder Feld |
| 2 | Warum Komoot das nicht ist | 1 Screenshot Komoot-Suche vs. unser Peek (Kinder, Dauer, Distanz zum Start) |
| 3 | Katalog ist die harte Kante | Eine Tafel / ein Flyer vs. was in der App steht |
| 4 | Arten, nicht Lexikon | Steckbrief + „gesehen“ — fürs Kind, nicht für den Ornithologen |
| 5 | 10 Familien zum Testen | Nur wenn Tür existiert (TestFlight / Web / Testgruppe) |

Kommentare und DMs aus Post 1 können die Reihenfolge sprengen. Dann denen folgen.

---

## 5 Leute aktiv schicken

Nicht „Netzwerk aktivieren“. Fünf Namen, denen der Post persönlich hinterhergeht (LinkedIn-DM oder WhatsApp), weil ihr Gespräch wollt, nicht Reichweite.

**Mischung, sonst bleibt der Post in der Blase:** mindestens 3 davon Eltern (auch wenn sie Webflow machen — dann als Eltern anschreiben). Maximal 1–2 reine Builder.

Vorlage DM:

> Hab das gerade öffentlich gemacht — wir bauen die App, die ich am Sonntag mit [Kind] immer gebraucht hätte. Würd mich interessieren, ob das bei euch auch so ist / ob du jemanden kennst, der in so einem Naturpark sitzt.

Wenn die Person kommentieren soll, extra Satz (sonst kommt „sick build“):

> Falls du was unter den Post schreibst: als Elternteil, nicht als Dev. Der erste Kommentar entscheidet, wen LinkedIn als Nächstes zeigt.

Liste hier führen, wenn ihr sie habt:

- [ ] … (Eltern)
- [ ] … (Eltern)
- [ ] … (Eltern)
- [ ] …
- [ ] …

---

## Demo-Tür (sobald Post 1 nicht mehr reicht)

Ohne Store brauchen wir eins von:

1. **Web-Preview** (Vercel, siehe `DEV-SERVER.md`) — gut für „spiel mal 2 Minuten“. GPS/Tour auf Desktop schwach, Karte reicht.
2. **TestFlight / internes Android-Track** — sobald iOS-Signing steht. Das ist die echte Familientür.
3. **WhatsApp-Gruppe „10 Familien“** — reicht länger als eine Landingpage.

Warteliste-Landing ohne Demo ist für uns zu früh: wir haben nichts zum Downloaden und keinen Namen.
