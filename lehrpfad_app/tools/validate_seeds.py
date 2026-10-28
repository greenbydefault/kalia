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
import re
import sys

from resolve_arten import (
    SPECIES_PATH,
    load_catalog,
    load_merkmale,
    resolve_names,
)

SEED_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "seed")
# Keine Trail-Seeds (Kataloge / Rohreste)
NON_TRAIL = {
    "species.json", "merkmale.json", "pois.json", "nearby_zeiten.json",
    "art_pools.json",
    "orte_de.json",
    "index.json",
}
NEARBY_MAX_SEK = 1200

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
# Source of Truth: poiKategorieKatalog in lib/shared/catalogs/icon_catalog.dart
POI_KATS = {
    "cafe", "restaurant", "hofladen", "baden", "museum", "aktivitaet", "camping",
}
OH_MONTH = r"(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)"
OH_DAY = r"(?:Mo|Tu|We|Th|Fr|Sa|Su)"
OH_RULE = re.compile(
    r"^(?:" + OH_MONTH + r"(?:-" + OH_MONTH + r")?:?\s*)?"
    r"(?:" + OH_DAY + r"(?:-" + OH_DAY + r")?"
    r"(?:," + OH_DAY + r"(?:-" + OH_DAY + r")?)*\s*)?"
    r"(?:off|(?:\d{2}:\d{2}-\d{2}:\d{2}(?:,\d{2}:\d{2}-\d{2}:\d{2})*))?"
    r"$"
)
# Source of Truth: typKatalog in lib/shared/catalogs/icon_catalog.dart
TYP = {
    "wald", "moor", "aue",
    "walderlebnispfad", "erlebniswald",
    "naturerlebnis", "naturerlebnisraum",
    "waldspielplatz", "wasserspielplatz", "waldspazierplatz",
    "sinnespfad", "barfusspfad",
    "kueste",
    "kinderbauernhof",
}
SPECIES_KATS = {"flora", "fauna", "geraete"}
# Source of Truth: geraeteKatalog in lib/shared/catalogs/icon_catalog.dart
GERAETE_ICON_KEYS = {"geraet"}

# Profil (flora/fauna) — Source of Truth: Kataloge in icon_catalog.dart
GRUPPEN = {"saeugetiere", "voegel", "insekten", "amphibien", "reptilien",
           "spinnen", "baeume", "straeucher", "kraeuter", "moose", "pilze"}
LEBENSRAEUME = {
    "kuestenwald-kiefer", "buchenwald", "eichen-mischwald", "kiefernforst",
    "auwald", "moor", "heide", "streuobst-hecke", "teich-tuempel",
    "fliessgewaesser", "see-ufer", "salzwiese-watt", "duene-strand",
    "trockenrasen", "nadelforst", "hof-nutztier", "mediterraner-wald",
    "alpen-wald",
}
NATURRAUM = {
    "nordsee", "ostsee", "norddt-tiefland", "mittelgebirge", "alpenvorland",
    "katalonien", "daenemark",
}
ROLLEN = {"leit", "typisch", "bonus"}
SICHTBARKEIT = {"leicht", "geduld", "saison", "nacht"}
MIN_FLORA = 4
MIN_FAUNA = 6
SELTENHEIT = {"haeufig", "mittel", "selten", "sehr-selten"}
GEFAHR = (1, 5)
MASSE_KEYS = {"laenge", "spannweite", "gewicht", "alter", "tempo", "gelege",
              "tragzeit", "hoehe", "stamm", "frucht", "bluetezeit"}
