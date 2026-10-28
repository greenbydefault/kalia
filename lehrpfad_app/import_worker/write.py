"""Entwurf schreiben, Re-Import mit Sperren, Vorschlag anwenden.

Faelle je Slug (aus dem Dossier):
  kein Pfad                         -> neu: trails (sichtbar=false) + Stationen, Arten, Bilder, Quellen
  Pfad aus Import, sichtbar=false   -> Entwurf ersetzen: nur nicht gesperrte Felder/Bloecke
  Pfad aus Import, sichtbar=true    -> Aenderungsvorschlag (job.status 'vorschlag'), nichts live geaendert
  Pfad ohne source_job_id           -> Kollision, Job schlaegt mit Klartext fehl (nie in fremde Pfade schreiben)

Der Worker laeuft als service_role: die Sperr-Trigger (trails.locked_fields) greifen nur bei auth.uid().
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Set

from . import config, lists, pipeline
from .db import DB, eq, in_

TEXT_NN = ("typ", "kurzbeschreibung", "beschreibung", "markierung", "betreiber", "region", "anreise",
           "start_name", "naturraum")
TRAIL_SPALTEN = (
    "name", "typ", "form", "land", "bundesland", "kreis", "ort", "schutzgebiet", "region", "betreiber",
    "website", "kurzbeschreibung", "beschreibung", "anreise", "besuchshinweise", "markierung", "start_name",
    "hoertext", "start_lat", "start_lon", "laenge_km", "dauer_min", "rundkurs", "eintritt", "eintritt_preise",
    "oeffnungszeiten", "tags", "naturraum", "lebensraeume", "route", "area", "arten",
)
STATION_SPALTEN = ("osm_id", "lat", "lon", "km", "reihenfolge", "titel", "thema", "kurztext", "erlebnisse",
                   "barrierefrei", "steckbrief")
BLOECKE = ("stationen", "arten", "bilder")
VARIANTEN = ("thumb", "small", "medium")


def jetzt() -> str:
    return datetime.now(timezone.utc).isoformat()


def trail_zeile(t: Dict[str, Any]) -> Dict[str, Any]:
    r = {k: t.get(k) for k in TRAIL_SPALTEN}
    for k in TEXT_NN:
        r[k] = r[k] or ""
    r["form"] = r["form"] or "linie"
    r["rundkurs"], r["eintritt"] = bool(r["rundkurs"]), bool(r["eintritt"])
    for k in ("tags", "lebensraeume", "arten"):
        r[k] = list(r[k] or [])
    r["route"], r["area"] = r["route"] or [], r["area"] or []
    if r["land"] not in lists.LAENDER:
        r["land"] = None
    return r


def station_zeile(slug: str, s: Dict[str, Any]) -> Dict[str, Any]:
    r = {k: s.get(k) for k in STATION_SPALTEN}
    r["trail_id"] = slug
    r["erlebnisse"] = list(r["erlebnisse"] or [])
    r["barrierefrei"] = bool(r["barrierefrei"])
    return r


def event(db: DB, slug: Optional[str], job_id: str, typ: str, feld: Optional[str] = None,
          daten: Optional[Dict[str, Any]] = None) -> None:
    db.rpc("import_log_event", {"p_trail": slug, "p_job": job_id, "p_typ": typ, "p_feld": feld,
                                "p_daten": daten or {}})


# --------------------------------------------------------------------------
# Bloecke
# --------------------------------------------------------------------------
def schreibe_stationen(db: DB, slug: str, stationen: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Upsert nach (trail_id, reihenfolge): IDs bleiben stabil. Stationen mit Nutzerfotos werden nie geloescht."""
    bestehend = db.select("stations", "id,reihenfolge", trail_id=eq(slug))
    behalten = {s["reihenfolge"] for s in stationen}
    geschuetzt: List[int] = []
    weg = [r for r in bestehend if r["reihenfolge"] not in behalten]
    if weg:
        mit_foto = {r["station_id"] for r in db.select(
            "images", "station_id", trail_id=eq(slug), source=eq("user"),
            station_id=in_([r["id"] for r in weg]))}
        for r in weg:
            if r["id"] in mit_foto:
                geschuetzt.append(r["reihenfolge"])
            else:
                db.delete("stations", id=eq(r["id"]))
    db.insert("stations", [station_zeile(slug, s) for s in stationen], upsert_on="trail_id,reihenfolge")
    return {"geschuetzt": geschuetzt}


