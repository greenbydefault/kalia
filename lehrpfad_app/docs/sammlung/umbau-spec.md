# Sammlung – Umbau-Spec (Flow & Struktur)

Nov 15, 2026 · @Oliver

## Ziel & Grundsätze

Der Tab Sammlung wird vom langen Grid (Flora → Fauna → Geräte untereinander) zu einer umschaltbaren Ansicht umgebaut, die Funde zeigt und offene Einträge als Ziel anbietet. Diese Spec beschreibt nur Struktur, Flow und Logik – kein Design.

- **Design-neutral:** keine Farben, Abstände, Radien, Schriften, Animationskurven aus dem Prototyp übernehmen
- **Bestehendes nutzen:** vorhandene Widgets, Theme, Tokens, Icons und Datenzugriffe der Codebase (Flutter, Supabase); nur ergänzen, was fehlt
- **Prototyp-Look:** Platzhalter-Styles der App sind ausdrücklich okay; Hauptsache, der Flow stimmt
- **Semantik vor Optik:** Bereiche als klar benannte Widgets/Sektionen, damit später nur das Styling getauscht wird
- **Referenz:** klickbarer Prototyp auf dem Canvas „Kalia · Sammlung Redesign“ – nur für Ablauf und Reihenfolge, nicht für Maße
- **Bleibt wie bisher:** Freischalten durch Sichtung vor Ort, Detail als Bottom Sheet, Entfernen aus der Sammlung, Nutzung ohne Konto

## Screen-Aufbau

Ein scrollbarer Screen mit sieben Bereichen; Umschalter und Chips bleiben beim Scrollen oben stehen.

1. **Kopf**
   - Titel „Sammlung“
   - Zeile: „{n} Funde · +{m} diese Woche“ (Logik siehe Daten)
   - `+{m}`-Teil ausblenden, wenn m = 0
2. **Kategorie-Umschalter** (sticky)
   - 3 Segmente: Flora · Fauna · Geräte
   - je Segment: Label + Anzahl Funde dieser Kategorie (keine Gesamtzahl)
   - Default beim ersten Öffnen: Fauna (alternativ zuletzt gewählte Kategorie merken)
   - Wechsel setzt Gruppen-Filter auf „Alle“ und scrollt nach oben
3. **Gruppen-Chips** (sticky, direkt unter Umschalter, horizontal scrollbar)
   - „Alle“ + Artengruppen der aktiven Kategorie, dynamisch aus den Daten
   - Einfachauswahl; aktiver Chip markiert
4. **Zuletzt entdeckt** (nur bei Filter „Alle“)
   - horizontale Liste, max. 5 Funde der aktiven Kategorie, neueste zuerst
   - Item: Illustration, Name, relativer Zeitpunkt, Pfadname
   - ausblenden, wenn 0 Funde in der Kategorie
5. **Noch offen in eurer Nähe** (nur bei Filter „Alle“)
   - max. 2 offene Einträge mit kürzester Fahrzeit zu einem Pfad, auf dem sie vorkommen
   - Item: Silhouette, Name, „Gute Chancen: {Pfad} · {Fahrzeit}“, Pfeil
   - ausblenden ohne Standort / ohne Treffer
6. **Eure Funde** – Grid
   - Überschrift + Anzahl im aktuellen Filter
   - gefundene Einträge, neueste zuerst
   - Kachel: Illustration (farbig), Name, Seltenheits-Markierung
7. **Noch zu entdecken** – Grid
   - Überschrift + Anzahl im aktuellen Filter
   - offene Einträge in Katalog-Reihenfolge
   - Kachel: Silhouette der Illustration (kein Schloss-Icon), Name
   - ausblenden, wenn alles gefunden

Grid-Spaltenzahl wie bisher (3). Tap auf jedes Item in 4–7 öffnet das Detail-Sheet.

## Daten & Ableitungen

Katalog kommt aus Supabase, Funde liegen lokal (ohne Konto) und werden bei Registrierung synchronisiert – Feldnamen an das bestehende Schema anpassen.

