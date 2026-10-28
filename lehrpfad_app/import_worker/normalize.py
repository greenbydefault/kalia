"""Rohwerte aus dem Dossier in Python-Typen. Jede Korrektur wird als Hinweis gemeldet."""
from __future__ import annotations

import re
from typing import Any, List, Optional, Tuple

JA = {"ja", "j", "yes", "true", "1", "x", "✓"}
NEIN = {"nein", "n", "no", "false", "0", "-", "–"}


def blank(v: Any) -> bool:
    return v is None or (isinstance(v, str) and v.strip() == "")


def clean(v: Any) -> Optional[str]:
    """Strip, Mehrfach-Leerzeichen am Rand, None bei leer. Zeilenumbrueche im Text bleiben."""
    if v is None:
        return None
    s = str(v).replace("\u00a0", " ").strip()
    return s or None


def to_float(raw: Optional[str]) -> Tuple[Optional[float], bool]:
    """(Wert, korrigiert). Akzeptiert 53,55 und '53.55 km'. Nicht lesbar = (None, False)."""
    s = clean(raw)
    if s is None:
        return None, False
    plain = re.fullmatch(r"-?\d+(\.\d+)?", s)
    if plain:
        return float(s), False
    s2 = s.replace(",", ".")
    m = re.search(r"-?\d+(\.\d+)?", s2)
    if m and re.fullmatch(r"[^\d-]*(-?\d+(\.\d+)?)\s*[a-zA-Z°]*\.?", s2):
        return float(m.group(0)), True
    return None, False


def to_int(raw: Optional[str]) -> Tuple[Optional[int], bool]:
    f, korrigiert = to_float(raw)
    if f is None:
        return None, False
    if f != int(f):
        return int(round(f)), True
    return int(f), korrigiert


def to_bool(raw: Optional[str]) -> Tuple[Optional[bool], bool]:
    s = clean(raw)
    if s is None:
        return None, False
    low = s.lower()
    if low in ("ja", "nein"):
        return low == "ja", low != s
    if low in JA:
        return True, True
    if low in NEIN:
        return False, True
    return None, False


def to_list(raw: Optional[str]) -> List[str]:
    s = clean(raw)
    if s is None:
        return []
    parts = re.split(r"[,;\n]+", s)
    return [p.strip() for p in parts if p.strip()]


def to_key(raw: Optional[str]) -> Tuple[Optional[str], bool]:
    """Liste-Key: klein, getrimmt. (Wert, korrigiert)."""
    s = clean(raw)
    if s is None:
        return None, False
    k = s.lower().strip()
    return k, k != s


def split_latlon(raw: Optional[str]) -> Tuple[Optional[float], Optional[float], bool]:
    s = clean(raw)
    if s is None:
        return None, None, False
    nums = re.findall(r"-?\d+[.,]\d+|-?\d+", s)
    if len(nums) < 2:
        return None, None, False
    la = float(nums[0].replace(",", "."))
    lo = float(nums[1].replace(",", "."))
    return la, lo, ("," in s and "." not in s) or s.count(",") > 1


def to_date(raw: Optional[str]) -> Optional[str]:
    """ISO-Datum aus 22.10.2026 / 2026-10-22, sonst None."""
    s = clean(raw)
    if s is None:
        return None
    m = re.fullmatch(r"(\d{1,2})\.(\d{1,2})\.(\d{4})", s)
    if m:
        return "%s-%02d-%02d" % (m.group(3), int(m.group(2)), int(m.group(1)))
    m = re.fullmatch(r"(\d{4})-(\d{2})-(\d{2})", s)
    return s if m else None
