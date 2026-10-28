"""In-Memory-Ersatz fuer db.DB mit den Spaltenlisten der echten Tabellen (faengt Tippfehler und NOT NULL)."""
import copy
import re
import uuid
from datetime import datetime, timezone

from import_worker.db import DBFehler

COLS = {
    "trails": {"id", "name", "typ", "kurzbeschreibung", "beschreibung", "laenge_km", "dauer_min", "rundkurs",
               "markierung", "betreiber", "region", "website", "anreise", "start_name", "arten", "route",
               "start_lat", "start_lon", "start_pos", "updated_at", "tags", "form", "area", "eintritt",
               "eintritt_preise", "oeffnungszeiten", "besuchshinweise", "lebensraeume", "naturraum", "sichtbar",
               "data_version", "hoertext", "land", "bundesland", "kreis", "ort", "schutzgebiet", "source_job_id",
               "source_file_hash", "locked_fields", "field_meta"},
    "stations": {"id", "trail_id", "osm_id", "lat", "lon", "pos", "km", "reihenfolge", "titel", "thema", "kurztext",
                 "erlebnisse", "barrierefrei", "steckbrief"},
    "trail_species": {"trail_id", "species_id", "nachweis", "sortierung"},
    "images": {"id", "trail_id", "station_id", "uploader_id", "source", "status", "credit", "width", "height",
               "created_at", "mime_type", "thumb_bytes", "small_bytes", "medium_bytes", "geo_check", "caption",
               "license", "license_url", "source_url", "kind", "sort", "hash"},
    "trail_sources": {"id", "trail_id", "abschnitt", "angabe", "url", "abgerufen_am", "created_at"},
    "species_suggestions": {"id", "job_id", "trail_id", "name_de", "name_lat_guess", "nachweis", "quelle",
                            "species_id", "status", "created_at"},
    "import_jobs": {"id", "batch_id", "trail_id", "file_name", "file_hash", "storage_path", "status", "modus",
                    "stage", "priority", "attempts", "next_run_at", "locked_at", "locked_by", "template_version",
                    "parsed", "report", "proposal", "error", "error_detail", "kosten_usd", "created_by",
                    "created_at", "updated_at", "finished_at"},
    "import_batches": {"id", "name", "status", "kosten_usd", "kosten_deckel_usd", "created_by", "created_at"},
    "trail_candidates": {"id", "name", "land", "bundesland", "kreis", "ort", "quelle", "status",
                         "verworfen_grund", "notiz", "created_at", "updated_at"},
    "import_questions": {"id", "job_id", "trail_id", "field", "frage", "adressat", "person_id", "status",
                         "antwort", "created_by", "created_at", "answered_at", "updated_at"},
    "species": {"id", "name_de", "name_lat", "aliases"},
}
NOT_NULL = {
    "trails": {"id", "name", "typ", "kurzbeschreibung", "beschreibung", "rundkurs", "markierung", "betreiber",
               "region", "anreise", "start_name", "arten", "route", "tags", "form", "area", "eintritt",
               "lebensraeume", "naturraum", "locked_fields", "field_meta"},
    "stations": {"trail_id", "lat", "lon", "km", "reihenfolge", "titel", "thema", "kurztext", "erlebnisse",
                 "barrierefrei"},
    "images": {"id", "trail_id", "source", "status", "credit", "caption", "license", "license_url", "source_url",
               "sort"},
    "trail_species": {"trail_id", "species_id", "nachweis", "sortierung"},
}
REQUIRED = {"trails": ("id", "name", "typ", "route"), "stations": ("trail_id", "lat", "lon", "reihenfolge", "titel"),
            "images": ("trail_id",), "trail_species": ("trail_id", "species_id")}
DEFAULTS = {
    "trails": {"sichtbar": True, "data_version": 1, "locked_fields": [], "field_meta": {}},
    "import_jobs": {"modus": "import", "status": "wartet", "attempts": 0, "report": [], "kosten_usd": 0},
    "import_batches": {"status": "laeuft", "kosten_usd": 0},
}
UNIQUE = {"stations": ("trail_id", "reihenfolge"), "trails": ("id",), "images": ("id",),
          "trail_species": ("trail_id", "species_id")}


def _match(row, key, expr):
    v = row.get(key)
    if expr.startswith("eq."):
        from urllib.parse import unquote
        return str(v) == unquote(expr[3:]) if v is not None else False
    if expr.startswith("in.("):
        vals = [x.strip('"') for x in expr[4:-1].split(",")] if len(expr) > 5 else []
        return str(v) in vals
    raise AssertionError("Filter nicht unterstuetzt: " + expr)


