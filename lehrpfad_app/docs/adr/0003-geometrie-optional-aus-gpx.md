# ADR 0003: Geometrie optional aus GPX/GeoJSON

## Status

Accepted. Ergänzt ADR 0002 an einer Stelle.

## Context

ADR 0002 hält fest: „Geometrie (OSM-Route, Stationskoordinaten) und Fahrzeiten bleiben Pipeline; das CMS legt keine Trails an.“ Die Content-Import-Pipeline legt Trails jetzt aus Dossier-ZIPs an. Die Dossiers können `route.gpx` oder `flaeche.geojson` enthalten. Eine Linie ohne Geometrie lässt sich nicht anlegen. GPX-Dateien aus Portalen wie Komoot oder Outdooractive sind meist nicht frei nutzbar.

## Decision

1. Der Import liest `route.gpx` (Linie) oder `flaeche.geojson` (Fläche) aus dem ZIP und schreibt `route` bzw. `area`, `start_lat/lon` und bei Linien `laenge_km`.
2. Das gilt nur mit Quelle **und** Lizenz im Dossier (`import.geometrie_quelle`, `import.geometrie_lizenz`, Werte siehe Vorlage v3, Anhang A8). Fehlt eines davon oder ist der Key ungültig, verwirft der Import die Datei (`GEOMETRIE_LIZENZ`, Warnung) und fällt auf die OSM-Pipeline (`fetch_osm.sh`) zurück.
3. Die Herkunft steht in `trails.field_meta` unter `route` bzw. `area` (`quelle`, `lizenz`) und in `trail_sources`.
4. OSM bleibt der Rückfall und der Standard für Ausstattung (`amenities`), die Pipeline schreibt weiterhin keine `amenities` aus dem Dossier.
5. Das CMS legt weiterhin keine Geometrie an. Es zeigt die Route im Review nur an.

## Consequences

- Ohne Route und ohne OSM-Rückfall ist eine Linie ein harter Fehler (`GEOMETRIE_FEHLT`).
- Der Import prüft die Datei gegen Start, Länge und Stationen (`START_ABWEICHUNG`, `LAENGE_ABWEICHUNG`, `STATION_ABSEITS`).
- `docs/datenmodell.md` führt die Herkunft der Geometrie als Feld in `field_meta`.
