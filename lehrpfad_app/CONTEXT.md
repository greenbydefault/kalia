# Lehrpfad App

Digitale Begleit-App für Naturlehrpfade: Karte, Arten, Tour-Status und Community.

## Language

**Trail**:
Ein Lehrpfad (`form: linie` + `route`) oder Spiel-/Erlebnisplatz (`form: flaeche` + `area`) mit Stationen und Metadaten.
_Avoid_: Route (allein), Path, Track (als Synonym); Fake-Rundkurs für Plätze ohne Weg

**Trail-`form`**:
`linie` (Polyline) oder `flaeche` (Polygon auf der Karte). Defaults Flächen-Typen: `wasserspielplatz`, `waldspielplatz`, `waldspazierplatz`, `kinderbauernhof`.
_Avoid_: Mini-Routen als Platzhalter für Areas

**Trail-`typ`**:
Ortstyp-Key (`typKatalog` in `lib/shared/catalogs/icon_catalog.dart`): u. a. `wald`, `moor`, `spreewald`, `walderlebnispfad`, `erlebniswald`, `naturerlebnis`/`naturerlebnisraum`, `waldspielplatz`, `wasserspielplatz`, `waldspazierplatz`, `sinnespfad`, `barfusspfad`, `kinderbauernhof`. Arboretum / beschilderter Baumgarten = `naturerlebnis` (meist `form: flaeche`), kein eigener Key. Details: `docs/datenmodell.md`.
_Avoid_: freie Labels statt Keys; `typ: arboretum`; Tag/Erlebnis `barfusspfad` mit Trail-`typ` verwechseln (parallel erlaubt); Stadtspielplatz (nur Schaukel/Rutsche/Kletter) als `wasserspielplatz` seeden; Kita-only-Hof oder Produktionsstall als `kinderbauernhof`

**Besuch**:
Optional `eintritt`, `eintrittPreise`, `oeffnungszeiten`, `besuchshinweise`. Header-Chip „Eintritt“ nur wenn `eintritt: true`. Website schon am Trail, Anzeige im Accordion Anreise & Infos.
_Avoid_: Tag `eintritt` (Chip wäre doppelt); alte Ticket-NOGOs wieder öffnen

**Species-`kategorie`**:
`flora` \| `fauna` \| `geraete`. Geräte-Icons über `geraeteKatalog` + optional `iconKey` — nicht Phosphor hardcoden.
_Avoid_: Standard-Spielgeräte (Schaukel/Rutsche) als `geraete`-Steckbriefe

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
_Avoid_: Radius (in der UI), Nearby

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
