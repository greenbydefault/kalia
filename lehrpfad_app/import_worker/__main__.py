"""CLI: python3 -m import_worker <befehl>   (aus lehrpfad_app/)"""
from __future__ import annotations

import argparse
import hashlib
import json
import time
import os
import shutil
import sys
import tempfile
from typing import List

from . import candidates as cand, config, dossier_builder, messages, pipeline, rules
from .ai import KI
from .lookups import DBLookups, OfflineLookups

SYMBOL = {"hart": "✗", "uebersteuerbar": "!", "warnung": "·"}


def _db():
    from .db import DB
    return DB()


def _root_von(pfad: str, tmp: str) -> str:
    if os.path.isdir(pfad):
        return pfad
    with open(pfad, "rb") as f:
        return pipeline.entpacken(f.read(), tmp)


def cmd_check(a) -> int:
    lookups = DBLookups(_db()) if a.db else OfflineLookups()
    ki = KI(aktiv=bool(a.ki) and config.KI_AKTIV)
    exit_code = 0
    for pfad in a.pfade:
        with tempfile.TemporaryDirectory(prefix="kalia-check-") as tmp:
            try:
                d = pipeline.build_draft(_root_von(pfad, tmp), lookups, ki)
            except pipeline.ImportFehler as e:
                print("%s\n  ✗ %s" % (pfad, e))
                exit_code = 1
                continue
        b = rules.blockiert(d["report"])
        print("%s  (%s, %d Stationen, %d Arten, %d Bilder)  hart %d · übersteuerbar %d"
              % (d["trail"]["id"], d["trail"].get("form"), len(d["stationen"]), len(d["arten"]),
                 len(d["bilder"]), b["hart"], b["uebersteuerbar"]))
        for e in sorted(d["report"], key=lambda x: ("hart", "uebersteuerbar", "warnung").index(x["severity"])):
            if e["code"] == "FORM" and not a.alle:
                continue
            m = messages.render(e)
            print("  %s %-24s %s" % (SYMBOL[e["severity"]], e["code"], m["was"]))
        if b["hart"]:
            exit_code = 1
    return exit_code


def cmd_enqueue(a) -> int:
    db = _db()
    batch = db.rpc("import_batch_create", {"p_name": a.batch or ""}) if a.batch is not None or len(a.pfade) > 1 else None
    if batch:
        print("Batch %s" % batch)
    for pfad in a.pfade:
        with tempfile.TemporaryDirectory(prefix="kalia-enqueue-") as tmp:
            if os.path.isdir(pfad):
                zp = dossier_builder.zip_folder(os.path.abspath(pfad), os.path.join(tmp, os.path.basename(pfad.rstrip("/")) + ".zip"))
                name = os.path.basename(zp)
            else:
                zp, name = pfad, os.path.basename(pfad)
            data = open(zp, "rb").read()
        h = hashlib.sha256(data).hexdigest()
        db.upload(config.BUCKET_IMPORTS, h + ".zip", data, "application/zip")
        r = db.rpc("import_enqueue", {"p_file_name": name, "p_file_hash": h, "p_storage_path": h + ".zip",
                                      "p_batch": batch, "p_priority": a.priority})
        print("%-50s %s %s" % (name, r.get("status"), r.get("job_id", "")))
    return 0


def cmd_run(a) -> int:
    from .worker import Worker
    w = Worker(_db(), workers=a.workers, poll=a.poll)
    try:
        n = w.run(once=a.once)
    except KeyboardInterrupt:
        w.stop()
        return 0
    print("%d Jobs verarbeitet" % n)
    return 0


def cmd_candidates(a) -> int:
    rows = cand.lade_alle(a.ordner)
    print("%d Kandidaten gefunden" % len(rows))
    if a.dry_run:
        return 0
    db = _db()
    have = {r["id"] for r in db.select("trail_candidates", "id", _limit=100000)}
    neu = [r for r in rows if r["id"] not in have]
    for i in range(0, len(neu), 200):
        db.insert("trail_candidates", neu[i:i + 200], upsert_on="id", ignore=True)
    print("%d neu angelegt, %d vorhanden (Status bleibt)" % (len(neu), len(rows) - len(neu)))
    return 0


def cmd_stats(a) -> int:
    s = _db().rpc("import_batch_stats", {"p_batch": a.batch})
    print("Jobs %(jobs)s · bereit %(bereit)s · angelegt %(angelegt)s · fehlgeschlagen %(fehlgeschlagen)s" % s)
    for m in s["meldungen"]:
        titel = messages.CODES.get(m["code"], {}).get("titel", "")
        print("  %5.1f %%  %-4s %-24s %s" % (m["prozent"], SYMBOL.get(m["severity"], "?"), m["code"], titel))
    return 0


