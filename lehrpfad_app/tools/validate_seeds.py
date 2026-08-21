#!/usr/bin/env python3
"""Validiert alle Trail-Seeds in assets/seed/ gegen das App-Schema.

Prueft: Pflichtfelder/Typen (wie Trail.fromJson), Katalog-Schluessel
(erlebnisse/tags/amenities/typ gemaess icon_catalog.dart), Stationsreihenfolge,
Geometrie-Spruenge, Rundkurs-Schluss und Arten-Aufloesung gegen species.json.
Zusaetzlich: species.content gemaess tools/SPECIES_CONTENT.md.

Checklist neuer Trail: arten[] fuellen + fehlende Species in species.json.
"""
import glob
import json
import math
import os
import sys

from resolve_arten import SPECIES_PATH, load_catalog, resolve_names

SEED_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "seed")
# Keine Trail-Seeds (Kataloge / Rohreste)
NON_TRAIL = {"species.json"}

# Limits aus SPECIES_CONTENT.md
HOOK_WORDS = (12, 22)
ERKENNUNG_COUNT = (2, 4)
ERKENNUNG_WORDS_MAX = 12
LEBENSRAUM_WORDS_MAX = 40
FUN_FACTS_COUNT = (2, 3)
HINWEIS_WORDS_MAX = 15
HOERTEXT_WORDS = (90, 120)

ERLEBNISSE = {"tafel", "quiz", "steg", "bohrkernmodell", "mitmach-modell",
              "memory", "bestimmung", "audio", "barfusspfad"}
TAGS = {"kinderfreundlich", "kinderwagentauglich", "rollstuhltauglich",
        "hunde-erlaubt", "einkehr", "spielplatz", "picknick", "barfusspfad"}
AMENITY_KATS = {"wc", "parking", "bench", "picnic", "shelter", "playground",
                "viewpoint", "gastro"}
# Source of Truth: typKatalog in lib/shared/catalogs/icon_catalog.dart
TYP = {
    "wald", "moor", "spreewald",
    "walderlebnispfad", "erlebniswald",
    "naturerlebnis", "naturerlebnisraum",
    "waldspielplatz", "wasserspielplatz", "waldspazierplatz",
    "sinnespfad", "barfusspfad",
    "kinderbauernhof",
}
SPECIES_KATS = {"flora", "fauna", "geraete"}
# Source of Truth: geraeteKatalog in lib/shared/catalogs/icon_catalog.dart
GERAETE_ICON_KEYS = {"geraet"}
# Lange Segmente zwischen zwei OSM-Nodes sind legitim (gerade Wege) – erst
# sehr grosse Spruenge deuten auf eine kaputte Way-Verkettung hin.
MAX_SPRUNG_M = 800
WARN_SPRUNG_M = 200
ROH_PREFIXE = ("_rel", "_pois", "_amenities")


def haversine_m(a, b):
    r = 6371000.0
    p1, p2 = math.radians(a[0]), math.radians(b[0])
    dp = math.radians(b[0] - a[0])
    dl = math.radians(b[1] - a[1])
    x = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(x))


def _words(text):
    return [w for w in str(text).split() if w]