TAX_RANKS = ("reich", "stamm", "klasse", "ordnung", "familie")
BEZIEHUNG_TYPEN = {"frisst", "bestaeubt", "wohnt_an"}
MERKMALE_COUNT = (4, 8)
# Lange Segmente zwischen zwei OSM-Nodes sind legitim (gerade Wege) – erst
# sehr grosse Spruenge deuten auf eine kaputte Way-Verkettung hin.
MAX_SPRUNG_M = 800
WARN_SPRUNG_M = 200
ROH_PREFIXE = ("_rel", "_pois", "_amenities")
BILD_LIZENZEN = {
    "cc-by-sa-4.0", "cc-by-sa-3.0", "cc-by-sa-2.0",
    "cc-by-4.0", "cc-by-3.0", "cc-by-2.0",
    "cc0", "pd",
}
APP_ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))
PUBSPEC_PATH = os.path.join(APP_ROOT, "pubspec.yaml")


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

        tiefe = c.get("tiefe") or "voll"
        if tiefe not in ("kurz", "voll"):
            fehler.append(f"{sid}: tiefe {tiefe!r} (erlaubt: kurz, voll)")

        hoer = c.get("hoertext", "")
        ow = len(_words(hoer))
        if tiefe == "kurz":
            if ow:
                fehler.append(f"{sid}: tiefe kurz ohne hoertext (hat {ow} Woerter)")
        elif not (HOERTEXT_WORDS[0] <= ow <= HOERTEXT_WORDS[1]):
            fehler.append(
                f"{sid}: hoertext {ow} Woerter "
                f"(erlaubt {HOERTEXT_WORDS[0]}–{HOERTEXT_WORDS[1]})"
            )

        pflicht_keys = ["hook", "erkennung", "lebensraum", "funFacts", "hinweis"]
        if tiefe != "kurz":
            pflicht_keys.append("hoertext")
        for key in pflicht_keys:
            if key not in c:
                fehler.append(f"{sid}: content.{key} fehlt")

    return fehler


