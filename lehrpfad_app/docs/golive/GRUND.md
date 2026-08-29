# Go-Live Grund

Living-Backlog für App Store + Play Store. Abhaken hier. Neue Go-Live-Items als Checkbox **hier** anhängen — keine Parallel-Listen. Spec/Notizen nach `aufgaben/<id>.md` erst wenn das Item startet.

Web-Preview (kein Store, GitHub → Vercel Hobby): [`vercel.md`](vercel.md).

Erledigt = `[x]`, Zeile bleibt (Historie). Nicht löschen.

Quelle der ersten 14: Familien-Feature-Liste + Code-Stand Aug 2026.

## Store

- [ ] `legal` — Impressum, Datenschutz und Kontakt in der App, Privacy-URL fürs Store-Listing. Done wenn: alle drei Texte vom Konto-Tab erreichbar sind und die Listing-URL dieselbe Datenschutzerklärung öffnet.
- [ ] `konto-loeschen` — Account in der App löschen (Auth + Profil + Uploads). Done wenn: eingeloggter Nutzer sich selbst löschen kann und danach Login + Community-Daten weg sind.
- [ ] `passwort-reset` — Reset-Link im Login. Done wenn: „Passwort vergessen“ eine Reset-Mail über Supabase Auth auslöst und der neue Login funktioniert.
- [ ] `sso-stubs` — Google/Apple-Buttons im Onboarding entfernen, nicht implementieren. Done wenn: die Buttons weg sind und E-Mail/Passwort der einzige Login-Weg ist.
- [ ] `store-identitaet` — Display-Name, Icons, Screenshots, Age Rating. Done wenn: Store-Listing und Homescreen denselben finalen Namen/Icon zeigen, Screenshots und Age Rating stehen.
- [ ] `launch-region` — Katalog auf die Launch-Region schneiden oder Leerzustand ehrlich machen. Done wenn: außerhalb der Region kein leerer Pin-Friedhof entsteht und der Text die tatsächliche Abdeckung sagt.

## Produktbruch

- [ ] `station-open` — Tour öffnet das Stations-Sheet, nicht nur eine Snackbar. Done wenn: Station betreten → `StationDetailSheet` mit Inhalt, Snackbar allein reicht nicht.
- [ ] `amenities-ui` — WC, Parkplatz, Bank, Picknick, Spielplatz sichtbar. Done wenn: Icon-Leiste im Trail-Sheet und Marker auf der Karte im Tour-Modus, beides aus `amenityKatalog`.
- [ ] `familien-filter` — Karte filtert nach Kinderwagen, WC, Eintritt frei, max. Dauer, Hunde. Done wenn: jeder der fünf Filter die sichtbaren Trails verändert und ohne Treffer der Umkreis-Leerzustand gilt.
- [ ] `fehler-melden` — Meldeweg, den das Onboarding verspricht. Done wenn: von Trail oder Konto aus ein Formular oder Mailto mit Trail-Kontext abgeht.
- [ ] `sammlung-ehrlich` — Schloss-Copy und Toggle dieselbe Regel. Done wenn: entweder Gesehen nur vor Ort (Tour + Nähe) oder Grid/Copy ohne „Am Lehrpfad freischalten“.
- [ ] `trail-teilen` — Share-Sheet mit Name, Region, Maps-Link. Done wenn: das System-Share einen Text inkl. Maps-URL ausgibt. Deep Link nicht nötig.
- [ ] `katalog-suche` — Couch-Suche über Name, Region, Typ. Done wenn: ein Suchfeld neben der Karte den Katalog filtert; „Meine Listen“ bleibt Bookmarks.
- [ ] `distanz-card` — Entfernung zum Start am Peek, nicht Trail-Länge. Done wenn: bei Standort-Fix der Peek „12 km · 45 Min · …“ zur Nutzerposition zeigt.

## Nicht v1

Kein Checkbox hier. Offline-Kacheln, TTS, Aufgabe/Station, Quiz/Memory, KI-Kamera, echtes SSO, Deep Links, Wunderkammer, Gamification, Chat.
