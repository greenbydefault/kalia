#!/usr/bin/env python3
"""
Baut die drei Mini-Card-Ebenen (grau, blau, mitte) der Arten-Gruppen aus public/img/arten/{id}.svg.

Rahmen, Winkel und Farben wie im Moor-Entwurf (public/img/cards/moor/*.svg), 315 x 237.
Die Art steht aufrecht (nicht mitgekippt) im sichtbaren Streifen der Karte, grau links, blau rechts,
mitte vorn. Aufruf aus site/:  python3 tools/gen_card_fronts.py
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "public" / "img"
ARTEN = ROOT / "arten"
CARDS = ROOT / "cards"

# Gruppe -> (grau, mitte, blau). Schmale/hohe Arten außen, die auffälligste in die Mitte.
GRUPPEN = {
    "voegel": ("buntspecht", "rotkehlchen", "kohlmeise"),
    "baeume": ("haengebirke", "stieleiche", "kiefer"),
    "saeugetiere": ("feldhase", "reh", "eichhoernchen"),
    "kraeuter": ("margerite", "loewenzahn", "sonnentau"),
    "insekten": ("marienkaefer", "tagpfauenauge", "hummel"),
    "straeucher": ("heckenrose", "holunder", "haselnuss"),
    "amphibien": ("rotbauchunke", "moorfrosch", "erdkroete"),
    "reptilien": ("waldeidechse", "ringelnatter", "zauneidechse"),
}

# Platz der Art in Bildschirmkoordinaten: x, y, Breite, Höhe. Boden (unten mittig) als Anker.
BOX = {
    "grau": (22, 62, 62, 112),
    "mitte": (84, 44, 126, 148),
    "blau": (226, 62, 62, 112),
}

SHADOW = """<filter id="shadow" x="40" y="-2" width="260" height="240" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">
<feFlood flood-opacity="0" result="BackgroundImageFix" />
<feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha" />
<feOffset dy="4" />
<feGaussianBlur stdDeviation="7" />
<feComposite in2="hardAlpha" operator="out" />
<feColorMatrix type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.1 0" />
<feBlend mode="normal" in2="BackgroundImageFix" result="effect1_dropShadow" />
<feBlend mode="normal" in="SourceGraphic" in2="effect1_dropShadow" result="shape" />
</filter>"""


def art(art_id: str, box: tuple[int, int, int, int]) -> str:
    """Art-SVG als verschachteltes <svg> in `box`, unten mittig verankert."""
    src = (ARTEN / f"{art_id}.svg").read_text(encoding="utf-8")
    src = re.sub(r"^\s*<\?xml[^>]*>\s*", "", src)
    root = re.search(r"<svg\b[^>]*>", src)
    if not root:
        raise SystemExit(f"{art_id}.svg: kein <svg>")
    vb = re.search(r'viewBox="([^"]+)"', root.group(0))
    if not vb:
        raise SystemExit(f"{art_id}.svg: keine viewBox")
    x, y, w, h = box
    head = (
        f'<svg x="{x}" y="{y}" width="{w}" height="{h}" viewBox="{vb.group(1)}" '
        f'preserveAspectRatio="xMidYMax meet" xmlns="http://www.w3.org/2000/svg">'
    )
    return head + src[root.end():]


def grau(a: str) -> str:
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="315" height="237" viewBox="0 0 315 237" fill="none">\n'
        '<rect x="2.79094" y="2.0563" width="147.502" height="183.723" rx="13.5" '
        'transform="matrix(0.985634 -0.168898 0.130744 0.991416 -0.228753 35.3861)" fill="#F3F4F6" />\n'
        '<rect x="2.79094" y="2.0563" width="147.502" height="183.723" rx="13.5" '
        'transform="matrix(0.985634 -0.168898 0.130744 0.991416 -0.228753 35.3861)" stroke="white" stroke-width="5" />\n'
        + art(a, BOX["grau"])
        + "\n</svg>\n"
    )


def blau(a: str) -> str:
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="315" height="237" viewBox="0 0 315 237" fill="none">\n'
        f"<defs>{SHADOW}</defs>\n"
        '<g filter="url(#shadow)">\n'
        '<rect width="152.502" height="188.723" rx="16" '
        'transform="matrix(0.985631 0.168915 -0.130758 0.991414 145.677 8)" fill="#DCEBF5" />\n'
        '<rect x="2.13718" y="2.90082" width="147.502" height="183.723" rx="13.5" '
        'transform="matrix(0.985631 0.168915 -0.130758 0.991414 146.087 7.6639)" stroke="white" stroke-width="5" />\n'
        "</g>\n"
        + art(a, BOX["blau"])
        + "\n</svg>\n"
    )


def mitte(a: str) -> str:
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="315" height="237" viewBox="0 0 315 237" fill="none">\n'
        f"<defs>{SHADOW}</defs>\n"
        '<g filter="url(#shadow)">\n'
        '<rect width="152.013" height="189.193" rx="16" '
        'transform="matrix(1 0 -0.00632073 0.99998 71.1958 10)" fill="#EEE7D6" />\n'
        '<rect x="2.4842" y="2.49995" width="147.013" height="184.193" rx="13.5" '
        'transform="matrix(1 0 -0.00632073 0.99998 71.2116 10)" stroke="white" stroke-width="5" />\n'
        "</g>\n"
        + art(a, BOX["mitte"])
        + "\n</svg>\n"
    )


def main() -> None:
    for gruppe, (g, m, b) in GRUPPEN.items():
        out = CARDS / gruppe
        out.mkdir(parents=True, exist_ok=True)
        (out / "grau.svg").write_text(grau(g), encoding="utf-8")
        (out / "mitte.svg").write_text(mitte(m), encoding="utf-8")
        (out / "blau.svg").write_text(blau(b), encoding="utf-8")
        print(f"{gruppe}: grau={g} mitte={m} blau={b}")


if __name__ == "__main__":
    main()
