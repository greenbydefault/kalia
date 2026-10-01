"""Klang-Check fuer hoertext. Text auf stdin, Ausgabe pro Satz.

Trail:     python3 ../.cursor/skills/audio-trail/klang.py <<< "…"
Flora/Fauna: python3 ../.cursor/skills/audio-trail/klang.py --art <id> <<< "…"
"""
import glob
import json
import re
import sys
from pathlib import Path

SCHWACH = {"ist", "sind", "war", "hat", "haben", "gibt", "geht", "gehen",
           "macht", "machen", "kommt", "liegt", "steht"}
ANREDE = r"\b(ihr|euch|euer|eure|du|dich|dir|dein|deine|sie können)\b"

SEED = Path(__file__).resolve().parents[3] / "lehrpfad_app" / "assets" / "seed"
IMPERATIV = {"schau", "hör", "horch", "tast", "zähl", "such", "bleib", "nimm",
             "lass", "vergleich", "geh", "klopf", "guck", "fass", "riech",
             "achte", "warte", "komm", "sieh", "halt", "setz", "stell", "leg",
             "dreh", "streich", "folge", "versuch", "probier", "denk", "merk"}
FLOSKEL = ["allen Sinnen", "jedes Schild", "atme mit", "genau so soll es sein",
           "Genau dafür", "einen Moment stehen"]
WOLLEN = (r"\b(will|wollen|willst|möchte|möchten|versucht|versuchen|freut|freuen"
          r"|denkt|ausgedacht|erfunden|liebt|lieben|hasst|traurig|glücklich|stolz)\b")
LANDSCHAFT = ["Deutschland", "Spreewald", "Usedom", "Rügen", "Harz", "Lausitz",
              "Uckermark", "Fläming", "Havelland", "Schorfheide", "Oderbruch",
              "Allgäu", "Eifel", "Schwarzwald", "Bayerischer Wald", "Müritz",
              "Elbe", "Havel", "Spree", "Ostsee", "Nordsee", "Katalonien"]
KEIN_ORT = {"Speck", "Forst", "Kiel"}
PRAEFIX = r"^(Landkreis|Stadt|Naturpark|Nationalpark|NP|NSG|NER|Kreis|Region|Hansestadt)\s+"


def ortsnamen():
    out = set(LANDSCHAFT)
    for f in glob.glob(str(SEED / "*.json")):
        try:
            d = json.load(open(f))
        except (ValueError, OSError):
            continue
        if not isinstance(d, dict) or "region" not in d:
            continue
        out.add(d.get("name", ""))
        for p in re.split(r"[,/]", str(d["region"])):
            p = re.sub(r"\(.*?\)", "", p).split(" OT ")[0].strip()
            p = re.sub(PRAEFIX, "", p).strip()
            if len(p) >= 4 and p not in KEIN_ORT:
                out.add(p)
    return {o for o in out if o}


art = sys.argv[sys.argv.index("--art") + 1] if "--art" in sys.argv else None
von, bis = (90, 120) if art else (70, 110)

t = sys.stdin.read().strip()
saetze = [x for x in re.split(r"(?<=[.!?])\s+", t) if x]
laengen = [len(x.split()) for x in saetze]
anfaenge = [x.split()[0].lower().strip(",") for x in saetze]

print("Woerter:", len(t.split()), f"({von}-{bis})")
for n, x in zip(laengen, saetze):
    schwach = [w for w in re.findall(r"\w+", x.lower()) if w in SCHWACH]
    print(f"{n:3} | {x.split()[0]:12} | {x}" + (f"  [schwach: {', '.join(schwach)}]" if schwach else ""))

fehler = []
if not von <= len(t.split()) <= bis:
    fehler.append(f"Wortzahl ausserhalb {von}-{bis}")
if not any(n >= 20 for n in laengen):
    fehler.append("kein langer Satz (>= 20)")
if not any(n <= 7 for n in laengen):
    fehler.append("kein kurzer Satz (<= 7)")
for i in range(len(laengen) - 2):
    if max(laengen[i:i + 3]) - min(laengen[i:i + 3]) < 4:
        fehler.append(f"Gleichtakt ab Satz {i + 1}")
doppelt = sorted({w for w in anfaenge if anfaenge.count(w) > 1})
if doppelt:
    fehler.append(f"gleiche Satzanfaenge: {doppelt}")
if any(w in ("da", "dann") for w in anfaenge):
    fehler.append("Satzanfang Da/Dann")
if re.search(ANREDE, t, re.I):
    fehler.append(f"Anrede: {re.findall(ANREDE, t, re.I)}")
if len(re.findall(r"\bman\b", t)) > 1:
    fehler.append("'man' mehr als einmal")
if re.search(r"\b(bestimmt|jedes Kind|alle Kinder)\b", t):
    fehler.append("Prognose ueber Kinder")

hinweise = []
if art:
    befehl = [w for w in anfaenge if w.strip("!?.") in IMPERATIV]
    if befehl:
        fehler.append(f"Befehl am Satzanfang: {befehl}")
    floskel = [f for f in FLOSKEL if f.lower() in t.lower()]
    if floskel:
        fehler.append(f"Floskel: {floskel}")
    orte = sorted(o for o in ortsnamen() if re.search(r"\b" + re.escape(o), t))
    if orte:
        fehler.append(f"Ortsname: {orte}")
    wollen = re.findall(WOLLEN, t, re.I)
    if wollen:
        fehler.append(f"Wollen/Fuehlen/Denken: {wollen}")
    if len(re.findall(r"\bdamit\b", t, re.I)) > 1:
        fehler.append("'damit' mehr als einmal")
    if re.search(r"\bum\b[^.!?]*\bzu\b", t, re.I):
        hinweise.append("'um … zu': Zweck oder Wirkung? Wirkung im Praesens ist besser")

    eintraege = json.load(open(SEED / "species.json"))
    eintraege = eintraege if isinstance(eintraege, list) else eintraege["species"]
    s = next((e for e in eintraege if e["id"] == art), None)
    if s is None:
        hinweise.append(f"'{art}' nicht im Seed: Name und Hook ungeprueft")
    else:
        erster = saetze[0].lower() if saetze else ""
        namen = [s["nameDe"]] + list(s.get("aliases") or [])
        treffer = [n for n in namen if n and n.lower() in erster]
        if treffer:
            fehler.append(f"Artname im ersten Satz: {treffer}")
        hook = s.get("content", {}).get("hook", "").lower().split()[:4]
        if hook and erster.split()[:4] == hook:
            fehler.append("erster Satz beginnt wie der Scan-Hook")

for h in hinweise:
    print("Hinweis:", h)
print("OK" if not fehler else "ROT:\n  " + "\n  ".join(fehler))
sys.exit(1 if fehler else 0)
