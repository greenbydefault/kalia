#!/usr/bin/env python3
"""Smoke-Tests fuer resolve_arten / validate_seeds Arten-Check."""
import json
import os
import subprocess
import sys
import tempfile

from resolve_arten import load_catalog, resolve_names

TOOLS = os.path.dirname(__file__)
SEED = os.path.join(TOOLS, "..", "assets", "seed")


def test_aliases():
    slugs = resolve_names(["Sumpf-Iris", "Moosjungfer", "Rotbauchunke"])
    assert slugs == [
        "sumpf-schwertlilie",
        "grosse-moosjungfer",
        "rotbauchunke",
    ], slugs


def test_unknown_raises():
    try:
        resolve_names(["GibtEsNicht"])
        raise AssertionError("sollte ValueError werfen")
    except ValueError as e:
        assert "GibtEsNicht" in str(e)


def test_empty_raises():
    try:
        resolve_names([])
        raise AssertionError("sollte ValueError werfen")
    except ValueError as e:
        assert "leer" in str(e).lower()


def test_validate_fails_on_unknown_art():
    _, lookup = load_catalog()
    # Minimale Fake-Trail-JSON mit unbekannter Art
    fake = {
        "id": "fake",
        "name": "Fake",
        "typ": "moor",
        "kurzbeschreibung": "x",
        "beschreibung": "x",
        "laengeKm": 1.0,
        "dauerMin": 10,
        "rundkurs": False,
        "markierung": "x",
        "betreiber": "x",
        "region": "x",
        "anreise": "x",
        "startName": "x",
        "arten": ["UnbekannteArtXYZ"],
        "tags": [],
        "route": [[52.0, 13.0], [52.001, 13.001]],
        "stationen": [
            {
                "osmId": 1,
                "lat": 52.0,
                "lon": 13.0,
                "km": 0,
                "reihenfolge": 1,
                "titel": "A",
                "thema": "",
                "kurztext": "",
                "erlebnisse": ["tafel"],
                "barrierefrei": False,
                "steckbrief": None,
            }
        ],
        "amenities": [],
    }
    with tempfile.TemporaryDirectory() as tmp:
        path = os.path.join(tmp, "fake.json")
        with open(path, "w", encoding="utf-8") as f:
            json.dump(fake, f)
        # validate_seeds validiert nur assets/seed – wir pruefen resolve direkt
        try:
            resolve_names(fake["arten"], lookup)
            raise AssertionError("expected fail")
        except ValueError:
            pass


def main():
    test_aliases()
    test_unknown_raises()
    test_empty_raises()
    test_validate_fails_on_unknown_art()
    # echte Seeds muessen gruen sein
    r = subprocess.run(
        [sys.executable, os.path.join(TOOLS, "validate_seeds.py")],
        cwd=TOOLS,
        capture_output=True,
        text=True,
    )
    if r.returncode != 0:
        print(r.stdout, r.stderr)
        sys.exit("validate_seeds fehlgeschlagen")
    print("OK: resolve_arten + validate_seeds")


if __name__ == "__main__":
    main()
