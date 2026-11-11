#!/usr/bin/env python3
"""
Entfernt den Bodenschatten aus public/img/arten/*.svg (und cards/igel.svg) und passt die ViewBox
an den echten Inhalt an, damit Arten ohne Schatten mittig in Kachel und Mini-Card sitzen.

Zwei Schritte, weil die Bounding-Box im Browser gemessen wird (getBBox):
  1. python3 tools/strip_art_shadows.py strip            Schatten raus, ungenutzte Filter raus
  2. python3 tools/strip_art_shadows.py fit bboxes.json  ViewBox/width/height aus {datei: [x, y, w, h, stroke]}

Wasser (Ellipsen bei Schwan, Biber, Stockente, Ripples) ist Inhalt und bleibt.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "public" / "img"
FILES = sorted((ROOT / "arten").glob("*.svg")) + [ROOT / "cards" / "igel.svg"]

# Figma-Export: <g opacity=".." filter="url(#filter0_f_..)"><path/></g> als erstes Element
RE_G_SHADOW = re.compile(r'<g opacity="[\d.]+" filter="url\(#filter0_f_[^"]+\)">\s*<path[^>]*/>\s*</g>\s*')
# Generiert (Wasser-Serie): Ellipse mit filter="url(#soft)"
RE_SOFT = re.compile(r'<ellipse[^>]*filter="url\(#soft\)"[^>]*/>')
# Graureiher: erster Pfad, flacher Schatten
RE_FLAT = re.compile(r'<path opacity="0\.16"[^>]*fill="#3A3A26"[^>]*/>\s*')
RE_FILTER_DEF = re.compile(r'<filter id="(?:filter0_f_[^"]+|soft2?)"[^>]*>.*?</filter>\s*', re.S)
RE_EMPTY_DEFS = re.compile(r"<defs>\s*</defs>\s*")


def strip(s: str) -> tuple[str, bool]:
    before = s
    for rx in (RE_G_SHADOW, RE_SOFT, RE_FLAT):
        s = rx.sub("", s, count=1)
    removed = s != before
    s = RE_FILTER_DEF.sub("", s)
    s = RE_EMPTY_DEFS.sub("", s)
    return s, removed


def cmd_strip() -> None:
    for f in FILES:
        s = f.read_text(encoding="utf-8")
        new, removed = strip(s)
        f.write_text(new, encoding="utf-8")
        print(f"{'ohne Schatten' if removed else 'unverändert  '} {f.relative_to(ROOT)}")


def cmd_fit(bboxes: dict[str, list[float]]) -> None:
    for f in FILES:
        key = str(f.relative_to(ROOT))
        if key not in bboxes:
            print(f"keine BBox: {key}")
            continue
        x, y, w, h, stroke = bboxes[key]
        pad = min(stroke / 2, 1.5)  # Strichbreite ragt halb nach außen, breite Wasserringe nicht voll
        x, y, w, h = x - pad, y - pad, w + 2 * pad, h + 2 * pad
        s = f.read_text(encoding="utf-8")
        root = re.search(r"<svg\b[^>]*>", s).group(0)
        vb = [float(v) for v in re.search(r'viewBox="([^"]+)"', root).group(1).split()]
        ow = float(re.search(r'width="([\d.]+)"', root).group(1))
        scale = ow / vb[2]  # px je ViewBox-Einheit bleibt
        new_root = re.sub(r'viewBox="[^"]+"', f'viewBox="{x:.3f} {y:.3f} {w:.3f} {h:.3f}"', root)
        new_root = re.sub(r'width="[\d.]+"', f'width="{w * scale:.0f}"', new_root)
        new_root = re.sub(r'height="[\d.]+"', f'height="{h * scale:.0f}"', new_root)
        f.write_text(s.replace(root, new_root, 1), encoding="utf-8")
        print(f"{key}: {' '.join(map(str, vb))} -> {x:.2f} {y:.2f} {w:.2f} {h:.2f}")


if __name__ == "__main__":
    if len(sys.argv) >= 2 and sys.argv[1] == "strip":
        cmd_strip()
    elif len(sys.argv) >= 3 and sys.argv[1] == "fit":
        cmd_fit(json.loads(Path(sys.argv[2]).read_text()))
    else:
        raise SystemExit(__doc__)