def schreibe_arten(db: DB, slug: str, arten: List[Dict[str, Any]]) -> None:
    db.delete("trail_species", trail_id=eq(slug))
    db.insert("trail_species", [{"trail_id": slug, "species_id": a["species_id"],
                                 "nachweis": a.get("nachweis") if a.get("nachweis") in lists.NACHWEIS else "typisch",
                                 "sortierung": a.get("sortierung") or i}
                                for i, a in enumerate(arten, 1)])


def _bild_zeile(slug: str, b: Dict[str, Any], station_ids: Dict[int, int]) -> Dict[str, Any]:
    sid = station_ids.get(b.get("station_reihenfolge")) if b.get("station_reihenfolge") else None
    return {
        "id": b["id"], "trail_id": slug, "station_id": sid, "uploader_id": None,
        "source": "official", "status": b["status"], "credit": b.get("credit") or "",
        "caption": b.get("caption") or "", "license": b.get("license") or "",
        "license_url": b.get("license_url") or "", "source_url": b.get("source_url") or "",
        "kind": b.get("kind"), "sort": b.get("sort") or 0, "mime_type": b.get("mime_type"),
        "width": b.get("width"), "height": b.get("height"), "thumb_bytes": b.get("thumb_bytes"),
        "small_bytes": b.get("small_bytes"), "medium_bytes": b.get("medium_bytes"),
        "geo_check": b.get("geo_check") or "none", "hash": b.get("hash"),
    }


def _station_ids(db: DB, slug: str) -> Dict[int, int]:
    return {r["reihenfolge"]: r["id"] for r in db.select("stations", "id,reihenfolge", trail_id=eq(slug))}


def schreibe_bilder(db: DB, slug: str, bilder: List[Dict[str, Any]], dateien: str = "direkt",
                    job_id: Optional[str] = None) -> None:
    """dateien: 'direkt' (Bytes in b['files'] -> trail-images) oder 'staging' (aus imports/_vorschlag/<job>/ kopieren)."""
    station_ids = _station_ids(db, slug)
    for b in bilder:
        for v in VARIANTEN:
            ziel = "%s/%s/%s.avif" % (slug, b["id"], v)
            if dateien == "direkt":
                db.upload(config.BUCKET_TRAIL_IMAGES, ziel, b["files"][v], "image/avif")
            else:
                data = db.download(config.BUCKET_IMPORTS, "_vorschlag/%s/%s/%s.avif" % (job_id, b["id"], v))
                db.upload(config.BUCKET_TRAIL_IMAGES, ziel, data, "image/avif")
    neu_ids = {b["id"] for b in bilder}
    alt = db.select("images", "id", trail_id=eq(slug), source=eq("official"))
    for r in alt:
        if r["id"] not in neu_ids:
            db.delete("images", id=eq(r["id"]))
            db.remove(config.BUCKET_TRAIL_IMAGES,
                      ["%s/%s/%s.avif" % (slug, r["id"], v) for v in VARIANTEN])
    db.insert("images", [_bild_zeile(slug, b, station_ids) for b in bilder], upsert_on="id")


def staging_bilder(db: DB, job_id: str, bilder: List[Dict[str, Any]]) -> None:
    for b in bilder:
        for v in VARIANTEN:
            db.upload(config.BUCKET_IMPORTS, "_vorschlag/%s/%s/%s.avif" % (job_id, b["id"], v),
                      b["files"][v], "image/avif")


def schreibe_quellen(db: DB, slug: str, quellen: List[Dict[str, Any]]) -> None:
    db.delete("trail_sources", trail_id=eq(slug))
    db.insert("trail_sources", [{"trail_id": slug, "abschnitt": q["abschnitt"], "angabe": q.get("angabe") or "",
                                 "url": q.get("url") or "", "abgerufen_am": q.get("abgerufen_am") or None}
                                for q in quellen if q.get("abschnitt") is not None])