def validiere_species_profil(rows, merkmale_ids, species_ids):
    """Prueft Profil-Felder (flora/fauna): Gruppe, Seltenheit, Gefahr,
    Nahrung, Taxonomie, Masse, Merkmale, Beziehungen."""
    fehler = []
    for s in rows:
        sid = s.get("id", "?")
        kat = s.get("kategorie")
        if kat == "geraete":
            for key in ("gruppe", "seltenheit", "nahrung", "taxonomie",
                        "masse", "merkmale", "beziehungen"):
                if s.get(key) not in (None, "", [], {}, 0):
                    fehler.append(f"{sid}: geraete ohne Profilfelder ({key})")
            continue

        gruppe = s.get("gruppe")
        if gruppe not in GRUPPEN:
            fehler.append(
                f"{sid}: unbekannte gruppe {gruppe!r} (erlaubt: {sorted(GRUPPEN)})"
            )

        seltenheit = s.get("seltenheit")
        if seltenheit not in SELTENHEIT:
            fehler.append(
                f"{sid}: unbekannte seltenheit {seltenheit!r} "
                f"(erlaubt: {sorted(SELTENHEIT)})"
            )

        gefahr = s.get("gefahr")
        if not isinstance(gefahr, int) or not (GEFAHR[0] <= gefahr <= GEFAHR[1]):
            fehler.append(
                f"{sid}: gefahr {gefahr!r} (erlaubt {GEFAHR[0]}–{GEFAHR[1]})"
            )

        nahrung = s.get("nahrung")
        if not isinstance(nahrung, list) or not nahrung:
            fehler.append(f"{sid}: nahrung fehlt oder leer")

        tax = s.get("taxonomie")
        if not isinstance(tax, dict) or any(not tax.get(r) for r in TAX_RANKS):
            fehler.append(
                f"{sid}: taxonomie unvollstaendig (braucht {', '.join(TAX_RANKS)})"
            )

        masse = s.get("masse")
        if not isinstance(masse, list) or not masse:
            fehler.append(f"{sid}: masse fehlt oder leer")
        else:
            for i, m in enumerate(masse):
                if not isinstance(m, dict):
                    fehler.append(f"{sid}: masse[{i}] kein Objekt")
                    continue
                mk = m.get("key")
                if mk not in MASSE_KEYS:
                    fehler.append(
                        f"{sid}: masse[{i}] unbekannter key {mk!r} "
                        f"(erlaubt: {sorted(MASSE_KEYS)})"
                    )
                if not str(m.get("wert") or "").strip():
                    fehler.append(f"{sid}: masse[{i}] wert leer")

        merkmale = s.get("merkmale")
        if not isinstance(merkmale, list) or not (
            MERKMALE_COUNT[0] <= len(merkmale) <= MERKMALE_COUNT[1]
        ):
            fehler.append(
                f"{sid}: merkmale braucht {MERKMALE_COUNT[0]}–{MERKMALE_COUNT[1]} "
                f"Einträge (hat {len(merkmale or [])})"
            )
        else:
            unbekannt = set(merkmale) - merkmale_ids
            if unbekannt:
                fehler.append(f"{sid}: unbekannte merkmale {sorted(unbekannt)}")

        beziehungen = s.get("beziehungen")
        if not isinstance(beziehungen, list) or not beziehungen:
            fehler.append(f"{sid}: beziehungen fehlt oder leer")
        else:
            for i, b in enumerate(beziehungen):
                if not isinstance(b, dict):
                    fehler.append(f"{sid}: beziehungen[{i}] kein Objekt")
                    continue
                bt = b.get("typ")
                if bt not in BEZIEHUNG_TYPEN:
                    fehler.append(
                        f"{sid}: beziehungen[{i}] unbekannter typ {bt!r} "
                        f"(erlaubt: {sorted(BEZIEHUNG_TYPEN)})"
                    )
                to_id = b.get("toSpeciesId") or b.get("speciesId")
                name = str(b.get("nameDe") or "").strip()
                if to_id:
                    if to_id not in species_ids:
                        fehler.append(
                            f"{sid}: beziehungen[{i}] toSpeciesId {to_id!r} "
                            "nicht im Katalog"
                        )
                    if to_id == sid:
                        fehler.append(f"{sid}: beziehungen[{i}] auf sich selbst")
                elif not name:
                    fehler.append(
                        f"{sid}: beziehungen[{i}] braucht toSpeciesId oder nameDe"
                    )
                nw = len(_words(b.get("kurztext") or ""))
                if nw > 12:
                    fehler.append(
                        f"{sid}: beziehungen[{i}] kurztext {nw} Woerter (max 12)"
                    )

    return fehler


def validiere_pois(path):
    """Pflichtfelder, Kategorie-Keys, opening_hours-Subset."""
    fehler = []
    with open(path, encoding="utf-8") as f:
        rows = json.load(f)
    if not isinstance(rows, list):
        return ["pois.json muss ein Array sein"], 0
    seen = set()
    for i, p in enumerate(rows):
        if not isinstance(p, dict):
            fehler.append(f"pois[{i}] kein Objekt")
            continue
        pid = str(p.get("id") or "").strip() or f"#{i}"
        if pid in seen:
            fehler.append(f"{pid}: doppelte id")
        seen.add(pid)
        for feld in ("id", "name", "kategorie", "kurztext", "lat", "lon"):
            if feld not in p:
                fehler.append(f"{pid}: Pflichtfeld fehlt: {feld}")
        if not str(p.get("kurztext") or "").strip():
            fehler.append(f"{pid}: kurztext leer")
        kat = p.get("kategorie")
        if kat not in POI_KATS:
            fehler.append(
                f"{pid}: unbekannte kategorie {kat!r} (erlaubt: {sorted(POI_KATS)})"
            )
        for key in ("lat", "lon"):
            if not isinstance(p.get(key), (int, float)):
                fehler.append(f"{pid}: {key} keine Zahl")
        oh = p.get("opening_hours")
        if oh is not None and str(oh).strip():
            for rule in str(oh).split(";"):
                if not OH_RULE.match(rule.strip()):
                    fehler.append(f"{pid}: opening_hours ungueltig: {rule!r}")
                    break
    return fehler, len(rows)


