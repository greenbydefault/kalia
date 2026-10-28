"""Anhang A der Dossier-Vorlage: feste Wertelisten.

Quelle der Wahrheit ist weiterhin die App (icon_catalog.dart) bzw. tools/validate_seeds.py.
test_lists.py vergleicht beides, damit die Listen nicht auseinanderlaufen.
"""
from __future__ import annotations

TYP = (
    "wald", "moor", "aue", "walderlebnispfad", "erlebniswald", "naturerlebnis",
    "naturerlebnisraum", "waldspielplatz", "wasserspielplatz", "waldspazierplatz",
    "sinnespfad", "barfusspfad", "kueste", "kinderbauernhof",
)
# Typen, die sich ueber eine Flaeche statt eine Linie definieren.
FLAECHEN_TYPEN = ("wasserspielplatz", "waldspielplatz", "waldspazierplatz", "kinderbauernhof")

NATURRAUM = (
    "nordsee", "ostsee", "norddt-tiefland", "mittelgebirge", "alpenvorland",
    "katalonien", "daenemark",
)
LEBENSRAEUME = (
    "buchenwald", "kuestenwald-kiefer", "kiefernforst", "eichen-mischwald", "auwald",
    "moor", "heide", "teich-tuempel", "see-ufer", "fliessgewaesser", "salzwiese-watt",
    "duene-strand", "streuobst-hecke", "nadelforst", "alpen-wald", "mediterraner-wald",
    "trockenrasen", "hof-nutztier",
)
TAGS = (
    "kinderfreundlich", "kinderwagentauglich", "rollstuhltauglich", "hunde-erlaubt",
    "einkehr", "spielplatz", "picknick", "barfusspfad",
)
ERLEBNISSE = (
    "tafel", "quiz", "steg", "bohrkernmodell", "mitmach-modell", "memory",
    "bestimmung", "audio", "barfusspfad",
)
BILD_LIZENZEN = (
    "cc-by-sa-4.0", "cc-by-sa-3.0", "cc-by-sa-2.0", "cc-by-4.0", "cc-by-3.0",
    "cc-by-2.0", "cc0", "pd", "eigen", "freigabe",
)
# Lizenz-Keys, die direkt freigegeben sind. freigabe wartet auf Bestaetigung im CMS.
BILD_LIZENZ_APPROVED = tuple(k for k in BILD_LIZENZEN if k != "freigabe")
GEOMETRIE_LIZENZEN = (
    "osm-odbl", "eigen", "betreiber-freigabe", "cc-by-sa-4.0", "cc-by-4.0", "cc0", "pd",
)
STECKBRIEF_KEYS = ("groesseHa", "alterJahre", "tiefeM", "lebenselixier", "werdegang")
STATUS = ("offen", "in Arbeit", "fertig", "geprüft")
STATUS_FERTIG = ("fertig", "geprüft")
NACHWEIS = ("belegt", "typisch")
FORMEN = ("linie", "flaeche")
LAENDER = ("DE", "DK", "ES")
BILD_KINDS = ("hero", "station")

# Pflichtabschnitte (Nr. aus der Vorlage)
PFLICHT_ABSCHNITTE = (1, 2, 3, 4, 6, 7)

# Limits aus tools/TRAIL_SCAN.md
LIMITS = {
    "kurzbeschreibung": (None, 180),
    "beschreibung": (400, 650),
    "besuchshinweise": (None, 280),
}
HOERTEXT_WOERTER = (70, 110)
STATION_KURZTEXT_MIN = 50
