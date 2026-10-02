"""Scan-Check fuer Trail-Lesetexte (kurzbeschreibung, beschreibung, besuchshinweise).

Config pruefen:   python3 .cursor/skills/scan-trail/scan.py <id>
Entwurf (stdin):  python3 .cursor/skills/scan-trail/scan.py --feld kurz <<< "..."
                  --feld kurz | beschreibung | hinweise   [--id <id> fuer Doppelung/Zahlen]

Regeln: lehrpfad_app/tools/TRAIL_SCAN.md. Stimme und Wortliste: lehrpfad_app/docs/stimme.md.
Kein Ohr-Rhythmus (das macht klang.py fuer den hoertext).
Exit 0 = ok (Warnungen erlaubt), 1 = Fehler.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3] / "lehrpfad_app"
TRAILS = ROOT / "tools" / "trails"
STIMME = ROOT / "docs" / "stimme.md"
SEEDS = ROOT / "assets" / "seed"

# Feld -> (Config-Key, min Zeichen, max Zeichen, min Saetze, max Saetze, Anrede streng)
FELDER = {
    "kurz": ("kurzbeschreibung", 0, 180, 1, 3, True),
    "beschreibung": ("beschreibung", 400, 650, 1, 99, True),
    "hinweise": ("besuchshinweise", 0, 280, 1, 99, False),
}
MITTEL_MAX = 15
SATZ_MAX = 25

ABK = ["inkl.", "z. B.", "ca.", "bzw.", "ab ", "Nr.", "St.", "Dr.", "u. a.", "ggf.", "max.", "min.", "evtl."]
ANREDE_FEST = r"\b(du|dich|dir|dein|deine|deinen|deinem|deiner|euch|euer|eure|euren|eurem)\b"
ANREDE_SIE = r"(?<![.!?]\s)(?<!^)\bSie\b"
IHR = r"\bihr\b"
CHIP_WOERTER = ["Eintritt", "Rundkurs"]
GEDANKENSTRICH = r"—|\s–\s"


def stimme_liste():
    """Liest Hart- und Warnliste aus docs/stimme.md."""
    hart, warn = [], []
    for z in STIMME.read_text(encoding="utf-8").splitlines():
        for marke, ziel in (("**Hart", hart), ("**Warnung", warn)):
            if z.startswith(marke):
                rest = z.split(":**", 1)[1] if ":**" in z else ""
                rest = rest.split("Dazu")[0]
                for t in re.split(r",\s*", rest):
                    t = t.strip().strip(".").strip("„“\"").strip()
                    if t:
                        ziel.append(t)
    return hart, warn


def saetze(text):
    t = text
    for a in ABK:
        t = t.replace(a, a.replace(".", "\u2024"))
    t = re.sub(r"(\d)\.(\d)", "\\1\u2024\\2", t)
    teile = [x for x in re.split(r"(?<=[.!?])\s+", t.strip()) if x]
    return [x.replace("\u2024", ".") for x in teile]


def sechsgramme(text):
    w = re.findall(r"\w+", text.lower())
    return {" ".join(w[i:i + 6]) for i in range(len(w) - 5)}


def pruefe(feld, text, cfg):
    key, zmin, zmax, smin, smax, streng = FELDER[feld]
    fehler, warn = [], []
    sa = saetze(text)
    lang = [len(x.split()) for x in sa]
    mittel = sum(lang) / len(lang) if lang else 0
    zeichen = len(text)

    print(f"{feld}: {zeichen} Zeichen ({zmin}-{zmax}), {len(text.split())} Woerter, "
          f"{len(sa)} Saetze, Mittel {mittel:.1f}")
    for n, x in zip(lang, sa):
        print(f"  {n:3} | {x}")

    if zeichen > zmax or zeichen < zmin:
        fehler.append(f"{feld}: {zeichen} Zeichen ausserhalb {zmin}-{zmax}")
    if not smin <= len(sa) <= smax:
        fehler.append(f"{feld}: {len(sa)} Saetze ausserhalb {smin}-{smax}")
    if mittel > MITTEL_MAX:
        fehler.append(f"{feld}: mittlere Satzlaenge {mittel:.1f} > {MITTEL_MAX}")
    for n, x in zip(lang, sa):
        if n > SATZ_MAX:
            fehler.append(f"{feld}: Satz mit {n} Woertern > {SATZ_MAX}: {x[:50]}...")

    # Namen sind von der Wortliste ausgenommen
    ohne_name = text
    if cfg and cfg.get("name"):
        ohne_name = ohne_name.replace(cfg["name"], "")

    if streng:
        m = re.findall(ANREDE_FEST, text, re.I)
        if m:
            fehler.append(f"{feld}: Anrede {sorted(set(x.lower() for x in m))}")
        if re.search(ANREDE_SIE, text):
            fehler.append(f"{feld}: Anrede 'Sie'")
        if re.search(IHR, text, re.I):
            warn.append(f"{feld}: 'ihr' pruefen (Anrede oder Besitz)")
    if re.search(GEDANKENSTRICH, text):
        fehler.append(f"{feld}: Gedankenstrich als Konnektor")
    if re.search(r"!", text):
        fehler.append(f"{feld}: Ausrufezeichen")

    hart, weich = stimme_liste()
    for w in hart:
        if re.search(r"\b" + re.escape(w), ohne_name, re.I):
            fehler.append(f"{feld}: Wortliste hart: '{w}'")
    for w in weich:
        if re.search(r"\b" + re.escape(w), ohne_name, re.I):
            warn.append(f"{feld}: Wortliste Warnung (nur mit Beleg): '{w}'")

    if feld == "kurz":
        for w in CHIP_WOERTER:
            if re.search(r"\b" + w, text):
                warn.append(f"kurz: '{w}' ist schon ein Chip im Header")

    if cfg:
        gegen = {k: v for k, v in cfg.items() if isinstance(v, str) and k != key}
        hoer = cfg.get("hoertext") or ""
        if hoer:
            if text.strip() and text.strip() in hoer:
                fehler.append(f"{feld}: wortgleich Teil des hoertext")
            gemein = sechsgramme(text) & sechsgramme(hoer)
            if gemein:
                fehler.append(f"{feld}: gleiche Wortfolge wie hoertext: '{sorted(gemein)[0]}'")
        if feld == "beschreibung":
            kurz = cfg.get("kurzbeschreibung") or ""
            gemein = sechsgramme(text) & sechsgramme(kurz)
            if gemein:
                fehler.append(f"beschreibung: gleiche Wortfolge wie kurzbeschreibung: '{sorted(gemein)[0]}'")
        korpus = json.dumps({k: v for k, v in cfg.items() if k != key}, ensure_ascii=False)
        extra = []
        if cfg.get("laengeKm"):
            extra.append(str(round(cfg["laengeKm"] * 1000)))
        korpus += " " + " ".join(extra)
        for z in sorted(set(re.findall(r"\d[\d.,]*\d|\d", text))):
            if z not in korpus and z.replace(".", "") not in korpus:
                warn.append(f"{feld}: Zahl {z} steht in keinem anderen Config-Feld")
        del gegen
    return fehler, warn


def main():
    args = sys.argv[1:]
    feld = args[args.index("--feld") + 1] if "--feld" in args else None
    tid = args[args.index("--id") + 1] if "--id" in args else None
    if feld is None and args:
        tid = args[0]
    if tid is None and feld is None:
        print(__doc__)
        sys.exit(2)

    cfg = None
    if tid:
        p = TRAILS / f"{tid}.json"
        if not p.exists():
            print(f"Config fehlt: {p}")
            sys.exit(2)
        cfg = json.loads(p.read_text(encoding="utf-8"))
        # Seed-only Trails (z. B. kollhorst): Texte stehen nur im Seed.
        sp = SEEDS / f"{tid}.json"
        if "beschreibung" not in cfg and sp.exists():
            cfg = {**json.loads(sp.read_text(encoding="utf-8")), **cfg}

    fehler, warn = [], []
    if feld:
        if feld not in FELDER:
            print(f"Feld unbekannt: {feld} ({', '.join(FELDER)})")
            sys.exit(2)
        text = sys.stdin.read().strip()
        f, w = pruefe(feld, text, cfg)
        fehler += f
        warn += w
    else:
        for fe, (key, *_rest) in FELDER.items():
            text = (cfg.get(key) or "").strip()
            if not text:
                if fe != "hinweise":
                    fehler.append(f"{key} fehlt")
                continue
            f, w = pruefe(fe, text, cfg)
            fehler += f
            warn += w
            print()

    for w in warn:
        print("WARN ", w)
    for f in fehler:
        print("FEHLER", f)
    if not fehler:
        print("gruen" + (" (mit Warnungen)" if warn else ""))
    sys.exit(1 if fehler else 0)


if __name__ == "__main__":
    main()