def validiere_zeiten(path, poi_ids, trail_ids):
    """nearby_zeiten.json: Orte existieren, sek <= 20 Min, sortiert, Trails bekannt."""
    fehler = []
    with open(path, encoding="utf-8") as f:
        daten = json.load(f)
    if not isinstance(daten, dict):
        return ["nearby_zeiten.json muss ein Objekt sein"], 0
    for tid, eintraege in daten.items():
        if tid not in trail_ids:
            fehler.append(f"{tid}: Trail nicht in assets/seed")
        if not isinstance(eintraege, list):
            fehler.append(f"{tid}: kein Array")
            continue
        last = -1
        seen = set()
        for e in eintraege:
            pid, sek = e.get("poi"), e.get("sek")
            if pid not in poi_ids:
                fehler.append(f"{tid}: unbekannter Ort {pid!r}")
            if pid in seen:
                fehler.append(f"{tid}: Ort doppelt {pid!r}")
            seen.add(pid)
            if not isinstance(sek, int) or sek < 0 or sek > NEARBY_MAX_SEK:
                fehler.append(f"{tid}/{pid}: sek {sek!r} ausserhalb 0..{NEARBY_MAX_SEK}")
            elif sek < last:
                fehler.append(f"{tid}/{pid}: nicht nach sek sortiert")
            else:
                last = sek
    return fehler, len(daten)


def validiere_pools(path, species_ids):
    """art_pools.json: Lebensraum x Naturraum, jede Art im Katalog."""
    fehler = []
    with open(path, encoding="utf-8") as f:
        daten = json.load(f)
    pools = daten.get("pools") if isinstance(daten, dict) else None
    if not isinstance(pools, list) or not pools:
        return ["art_pools.json: pools fehlt oder leer"]
    for i, pool in enumerate(pools):
        label = f"pools[{i}]"
        lr = pool.get("lebensraum")
        if lr not in LEBENSRAEUME:
            fehler.append(f"{label}: unbekannter lebensraum {lr!r}")
        nrs = pool.get("naturraeume")
        if not isinstance(nrs, list) or not nrs:
            fehler.append(f"{label}: naturraeume fehlt")
        else:
            for nr in nrs:
                if nr not in NATURRAUM:
                    fehler.append(f"{label}: unbekannter naturraum {nr!r}")
        gesehen = set()
        arten = pool.get("arten")
        if not isinstance(arten, list) or not arten:
            fehler.append(f"{label}: arten leer")
            continue
        for art in arten:
            aid = art.get("id")
            if aid in gesehen:
                fehler.append(f"{label}: Art doppelt {aid}")
            gesehen.add(aid)
            if aid not in species_ids:
                fehler.append(f"{label}: Art nicht im Katalog: {aid}")
            if art.get("rolle") not in ROLLEN:
                fehler.append(f"{label}/{aid}: rolle {art.get('rolle')!r}")
            if art.get("sichtbarkeit") not in SICHTBARKEIT:
                fehler.append(
                    f"{label}/{aid}: sichtbarkeit {art.get('sichtbarkeit')!r}"
                )
            if not str(art.get("quelle") or "").strip():
                fehler.append(f"{label}/{aid}: quelle fehlt")
    return fehler


def arten_duenn(t, arten_lookup, arten_by_id):
    """Warnung, kein Fehler. Ziel: Flora >= 4, Fauna >= 6."""
    flora = fauna = 0
    for name in t.get("arten") or []:
        sid = arten_lookup.get(str(name).casefold())
        if not sid:
            continue
        kat = arten_by_id[sid].get("kategorie")
        if kat == "flora":
            flora += 1
        elif kat == "fauna":
            fauna += 1
    if flora < MIN_FLORA or fauna < MIN_FAUNA:
        return flora, fauna
    return None