def validiere_species_content(rows):
    """Prueft content-Shape, Kategorie, iconKey und Laengenlimits."""
    fehler = []
    for s in rows:
        sid = s.get("id", "?")
        kat = s.get("kategorie")
        if kat not in SPECIES_KATS:
            fehler.append(
                f"{sid}: unbekannte kategorie {kat!r} "
                f"(erlaubt: {sorted(SPECIES_KATS)})"
            )

        icon_key = s.get("iconKey")
        if icon_key is not None and icon_key != "":
            if kat != "geraete":
                fehler.append(
                    f"{sid}: iconKey nur bei kategorie geraete erlaubt"
                )
            elif icon_key not in GERAETE_ICON_KEYS:
                fehler.append(
                    f"{sid}: unbekannter iconKey {icon_key!r} "
                    f"(erlaubt: {sorted(GERAETE_ICON_KEYS)})"
                )

        c = s.get("content")
        if not isinstance(c, dict) or not c:
            fehler.append(f"{sid}: content fehlt oder leer")
            continue

        hook = c.get("hook", "")
        hw = len(_words(hook))
        if not (HOOK_WORDS[0] <= hw <= HOOK_WORDS[1]):
            fehler.append(
                f"{sid}: hook {hw} Woerter (erlaubt {HOOK_WORDS[0]}–{HOOK_WORDS[1]})"
            )

        erk = c.get("erkennung")
        if not isinstance(erk, list) or not (
            ERKENNUNG_COUNT[0] <= len(erk) <= ERKENNUNG_COUNT[1]
        ):
            fehler.append(
                f"{sid}: erkennung braucht {ERKENNUNG_COUNT[0]}–{ERKENNUNG_COUNT[1]} Bullets"
            )
        else:
            for i, bullet in enumerate(erk):
                n = len(_words(bullet))
                if n == 0 or n > ERKENNUNG_WORDS_MAX:
                    fehler.append(
                        f"{sid}: erkennung[{i}] {n} Woerter (max {ERKENNUNG_WORDS_MAX})"
                    )

        leb = c.get("lebensraum", "")
        lw = len(_words(leb))
        if lw == 0 or lw > LEBENSRAUM_WORDS_MAX:
            fehler.append(
                f"{sid}: lebensraum {lw} Woerter (1–{LEBENSRAUM_WORDS_MAX})"
            )

        facts = c.get("funFacts")
        if not isinstance(facts, list) or not (
            FUN_FACTS_COUNT[0] <= len(facts) <= FUN_FACTS_COUNT[1]
        ):
            fehler.append(
                f"{sid}: funFacts braucht {FUN_FACTS_COUNT[0]}–{FUN_FACTS_COUNT[1]} Bullets"
            )
        elif any(not str(f).strip() for f in facts):
            fehler.append(f"{sid}: funFacts enthaelt leeren Eintrag")

        hinweis = c.get("hinweis", "")
        if hinweis is None:
            fehler.append(f"{sid}: hinweis fehlt (leerstring erlaubt)")
        else:
            nw = len(_words(hinweis))
            if nw > HINWEIS_WORDS_MAX:
                fehler.append(
                    f"{sid}: hinweis {nw} Woerter (max {HINWEIS_WORDS_MAX})"
                )

        hoer = c.get("hoertext", "")
        ow = len(_words(hoer))
        if not (HOERTEXT_WORDS[0] <= ow <= HOERTEXT_WORDS[1]):
            fehler.append(
                f"{sid}: hoertext {ow} Woerter "
                f"(erlaubt {HOERTEXT_WORDS[0]}–{HOERTEXT_WORDS[1]})"
            )

        for key in ("hook", "erkennung", "lebensraum", "funFacts",
                    "hinweis", "hoertext"):
            if key not in c:
                fehler.append(f"{sid}: content.{key} fehlt")

    return fehler