| Feld | Quelle | Wofür |
| --- | --- | --- |
| id, Name, wissenschaftl. Name | Katalog | Kachel, Sheet |
| Kategorie (flora / fauna / geraete) | Katalog | Umschalter |
| Artengruppe (z. B. Vögel, Bäume, Pilze) | Katalog | Chips |
| Seltenheit (häufig … legendär) | Katalog | Markierung, Sheet |
| Illustration | Katalog | farbig + als Silhouette |
| Kurzfakt für Kinder | Katalog | „Wusstest du?“ |
| Hinweis (wann/wo gute Chancen) | Katalog, optional | Sheet offen |
| Audio (Ruf/Geräusch) | Katalog, optional | Anhören |
| Pfade, auf denen der Eintrag vorkommt | Katalog-Relation | Nähe, Sheet |
| Fund: Datum, Pfad-ID | lokal / Konto | Sortierung, Sheet |
| Fund: Wer hat’s entdeckt (optional) | lokal / Konto | Sheet |

**Ableitungen**

- `gefunden` = Fund-Eintrag existiert
- Kopf-Zähler: Anzahl aller Funde; „diese Woche“ = Funde mit Datum ≤ 7 Tage
- Segment-Zähler: Funde je Kategorie – nie „x von y“ (Katalog wächst)
- Relativer Zeitpunkt: heute · gestern · vor X Tagen · vor X Wochen · vor X Monaten
- Nähe: je offenem Eintrag kürzeste Fahrzeit vom Standort zu einem passenden Pfad; vorhandene Fahrzeit-Logik der App nutzen; Top 2
- Silhouette: aus derselben Illustration ableiten (Filter/Tint), keine extra Assets
- Funde-Grid sortiert nach Fund-Datum absteigend; Offen-Grid in Katalog-Reihenfolge

## Detail-Sheet

Ein Bottom Sheet mit zwei Varianten – gefunden und offen; Reihenfolge der Bereiche ist verbindlich, Gestaltung nicht.

| Bereich | Gefunden | Offen |
| --- | --- | --- |
| Bühne | Illustration farbig, Schließen-Button | Silhouette, Label „Noch nicht entdeckt“, Schließen-Button |
| Kopf | Seltenheit, Artengruppe, Name, wiss. Name | gleich |
| Aktionen | Anhören | Anhören · „Hab ich gesehen“ (primär) |
| Kontext | „Entdeckt {Zeitpunkt}“ + Pfadname | „Gute Chancen“: Pfad + Fahrzeit + Hinweis |
| Wusstest du? | Kurzfakt | Kurzfakt |
| Wer hat’s entdeckt? | Auswahl: Erwachsene · Kind · Gemeinsam (optional) | – |
| Entfernen | Textlink „Doch nicht gesehen? Aus der Sammlung nehmen“ | – |

- Sheet schließt per Wisch nach unten, Tap auf Hintergrund oder Schließen-Button
- Anhören nur zeigen, wenn Audio vorhanden; bei offenen Einträgen bewusst prominent (Ruf vorher kennenlernen)
- Kontext „Gute Chancen“ ohne Standort: nur Pfadname(n), keine Fahrzeit
- Bereiche ohne Daten (kein Fakt, kein Hinweis) komplett ausblenden, keine Leerzustände im Sheet
- Bestehende „Kleinigkeiten anpassen“-Optionen aus dem aktuellen Sheet unter „Kontext“ einordnen

## Flows

Vier Abläufe, jeweils mit Zustand und Auswirkung auf die übrigen Bereiche.

**Freischalten im Sheet (offen → gefunden)**

1. Tap „Hab ich gesehen“
2. Fund anlegen: Datum = heute, Pfad = nächster passender Pfad (bzw. aktueller Pfad im Trail Modus, sonst leer)
3. Sheet bleibt offen und wechselt in Variante „gefunden“ mit Hinweis „Neu in eurer Sammlung“ (einmaliger kurzer Effekt, Art frei)
4. Kurze Bestätigung (Snackbar): „{Name} ist jetzt in eurer Sammlung“
5. Im Hintergrund aktualisieren: Kopf-Zähler, Segment-Zähler, Zuletzt entdeckt, beide Grids, Nähe-Liste
6. Kachel im Funde-Grid einmalig hervorheben, bis das Sheet geschlossen ist

**Freischalten vor Ort (bestehender Weg)**

- unverändert; Fund taucht danach automatisch oben in „Zuletzt entdeckt“ auf

**Entfernen (gefunden → offen)**

