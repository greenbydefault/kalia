"""Queue-Worker: claim_import_job -> Job verarbeiten -> Ergebnis zurueckschreiben.

Fehlerbehandlung
  ImportFehler        dauerhaft (kaputtes ZIP, Dossier unlesbar): sofort 'fehlgeschlagen', Klartext
  DBFehler transient  Retry nach 30 s / 2 min / 10 min, danach 'fehlgeschlagen'
  sonstige Ausnahmen  wie transient, Traceback in error_detail
Validate/Apply-Laeufe kippen nie in 'fehlgeschlagen' (der Entwurf bleibt benutzbar), sie melden den Fehler am Job.
Idempotenz: Slug + uuid5-Bild-IDs + Upserts; ein erneuter Lauf desselben Jobs ueberschreibt nur sich selbst.
"""
from __future__ import annotations

import os
import socket
import tempfile
import threading
import time
import traceback
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from typing import Any, Callable, Dict, List, Optional

from . import config, pipeline, write
from .ai import KI
from .db import DB, DBFehler, eq
from .lookups import DBLookups
from .pipeline import ImportFehler

FERTIG = ("angelegt", "verworfen", "fehlgeschlagen")
RUECKFALL = {"validate": "bereit", "apply": "vorschlag"}


def _now() -> datetime:
    return datetime.now(timezone.utc)


