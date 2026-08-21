#!/usr/bin/env python3
"""Konvertiert eine GPX-Track/Route zu tools/osm/<prefix>_route.json.

Nutzung:
  python3 tools/gpx_to_route.py pfad/zum/track.gpx alt-daber
"""
import json
import os
import sys
import xml.etree.ElementTree as ET

NS = {"g": "http://www.topografix.com/GPX/1/1"}


def points_from_gpx(path):
    root = ET.parse(path).getroot()
    pts = []
    for tag in ("trkpt", "rtept"):
        for el in root.findall(f".//g:{tag}", NS):
            pts.append([float(el.attrib["lat"]), float(el.attrib["lon"])])
        if pts:
            break
    if not pts:
        # Fallback ohne Namespace
        for tag in ("trkpt", "rtept"):
            for el in root.iter():
                if el.tag.endswith(tag):
                    pts.append([float(el.attrib["lat"]), float(el.attrib["lon"])])
            if pts:
                break
    return pts


def main():
    if len(sys.argv) < 3:
        sys.exit("Nutzung: gpx_to_route.py <file.gpx> <prefix>")
    gpx_path, prefix = sys.argv[1], sys.argv[2]
    pts = points_from_gpx(gpx_path)
    if len(pts) < 2:
        sys.exit("Keine Trackpunkte in GPX gefunden")
    out = os.path.join(os.path.dirname(__file__), "osm", f"{prefix}_route.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(pts, f, ensure_ascii=False)
    print(f"OK: {out} ({len(pts)} Punkte)")


if __name__ == "__main__":
    main()
