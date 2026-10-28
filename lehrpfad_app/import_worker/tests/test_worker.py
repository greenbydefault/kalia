import copy
import glob
import json
import os
import shutil
import tempfile

import pytest

from import_worker import dossier_builder as b, rules
from import_worker.ai import KI
from import_worker.db import DBFehler
from import_worker.worker import Worker

from .conftest import SEED_DIR
from .fakes import FakeDB


def seed(slug="naturlehrpfad-pressel"):
    with open(os.path.join(SEED_DIR, slug + ".json"), encoding="utf-8") as f:
        return json.load(f)


def zip_aus_seed(s, tmp):
    p = os.path.join(tmp, "seed_%s.json" % s["id"])
    with open(p, "w", encoding="utf-8") as f:
        json.dump(s, f)
    out = os.path.join(tmp, "out")
    folder = b.build_package(p, out)
    z = b.zip_folder(folder, os.path.join(tmp, s["id"] + ".zip"))
    shutil.rmtree(folder)
    with open(z, "rb") as f:
        return f.read()


@pytest.fixture
def tmp():
    d = tempfile.mkdtemp()
    yield d
    shutil.rmtree(d, ignore_errors=True)


def species_rows():
    with open(os.path.join(SEED_DIR, "species.json"), encoding="utf-8") as f:
        return [{"id": s["id"], "name_de": s["nameDe"], "name_lat": s.get("nameLat"),
                 "aliases": s.get("aliases", [])} for s in json.load(f)]


@pytest.fixture
def db():
    d = FakeDB()
    d.t["species"] = species_rows()
    return d


def worker(db):
    return Worker(db, name="test", workers=1, poll=0, log=lambda m: None,
                  ki_factory=lambda **kw: KI(aktiv=False, **{k: v for k, v in kw.items() if k == "deckel_usd"}))


def lauf(db):
    return worker(db).run(once=True)


def test_neuer_pfad_wird_entwurf(db, tmp):
    s = seed()
    jid = db.neuer_job(zip_aus_seed(s, tmp))
    assert lauf(db) == 1
    j = db.job(jid)
    assert j["status"] == "bereit", j.get("error")
    t = db.trail("naturlehrpfad-pressel")
    assert t["sichtbar"] is False
    assert t["source_job_id"] == jid and t["source_file_hash"] == j["file_hash"]
    assert t["land"] == "DE" and t["typ"] == s["typ"]
    assert len(t["route"]) > 10
    st = [x for x in db.t["stations"] if x["trail_id"] == t["id"]]
    assert len(st) == len(s["stationen"])
    assert db.t["trail_species"] and len(db.t["trail_species"]) == len(t["arten"])
    assert db.t["trail_sources"]
    assert j["trail_id"] == t["id"] and j["template_version"] == 3
    assert j["parsed"]["trail"]["id"] == t["id"] and "files" not in json.dumps(j["parsed"])
    assert rules.blockiert(j["report"])["hart"] == 0, [e for e in j["report"] if e["severity"] == "hart"]
    assert any(e["typ"] == "import" for e in db.events)


def test_entwurf_ersetzen_respektiert_sperren(db, tmp):
    s = seed()
    lauf_id = db.neuer_job(zip_aus_seed(s, tmp))
    lauf(db)
    t = db.trail(s["id"])
    t["locked_fields"] = ["name"]
    t["name"] = "Von Hand benannt"
    s2 = copy.deepcopy(s)
    s2["name"] = "Anderer Name"
    s2["kurzbeschreibung"] = "Neue Kurzbeschreibung."
    jid2 = db.neuer_job(zip_aus_seed(s2, tmp))
    lauf(db)
    t = db.trail(s["id"])
    assert t["name"] == "Von Hand benannt"
    assert t["kurzbeschreibung"] == "Neue Kurzbeschreibung."
    assert t["sichtbar"] is False and t["source_job_id"] == jid2
    assert any(e["typ"] == "uebersprungen" and e["feld"] == "name" for e in db.events)


def test_gesperrter_block_stationen(db, tmp):
    s = seed()
    db.neuer_job(zip_aus_seed(s, tmp))
    lauf(db)
    db.trail(s["id"])["locked_fields"] = ["stationen"]
    n = len(db.t["stations"])
    s2 = copy.deepcopy(s)
    s2["stationen"] = s2["stationen"][:3]
    db.neuer_job(zip_aus_seed(s2, tmp))
    lauf(db)
    assert len(db.t["stations"]) == n