def validiere(path, arten_lookup, arten_by_id=None):
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

    gebiet = t.get("gebiet")
    if gebiet is not None and gebiet not in (
        "wald", "heide", "moor", "kueste", "wasser", "aue", "hof"
    ):
        fehler.append(f"Unbekanntes gebiet: {gebiet!r}")

    try:
        resolve_names(t.get("arten", []), arten_lookup)
    except ValueError as e:
        fehler.append(str(e))

    lr = t.get("lebensraeume")
    if not isinstance(lr, list) or len(lr) > 3:
        fehler.append("lebensraeume: Liste mit 0–3 Keys")
    else:
        unbekannt_lr = set(lr) - LEBENSRAEUME
        if unbekannt_lr:
            fehler.append(f"Unbekannte lebensraeume: {sorted(unbekannt_lr)}")
    if t.get("naturraum") not in NATURRAUM:
        fehler.append(
            f"naturraum {t.get('naturraum')!r} "
            f"(erlaubt: {sorted(NATURRAUM)})"
        )
    nachweis = t.get("artenNachweis") or {}
    if not isinstance(nachweis, dict):
        fehler.append("artenNachweis muss ein Objekt sein")
    else:
        for name, stufe in nachweis.items():
            if stufe not in ("belegt", "typisch"):
                fehler.append(f"artenNachweis {name}: {stufe!r}")
            elif arten_lookup.get(str(name).casefold()) is None:
                fehler.append(f"artenNachweis unbekannte Art: {name}")

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

    fehler.extend(validiere_bilder(t))

    return fehler, t


def validiere_bilder(t):
    """credits.json (lokal vor migrate_hero_images.py) oder DB-Bilder, License-Keys."""
    fehler = []
    asset = (t.get("bilderAsset") or "").strip()
    inline = t.get("bilder")
    if not asset and not (isinstance(inline, list) and inline):
        return fehler

    rows = inline if isinstance(inline, list) and inline else None
    credits_path = None
    if asset:
        credits_path = os.path.join(APP_ROOT, asset)
        if not os.path.isfile(credits_path):
            fehler.append(f"bilderAsset nicht gefunden: {asset}")
            return fehler
        try:
            with open(credits_path, encoding="utf-8") as f:
                rows = json.load(f)
        except (OSError, json.JSONDecodeError) as e:
            fehler.append(f"bilderAsset ungueltig ({asset}): {e}")
            return fehler

    if not isinstance(rows, list) or not rows:
        fehler.append("bilder/credits.json muss ein nicht-leeres Array sein")
        return fehler

    trail_id = t.get("id") or ""
    img_dir = os.path.join(APP_ROOT, "assets", "images", "trails", trail_id)
    seen_files = set()
    for i, row in enumerate(rows):
        if not isinstance(row, dict):
            fehler.append(f"bilder[{i}] kein Objekt")
            continue
        fn = str(row.get("file") or "").strip()
        if not fn:
            fehler.append(f"bilder[{i}]: file fehlt")
            continue
        if fn in seen_files:
            fehler.append(f"bilder[{i}]: doppelte file {fn!r}")
        seen_files.add(fn)
        lic = str(row.get("license") or "").strip()
        if lic and lic not in BILD_LIZENZEN:
            fehler.append(
                f"bilder[{i}] ({fn}): unbekannte license {lic!r} "
                f"(erlaubt: {sorted(BILD_LIZENZEN)})"
            )
        if row.get("id"):
            # Bild liegt in Supabase Storage (Offline-First, kein Bundle-Asset)
            continue
        if fn.startswith("assets/"):
            disk = os.path.join(APP_ROOT, fn)
        else:
            disk = os.path.join(img_dir, fn)
        if not os.path.isfile(disk):
            stem = os.path.splitext(os.path.basename(fn))[0]
            avifs = [
                os.path.join(img_dir, f"{stem}.{v}.avif")
                for v in ("thumb", "small", "medium")
            ]
            if not all(os.path.isfile(p) for p in avifs):
                fehler.append(f"bilder[{i}]: Datei fehlt ({disk})")

    return fehler