def schreibe_vorschlaege(db: DB, slug: str, job_id: str, offen: List[Dict[str, Any]]) -> None:
    db.delete("species_suggestions", trail_id=eq(slug), status=eq("offen"))
    rows = [{"job_id": job_id, "trail_id": slug, "name_de": a["name_de"],
             "name_lat_guess": a.get("name_lat_guess"),
             "nachweis": a.get("nachweis") if a.get("nachweis") in lists.NACHWEIS else "typisch",
             "quelle": a.get("quelle"), "status": "offen"} for a in offen if a.get("name_de")]
    db.insert("species_suggestions", rows)


# --------------------------------------------------------------------------
# Hauptweg
# --------------------------------------------------------------------------
def schreibe(db: DB, lookups, job: Dict[str, Any], draft: Dict[str, Any],
             alt_report: Optional[List[Dict[str, Any]]] = None) -> Dict[str, Any]:
    """-> {"status", "trail_id", "report", "proposal", "error", "aktion"}"""
    from . import rules
    trail = draft["trail"]
    slug = trail["id"]
    existing = draft.get("existing")
    report = draft["report"]
    if alt_report:
        rules.apply_overrides(report, alt_report)
        rules.carry_status(report, alt_report)

    if draft.get("slug_kollision"):
        return {"status": "fehlgeschlagen", "trail_id": None, "report": report, "proposal": None,
                "aktion": "kollision",
                "error": 'Die ID "%s" gehört schon zu einem anderen Pfad, der nicht aus einem Import stammt. '
                         "Im Dossier eine eindeutige ID eintragen und die Datei ersetzen." % slug}

    if existing is not None and existing.get("sichtbar"):
        return _vorschlag(db, job, draft, existing, report)

    gesperrt: Set[str] = set(existing.get("locked_fields") or []) if existing else set()
    zeile = trail_zeile(trail)
    meta = dict((existing or {}).get("field_meta") or {})
    meta.update({k: v for k, v in draft["field_meta"].items() if k not in gesperrt})

    if existing is None:
        db.insert("trails", {**zeile, "id": slug, "sichtbar": False, "source_job_id": job["id"],
                             "source_file_hash": job["file_hash"], "locked_fields": [], "field_meta": meta})
        aktion = "neu"
    else:
        felder = {k: v for k, v in zeile.items() if k not in gesperrt}
        db.patch("trails", {**felder, "source_job_id": job["id"], "source_file_hash": job["file_hash"],
                            "field_meta": meta}, id=eq(slug))
        aktion = "entwurf_ersetzt"
        for k in sorted(gesperrt & set(TRAIL_SPALTEN)):
            event(db, slug, job["id"], "uebersprungen", k, {"grund": "gesperrt"})

    uebersprungen = False
    if "stationen" in gesperrt:
        uebersprungen = True
        event(db, slug, job["id"], "uebersprungen", "stationen", {"grund": "gesperrt"})
    else:
        r = schreibe_stationen(db, slug, draft["stationen"])
        if r["geschuetzt"]:
            event(db, slug, job["id"], "stationen_behalten", "stationen",
                  {"reihenfolge": r["geschuetzt"], "grund": "Nutzerfotos"})
    if "arten" in gesperrt:
        uebersprungen = True
        event(db, slug, job["id"], "uebersprungen", "arten", {"grund": "gesperrt"})
    else:
        schreibe_arten(db, slug, draft["arten"])
    if "bilder" in gesperrt:
        uebersprungen = True
        event(db, slug, job["id"], "uebersprungen", "bilder", {"grund": "gesperrt"})
    else:
        schreibe_bilder(db, slug, draft["bilder"])
    schreibe_quellen(db, slug, draft["quellen"])
    schreibe_vorschlaege(db, slug, job["id"], draft["arten_offen"])
    db.patch("trail_candidates", {"status": "entwurf"}, id=eq(slug), status=in_(["offen", "dossier"]))
    event(db, slug, job["id"], "import", None, {"aktion": aktion, "datei": job.get("file_name"),
                                                 "hash": job.get("file_hash")})

    if uebersprungen or gesperrt & set(TRAIL_SPALTEN):
        # Der Report muss zum DB-Stand passen, nicht zum verworfenen Dossierwert.
        state = lookups.state(slug)
        report = pipeline.validate_state(state, report, lookups)
    return {"status": "bereit", "trail_id": slug, "report": report, "proposal": None, "error": None,
            "aktion": aktion}