def cmd_pilot(a) -> int:
    """Seeds -> Dossiers -> Parser + Regeln (offline). Meldungen x Haeufigkeit, wie `stats` auf dem Live-Batch."""
    import glob
    from collections import Counter
    def ist_trail(p: str) -> bool:
        try:
            with open(p, encoding="utf-8") as f:
                j = json.load(f)
        except ValueError:
            return False
        return isinstance(j, dict) and "stationen" in j and ("route" in j or "area" in j)

    seeds = sorted(p for p in glob.glob(os.path.join(dossier_builder.SEED_DIR, "*.json")) if ist_trail(p))
    if a.ids:
        seeds = [p for p in seeds if os.path.basename(p)[:-5] in a.ids]
    elif a.n:
        # gleichmaessig ueber die Liste streuen statt die ersten n
        step = max(1, len(seeds) // a.n)
        seeds = seeds[::step][:a.n]
    lookups = OfflineLookups()
    codes: Counter = Counter()
    sev: dict = {}
    fehler, hart_pfade, laufzeit = [], [], []
    for sp in seeds:
        slug = os.path.basename(sp)[:-5]
        with tempfile.TemporaryDirectory(prefix="kalia-pilot-") as tmp:
            try:
                root = dossier_builder.build_package(sp, os.path.join(tmp, slug), {})
                t0 = time.time()
                d = pipeline.build_draft(root, lookups, KI(aktiv=False))
                laufzeit.append(time.time() - t0)
            except Exception as e:  # noqa: BLE001 - Pilot soll alles melden, nie abbrechen
                fehler.append((slug, str(e)[:160]))
                continue
        for c in {e["code"] for e in d["report"]}:
            codes[c] += 1
        for e in d["report"]:
            sev[e["code"]] = e["severity"]
        if rules.blockiert(d["report"])["hart"]:
            hart_pfade.append(slug)
    n = len(seeds)
    print("%d Seeds · %d ohne Absturz · Parse+Regeln im Schnitt %.2f s" %
          (n, n - len(fehler), sum(laufzeit) / max(1, len(laufzeit))))
    for code, k in codes.most_common():
        print("  %5.1f %%  %-4s %-24s %s" % (100.0 * k / n, SYMBOL.get(sev[code], "?"), code,
                                            messages.CODES.get(code, {}).get("titel", "")))
    if hart_pfade:
        print("Harte Fehler bei: %s" % ", ".join(hart_pfade))
    for slug, msg in fehler:
        print("Absturz %s: %s" % (slug, msg))
    return 1 if fehler else 0


def cmd_dossier(a) -> int:
    opts = json.loads(a.opts) if a.opts else {}
    folder = dossier_builder.build_package(a.seed, a.out, opts)
    print(folder)
    return 0


def main(argv: List[str] = None) -> int:
    p = argparse.ArgumentParser(prog="import_worker")
    sp = p.add_subparsers(dest="cmd", required=True)

    c = sp.add_parser("check", help="Dossier parsen und prüfen, schreibt nichts")
    c.add_argument("pfade", nargs="+")
    c.add_argument("--db", action="store_true", help="Arten und Duplikate gegen die Datenbank prüfen")
    c.add_argument("--ki", action="store_true", help="KI-Rückfall erlauben (ANTHROPIC_API_KEY)")
    c.add_argument("--alle", action="store_true", help="auch FORM-Hinweise zeigen")
    c.set_defaults(fn=cmd_check)

    e = sp.add_parser("enqueue", help="ZIP/Ordner hochladen und Jobs anlegen")
    e.add_argument("pfade", nargs="+")
    e.add_argument("--batch", default=None, help="Batch-Name (mehrere Dateien = automatisch ein Batch)")
    e.add_argument("--priority", type=int, default=0)
    e.set_defaults(fn=cmd_enqueue)

    r = sp.add_parser("run", help="Queue abarbeiten")
    r.add_argument("--once", action="store_true", help="beenden, wenn die Queue leer ist")
    r.add_argument("--workers", type=int, default=config.PARALLELITAET)
    r.add_argument("--poll", type=float, default=5.0)
    r.set_defaults(fn=cmd_run)

    k = sp.add_parser("candidates", help="trail_candidates aus _kandidaten.md")
    k.add_argument("ordner", nargs="?", default="research/Länder")
    k.add_argument("--dry-run", action="store_true")
    k.set_defaults(fn=cmd_candidates)

    s = sp.add_parser("stats", help="Meldungen × Häufigkeit je Batch")
    s.add_argument("batch")
    s.set_defaults(fn=cmd_stats)

    pl = sp.add_parser("pilot", help="Seeds -> Dossiers -> Parser + Regeln (offline), Meldungen x Häufigkeit")
    pl.add_argument("-n", type=int, default=0, help="Anzahl, gleichmäßig gestreut (0 = alle)")
    pl.add_argument("ids", nargs="*", help="Seed-IDs statt Stichprobe")
    pl.set_defaults(fn=cmd_pilot)

    d = sp.add_parser("dossier", help="Dossier-Paket aus einem Seed bauen (Round-Trip, Tests)")
    d.add_argument("seed")
    d.add_argument("out")
    d.add_argument("--opts", default=None, help="JSON mit Builder-Optionen")
    d.set_defaults(fn=cmd_dossier)

    a = p.parse_args(argv)
    return a.fn(a)


if __name__ == "__main__":
    sys.exit(main())