def main():
    try:
        with open(SPECIES_PATH, encoding="utf-8") as f:
            species_rows_raw = json.load(f)
        arten_by_id, arten_lookup = load_catalog()
        merkmale_by_id = load_merkmale()
    except (OSError, ValueError, json.JSONDecodeError) as e:
        sys.exit(f"species.json ungueltig: {e}")

    ok = True
    content_fehler = validiere_species_content(species_rows_raw)
    status = "OK  " if not content_fehler else "FEHLER"
    print(f"{status} species.json: {len(species_rows_raw)} Arten (content)")
    for f_ in content_fehler:
        print(f"      - {f_}")
        ok = False

    species_ids = {s.get("id") for s in species_rows_raw}
    pools_path = os.path.join(SEED_DIR, "art_pools.json")
    if os.path.isfile(pools_path):
        pools_fehler = validiere_pools(pools_path, species_ids)
        status = "OK  " if not pools_fehler else "FEHLER"
        print(f"{status} art_pools.json")
        for f_ in pools_fehler:
            print(f"      - {f_}")
            ok = False
    else:
        print("FEHLER art_pools.json fehlt")
        ok = False
    profil_fehler = validiere_species_profil(
        species_rows_raw, set(merkmale_by_id), species_ids
    )
    status = "OK  " if not profil_fehler else "FEHLER"
    print(f"{status} species.json: Profil (gruppe/seltenheit/gefahr/…) "
          f"+ {len(merkmale_by_id)} Merkmale")
    for f_ in profil_fehler:
        print(f"      - {f_}")
        ok = False

    pois_path = os.path.join(SEED_DIR, "pois.json")
    try:
        pois_fehler, pois_n = validiere_pois(pois_path)
    except (OSError, json.JSONDecodeError) as e:
        print(f"FEHLER pois.json: {e}")
        ok = False
    else:
        status = "OK  " if not pois_fehler else "FEHLER"
        print(f"{status} pois.json: {pois_n} Orte")
        for f_ in pois_fehler:
            print(f"      - {f_}")
            ok = False

    dateien = sorted(
        p for p in glob.glob(os.path.join(SEED_DIR, "*.json"))
        if os.path.basename(p) not in NON_TRAIL
        and not any(p.endswith(f"{s}.json") for s in ROH_PREFIXE)
    )
    for path in dateien:
        fehler, t = validiere(path, arten_lookup, arten_by_id)
        status = "OK  " if not fehler else "FEHLER"
        print(f"{status} {os.path.basename(path)}: {t['name']} | "
              f"{t['laengeKm']} km, {len(t['stationen'])} Stationen, "
              f"{len(t['amenities'])} Amenities, tags={t.get('tags')}")
        duenn = arten_duenn(t, arten_lookup, arten_by_id)
        if duenn and not fehler:
            print(f"      info: Arten dünn flora={duenn[0]} fauna={duenn[1]} "
                  f"(Ziel {MIN_FLORA}/{MIN_FAUNA})")
        for f_ in fehler:
            print(f"      - {f_}")
            ok = False

    zeiten_path = os.path.join(SEED_DIR, "nearby_zeiten.json")
    try:
        with open(pois_path, encoding="utf-8") as f:
            poi_ids = {p["id"] for p in json.load(f)}
        trail_ids = set()
        for p in dateien:
            with open(p, encoding="utf-8") as f:
                trail_ids.add(json.load(f).get("id"))
        z_fehler, z_n = validiere_zeiten(zeiten_path, poi_ids, trail_ids)
    except (OSError, json.JSONDecodeError) as e:
        print(f"FEHLER nearby_zeiten.json: {e}")
        ok = False
    else:
        status = "OK  " if not z_fehler else "FEHLER"
        print(f"{status} nearby_zeiten.json: {z_n} Trails")
        for f_ in z_fehler:
            print(f"      - {f_}")
            ok = False
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
