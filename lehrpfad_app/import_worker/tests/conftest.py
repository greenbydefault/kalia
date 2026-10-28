import glob
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if ROOT not in sys.path:
    sys.path.insert(0, ROOT)
TOOLS = os.path.join(ROOT, "tools")
if TOOLS not in sys.path:
    sys.path.insert(0, TOOLS)

import pytest  # noqa: E402

SEED_DIR = os.path.join(ROOT, "assets", "seed")
NON_TRAIL = {"species", "merkmale", "pois", "nearby_zeiten", "art_pools", "orte_de", "index", "trail"}


def seed_paths():
    out = []
    for p in sorted(glob.glob(os.path.join(SEED_DIR, "*.json"))):
        if os.path.basename(p)[:-5] in NON_TRAIL:
            continue
        out.append(p)
    return out


@pytest.fixture(scope="session")
def pressel_seed():
    with open(os.path.join(SEED_DIR, "naturlehrpfad-pressel.json"), encoding="utf-8") as f:
        return json.load(f)
