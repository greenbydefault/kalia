"""Slug-Regel: ^[a-z0-9]+(-[a-z0-9]+)*$, Umlaute ae/oe/ue/ss."""
from __future__ import annotations

import re
from typing import Optional, Tuple

SLUG_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
_UMLAUTE = {"ä": "ae", "ö": "oe", "ü": "ue", "ß": "ss", "Ä": "ae", "Ö": "oe", "Ü": "ue"}


def slugify(text: str) -> str:
    s = (text or "").strip()
    for k, v in _UMLAUTE.items():
        s = s.replace(k, v)
    s = s.lower()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return s.strip("-")


def check_slug(raw: Optional[str]) -> Tuple[str, bool, bool]:
    """Liefert (slug, korrigiert, gueltig).

    korrigiert = der Rohwert war kein gueltiger Slug, ist aber nach der Umschrift einer.
    gueltig = Ergebnis erfuellt die Regel (sonst harter Fehler SLUG).
    """
    raw = (raw or "").strip()
    if SLUG_RE.match(raw):
        return raw, False, True
    cand = slugify(raw)
    if cand and SLUG_RE.match(cand):
        return cand, True, True
    return cand, False, False