def test_live_pfad_wird_vorschlag_und_apply(db, tmp):
    s = seed()
    db.neuer_job(zip_aus_seed(s, tmp))
    lauf(db)
    t = db.trail(s["id"])
    t["sichtbar"] = True
    alt_kurz = t["kurzbeschreibung"]
    s2 = copy.deepcopy(s)
    s2["kurzbeschreibung"] = "Neue Kurzbeschreibung."
    s2["stationen"] = s2["stationen"][:-1]
    jid = db.neuer_job(zip_aus_seed(s2, tmp))
    lauf(db)
    j = db.job(jid)
    assert j["status"] == "vorschlag", j.get("error")
    assert db.trail(s["id"])["kurzbeschreibung"] == alt_kurz           # live unveraendert
    assert "kurzbeschreibung" in j["proposal"]["felder"] and "stationen" in j["proposal"]["bloecke"]
    n_alt = len(db.t["stations"])

    # nur das Feld annehmen
    j["proposal"]["accepted"] = ["kurzbeschreibung"]
    j["modus"], j["status"] = "apply", "wartet"
    lauf(db)
    assert db.job(jid)["status"] == "angelegt"
    assert db.trail(s["id"])["kurzbeschreibung"] == "Neue Kurzbeschreibung."
    assert len(db.t["stations"]) == n_alt                              # Stationen nicht angenommen
    assert db.trail(s["id"])["sichtbar"] is True


def test_live_pfad_ohne_aenderung(db, tmp):
    s = seed()
    db.neuer_job(zip_aus_seed(s, tmp))
    lauf(db)
    db.trail(s["id"])["sichtbar"] = True
    # anderer Hash, gleicher Inhalt
    db.neuer_job(zip_aus_seed(s, tmp), hash_="andereshash")
    lauf(db)
    j = [x for x in db.t["import_jobs"] if x["file_hash"] == "andereshash"][0]
    assert j["status"] == "angelegt"
    assert any(e["typ"] == "keine_aenderung" for e in db.events)


def test_kollision_mit_fremdem_pfad(db, tmp):
    s = seed()
    db.t["trails"].append({"id": s["id"], "name": "Alt", "typ": "wald", "sichtbar": True, "source_job_id": None,
                           "locked_fields": [], "field_meta": {}})
    jid = db.neuer_job(zip_aus_seed(s, tmp))
    lauf(db)
    j = db.job(jid)
    assert j["status"] == "fehlgeschlagen" and "gehört schon zu einem anderen Pfad" in j["error"]
    assert j["trail_id"] is None
    assert db.trail(s["id"])["name"] == "Alt"
    assert not db.t["stations"]


def test_kaputtes_zip_sofort_fehlgeschlagen(db):
    jid = db.neuer_job(b"kein zip")
    lauf(db)
    j = db.job(jid)
    assert j["status"] == "fehlgeschlagen" and "ZIP" in j["error"] and j["attempts"] == 1


def test_zip_ohne_dossier(db, tmp):
    import zipfile, io
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as z:
        z.writestr("leer.txt", "x")
    jid = db.neuer_job(buf.getvalue())
    lauf(db)
    assert "kein Dossier" in db.job(jid)["error"]


def test_transienter_fehler_wird_wiederholt(db, tmp):
    s = seed()
    jid = db.neuer_job(zip_aus_seed(s, tmp))
    db.fail_next = []  # claim ok
    w = worker(db)
    job = w.claim()
    db.fail_next = [DBFehler(503, "weg")]
    w.process(job)
    j = db.job(jid)
    assert j["status"] == "wartet" and "neuer Versuch in 30 s" in j["error"]
    assert j["next_run_at"] > "2001"
    # nach dem vierten Versuch ist Schluss
    j["attempts"] = 4
    j["status"] = "laeuft"
    db.fail_next = [DBFehler(503, "weg")]
    w.process(copy.deepcopy(j))
    assert db.job(jid)["status"] == "fehlgeschlagen"


def test_validate_modus_rechnet_auf_db_stand(db, tmp):
    s = seed()
    jid = db.neuer_job(zip_aus_seed(s, tmp))
    lauf(db)
    j = db.job(jid)
    # CMS-Aenderung: Kurzbeschreibung zu lang gemacht, Name geleert
    t = db.trail(s["id"])
    t["kurzbeschreibung"] = "x" * 250
    t["name"] = ""
    j["modus"], j["status"] = "validate", "wartet"
    lauf(db)
    j = db.job(jid)
    assert j["status"] == "bereit" and j["modus"] == "import"
    codes = {(e["code"], e["feld"]) for e in j["report"]}
    assert ("TEXT_LAENGE", "kurzbeschreibung") in codes and ("PFLICHT", "name") in codes
    # Dossier-Meldungen bleiben erhalten
    t["kurzbeschreibung"], t["name"] = "ok", "Name"
    j["modus"], j["status"] = "validate", "wartet"
    lauf(db)
    codes = {(e["code"], e["feld"]) for e in db.job(jid)["report"]}
    assert ("PFLICHT", "name") not in codes and ("TEXT_LAENGE", "kurzbeschreibung") not in codes


