#!/usr/bin/env python3
"""Gebiet (Wald, Heide, Moor, Küste, Wasser, Aue, Hof) je Trail.

Ein Hauptgebiet pro Eintrag, abgeleitet aus `typ` und `lebensraeume`.
Die Regeln stehen hier und in `lib/features/trail/domain/gebiet.dart`
(`deriveGebiet`) — beide müssen gleich bleiben.

Nutzung:
  python3 tools/gebiet.py            # schreibt "gebiet" in alle Trail-Seeds
  python3 tools/gebiet.py --dry-run  # nur Liste, nichts schreiben
"""
import glob
import json
import os
import re
import sys

SEED_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "seed")

GEBIETE = ("wald", "heide", "moor", "kueste", "wasser", "aue", "hof")

# typ gewinnt, wenn er ein Gebiet eindeutig festlegt.
TYP_GEBIET = {
    "kueste": "kueste",
    "moor": "moor",
    "aue": "aue",
    "kinderbauernhof": "hof",
    "wasserspielplatz": "wasser",
}

# Sonst entscheidet der erste Lebensraum, der ein Nicht-Wald-Gebiet hat.
LEBENSRAUM_GEBIET = {
    "heide": "heide",
    "trockenrasen": "heide",
    "moor": "moor",
    "duene-strand": "kueste",
    "salzwiese-watt": "kueste",
    "fliessgewaesser": "wasser",
    "see-ufer": "wasser",
    "teich-tuempel": "wasser",
    "hof-nutztier": "hof",
}

# Reine Waldtypen: erster Lebensraum entscheidet nur bei Heide/Moor/Wasser/Küste.
# Bei Wald-Lebensräumen (Buchenwald, Kiefernforst, Auwald …) bleibt es Wald.


def derive_gebiet(typ, lebensraeume):
    if typ in TYP_GEBIET:
        return TYP_GEBIET[typ]
    if lebensraeume:
        erster = lebensraeume[0]
        if erster in LEBENSRAUM_GEBIET:
            return LEBENSRAUM_GEBIET[erster]
    return "wald"


def is_trail(d):
    return isinstance(d, dict) and "id" in d and "typ" in d and (
        "route" in d or "area" in d
    )


def main():
    dry = "--dry-run" in sys.argv
    unsicher = []
    zaehler = {}
    for path in sorted(glob.glob(os.path.join(SEED_DIR, "*.json"))):
        text = open(path, encoding="utf-8").read()
        try:
            d = json.loads(text)
        except ValueError:
            continue
        if not is_trail(d):
            continue
        g = d.get("gebiet") or derive_gebiet(d["typ"], d.get("lebensraeume") or [])
        zaehler[g] = zaehler.get(g, 0) + 1
        # Mehrdeutig: kein Lebensraum, der Wald/Nicht-Wald trägt, und kein Typ-Treffer.
        if d["typ"] not in TYP_GEBIET and not d.get("lebensraeume"):
            unsicher.append((os.path.basename(path), d["typ"], g))
        if d.get("gebiet") == g:
            continue
        if dry:
            continue
        if '"gebiet"' in text:
            text = re.sub(r'"gebiet":\s*"[^"]*"', '"gebiet": "%s"' % g, text, count=1)
        else:
            # Seeds sind mit 1 Leerzeichen eingerückt; neben "typ" einfügen.
            text, n = re.subn(
                r'(\n( *)"typ": "[^"]*",)', r'\1\n\2"gebiet": "%s",' % g, text, count=1
            )
            if n == 0:
                print("kein typ-Anker:", path)
                continue
        open(path, "w", encoding="utf-8").write(text)
    print("Verteilung:", zaehler)
    if unsicher:
        print("Zur Durchsicht (ohne Lebensraum, Fallback Wald):")
        for f, typ, g in unsicher:
            print("  %s  typ=%s  -> %s" % (f, typ, g))


if __name__ == "__main__":
    main()
