# Audio: Recherche

Belege hinter [`GRUND.md`](GRUND.md). Claims nur, wenn der Eigentümer der Regel sie so sagt. Vendor-Blogs sind Hinweis, kein Beweis.

`hoertext` ist Einsprech-Skript. Nutzer drückt Play. Scan ist das, was man in der App liest.

---

## Halt

Kalia ist Interpreter vor Ort, mit Kind, oft in Bewegung. Play liefert eine kleine Geschichte. Nicht Podcast, nicht Lexikon, nicht Instagram, nicht Junior-Ranger-Moralstunde, nicht Lesetext in der UI.

| Register | In der App | Job |
|---|---|---|
| Scan (`hook` … `funFacts`) | ja, Steckbrief | NPS-Wayside, Serrell |
| `hoertext` | nein, nur Audio | NPR/RNZ/BBC: gesprochenes Stück |

---

## 1. Ohr (Einsprechen)

### NPR Training, *Campfire tales* (2025)

Radio-Storytelling kommt von mündlichem Erzählen. Campfire: Anfang verführt, Details nach und nach, bis zum Schluss. Eine klare Pointe, sonst Ärger. Nicht zurückspringen. Frage im Kopf des Hörers aufwerfen, dann beantworten. Übergänge in Print dürfen hart sein, im Radio nicht. Signposts weichen den Wechsel. Kurze Sätze, wenig Nebensatz. Verben vor Adjektiven. Satzfragmente sind ok, wir sprechen so. Laut lesen: stolpert der Mund, ist es Print. Der Hörer merkt, wenn dich das Stück langweilt.

**Übernehmen:** eine Pointe. Anfang zieht. Nicht fünf Kapitel, sondern nach und nach. Weiche Übergänge. Probehören.

**Verwerfen:** Tape/Actuality-Tango (Interview-Cuts). Wir haben eine Stimme, kein Feature mit O-Tönen. Lange Signposts brauchen wir in 45–60 s nicht. Ein Atem, kein „jetzt zum nächsten Punkt“.

### RNZ, Owen & Perkins, *Scripting for the Radio Documentary*

Scripting sagt, was gesagt werden muss, sauber und knapp. Ohne Flow wird das Programm zur Würstchenkette. Flow: nicht nur Stakkato, nicht nur endlose Sätze. Gutes gesprochenes Englisch heißt: beim Schreiben zurücklesen und ändern. Present tense, aktiv. „Tom Jones slams the door“ schlägt Passiv. Einfachheit in der Atmosphäre: das treffende Verb, nicht lila Prosa. Über-Schreiben tötet den Effekt.

**Übernehmen:** Flow. Präsens, aktiv. Wirtschaftlich. Beim Schreiben laut. Keine Würstchen aus Szene / Auftrag / Bedeutung / Fakt / Schluss.

**Verwerfen:** Cut-Technik, Magpie-Methode, Studio-Documentary-Länge. Wir schreiben 90–120 Wörter, kein 20-Minuten-Feature.

### BBC Radio News Style Guide (Newsroom, 2002)

Einmal hören, nicht nachlesen. Zuerst wissen, was die Geschichte *ist*. SVO. Nicht mit Nebensatz aufmachen. Zahlen runden. Jargon schließt aus. Laut lesen. Anmoderation sagt nicht denselben Satz wie das Stück.

**Übernehmen:** einmal hören, SVO, Zahlen runden, Scan-Hook ≠ Hörtext-Einstieg, Probehören.

**Nicht 1:1:** 180 Wörter/min ist Nachricht. Einsprechen auf dem Pfad: ~130–160 Wörter/min.

### Museum-Audioguide (gesprochen, nicht Wand)

soundgarden: Objekt-Tracks unabhängig, linear, Kern am Satzende, keine runden Klammern. 120 Wörter ≈ 1 min. Galerie plant oft 60–90 s Stehen.

**Übernehmen:** jede Art allein verständlich. Linear. Spekulation als Vermutung. Klammern vermeiden.

**Nicht als Längen-Diktat:** 1:30 Galerie. Wir: 90–120 Wörter, ~45–60 s, Kind plus Gehen.

---

## 2. Scan (Steckbrief in der App)

### Tilden, *Interpreting Our Heritage* (1957)

Sechs Prinzipien. Für uns vor allem: ohne Bezug zur Erfahrung steril. Information ist nicht Interpretation. Ziel ist Provokation, nicht Unterricht. Kinder (bis etwa zwölf) keinen verdünnten Erwachsenentext, sondern anderen Ansatz.

**Übernehmen:** Kernidee, Neugier, Ort an Erfahrung. Kind: konkret, nicht verdünnt. v1: ein eingesprochenes Stück, kein zweites Kinderprogramm.

**Verwerfen als v1:** Tildens „separate program“.