def test_validate_behaelt_override_und_entscheidung(db, tmp):
    s = seed()
    s["stationen"] = s["stationen"][:2]
    jid = db.neuer_job(zip_aus_seed(s, tmp))
    lauf(db)
    j = db.job(jid)
    e = [x for x in j["report"] if x["code"] == "STATIONEN_MIN"]
    assert e and e[0]["severity"] == "uebersteuerbar"
    e[0]["override"] = {"reason": "kleiner Ort", "by": "u", "at": "t"}
    j["modus"], j["status"] = "validate", "wartet"
    lauf(db)
    j = db.job(jid)
    assert rules.blockiert(j["report"])["uebersteuerbar"] == 0 or all(
        x.get("override") for x in j["report"] if x["severity"] == "uebersteuerbar" and x["code"] == "STATIONEN_MIN")


def test_batch_wird_bei_hoher_fehlerquote_pausiert(db):
    bid = "b1"
    db.t["import_batches"].append({"id": bid, "status": "laeuft", "kosten_usd": 0})
    for i in range(10):
        db.neuer_job(("kaputt%d" % i).encode(), hash_="h%d" % i, batch=bid)
    lauf(db)
    assert db.t["import_batches"][0]["status"] == "pausiert"


def test_bilder_werden_hochgeladen_und_ersetzt(db, tmp):
    from PIL import Image
    s = seed()
    p = os.path.join(tmp, "s.json")
    json.dump(s, open(p, "w", encoding="utf-8"))
    out = os.path.join(tmp, "out")
    opts = {"bilder": [
        {"kind": "hero", "caption": "Teich", "datei": "teich.jpg", "license": "cc-by-4.0", "credit": "A",
         "source_url": "https://x.de/a"},
        {"kind": "station", "station": 2, "caption": "Tafel", "datei": "tafel.jpg", "license": "freigabe",
         "credit": "B"},
    ]}
    folder = b.build_package(p, out, opts)
    os.makedirs(os.path.join(folder, "bilder"))
    for n, col in (("teich.jpg", (30, 120, 60)), ("tafel.jpg", (200, 180, 60))):
        Image.new("RGB", (1200, 800), col).save(os.path.join(folder, "bilder", n), quality=85)
    z = b.zip_folder(folder, os.path.join(tmp, "p.zip"))
    jid = db.neuer_job(open(z, "rb").read())
    lauf(db)
    j = db.job(jid)
    assert j["status"] == "bereit", j.get("error")
    imgs = db.t["images"]
    assert len(imgs) == 2
    hero = [i for i in imgs if i["caption"] == "Teich"][0]
    tafel = [i for i in imgs if i["caption"] == "Tafel"][0]
    assert hero["status"] == "approved" and hero["kind"] == "ort" and hero["station_id"] is None
    assert tafel["status"] == "pending" and tafel["station_id"] is not None   # freigabe wartet auf CMS
    for v in ("thumb", "small", "medium"):
        assert ("trail-images", "%s/%s/%s.avif" % (s["id"], hero["id"], v)) in db.storage
    codes = [(e["code"], e["feld"]) for e in j["report"]]
    assert ("BILD_LIZENZ", "bilder[2]") in codes and ("BILD_FEHLT", "bilder") not in codes
    # Zweiter Lauf ohne Bilder: offizielle Bilder verschwinden samt Dateien
    s2 = copy.deepcopy(s)
    db.neuer_job(zip_aus_seed(s2, tmp))
    lauf(db)
    assert db.t["images"] == []
    assert not [k for k in db.storage if k[0] == "trail-images"]


def test_stationen_mit_nutzerfoto_bleiben(db, tmp):
    s = seed()
    db.neuer_job(zip_aus_seed(s, tmp))
    lauf(db)
    letzte = max(db.t["stations"], key=lambda x: x["reihenfolge"])
    db.t["images"].append({"id": "u1", "trail_id": s["id"], "station_id": letzte["id"], "source": "user",
                           "status": "approved", "credit": "", "caption": "", "license": "", "license_url": "",
                           "source_url": "", "sort": 0})
    s2 = copy.deepcopy(s)
    s2["stationen"] = s2["stationen"][:-1]
    db.neuer_job(zip_aus_seed(s2, tmp))
    lauf(db)
    assert any(x["id"] == letzte["id"] for x in db.t["stations"])
    assert any(e["typ"] == "stationen_behalten" for e in db.events)
