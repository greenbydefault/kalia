#!/usr/bin/env python3
"""Schreibt content aus _species_content_data.json in assets/seed/species.json.

Nutzung:
  python3 tools/_build_species_content.py
  python3 tools/validate_seeds.py
"""
from __future__ import annotations

import json
import os
import sys

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "seed")
PATH = os.path.join(ROOT, "species.json")
DATA = os.path.join(os.path.dirname(__file__), "_species_content_data.json")


def words(text: str) -> int:
    return len([w for w in text.split() if w])


def check(cid: str, c: dict) -> list[str]:
    err = []
    hw = words(c["hook"])
    if not 12 <= hw <= 22:
        err.append(f"{cid} hook={hw}")
    if not 2 <= len(c["erkennung"]) <= 4:
        err.append(f"{cid} erkennung count={len(c['erkennung'])}")
    for i, b in enumerate(c["erkennung"]):
        n = words(b)
        if n == 0 or n > 12:
            err.append(f"{cid} erkennung[{i}]={n}")
    lw = words(c["lebensraum"])
    if not 1 <= lw <= 40:
        err.append(f"{cid} lebensraum={lw}")
    if not 2 <= len(c["funFacts"]) <= 3:
        err.append(f"{cid} funFacts count")
    nw = words(c.get("hinweis", ""))
    if nw > 15:
        err.append(f"{cid} hinweis={nw}")
    ow = words(c["hoertext"])
    if not 90 <= ow <= 120:
        err.append(f"{cid} hoertext={ow}")
    return err


def main() -> None:
    with open(DATA, encoding="utf-8") as f:
        content = json.load(f)
    with open(PATH, encoding="utf-8") as f:
        rows = json.load(f)

    ids = {r["id"] for r in rows}
    missing = ids - set(content)
    extra = set(content) - ids
    if missing or extra:
        sys.exit(f"ID mismatch missing={missing} extra={extra}")

    errors = []
    for cid, c in content.items():
        errors.extend(check(cid, c))
    if errors:
        print("WORDCOUNT ERRORS:")
        for e in errors:
            print(" ", e)
        sys.exit(1)

    for r in rows:
        c = content[r["id"]]
        r["content"] = {
            "hook": c["hook"],
            "erkennung": c["erkennung"],
            "lebensraum": c["lebensraum"],
            "funFacts": c["funFacts"],
            "hinweis": c.get("hinweis", ""),
            "hoertext": c["hoertext"],
        }
        r["kurztext"] = c["hook"]

    with open(PATH, "w", encoding="utf-8") as f:
        json.dump(rows, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"OK wrote content for {len(rows)} species → {PATH}")


if __name__ == "__main__":
    main()