class FakeDB:
    def __init__(self):
        self.t = {k: [] for k in COLS}
        self.storage = {}
        self.events = []
        self.fail_next = []          # Liste von DBFehler, die der naechste Aufruf wirft
        self._seq = {}
        self.calls = []

    # -- Hilfen -------------------------------------------------------------
    def _check(self, table, row, partial=False):
        unknown = set(row) - COLS[table]
        if unknown:
            raise DBFehler(400, "Spalte(n) unbekannt in %s: %s" % (table, sorted(unknown)))
        for c in NOT_NULL.get(table, ()):
            if c in row and row[c] is None:
                raise DBFehler(400, "NOT NULL verletzt: %s.%s" % (table, c))
        if not partial:
            for c in REQUIRED.get(table, ()):
                if c not in row:
                    raise DBFehler(400, "NOT NULL fehlt: %s.%s" % (table, c))

    def _maybe_fail(self):
        if self.fail_next:
            raise self.fail_next.pop(0)

    def _filter(self, table, filters):
        rows = self.t[table]
        for k, expr in filters.items():
            rows = [r for r in rows if _match(r, k, expr)]
        return rows

    # -- Tabellen -------------------------------------------------------------
    def select(self, table, select="*", **filters):
        self._maybe_fail()
        order = filters.pop("_order", None)
        limit = filters.pop("_limit", None)
        rows = [copy.deepcopy(r) for r in self._filter(table, filters)]
        if order:
            col, _, d = order.partition(".")
            rows.sort(key=lambda r: (r.get(col) is None, r.get(col)), reverse=(d == "desc"))
        if limit:
            rows = rows[: int(limit)]
        return rows

    def insert(self, table, rows, upsert_on=None, ignore=False):
        self._maybe_fail()
        if rows is None or rows == []:
            return
        if isinstance(rows, dict):
            rows = [rows]
        for r in rows:
            self._check(table, r)
            key = tuple(upsert_on.split(",")) if upsert_on else UNIQUE.get(table)
            hit = None
            if key:
                hit = next((x for x in self.t[table] if all(x.get(k) == r.get(k) for k in key)), None)
            if hit is not None:
                if upsert_on and not ignore:
                    hit.update(copy.deepcopy(r))
                    continue
                if not upsert_on:
                    raise DBFehler(409, "duplicate key %s %s" % (table, key))
                continue
            new = {**copy.deepcopy(DEFAULTS.get(table, {})), **copy.deepcopy(r)}
            if table in ("stations", "species_suggestions", "trail_sources", "import_questions"):
                self._seq[table] = self._seq.get(table, 0) + 1
                new.setdefault("id", self._seq[table])
            if table in ("import_jobs", "import_batches"):
                new.setdefault("id", str(uuid.uuid4()))
            self.t[table].append(new)

    def patch(self, table, body, **filters):
        self._maybe_fail()
        self._check(table, body, partial=True)
        for r in self._filter(table, filters):
            r.update(copy.deepcopy(body))

    def delete(self, table, **filters):
        self._maybe_fail()
        gone = self._filter(table, filters)
        self.t[table] = [r for r in self.t[table] if r not in gone]
        if table == "stations":  # FK-Kaskade images.station_id
            ids = {r["id"] for r in gone}
            self.t["images"] = [r for r in self.t["images"] if r.get("station_id") not in ids]

    def rpc(self, name, args=None):
        self._maybe_fail()
        args = args or {}
        self.calls.append((name, args))
        if name == "claim_import_job":
            now = datetime.now(timezone.utc).isoformat()
            for j in self.t["import_jobs"]:
                if j["status"] == "wartet" and (j.get("next_run_at") or "") <= now:
                    j["status"] = "laeuft"
                    j["attempts"] += 1
                    return [copy.deepcopy(j)]
            return []
        if name == "import_log_event":
            self.events.append({"trail_id": args["p_trail"], "job_id": args["p_job"], "typ": args["p_typ"],
                                "feld": args["p_feld"], "daten": args["p_daten"]})
            return None
        if name == "find_trail_duplicates":
            return []
        if name == "import_pause_batch":
            for b in self.t["import_batches"]:
                if b["id"] == args["p_batch"]:
                    b["status"] = "pausiert"
            return None
        raise AssertionError("rpc nicht simuliert: " + name)

    # -- Storage ----------------------------------------------------------------
    def upload(self, bucket, path, data, content_type):
        self._maybe_fail()
        self.storage[(bucket, path)] = data

    def download(self, bucket, path):
        self._maybe_fail()
        if (bucket, path) not in self.storage:
            raise DBFehler(404, "Object not found " + path)
        return self.storage[(bucket, path)]

    def remove(self, bucket, paths):
        for p in paths:
            self.storage.pop((bucket, p), None)

    # -- Testhilfen ----------------------------------------------------------------
    def neuer_job(self, zip_bytes, name="x.zip", hash_=None, batch=None):
        import hashlib
        h = hash_ or hashlib.sha256(zip_bytes).hexdigest()
        self.storage[("imports", h + ".zip")] = zip_bytes
        jid = str(uuid.uuid4())
        self.t["import_jobs"].append({
            "id": jid, "batch_id": batch, "trail_id": None, "file_name": name, "file_hash": h,
            "storage_path": h + ".zip", "status": "wartet", "modus": "import", "attempts": 0, "report": [],
            "kosten_usd": 0, "next_run_at": "2000-01-01T00:00:00+00:00", "created_at": "2000-01-01"})
        return jid

    def job(self, jid):
        return next(j for j in self.t["import_jobs"] if j["id"] == jid)

    def trail(self, slug):
        return next((r for r in self.t["trails"] if r["id"] == slug), None)
