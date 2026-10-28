import io
import os

from PIL import Image

from import_worker import images
from import_worker.geometry_source import find_file


def _jpg(path, size=(3000, 2000), exif_gps=None, orientation=None, color=(90, 140, 70)):
    im = Image.new("RGB", size, color)
    exif = Image.Exif()
    if orientation:
        exif[0x0112] = orientation
    if exif_gps:
        la, lo = exif_gps
        def dms(v):
            v = abs(v)
            d = int(v); m = int((v - d) * 60); s = (v - d - m / 60) * 3600
            return (d, m, s)
        exif[0x8825] = {1: "N" if la >= 0 else "S", 2: dms(la), 3: "E" if lo >= 0 else "W", 4: dms(lo)}
    im.save(path, quality=90, exif=exif)
    return path


def test_varianten_kanten_und_hash(tmp_path):
    p = _jpg(str(tmp_path / "a.jpg"))
    v = images.make_variants(p)
    for name, edge in (("thumb", 480), ("small", 900), ("medium", 2000)):
        im = Image.open(io.BytesIO(v[name]))
        assert im.format == "AVIF"
        assert max(im.size) == edge
        assert abs(im.size[0] / im.size[1] - 1.5) < 0.01          # kein Crop
    import hashlib
    assert v["hash"] == hashlib.sha256(v["medium"]).hexdigest()


def test_kein_hochskalieren(tmp_path):
    p = _jpg(str(tmp_path / "k.jpg"), size=(600, 400))
    v = images.make_variants(p)
    assert max(Image.open(io.BytesIO(v["medium"])).size) == 600
    assert max(Image.open(io.BytesIO(v["small"])).size) == 600
    assert max(Image.open(io.BytesIO(v["thumb"])).size) == 480


def test_exif_orientierung_wird_angewendet(tmp_path):
    p = _jpg(str(tmp_path / "o.jpg"), size=(3000, 2000), orientation=6)   # 90 Grad
    v = images.make_variants(p)
    w, h = Image.open(io.BytesIO(v["medium"])).size
    assert h > w
    assert not Image.open(io.BytesIO(v["medium"])).getexif()          # EXIF entfernt


def test_gps_und_geo_check(tmp_path):
    p = _jpg(str(tmp_path / "g.jpg"), exif_gps=(53.0005, 13.0))
    v = images.make_variants(p)
    assert abs(v["gps"][0] - 53.0005) < 1e-3
    route = [[53.0, 13.0], [53.001, 13.0]]
    assert images.geo_check(v["gps"], route, [], False) == "match"
    assert images.geo_check((53.01, 13.0), route, [], False) == "near"
    assert images.geo_check((54.0, 13.0), route, [], False) == "far"
    assert images.geo_check(None, route, [], False) == "none"
    assert images.geo_check((53.0, 13.0), [], [], False) == "none"


def test_id_stabil_und_unabhaengig_von_endung():
    a = images.image_id("pfad", "01-teich.jpg")
    assert a == images.image_id("pfad", "bilder/01-teich.png")
    assert a != images.image_id("anderer", "01-teich.jpg")
    # gleiche ID wie tools/upload_catalog_media.py fuer pressel/01-teich
    import uuid
    ns = uuid.UUID("6f1c1d5e-0a5b-4f43-9a6a-1e6f2b8f0c11")
    assert a == str(uuid.uuid5(ns, "pfad/01-teich"))


def test_lizenz_status():
    assert images.lizenz_status("cc-by-4.0") == "approved"
    assert images.lizenz_status("eigen") == "approved"
    assert images.lizenz_status("freigabe") == "pending"
    assert images.lizenz_status("") == "pending"
    assert images.lizenz_status(None) == "pending"
    assert images.lizenz_status("komoot") == "pending"


def test_process_bilder(tmp_path):
    root = tmp_path / "pfad"
    (root / "bilder").mkdir(parents=True)
    _jpg(str(root / "bilder" / "01.jpg"), size=(1200, 800))
    _jpg(str(root / "bilder" / "02.jpg"), size=(1200, 800), color=(10, 20, 30))
    rows = [
        {"sort": 1, "kind": "hero", "datei": "01.jpg", "license": "cc0", "caption": "A"},
        {"sort": 2, "kind": "station", "station_reihenfolge": 3, "datei": "02.jpg", "license": None},
        {"sort": 3, "kind": "hero", "datei": "fehlt.jpg", "license": "cc0"},
        {"sort": 4, "kind": "hero", "datei": "", "license": "cc0"},
    ]
    r = images.process_bilder(str(root), "pfad", rows, [], [], False, find_file)
    assert [x["status"] for x in r["bilder"]] == ["approved", "pending"]
    assert r["bilder"][0]["kind"] == "ort" and r["bilder"][1]["kind"] == "station"
    assert r["bilder"][1]["station_reihenfolge"] == 3
    codes = sorted(i["code"] for i in r["issues"])
    assert codes == ["BILD_LIZENZ", "DATEI_FEHLT", "DATEI_FEHLT"]


def test_unlesbares_bild(tmp_path):
    root = tmp_path / "pfad"
    root.mkdir()
    (root / "x.jpg").write_bytes(b"kein bild")
    r = images.process_bilder(str(root), "pfad", [{"datei": "x.jpg", "license": "cc0"}], [], [], False, find_file)
    assert r["bilder"] == [] and r["issues"][0]["code"] == "BILD_DATEI"