# --------------------------------------------------------------------------
# Aenderungsvorschlag (Pfad ist live)
# --------------------------------------------------------------------------
def _norm(v: Any) -> Any:
    if v is None or v == "":
        return None
    if isinstance(v, float):
        return round(v, 6)
    if isinstance(v, list):
        return [_norm(x) for x in v]
    return v


def _gleich(a: Any, b: Any) -> bool:
    return json.dumps(_norm(a), sort_keys=True, default=str) == json.dumps(_norm(b), sort_keys=True, default=str)


def _kurz(v: Any) -> Any:
    """Grosse Werte (Route) im Vorschlag nur zusammenfassen."""
    if isinstance(v, list) and len(v) > 40:
        return {"punkte": len(v)}
    if isinstance(v, str) and len(v) > 2000:
        return v[:2000]
    return v


def diff_felder(existing: Dict[str, Any], zeile: Dict[str, Any], gesperrt: Set[str]) -> Dict[str, Any]:
    out: Dict[str, Any] = {}
    for k in TRAIL_SPALTEN:
        if k == "arten":
            continue
        if not _gleich(existing.get(k), zeile.get(k)):
            out[k] = {"alt": _kurz(existing.get(k)), "neu": _kurz(zeile.get(k)), "gesperrt": k in gesperrt}
    return out


def _sig_station(s: Dict[str, Any]) -> Dict[str, Any]:
    return {k: _norm(s.get(k)) for k in ("reihenfolge", "titel", "thema", "kurztext", "lat", "lon", "km",
                                          "erlebnisse", "barrierefrei")}


def diff_bloecke(state: Dict[str, Any], draft: Dict[str, Any]) -> Dict[str, Any]:
    out: Dict[str, Any] = {}
    alt = {s["reihenfolge"]: _sig_station(s) for s in state["stationen"]}
    neu = {s["reihenfolge"]: _sig_station(s) for s in draft["stationen"]}
    aenderungen = ["neu: %s" % n for n in sorted(neu.keys() - alt.keys())] + \
                  ["entfällt: %s" % n for n in sorted(alt.keys() - neu.keys())] + \
                  ["geändert: %s" % n for n in sorted(alt.keys() & neu.keys()) if alt[n] != neu[n]]
    if aenderungen:
        out["stationen"] = {"alt": len(alt), "neu": len(neu), "aenderungen": aenderungen}
    a_alt = {(a["species_id"], a.get("nachweis")) for a in state["arten"]}
    a_neu = {(a["species_id"], a.get("nachweis")) for a in draft["arten"]}
    if a_alt != a_neu:
        out["arten"] = {"alt": len(a_alt), "neu": len(a_neu),
                        "aenderungen": ["neu: %s" % s for s, _ in sorted(a_neu - a_alt)] +
                                       ["entfällt: %s" % s for s, _ in sorted(a_alt - a_neu)]}
    b_alt = {b["id"]: b.get("hash") for b in state["bilder"]}
    b_neu = {b["id"]: b.get("hash") for b in draft["bilder"]}
    if b_alt != b_neu:
        out["bilder"] = {"alt": len(b_alt), "neu": len(b_neu),
                         "aenderungen": ["neu: %s" % i[:8] for i in sorted(b_neu.keys() - b_alt.keys())] +
                                        ["entfällt: %s" % i[:8] for i in sorted(b_alt.keys() - b_neu.keys())] +
                                        ["geändert: %s" % i[:8] for i in sorted(b_alt.keys() & b_neu.keys())
                                         if b_alt[i] != b_neu[i]]}
    return out