class Worker:
    def __init__(self, db: DB, name: Optional[str] = None, workers: int = config.PARALLELITAET,
                 poll: float = 5.0, log: Callable[[str], None] = print, ki_factory=None):
        self.db = db
        self.lookups = DBLookups(db)
        self.name = name or "%s-%d" % (socket.gethostname(), os.getpid())
        self.workers = workers
        self.poll = poll
        self.log = log
        self.ki_factory = ki_factory or KI
        self._stop = threading.Event()

    # -- Schleife ----------------------------------------------------------
    def claim(self) -> Optional[Dict[str, Any]]:
        rows = self.db.rpc("claim_import_job", {"p_worker": self.name, "p_timeout_seconds": 900})
        if isinstance(rows, list):
            return rows[0] if rows else None
        return rows or None

    def stop(self) -> None:
        self._stop.set()

    def run(self, once: bool = False) -> int:
        """Gibt die Zahl verarbeiteter Jobs zurueck."""
        zaehler = [0]
        lock = threading.Lock()

        def loop() -> None:
            while not self._stop.is_set():
                try:
                    job = self.claim()
                except DBFehler as e:
                    self.log("claim fehlgeschlagen: %s" % e)
                    job = None
                if job is None:
                    if once:
                        return
                    time.sleep(self.poll)
                    continue
                self.process(job)
                with lock:
                    zaehler[0] += 1

        with ThreadPoolExecutor(max_workers=self.workers) as ex:
            for _ in range(self.workers):
                ex.submit(loop)
        return zaehler[0]

    # -- Job ----------------------------------------------------------------
    def process(self, job: Dict[str, Any]) -> None:
        modus = job.get("modus") or "import"
        t0 = time.time()
        self.log("[%s] %s (%s) Versuch %s" % (job["id"][:8], job["file_name"], modus, job.get("attempts")))
        ki = self._ki(job)
        try:
            if modus == "validate":
                res = self._validate(job, ki)
            elif modus == "apply":
                res = self._apply(job)
            else:
                res = self._import(job, ki)
            self._finish(job, res, ki)
            self.log("[%s] %s in %.1f s" % (job["id"][:8], res["status"], time.time() - t0))
        except ImportFehler as e:
            self._fail(job, str(e), None, dauerhaft=True, ki=ki)
        except DBFehler as e:
            self._fail(job, "Datenbank/Netz: %s" % e, traceback.format_exc(), dauerhaft=not e.transient, ki=ki)
        except Exception as e:  # noqa: BLE001
            self._fail(job, "Unerwarteter Fehler: %s" % e, traceback.format_exc(), dauerhaft=False, ki=ki)
        self._pruefe_batch(job.get("batch_id"))

    # -- KI-Budget -------------------------------------------------------
    def _ki(self, job: Dict[str, Any]) -> KI:
        deckel = config.KI_KOSTEN_DECKEL_USD_BATCH
        spent = 0.0
        if job.get("batch_id"):
            b = self.db.select("import_batches", "kosten_deckel_usd", id=eq(job["batch_id"]))
            if b and b[0].get("kosten_deckel_usd") is not None:
                deckel = float(b[0]["kosten_deckel_usd"])
            spent = sum(float(r.get("kosten_usd") or 0) for r in self.db.select(
                "import_jobs", "id,kosten_usd", batch_id=eq(job["batch_id"])) if r["id"] != job["id"])
        rest = deckel - spent
        return self.ki_factory(aktiv=(config.KI_AKTIV and rest > 0), deckel_usd=max(rest, 0.0))

    # -- Modi ------------------------------------------------------------------
    def _import(self, job: Dict[str, Any], ki: KI) -> Dict[str, Any]:
        path = job["storage_path"]
        if path.startswith(config.BUCKET_IMPORTS + "/"):
            path = path[len(config.BUCKET_IMPORTS) + 1:]
        data = self.db.download(config.BUCKET_IMPORTS, path)
        with tempfile.TemporaryDirectory(prefix="kalia-import-") as tmp:
            root = pipeline.entpacken(data, tmp)
            draft = pipeline.build_draft(root, self.lookups, ki)
            slug = draft["trail"]["id"]
            alt = self._alter_report(slug, job["id"])
            res = write.schreibe(self.db, self.lookups, job, draft, alt)
        res["parsed"] = pipeline.fuer_speicher(draft)
        res["template_version"] = draft["meta"].get("template_version")
        return res

    def _alter_report(self, slug: str, job_id: str) -> List[Dict[str, Any]]:
        rows = self.db.select("import_jobs", "id,report", trail_id=eq(slug), _order="created_at.desc", _limit=5)
        for r in rows:
            if r["id"] != job_id and r.get("report"):
                return r["report"]
        return []

    def _validate(self, job: Dict[str, Any], ki: KI) -> Dict[str, Any]:
        slug = job.get("trail_id")
        state = self.lookups.state(slug) if slug else None
        if not state:
            raise ImportFehler("Der Pfad existiert nicht mehr in der Datenbank.")
        report = pipeline.validate_state(state, job.get("report") or [], self.lookups, ki)
        offen = self.db.select("import_questions", "id", job_id=eq(job["id"]), status=eq("offen"))
        return {"status": "wartet_auf_klaerung" if offen else "bereit", "trail_id": slug, "report": report,
                "aktion": "validiert"}

    def _apply(self, job: Dict[str, Any]) -> Dict[str, Any]:
        if not job.get("proposal"):
            raise ImportFehler("Kein Änderungsvorschlag vorhanden.")
        return write.wende_an(self.db, self.lookups, job)

    # -- Ergebnis ---------------------------------------------------------------
    def _finish(self, job: Dict[str, Any], res: Dict[str, Any], ki: KI) -> None:
        body: Dict[str, Any] = {
            "status": res["status"], "modus": "import", "stage": "fertig", "error": res.get("error"),
            "error_detail": None, "locked_at": None, "locked_by": None,
            "kosten_usd": round(float(job.get("kosten_usd") or 0) + ki.kosten, 4),
        }
        if "trail_id" in res:
            body["trail_id"] = res["trail_id"]
        if res.get("report") is not None:
            body["report"] = res["report"]
        if "proposal" in res and res["proposal"] is not None:
            body["proposal"] = res["proposal"]
        if res.get("parsed") is not None:
            body["parsed"] = res["parsed"]
        if res.get("template_version") is not None:
            body["template_version"] = res["template_version"]
        if res["status"] in FERTIG:
            body["finished_at"] = _now().isoformat()
        self.db.patch("import_jobs", body, id=eq(job["id"]))
        if job.get("batch_id") and ki.kosten:
            self._batch_kosten(job["batch_id"])
        if ki.events:
            write.event(self.db, res.get("trail_id") or job.get("trail_id"), job["id"], "ki", None,
                        {"aufrufe": ki.aufrufe, "kosten_usd": round(ki.kosten, 6), "modell": ki.modell,
                         "felder": sorted({e["feld"] for e in ki.events})})

    def _batch_kosten(self, batch_id: str) -> None:
        summe = sum(float(r.get("kosten_usd") or 0) for r in
                    self.db.select("import_jobs", "id,kosten_usd", batch_id=eq(batch_id)))
        self.db.patch("import_batches", {"kosten_usd": round(summe, 4)}, id=eq(batch_id))

    def _fail(self, job: Dict[str, Any], text: str, detail: Optional[str], dauerhaft: bool, ki: KI) -> None:
        modus = job.get("modus") or "import"
        attempts = int(job.get("attempts") or 1)
        self.log("[%s] Fehler: %s" % (job["id"][:8], text))
        base = {"locked_at": None, "locked_by": None, "error": text, "error_detail": detail,
                "kosten_usd": round(float(job.get("kosten_usd") or 0) + ki.kosten, 4)}
        if modus in RUECKFALL:
            self.db.patch("import_jobs", {**base, "status": RUECKFALL[modus], "modus": "import"}, id=eq(job["id"]))
            return
        if not dauerhaft and attempts <= len(config.RETRY_SEKUNDEN):
            wait = config.RETRY_SEKUNDEN[attempts - 1]
            self.db.patch("import_jobs", {**base, "status": "wartet",
                                          "next_run_at": (_now() + timedelta(seconds=wait)).isoformat(),
                                          "error": "%s (neuer Versuch in %d s)" % (text, wait)},
                          id=eq(job["id"]))
            return
        self.db.patch("import_jobs", {**base, "status": "fehlgeschlagen",
                                      "finished_at": _now().isoformat()}, id=eq(job["id"]))

    # -- Batch-Abbruch -----------------------------------------------------------
    def _pruefe_batch(self, batch_id: Optional[str]) -> None:
        if not batch_id:
            return
        try:
            rows = self.db.select("import_jobs", "status", batch_id=eq(batch_id))
            fertig = [r for r in rows if r["status"] not in ("wartet", "laeuft")]
            if len(fertig) < config.BATCH_MIN_JOBS:
                return
            fehl = sum(1 for r in fertig if r["status"] == "fehlgeschlagen")
            if fehl / len(fertig) > config.BATCH_ABBRUCH_FEHLERQUOTE:
                b = self.db.select("import_batches", "status", id=eq(batch_id))
                if b and b[0]["status"] == "laeuft":
                    self.db.rpc("import_pause_batch", {"p_batch": batch_id, "p_pause": True})
                    self.log("Batch %s pausiert: %d von %d fehlgeschlagen" % (batch_id[:8], fehl, len(fertig)))
        except DBFehler:
            pass
