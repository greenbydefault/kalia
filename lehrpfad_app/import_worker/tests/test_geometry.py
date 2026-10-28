import json
import os

import pytest

from import_worker import dossier_builder as b
from import_worker import geometry as g
from import_worker.geometry_source import derive_from_geometry, find_file, pick_geometry

ROUTE = [[53.0, 13.0], [53.001, 13.0], [53.001, 13.002], [53.0, 13.002], [53.0, 13.0]]


def test_laenge_und_abstand():
    km = g.length_km(ROUTE)
    assert 0.45 < km < 0.55
    assert g.distance_to_polyline_m([53.0005, 13.0], ROUTE) < 1
    assert 60 < g.distance_to_polyline_m([53.0005, 13.003], ROUTE) < 75
    area = [[53.0, 13.0], [53.001, 13.0], [53.001, 13.002], [53.0, 13.002]]
    assert g.distance_to_area_m([53.0005, 13.001], area) == 0
    assert g.distance_to_area_m([53.01, 13.001], area) > 1000


def test_gpx_lesen(tmp_path):
    p = tmp_path / "route.gpx"
    b.write_gpx(ROUTE, str(p))
    r = g.read_gpx(str(p))
    assert r[0] == [53.0, 13.0] and len(r) == 4 + 1 - 0 or len(r) >= 4


def test_gpx_zu_kurz(tmp_path):
    p = tmp_path / "x.gpx"
    p.write_text('<gpx><trk><trkseg><trkpt lat="1" lon="1"/></trkseg></trk></gpx>')
    with pytest.raises(g.GeometrieFehler):
        g.read_gpx(str(p))


def test_gpx_kaputt(tmp_path):
    p = tmp_path / "x.gpx"
    p.write_text("<gpx")
    with pytest.raises(g.GeometrieFehler):
        g.read_gpx(str(p))


def test_geojson_polygon(tmp_path):
    p = tmp_path / "f.geojson"
    p.write_text(json.dumps({"type": "Feature", "geometry": {"type": "Polygon", "coordinates": [
        [[13.0, 53.0], [13.0, 53.001], [13.002, 53.001], [13.002, 53.0], [13.0, 53.0]]]}}))
    r = g.read_geojson(str(p))
    assert len(r["area"]) == 4 and r["area"][0] == [53.0, 13.0]


def test_geojson_multipolygon_nimmt_groesstes(tmp_path):
    klein = [[13.0, 53.0], [13.0, 53.0001], [13.0001, 53.0001], [13.0, 53.0]]
    gross = [[13.0, 53.0], [13.0, 53.01], [13.01, 53.01], [13.01, 53.0], [13.0, 53.0]]
    p = tmp_path / "f.geojson"
    p.write_text(json.dumps({"type": "MultiPolygon", "coordinates": [[klein], [gross]]}))
    assert len(g.read_geojson(str(p))["area"]) == 4


def test_simplify_haelt_form():
    gerade = [[53.0 + i * 1e-5, 13.0] for i in range(500)]
    s = g.simplify(gerade, 1.5)
    assert len(s) == 2
    knick = gerade + [[53.005, 13.0 + i * 1e-5] for i in range(1, 300)]
    assert len(g.simplify(knick, 1.5)) == 3


def _meta(**kw):
    m = {"geometrie_datei": "route.gpx", "geometrie_quelle": "Eigene Aufnahme", "geometrie_lizenz": "eigen"}
    m.update(kw)
    return m


def test_pick_gpx_mit_lizenz(tmp_path):
    b.write_gpx(ROUTE, str(tmp_path / "route.gpx"))
    r = pick_geometry(str(tmp_path), "x", "linie", _meta(), osm_dir=str(tmp_path / "osm"))
    assert r["herkunft"] == "gpx" and r["lizenz"] == "eigen" and not r["issues"]


def test_pick_gpx_ohne_lizenz_faellt_auf_osm(tmp_path):
    b.write_gpx(ROUTE, str(tmp_path / "route.gpx"))
    osm = tmp_path / "osm"
    osm.mkdir()
    (osm / "x_route.json").write_text(json.dumps([[53.0, 13.0], [53.1, 13.1]]))
    r = pick_geometry(str(tmp_path), "x", "linie", _meta(geometrie_lizenz=None), osm_dir=str(osm))
    assert r["herkunft"] == "osm" and r["lizenz"] == "osm-odbl"
    assert [i["code"] for i in r["issues"]] == ["GEOMETRIE_LIZENZ"]


def test_pick_gpx_ungueltige_lizenz_ohne_osm(tmp_path):
    b.write_gpx(ROUTE, str(tmp_path / "route.gpx"))
    r = pick_geometry(str(tmp_path), "x", "linie", _meta(geometrie_lizenz="komoot"), osm_dir=str(tmp_path / "osm"))
    assert r["herkunft"] is None
    assert {i["code"] for i in r["issues"]} == {"GEOMETRIE_LIZENZ", "GEOMETRIE_FEHLT"}


def test_pick_datei_fehlt(tmp_path):
    r = pick_geometry(str(tmp_path), "x", "linie", _meta(), osm_dir=str(tmp_path / "osm"))
    assert {i["code"] for i in r["issues"]} == {"DATEI_FEHLT", "GEOMETRIE_FEHLT"}


def test_pick_flaeche(tmp_path):
    (tmp_path / "flaeche.geojson").write_text(json.dumps({"type": "Polygon", "coordinates": [
        [[13.0, 53.0], [13.0, 53.001], [13.002, 53.001], [13.0, 53.0]]]}))
    r = pick_geometry(str(tmp_path), "x", "flaeche", _meta(geometrie_datei="flaeche.geojson"),
                      osm_dir=str(tmp_path / "osm"))
    assert r["herkunft"] == "geojson" and len(r["area"]) == 3


def test_derive_linie_und_flaeche():
    t = {"form": "linie", "start_lat": None, "start_lon": None, "laenge_km": None}
    derive_from_geometry(t, {"route": ROUTE})
    assert t["start_lat"] == 53.0 and 0.45 < t["laenge_km"] < 0.55
    f = {"form": "flaeche", "laenge_km": 3, "rundkurs": True, "start_lat": None, "start_lon": None}
    derive_from_geometry(f, {"area": [[53.0, 13.0], [53.002, 13.0], [53.002, 13.002], [53.0, 13.002]]})
    assert f["laenge_km"] == 0 and f["rundkurs"] is False and abs(f["start_lat"] - 53.001) < 1e-6


def test_find_file_case_insensitive(tmp_path):
    (tmp_path / "sub").mkdir()
    (tmp_path / "sub" / "ROUTE.GPX").write_text("x")
    assert find_file(str(tmp_path), "route.gpx", ()).endswith("ROUTE.GPX")