def _vorschlag(db: DB, job: Dict[str, Any], draft: Dict[str, Any], existing: Dict[str, Any],
               report: List[Dict[str, Any]]) -> Dict[str, Any]:
    slug = draft["trail"]["id"]
    state = db_state(db, slug)
    felder = diff_felder(existing, trail_zeile(draft["trail"]), set(existing.get("locked_fields") or []))
    bloecke = diff_bloecke(state, draft)
    if not felder and not bloecke:
        event(db, slug, job["id"], "keine_aenderung", None, {"datei": job.get("file_name")})
        return {"status": "angelegt", "trail_id": slug, "report": report, "proposal": None, "error": None,
                "aktion": "keine_aenderung"}
    staging_bilder(db, job["id"], draft["bilder"])
    gespeichert = pipeline.fuer_speicher(draft)
    gespeichert.pop("roh", None)
    proposal = {"felder": felder, "bloecke": bloecke, "draft": gespeichert,
                "gesperrt": sorted(existing.get("locked_fields") or []), "erstellt": jetzt()}
    event(db, slug, job["id"], "vorschlag", None, {"felder": sorted(felder), "bloecke": sorted(bloecke)})
    return {"status": "vorschlag", "trail_id": slug, "report": report, "proposal": proposal, "error": None,
            "aktion": "vorschlag"}


def db_state(db: DB, slug: str) -> Dict[str, Any]:
    from .lookups import DBLookups
    return DBLookups(db).state(slug)


def wende_an(db: DB, lookups, job: Dict[str, Any]) -> Dict[str, Any]:
    """modus 'apply': angenommene Teile von job.proposal schreiben. Nicht angenommene bleiben unveraendert."""
    prop = job["proposal"]
    slug = job["trail_id"]
    teile = prop.get("accepted")
    felder = {k: v["neu"] for k, v in prop["felder"].items() if teile is None or k in teile}
    draft = prop["draft"]
    existing = lookups.trail(slug)
    gesperrt = set(existing.get("locked_fields") or [])

    patch: Dict[str, Any] = {}
    for k in felder:
        # Grosse Werte stehen im Vorschlag nur als Zusammenfassung: aus dem gespeicherten Draft holen
        patch[k] = trail_zeile(draft["trail"])[k]
    meta = dict(existing.get("field_meta") or {})
    if patch:
        db.patch("trails", {**patch, "source_job_id": job["id"], "source_file_hash": job["file_hash"],
                            "locked_fields": sorted(gesperrt - set(patch)), "field_meta": meta},
                 id=eq(slug))
    else:
        db.patch("trails", {"source_job_id": job["id"], "source_file_hash": job["file_hash"]}, id=eq(slug))

    block_ok = {b for b in BLOECKE if b in prop["bloecke"] and (teile is None or b in teile)}
    freigeben: Set[str] = set()
    if "stationen" in block_ok:
        schreibe_stationen(db, slug, draft["stationen"])
        freigeben.add("stationen")
    if "arten" in block_ok:
        schreibe_arten(db, slug, draft["arten"])
        freigeben.add("arten")
    if "bilder" in block_ok:
        schreibe_bilder(db, slug, draft["bilder"], dateien="staging", job_id=job["id"])
        freigeben.add("bilder")
    if freigeben:
        # Die Sperre auf angenommene Bloecke faellt weg: das Dossier gilt wieder
        neu = sorted((set((lookups.trail(slug) or {}).get("locked_fields") or [])) - freigeben)
        db.patch("trails", {"locked_fields": neu}, id=eq(slug))
    schreibe_quellen(db, slug, draft["quellen"])
    try:
        db.remove(config.BUCKET_IMPORTS, ["_vorschlag/%s/%s/%s.avif" % (job["id"], b["id"], v)
                                          for b in draft["bilder"] for v in VARIANTEN])
    except Exception:
        pass  # Aufraeumen ist kein Grund zum Scheitern
    event(db, slug, job["id"], "angewendet", None, {"felder": sorted(felder), "bloecke": sorted(block_ok)})
    return {"status": "angelegt", "trail_id": slug, "aktion": "angewendet"}