def validiere(path, arten_lookup):
    fehler = []
    with open(path, encoding="utf-8") as f:
        t = json.load(f)

    for feld in ("id", "name", "typ", "kurzbeschreibung", "beschreibung",
                 "laengeKm", "dauerMin", "markierung", "betreiber", "region",
                 "anreise", "startName"):
        if feld not in t:
            fehler.append(f"Pflichtfeld fehlt: {feld}")

    unbekannt = set(t.get("tags", [])) - TAGS
    if unbekannt:
        fehler.append(f"Unbekannte tags: {unbekannt}")

    typ = t.get("typ")
    if typ not in TYP:
        fehler.append(f"Unbekannter typ: {typ!r} (erlaubt: {sorted(TYP)})")

    try:
        resolve_names(t.get("arten", []), arten_lookup)
    except ValueError as e:
        fehler.append(str(e))

    form = t.get("form") or "linie"
    if form not in ("linie", "flaeche"):
        fehler.append(f"Unbekannte form: {form!r} (erlaubt: linie, flaeche)")

    area = t.get("area") or []
    route = t.get("route") or []

    if form == "flaeche":
        if not isinstance(area, list) or len(area) < 3:
            fehler.append("form=flaeche braucht area mit ≥3 Punkten")
        if t.get("rundkurs"):
            fehler.append("form=flaeche: rundkurs muss false sein")
        if float(t.get("laengeKm") or 0) != 0:
            fehler.append("form=flaeche: laengeKm muss 0 sein")
    else:
        if not isinstance(route, list) or len(route) < 2:
            fehler.append("form=linie braucht route mit ≥2 Punkten")
        else:
            spruenge = [(i, haversine_m(route[i - 1], route[i]))
                        for i in range(1, len(route))]
            grosse = [(i, d) for i, d in spruenge if d > MAX_SPRUNG_M]
            if grosse:
                fehler.append(
                    f"Geometrie-Spruenge >{MAX_SPRUNG_M} m: "
                    + ", ".join(
                        f"{d:.0f} m bei Punkt {i}" for i, d in grosse
                    )
                )
            warnungen = [
                (i, d) for i, d in spruenge
                if WARN_SPRUNG_M < d <= MAX_SPRUNG_M
            ]
            if warnungen:
                print(
                    "      info: lange Segmente: "
                    + ", ".join(f"{d:.0f} m" for _, d in warnungen)
                )
            if t.get("rundkurs") and haversine_m(route[0], route[-1]) > 100:
                fehler.append(
                    f"rundkurs=true, aber Start-Ende "
                    f"{haversine_m(route[0], route[-1]):.0f} m auseinander"
                )

    stationen = t.get("stationen") or []
    if len(stationen) < 3:
        fehler.append(f"Mindestens 3 Stationen nötig (hat {len(stationen)})")

    kms = []
    for s in stationen:
        unbekannt = set(s.get("erlebnisse") or []) - ERLEBNISSE
        if unbekannt:
            fehler.append(
                f"Station {s.get('titel')}: unbekannte erlebnisse {unbekannt}"
            )
        kms.append(s["km"])
    if kms != sorted(kms):
        fehler.append("Stationen-km nicht aufsteigend")
    reihen = [s["reihenfolge"] for s in stationen]
    if reihen != list(range(1, len(reihen) + 1)):
        fehler.append(f"reihenfolge fehlerhaft: {reihen}")

    for a in t.get("amenities") or []:
        if a["kategorie"] not in AMENITY_KATS:
            fehler.append(
                f"Amenity {a['osmId']}: unbekannte Kategorie {a['kategorie']}"
            )

    return fehler, t


def main():
    try:
        with open(SPECIES_PATH, encoding="utf-8") as f:
            species_rows_raw = json.load(f)
        _, arten_lookup = load_catalog()
    except (OSError, ValueError, json.JSONDecodeError) as e:
        sys.exit(f"species.json ungueltig: {e}")

    ok = True
    content_fehler = validiere_species_content(species_rows_raw)
    status = "OK  " if not content_fehler else "FEHLER"
    print(f"{status} species.json: {len(species_rows_raw)} Arten (content)")
    for f_ in content_fehler:
        print(f"      - {f_}")
        ok = False

    dateien = sorted(
        p for p in glob.glob(os.path.join(SEED_DIR, "*.json"))
        if os.path.basename(p) not in NON_TRAIL
        and not any(p.endswith(f"{s}.json") for s in ROH_PREFIXE)
    )
    for path in dateien:
        fehler, t = validiere(path, arten_lookup)
        status = "OK  " if not fehler else "FEHLER"
        print(f"{status} {os.path.basename(path)}: {t['name']} | "
              f"{t['laengeKm']} km, {len(t['stationen'])} Stationen, "
              f"{len(t['amenities'])} Amenities, tags={t.get('tags')}")
        for f_ in fehler:
            print(f"      - {f_}")
            ok = False
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
