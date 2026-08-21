# Waldpoesie-Pfad Erkner – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `waldpoesie-pfad` |
| Name | Waldpoesie-Pfad (Theodor-Fontane-Weg) |
| typ | `wald` |
| Region | Erkner, Oder-Spree |
| Länge | 1,3 km (Flyer); Verlängerung 2,8 km bis Woltersdorfer Schleuse = Wander-Amenity, nicht Pflicht |
| Start | nördlicher Parkplatz Fangschleusenstraße (Höhe ~Nr. 6) |

Quelle: [`_kandidaten.md`](_kandidaten.md). Filter: [`README.md`](../../../README.md).

Nicht parallel: Wupatz’ Lehrpfad (HAVE, südlich/Löcknitzinsel). Südparkplatz Fangschleusenstraße bis Oktober 2026 fast gesperrt.

## Quellen

- Stadt Erkner: https://www.erkner.de/freizeit-und-tourismus/naturerlebnisse/wandern/waldpoesie-pfad.html
- Flyer (10 Stationen namentlich): https://www.erkner.de/_Resources/Persistent/b/4/5/0/b45071c2bf90be7246df9cfb78472dca1a7b01a4/Faltblatt%20Waldpoesie-Pfad%20Web.pdf
- Reiseland: https://www.reiseland-brandenburg.de/poi/seenland-oder-spree/wandertouren/theodor-fontane-weg-waldpoesie-pfad/

Übersichtstafel am Start (Wald + Karte). Stationen: Baumart + inspirierendes Gedicht.

## Stationen (Flyer, ≥3)

Reihenfolge Flyer 1→10, Fangschleusenstraße nordwärts Richtung Woltersdorf:

1. Wald-Kiefer — Theodor Fontane, „Mittag“
2. Spitz-Ahorn — Georg Trakl, „Zu Abend mein Herz“
3. Rot-Eiche — Hermann Hesse, „Gestutzte Eiche“
4. Hänge-Birke — Wilhelm Busch, „Die Birke“
5. Flatter-Ulme — Theodor Storm, „Käuzlein“
6. Schwarz-Erle — Novalis, „Die Erlen“
7. Winter-Linde — Wilhelm Müller, „Der Lindenbaum“
8. Eberesche — Gottfried Benn, „Ebereschen“
9. Rot-Buche — Hermann Löns, „Das Buchenblatt“
10. Fahl-Weide — Eva Strittmatter, „Weiden I“

GPS der Einzeltafeln nicht im Flyer — entlang Theodor-Fontane-Weg mappen.

## Arten

Waldkiefer, Spitzahorn, Roteiche, Hängebirke, Flatterulme, Schwarzerle, Winterlinde, Eberesche, Rotbuche, Fahl-Weide (alle in Stationen).

## Go / No-Go

**Go:** frei, Wald, 10 benannte Stationen aus Erstquelle.

**No-Go:** Gedichtvolltexte (Urheberrecht — nur Titel/Autor/Baum + Kurzsinn, keine Lyrics); Wupatz-Stationen mixen; 66-Seen als Route.

## Pipeline

1. OSM Theodor-Fontane-Weg / Bäume als POIs
2. Config `tools/trails/waldpoesie-pfad.json`
3. Seed; Texte kurz halten (Baum + Autor + Thema, nicht Gedicht)
4. Validator + STATUS HAVE
