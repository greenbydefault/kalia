#!/usr/bin/env python3
"""Platzhalter-App-Icon: Phosphor `tree` (Fill) weiß auf Marken-Neutral.

Aus dem Font des Pakets phosphoricons_flutter (pub-cache). Echtes Logo später:
`assets/icons/app/icon_placeholder.png` (Vollbild) und `icon_placeholder_fg.png`
(transparenter Vordergrund) austauschen, dann
`dart run flutter_launcher_icons`.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

FONT = (
    Path.home()
    / ".pub-cache/hosted/pub.dev/phosphoricons_flutter-1.0.0/lib/fonts/Phosphor-Fill.ttf"
)
CODEPOINT = 0xE6DA  # PhosphorIcons.treeFill, siehe icon_catalog.dart (wald)
BG = (0x14, 0x14, 0x14, 255)  # AppColors.brand = n900
SIZE = 1024
OUT = Path(__file__).resolve().parent.parent / "assets/icons/app"


def glyph_layer(scale: float) -> Image.Image:
    """Weißes Glyph, mittig auf transparentem SIZE×SIZE-Canvas."""
    font = ImageFont.truetype(str(FONT), int(SIZE * scale))
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.text(
        (SIZE / 2, SIZE / 2),
        chr(CODEPOINT),
        font=font,
        fill=(255, 255, 255, 255),
        anchor="mm",
    )
    return layer


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    # Adaptive Vordergrund: Safe-Zone ist der mittlere Kreis (66 %), daher klein.
    glyph_layer(0.52).save(OUT / "icon_placeholder_fg.png")
    # Vollbild (Legacy-Icon, Web, iOS): etwas größer.
    full = Image.new("RGBA", (SIZE, SIZE), BG)
    full.alpha_composite(glyph_layer(0.62))
    full.convert("RGB").save(OUT / "icon_placeholder.png")
    print("ok:", OUT)


if __name__ == "__main__":
    main()