### NPS Wayside + Interpretive Text Writing

Caption der Landschaft. 30–45 s Aufmerksamkeit. Eine Idee. Hook mit Bedeutung, kein Sachlabel. So-what. Nicht das Offensichtliche beschreiben. Aktiv. Sicherheit als Do/Don’t.

**Übernehmen nur für Scan.** Nicht als Hörtext-Form (fünf Wayside-Absätze hintereinander).

### Serrell, *Exhibit Labels* / Big Idea

Kurze Labels werden gelesen. Wie viele Wörter braucht *diese* Idee. Big Idea = eine These.

**Übernehmen für Scan.** Tweet-Länge ist kein Hörtext-Limit.

---

## 3. Raus als Ohr-Lehre

Google Conversation Design (Menüs, Chips, Turn-Taking): anderes Job. Quantity (nicht zu viel, nicht zu wenig) trifft unsere Länge, sonst VUI.

Mayer Redundancy: Hörtext liegt nicht mehr als Text in der UI. Scan-Bullets trotzdem nicht einsprechen.

Apple WWDC Speech: Technik, keine Story. QA: Probehören, auch in TTS, bevor jemand einspricht.

Alexa, Sonification, Audio-AR-Navigation: raus.

---

## 4. Unterwegs (warum Play)

Patel et al., MobileHCI 2006: Audio beim Gehen entlastet die Augen gegenüber Handy-Lesen.

Wayfindr: Kopfhörer, die Umgebung zudecken, sind unterwegs schlecht. Stück muss über Lautsprecher tragen. Keine Studio-Dramaturgie, die Stille braucht.

---

## Länge (Entscheidung)

| Stück | Spec | Tempo | Dauer |
|---|---|---|---|
| Species / Geräte `hoertext` | 90–120 Wörter | ~130–160 Wörter/min | ~45–60 s |
| Trail-Overview | 40–70 Wörter | dasselbe | ~20–35 s |

NPR/RNZ erklären Dramaturgie, nicht Minuten. Galerie-90-s ist Stehen. 90–120 bleibt. Validator unangetastet.

---

## Shape (Produktion)

Dieselbe Dramaturgie für alle Arten, damit Qualität sich wiederholt. Check beim Schreiben, nicht als hörbare Kapitel:

1. Anfang: Szene, Laut oder Frage. Nicht der Scan-Hook wortgleich. NPR: verführt.
2. Am selben Ding bleiben: ein Merkmal, eine Spur. Kein Inventar, kein „links von dir“.
3. Warum *hier*. Tilden, in den Fluss gezogen, nicht als Block.
4. Ein Fakt, der sitzt. Einer.
5. Cue-out, der nur hier gilt.

RNZ: Flow zwischen den Schlägen. NPR: nicht zurückspringen, nicht hart umschalten.

---

## Quellen

| | |
|---|---|
| NPR Training. *Campfire tales: The essentials of writing for radio* (2025). | https://www.npr.org/sections/npr-training/2025/05/31/g-s1-65875/campfire-tales-the-essentials-of-writing-for-radio |
| Owen, Alwyn, and Jack Perkins. *Scripting for the Radio Documentary.* Radio New Zealand. | https://www.rnz.co.nz/assets/cms_uploads/000/000/016/Scripting_for_the_Radio_Documentary.pdf |
| BBC Radio Newsroom. *Radio News Style Guide* (2002). | http://news.bbc.co.uk/2/hi/programmes/radio_newsroom/1099302.stm |
| Tilden, Freeman. *Interpreting Our Heritage.* Chapel Hill: University of North Carolina Press, 1957. | Buch |
| NPS Harpers Ferry Center. *Wayside Exhibits* (Scan). | https://www.nps.gov/subjects/hfc/upload/Wayside-Guide-First-Edition.pdf |
| NPS. *Interpretive Text Writing.* | https://npshistory.com/publications/interpretation/interpretive-text-writing.pdf |
| Serrell, Beverly. *Exhibit Labels* (Scan; Tweet-Maß zitiert in AAM *Less is More*, 2015). | https://www.aam-us.org/wp-content/uploads/2024/03/11_Exhibition_LessIsMore.pdf |
| soundgarden. *Wie schreibt man eine Audioführung?* (DE, Produktionshaus). | https://audioguide.de/site/assets/files/1163/do-kd_mb_03_schreibninweise_fuehrungstexte-print-1.pdf |
| Patel, N., Clawson, J., Starner, T. *Reading On-the-Go.* MobileHCI 2006. | http://nirmalpatel.com/docs/reading_on_the_go_mhci_2006.pdf |
| Wayfindr. *Open Standard for Audio-based Wayfinding* Rec. 2.0. | http://www.wayfindr.net/wp-content/uploads/2018/07/Wayfindr-Open-Standard-Rec-2.0.pdf |
