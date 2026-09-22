# Kalia

Digitale Begleit-App für Naturlehrpfade: Karte, Arten, Tour-Status und Community.

Go-Live-Backlog: `docs/golive/GRUND.md`.
Web-Preview (GitHub → Vercel Hobby): `docs/golive/vercel.md`.
Öffentlich / Stimme / Kanäle: `docs/oeffentlich/GRUND.md`.
Hörtexte: Einsprech-Skript, Play. Stimme `docs/audio/GRUND.md` plus Unslop (Belege `docs/audio/quellen.md`).
Videos an Produkt koppeln: `docs/marketing/GRUND.md` (Board [Kalia · Marketing](https://trello.com/b/uCs6tzIa/kalia-marketing)).

## Language

**Trail**:
Ein Lehrpfad (`form: linie` + `route`) oder Spiel-/Erlebnisplatz (`form: flaeche` + `area`) mit Stationen und Metadaten.
_Avoid_: Route (allein), Path, Track (als Synonym); Fake-Rundkurs für Plätze ohne Weg

**Trail-`form`**:
`linie` (Polyline) oder `flaeche` (Polygon auf der Karte). Defaults Flächen-Typen: `wasserspielplatz`, `waldspielplatz`, `waldspazierplatz`, `kinderbauernhof`.
_Avoid_: Mini-Routen als Platzhalter für Areas

**Trail-`typ`**:
Ortstyp-Key (`typKatalog` in `lib/shared/catalogs/icon_catalog.dart`): u. a. `wald`, `moor`, `spreewald`, `walderlebnispfad`, `erlebniswald`, `naturerlebnis`/`naturerlebnisraum`, `waldspielplatz`, `wasserspielplatz`, `waldspazierplatz`, `sinnespfad`, `barfusspfad`, `kueste`, `kinderbauernhof`. Arboretum / beschilderter Baumgarten = `naturerlebnis` (meist `form: flaeche`), kein eigener Key. Details: `docs/datenmodell.md`.
_Avoid_: freie Labels statt Keys; `typ: arboretum`; Tag/Erlebnis `barfusspfad` mit Trail-`typ` verwechseln (parallel erlaubt); Stadtspielplatz (nur Schaukel/Rutsche/Kletter) als `wasserspielplatz` seeden; Kita-only-Hof oder Produktionsstall als `kinderbauernhof`

**Besuch**:
Optional `eintritt`, `eintrittPreise`, `oeffnungszeiten`, `besuchshinweise`. Header-Chip „Eintritt“ nur wenn `eintritt: true`. Pin-Ring folgt demselben Flag (`TypStartMarker.forTrail`). Website schon am Trail, Anzeige im Accordion Anreise & Infos.
_Avoid_: Tag `eintritt` (Chip wäre doppelt); alte Ticket-NOGOs wieder öffnen; Pin-Gold nur für einen Trail hartcoden

**Species-`kategorie`**:
`flora` \| `fauna` \| `geraete`. Geräte-Icons über `geraeteKatalog` + optional `iconKey` — nicht Phosphor hardcoden.
_Avoid_: Standard-Spielgeräte (Schaukel/Rutsche) als `geraete`-Steckbriefe

**Hörtext**:
Einsprech-Skript in `content.hoertext` (Arten/Geräte) bzw. Trail-`hoertext`. Nutzer drückt Play. Stimme: `docs/audio/GRUND.md`. Limits in den Content-Specs.
_Avoid_: Lesetext in der UI; Scan-Bullets einsprechen; Instagram-Caption; Podcast; Floskel-Schluss („nimm den Ort mit allen Sinnen wahr“)

**Merkmal**:
Geteiltes Badge einer Art (Aussehen / Verhalten / Rolle / Lebensraum). Eigene Tabelle `merkmale` + M2M `species_merkmale`; viele Arten tragen dasselbe Merkmal. Icon über `iconKey` in `merkmaleKatalog` — Phosphor-Platzhalter, kein Snappit-Schild-Look.
_Avoid_: Trait, Tag, Eigenschaft, Schild-Badge, Custom-Illustration

**Artgruppe**:
Species-`gruppe` — grobe Kategorie im Profil (`saeugetiere`, `voegel`, `insekten`, `amphibien`, `reptilien`, `spinnen`, `baeume`, `straeucher`, `kraeuter`, `moose`). Karte „Kategorie“ im Steckbrief.
_Avoid_: Taxonomie-Label, Klasse (als UI-Begriff)

**Seltenheit**:
Species-`seltenheit` — wie oft Kinder die Art auf den Trails in der App treffen (`haeufig` / `mittel` / `selten` / `sehr-selten`). Kein IUCN / Rote Liste.
_Avoid_: Rote Liste, Gefährdungsstatus, Common/Rare (englisch)

**Gefahr**:
Species-`gefahr` 1–5 — „darf ich nah ran?“ (1 sehr gering … 5 nicht annähern). Ergänzt `hinweis`, ersetzt es nicht.
_Avoid_: Giftlexikon, Warnung vor Tieren generell

**Nahrung**:
Species-`nahrung` — Fauna: was sie fressen; Flora: was sie anbieten (Nektar, Eicheln). Chips im Steckbrief.
_Avoid_: Diät, Ernährungsweise (als UI-Label)

**Beziehung**:
`species_beziehungen` — ökologischer Zusammenhang (`frisst` / `bestaeubt` / `wohnt_an`). Ziel: Katalog-Art (`to_species_id`, tippbar) oder Freitext-Karte (`name_de`, z. B. „Mücke“, „Uhu“).
_Avoid_: Ghost-Species für jede Mücke, eigene Tabelle pro Beziehungstyp

**Maß**:
Species-`masse[]` — Key aus `masseKatalog` + Anzeigewert (`80–100 cm`, `15–30 kg`). Nicht jede Art nutzt jeden Key; Flora ≠ Fauna.
_Avoid_: cm-Dump, Pseudopräzision, Lexikon-Werte

**Taxonomie**:
Species-`taxonomie` — `reich` / `stamm` / `klasse` / `ordnung` / `familie` (lateinische Rangnamen, UI-Labels deutsch). Pills im Steckbrief.
_Avoid_: wissenschaftliche Abhandlung, alle Ränge anzeigen wenn leer

**Merken**:
Bookmark eines Trails für später.
_Avoid_: Favorit, Speichern, Liked

**Liste**:
Benannte Sammlung von Trails, die der Nutzer anlegt. Ein Trail kann in mehreren Listen liegen.
_Avoid_: Ordner, Album, Playlist, Favoritenliste

**Standort**:
Geräteposition (When-in-use). Für Umkreis und Vor-Ort ein One-Shot, für die Tour ein Stream.
_Avoid_: GPS als Synonym für den Kartenfilter

**Umkreis**:
Kartenfilter um den Standort (20 / 50 / 100 km / Alle). Default 20 km. Ohne Consent = Alle.
_Avoid_: Radius (in der UI), Nearby; mit „Ort in der Nähe“ (kuratierte Cafés/Camping) verwechseln

**Ort in der Nähe**:
Kuratierter Ort im Umfeld eines Trails (`cafe` / `restaurant` / `hofladen` / `baden` / `museum` / `aktivitaet` / `camping`). Eigene Katalog-Entity; Zugehörigkeit über Distanz zu Trail-`start` (Default 20 km, Camping 5 km). Anzeige max. 8 (erst max. 2 pro Kategorie, Rest nach Distanz). Marker-Layer bei Trail-Auswahl, Accordion „In der Nähe“ im Detail.
_Avoid_: POI (UI-Wort); Amenity aufbohren (`gastro` ist Weg-Infrastruktur); Tag `einkehr` als Ersatz; Join `trail_pois` (Zugehörigkeit ist geografisch)

**Kartenkamera**:
Besitzt jede Kamerabewegung der Übersichtskarte (Intent, Abbruch, Follow) inklusive wann welcher Intent feuert. Widget liefert Events, nicht Orchestrierung.
_Avoid_: parallele `MapController.move`-Aufrufe; Intent aus `didUpdateWidget`-Diffs im Widget; Geste ohne Animator-Cancel

**Kameraziel**:
Katalog, Hero, externer Einstieg und Cluster-Kinder: Center/Zoom so, dass Trail-`mapPoints` (`form:linie` → route, `form:flaeche` → area) im Viewport liegen. Peek-Card als Bottom-Padding.
Tap-Selektion: Kamera bleibt; Peek-Card und Track-Fade ohne Pan/Zoom.
_Avoid_: Startpunkt + Südoffset (statt Padding beim Fit); Cluster-Centroid ohne Kinder-Bounds; Zoom oder Nudge auf Tap

**Cluster**:
Sammelmarker naher Trail-Startpunkte auf der Übersichtskarte. Zoom merged/splittet; Tap expandiert die Kinder.
_Avoid_: Pin-Gruppe, Heatmap, Supercluster (Implementation), Cluster-Zoom im Karten-Widget / hinter dem Gesture-Gate

**Vor Ort**:
Hartes Gate für Tour-Start und Resume. Linie ≤ 250 m zur Polyline, Fläche im Polygon oder ≤ 150 m zur Kante.
_Avoid_: Geofence (in der UI)

**Tour**:
Eine aktive GPS-Session auf einem Trail.
_Avoid_: Track starten, Walk, Session (in der UI)

**Unterwegs**:
Status einer laufenden Tour.
_Avoid_: Aktiv, In Progress, Gestartet

**Gelaufen**:
Trail als abgeschlossen markiert (manuell oder nach Tour).
_Avoid_: Erledigt, Completed, Abgelaufen

**Eignung**:
Abgeleiteter 1–5-Score (Kinderfreundlich / Barrierefreundlich) aus Tags, Amenities und Stations-`barrierefrei`.
_Avoid_: Rating (Community-Sterne), Tag (einzelnes Merkmal)

**Catalog-Cache**:
Persistenter String-Store für den unfiltered Katalog (Trails, Species, Merkmale, Orte in der Nähe). Remote → Cache → Seed. Native File, Web Prefs.
_Avoid_: Prefs für Trail-Geometrie auf allen Plattformen; gefilterte `near`/`radiusKm`-Antwort als Vollkatalog

**Queue**:
Persistente FIFO der [SyncEngine] für fehlgeschlagene Remote-Mutationen. Coalescing pro (Entity, Key).
_Avoid_: zweiter Sync-Pfad, direkter Remote-Upsert am Hybrid vorbei

**Merge**:
Login-Abgleich lokal ↔ remote. Union Bookmarks/Gesehen, local-wins Completions, eine `active` Tour. Push nur was remote fehlt.
_Avoid_: updatedAt als Push-Kriterium; Unmerken-Push ohne Produktentscheid

**Sync**:
Remote-Nachlieferung von User-State über Queue + Merge. Drei Adapter-Familien: Katalog, User-State, Community (live-only).
_Avoid_: Hybrid-Framework, Community in die Queue ziehen
