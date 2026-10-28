# Dossier-Vorlage v3 – Ergänzungen gegenüber v2

Die Vorlage liegt als `import_worker/templates/Vorlage_Pfad-Dossier_v3.docx`. Erzeugt wird sie aus v2 mit
`python3 -m import_worker.make_vorlage_v3 <v2.docx>`. Der Parser nimmt `template_version` 2 und 3.
v2 funktioniert weiter, ohne Geometrie-Herkunft und ohne Steckbrief-Tabelle.

## Was neu ist

| Stelle | v2 | v3 |
|---|---|---|
| Kopf | `template_version: 2` | `template_version: 3` |
| Abschnitt 1 | Land, Bundesland, Kreis, Ort, Schutzgebiet: „Spalte geplant“ | zeigen auf `trails.land`, `trails.bundesland`, `trails.kreis`, `trails.ort`, `trails.schutzgebiet` |
| Abschnitt 1 | Region (Freitext wie bisher) | Region leer = „Ort, Kreis, Bundesland“; gefüllter Freitext gewinnt |
| Abschnitt 3 | – | `import.geometrie_quelle`, `import.geometrie_lizenz` (Pflicht, wenn `route.gpx` oder `flaeche.geojson` beiliegt) |
| Abschnitt 6 | Steckbrief als Freitext | Tabelle Station / Schlüssel / Wert |
| Abschnitt 7 | Spalte Geo-Check | entfällt, der Import liest EXIF und prüft den Abstand zum Pfad selbst |
| Anhang A3 | „Liste folgt“ | 18 Lebensräume |
| Anhang A4, A5 | „wird bestätigt“ | 8 Tags, 9 Erlebnisse |
| Anhang A6 | `eigen`, `freigabe` „geplant“ | gültige Keys. `eigen` ist freigegeben, `freigabe` bleibt unsichtbar, bis sie im CMS bestätigt ist |
| Anhang A8 | – | Geometrie-Lizenzen: `osm-odbl`, `eigen`, `betreiber-freigabe`, `cc-by-sa-4.0`, `cc-by-4.0`, `cc0`, `pd` |

## Regeln, die der Import durchsetzt

- **Anker** ist die Spalte „Supabase“ (bzw. die Spaltenköpfe der Tabellen), nicht die Überschrift. Der Slug aus Abschnitt 1 zählt, der Dateiname nicht.
- **Slug:** `^[a-z0-9]+(-[a-z0-9]+)*$`. Umlaute werden zu ae, oe, ue, ss. Ein Slug, der nach der Umschrift anders aussieht, wird mit `FORM` korrigiert gemeldet.
- **Abschnittsstatus:** `fertig` und `geprüft` zählen als fertig. Pflicht sind 1, 2, 3, 4, 6, 7. Sonst `DOSSIER_UNVOLLSTAENDIG` (übersteuerbar).
- **Stationen:** Linie unter 3 Stationen ist übersteuerbar, Fläche unter 3 eine Warnung, 0 Stationen hart. Reihenfolge ab 1 ohne Lücken.
- **Fläche:** `laenge_km` leer, der Import setzt 0. `rundkurs` = nein.
- **Geometrie:** GPX wird `route`, GeoJSON wird `area`. Ohne gültigen Lizenz-Key aus A8 greift die OSM-Pipeline (`GEOMETRIE_LIZENZ`, Warnung). Eine Linie ohne Route ist hart (`GEOMETRIE_FEHLT`).
- **Bilder:** liegen unter `bilder/`, Dateiname wie in Abschnitt 7. Ohne gültigen Lizenz-Key bleibt das Bild unsichtbar (`pending`).
- **Abschnitt 5** (Orte in der Nähe) wird nur gespeichert (`import_jobs.parsed`), nicht nach `pois` oder `amenities` geschrieben.

## Widersprüche in der Spec, die nachzuziehen sind

1. Abgleich/Bilder sagt „Bilder aus der .docx extrahieren“, IMP-02 sagt „.docx oder .zip“ und „Bitte als .docx exportieren“. Gilt: ein ZIP mit `bilder/`.
2. IMP-04 nennt „Originaldokument gerendert aus der .docx“ und „Route nur Anzeige (Geometrie bleibt Pipeline)“. Gilt: Dossier-Text je Abschnitt, Geometrie optional aus GPX (ADR 0003).
3. `kandidat_id` meint den Slug.
4. „Alle Regeln laufen nach dem KI-Schritt“ gilt nur, wenn der KI-Rückfall nötig war.
5. Die Spec nennt `messages.py`, umgesetzt ist `messages.json` (gemeinsame Quelle für Worker und Admin).
6. `STATIONEN_MIN` steht in der Regeltabelle als Warnung, in den Schweregraden als übersteuerbar. Umgesetzt: übersteuerbar (Linie), Warnung (Fläche).
