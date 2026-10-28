#!/usr/bin/env python3
"""Naturraum aus Koordinate und Regionstext.

Zonen, keine Biogeografie-Polygone: Küste per Abstand zur Küstenlinie,
danach Alpenvorland, Mittelgebirge, Norddeutsches Tiefland.
Dänemark und Katalonien vor der deutschen Küste.
"""
import math
import re

# Grobe Küstenlinie, nur für die Zone (nicht fürs Routing).
NORDSEE = [
    (53.37, 7.21), (53.62, 7.16), (53.68, 7.57), (53.54, 8.58),
    (53.87, 8.70), (54.13, 8.86), (54.30, 8.64), (54.48, 8.88),
    (54.73, 8.69), (55.02, 8.40),
]
OSTSEE = [
    (54.80, 9.44), (54.47, 9.84), (54.32, 10.13), (54.37, 10.98),
    (54.44, 11.19), (53.96, 10.87), (53.99, 11.20), (53.89, 11.46),
    (54.15, 11.75), (54.18, 12.08), (54.25, 12.25), (54.43, 12.69),
    (54.31, 13.08), (54.67, 13.44), (54.57, 13.66), (54.40, 13.61),
    (54.14, 13.77),
    (53.96, 14.17),
]
KUESTE_KM = 12.0

MITTEL_KEYS = (
    "harzburg", "oberharz", "schwarzwald", "taunus", "vogelsberg", "steigerwald",
    "hainich", "eifel", "sauerland", "odenwald", "spessart", "rhön",
    "rhoen", "thüring", "thuering", "erzgebirge", "bayerischer wald",
    "saar", "alb", "fichtel", "teutoburg", "iburg", "wiehen",
    "westerwald", "siebengebirge", "kellerwald", "edersee", "pfalz",
    "hunsrück", "hunsrueck", "bergisch", "panarbora", "waldbröl",
    "hoherodskopf",
)
ALPEN_KEYS = (
    "allgäu", "allgaeu", "füssen", "fuessen",
)
KATALONIEN_KEYS = (
    "katalon", "collserola", "montnegre", "mataro", "mataró",
    "arenys", "vallvidrera", "hortsaviny", "tordera", "maresme",
)
DAENEMARK_KEYS = (
    "dänemark", "daenemark", "danmark", "møn", "moens", "møns",
    "sjælland", "sjaelland", "vordingborg",
)


def haversine_km(a, b):
    r = 6371.0
    p1, p2 = math.radians(a[0]), math.radians(b[0])
    dp = math.radians(b[0] - a[0])
    dl = math.radians(b[1] - a[1])
    x = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(x))


def _nahe(lat, lon, linie):
    return min(haversine_km((lat, lon), p) for p in linie)


def _wort(blob, key):
    """Ganzes Wort, damit 'alb' nicht in 'halb' und 'harz' nicht in 'Harzung' trifft."""
    return re.search(r"(?<![0-9a-zäöü])" + re.escape(key) + r"(?![0-9a-zäöü])", blob) is not None


def _eines(blob, keys):
    return any(_wort(blob, k) for k in keys)


def _in_deutschland(lat, lon):
    return 47.2 < lat < 55.1 and 5.7 < lon < 15.1


def naturraum_for(lat, lon, text=""):
    """Liefert einen Key aus dem Naturraum-Katalog."""
    blob = (text or "").lower()
    # Ein erwähntes Nachbarland ("Watt bis Dänemark") ist kein Standort.
    if (lat < 44 and 0 < lon < 4) or (
        _eines(blob, KATALONIEN_KEYS) and not _in_deutschland(lat, lon)
    ):
        return "katalonien"
    if (lat > 54.9 and lon > 11.5) or (
        _eines(blob, DAENEMARK_KEYS) and not _in_deutschland(lat, lon)
    ):
        return "daenemark"
    # Küste vor jedem Inland-Schlüssel, sonst wird Rügen zum Alpenvorland,
    # sobald die Beschreibung zufällig ein Mittelgebirgswort enthält.
    if lat > 53.2:
        nord = _nahe(lat, lon, NORDSEE)
        ost = _nahe(lat, lon, OSTSEE)
        if min(nord, ost) <= KUESTE_KM:
            return "nordsee" if nord <= ost else "ostsee"
    if _eines(blob, ALPEN_KEYS) or (
        lat < 48.0 and 9.3 < lon < 13.6 and lat > 46
    ):
        if not _eines(blob, MITTEL_KEYS):
            return "alpenvorland"
    if _eines(blob, MITTEL_KEYS) or lat < 51.2:
        return "mittelgebirge"
    return "norddt-tiefland"