1. Tap Textlink „Doch nicht gesehen? …“
2. Inline-Bestätigung an gleicher Stelle: „Wirklich entfernen?“ · Behalten · Entfernen – kein Dialog
3. Entfernen → Fund löschen, Sheet schließen
4. Snackbar „{Name} entfernt“ mit Aktion „Rückgängig“ (ca. 4 s)
5. Rückgängig stellt Fund mit ursprünglichem Datum, Pfad und Wer-Angabe wieder her
6. Zähler und Listen wie beim Freischalten aktualisieren

**Anhören**

- Tap startet Audio; Button zeigt Wiedergabe-Zustand, erneuter Tap stoppt
- Schließen des Sheets stoppt Audio
- bestehenden Audio-Player der App nutzen (keine zweite Logik)

**Wer hat’s entdeckt?**

- Einfachauswahl, optional, sofort gespeichert; erneuter Tap auf aktive Option hebt Auswahl auf

## Zustände & Randfälle

Jeder Bereich blendet sich aus, statt leer zu stehen – außer bei „noch gar nichts gefunden“.

| Situation | Verhalten |
| --- | --- |
| Noch kein einziger Fund (neue Nutzer) | Kopf: „Noch keine Funde“; kurzer Hinweis, wie man etwas sammelt (vor Ort sehen → antippen); Nähe-Liste und Offen-Grid normal zeigen |
| Kategorie ohne Funde | Zuletzt entdeckt ausblenden; Funde-Grid zeigt einen Satz statt Kacheln |
| Gruppe (Chip) ohne Funde | Funde-Grid zeigt einen Satz („Aus dieser Gruppe habt ihr noch nichts entdeckt“) |
| Alles in Filter gefunden | Offen-Grid ausblenden |
| Kein Standort / keine Freigabe | Nähe-Liste ausblenden; im Sheet nur Pfadnamen ohne Fahrzeit |
| Offline | Liste und Sheet aus lokalem Cache; Fahrzeit weglassen, wenn nicht berechenbar; Audio nur, wenn offline gespeichert |
| Fund ohne Pfad | Kontextzeile nur „Entdeckt {Zeitpunkt}“ |
| Eintrag ohne Illustration | neutrales Platzhalter-Bild der Kategorie, auch als Silhouette |
| Katalog wächst | neue Einträge erscheinen im Offen-Grid; kein Zähler bricht |

## Annahmen & offene Fragen

- [ ] „Geräte“: welche Einträge gehören dazu und welche Gruppen-Chips ergeben sich daraus?
- [ ] Gibt es pro Eintrag schon Seltenheit, Kurzfakt, Hinweis und Audio im Schema – oder Felder ergänzen?
- [ ] Relation Eintrag ↔ Pfade vorhanden? Ohne sie entfällt „Noch offen in eurer Nähe“ vorerst
- [ ] Welche Optionen bietet das aktuelle Sheet zum Anpassen – alle übernehmen?
- [ ] Pfad beim manuellen Freischalten: nächster Pfad oder leer lassen?
- [ ] Kategorie-Default: immer Fauna oder zuletzt gewählte merken?
- [ ] Optionaler Schalter später: Album-Ansicht (Funde und Offene gemischt in Katalog-Reihenfolge) und Namen offener Einträge ausblenden („???“) – im Prototyp als Varianten testbar

## Akzeptanzkriterien

- [ ] Flora, Fauna, Geräte per Umschalter; kein Endlos-Scroll über alle drei
- [ ] Umschalter und Chips bleiben beim Scrollen sichtbar
- [ ] Chips kommen aus den Daten der aktiven Kategorie
- [ ] Kein Zähler zeigt eine Gesamtzahl („x von y“)
- [ ] Funde stehen vor offenen Einträgen; offene als Silhouette ohne Schloss
- [ ] Zuletzt entdeckt und Nähe-Liste nur bei Filter „Alle“, sonst ausgeblendet
- [ ] Sheet zeigt je nach Status die richtige Variante
- [ ] „Hab ich gesehen“ schaltet frei, Sheet wechselt in Variante gefunden, alle Bereiche aktualisieren sich ohne Neuladen
- [ ] Entfernen nur über Textlink + Inline-Bestätigung; Rückgängig stellt alles wieder her
- [ ] Funktioniert ohne Konto, ohne Standort und offline (siehe Randfälle)
- [ ] Keine Styles aus dem Prototyp übernommen; nur Theme, Tokens und Widgets der Codebase
