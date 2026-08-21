# Kinderwald Märkisch Buchholz – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `kinderwald-maerkisch-buchholz` |
| Name | Kinderwald Märkisch Buchholz |
| typ | `waldspielplatz` |
| `form` | **`flaeche`** |
| Region | Märkisch Buchholz, Dahme-Spreewald |
| Adresse | Alte Berliner Straße 1, 15748 Märkisch Buchholz |
| Zugang | jederzeit frei (Forst BB); teilweise gezäunt; Betreten auf eigene Gefahr, Hunde an der Leine |
| Status | **HAVE** – Seed `assets/seed/kinderwald-maerkisch-buchholz.json` |
| OSM | Playground-Node [`5851271398`](https://www.openstreetmap.org/node/5851271398) ≈ 52.11280, 13.75992 |

Quelle: [`_kandidaten.md`](_kandidaten.md). Filter: [`README.md`](../../../README.md).

## Quellen

- Forst-Flyer (Okt. 2016): https://forst.brandenburg.de/sixcms/media.php/9/kiwafly.pdf
- Betreiber: Oberförsterei Königs Wusterhausen / Landeswaldoberförsterei Hammer

## Filter / Abgrenzung

| Ort | Einstufung |
|---|---|
| Kinderwald-Geräte + Infotafeln Forst/Jagd/Tiere | **GO** |
| Försterwanderung, Lagerfeuer | **NOGO** — nur mit Förster |
| Wald-Theater als gebuchte Aufführung | Anmeldung; spontanes Spielen auf der Bühne ist GO-Gerät |

Nicht als alleinige `geraete`: Picknickbänke.

## Geometrie

- `form: flaeche`, `rundkurs: false`, `laengeKm: 0`
- Marker = Centroid der Fläche (ehem. Försterei-Gehöft an der Dahme)

## Geräte (≥3)

| Gerät | Thema |
|---|---|
| Baumstämme Klettern/Balancieren | Motorik |
| Kinderhochstand | Wald/Jagd-Anschauung |
| Wald-Theater | Spielbühne am Hang |
| Wald-Sandkasten | Kellerruine des Forsthauses |
| 12-m-Tau | Hangeln, barfuß möglich |
| Insektenhotel | Insekten |
| Bienen-Schaukasten | Honigbiene |
| Wald-Litfaßsäule (Eichenstamm) | Kinderzeichnungen |
| Lesesteinhaufen | Eidechsen/Kriechtiere |
| Raum-Meter-Holzstapel | Forstwirtschaft |

Plus Infotafeln: Aufgaben der Forstwirtschaft, Jagd, Tiere, Gefahren.

## Go / No-Go

**Go:** frei, Outdoor, Wald, ≥3 Geräte.

**No-Go:** Stadtspielplatz-Set; Seed als gebuchte Waldpädagogik.

## Seed (HAVE)

Flächen-Seed direkt `assets/seed/kinderwald-maerkisch-buchholz.json` (`form=flaeche`). Geräte in `arten[]` + `species.json`. Nicht als `geraete`: Sandkasten, Litfaßsäule, Picknickbänke. Lesesteinhaufen = Station + Zauneidechse. In `_seedPaths`.
