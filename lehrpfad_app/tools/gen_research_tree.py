#!/usr/bin/env python3
"""Legt den Research-Baum Deutschland → Land → Kreis an.

Nutzung (Repo-Root = lehrpfad_app/):
  python3 tools/gen_research_tree.py

- Liest research/_kreise.json
- Legt fehlende Ordner + Kreis-STATUS.md (Status: leer) an
- Überschreibt keine existierende Kreis-STATUS.md
- Schreibt research/STATUS.md und <Land>/STATUS.md neu (Rollup)
"""
from __future__ import annotations

import json
import os
import re
from collections import Counter
from datetime import date

TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
APP_DIR = os.path.dirname(TOOLS_DIR)
RESEARCH_DIR = os.path.join(APP_DIR, "research")
KREISE_PATH = os.path.join(RESEARCH_DIR, "_kreise.json")

STATUS_RE = re.compile(r"^Status:\s*(\S+)", re.MULTILINE)
OBJEKTE_RE = re.compile(r"^## Objekte\s*\n(.*?)(?=^## |\Z)", re.MULTILINE | re.DOTALL)


def load_kreise():
    with open(KREISE_PATH, encoding="utf-8") as f:
        return json.load(f)


def parse_kreis_status(path):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    m = STATUS_RE.search(text)
    status = m.group(1).rstrip(".") if m else "leer"
    om = OBJEKTE_RE.search(text)
    n_obj = 0
    if om:
        block = om.group(1)
        if "_(noch keine)_" not in block:
            n_obj = len(re.findall(r"^[-*] \[[ xX]\]", block, re.MULTILINE))
    return status, n_obj


def kreis_status_template(name, typ):
    typ_label = {
        "landkreis": "Landkreis",
        "kreisfrei": "kreisfreie Stadt",
        "bezirk": "Bezirk",
    }.get(typ, typ)
    return (
        f"# {name}\n"
        f"\n"
        f"Typ: {typ_label}\n"
        f"Status: leer\n"
        f"Stand: {date.today().isoformat()}\n"
        f"\n"
        f"## Objekte\n"
        f"\n"
        f"_(noch keine)_\n"
        f"\n"
        f"## Kreis-Sweep\n"
        f"\n"
        f"- [ ] OSM Lehrpfad/Erlebnis\n"
        f"- [ ] Familienorte-Filter (frei, Outdoor)\n"
    )


def write_if_missing(path, content):
    if os.path.exists(path):
        return False
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    return True


def display_name(row):
    if row["folder"].startswith("Stadt-"):
        return f"Stadt {row['name']}"
    return row["name"]


def land_status_md(land, rows):
    counts = Counter(r["status"] for r in rows)
    lines = [
        f"# {land['name']}",
        "",
        f"Status: {counts.get('done', 0)} done / {counts.get('offen', 0)} offen / {counts.get('leer', 0)} leer",
        f"Stand: {date.today().isoformat()}",
        "",
        "| Kreis | Status | Objekte |",
        "|---|---|---:|",
    ]
    for r in rows:
        folder = r["folder"]
        lines.append(
            f"| [{display_name(r)}]({folder}/STATUS.md) | {r['status']} | {r['n_obj']} |"
        )
    lines.append("")
    return "\n".join(lines)


def master_status_md(laender_rows, stand):
    all_rows = [r for _, rows in laender_rows for r in rows]
    counts = Counter(r["status"] for r in all_rows)
    lines = [
        "# Research-Status Deutschland",
        "",
        "Nächsten `leer`-Kreis nehmen, `_kandidaten.md` füllen, abhaken. "
        "Filter und Ablauf: [README.md](README.md).",
        "",
        f"Stand Kreisliste: {stand}",
        f"Aktualisiert: {date.today().isoformat()}",
        "",
        f"**{counts.get('leer', 0)} leer** · "
        f"**{counts.get('offen', 0)} offen** · "
        f"**{counts.get('done', 0)} done** · "
        f"{len(all_rows)} Kreise/Bezirke",
        "",
    ]
    for land, rows in laender_rows:
        lc = Counter(r["status"] for r in rows)
        lines.append(f"## {land['name']}")
        lines.append("")
        lines.append(
            f"{lc.get('done', 0)} done / {lc.get('offen', 0)} offen / {lc.get('leer', 0)} leer"
        )
        lines.append("")
        lines.append("| Kreis | Status | Objekte |")
        lines.append("|---|---|---:|")
        folder = land["folder"]
        for r in rows:
            rel = f"{folder}/{r['folder']}/STATUS.md"
            lines.append(
                f"| [{display_name(r)}]({rel}) | {r['status']} | {r['n_obj']} |"
            )
        lines.append("")
    return "\n".join(lines)


def main():
    data = load_kreise()
    created = 0
    laender_rows = []
    for land in data["laender"]:
        land_dir = os.path.join(RESEARCH_DIR, land["folder"])
        os.makedirs(land_dir, exist_ok=True)
        rows = []
        for kreis in land["kreise"]:
            kdir = os.path.join(land_dir, kreis["folder"])
            os.makedirs(kdir, exist_ok=True)
            spath = os.path.join(kdir, "STATUS.md")
            if write_if_missing(
                spath, kreis_status_template(kreis["name"], kreis["typ"])
            ):
                created += 1
            status, n_obj = parse_kreis_status(spath)
            rows.append({
                "name": kreis["name"],
                "folder": kreis["folder"],
                "status": status,
                "n_obj": n_obj,
            })
        with open(os.path.join(land_dir, "STATUS.md"), "w", encoding="utf-8") as f:
            f.write(land_status_md(land, rows))
        laender_rows.append((land, rows))

    with open(os.path.join(RESEARCH_DIR, "STATUS.md"), "w", encoding="utf-8") as f:
        f.write(master_status_md(laender_rows, data.get("stand", "")))

    print(f"Kreis-STATUS neu: {created}")
    print(f"Kreise gesamt: {sum(len(r) for _, r in laender_rows)}")


if __name__ == "__main__":
    main()
