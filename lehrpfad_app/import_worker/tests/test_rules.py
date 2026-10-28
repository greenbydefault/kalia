import copy

import pytest

from import_worker import messages, rules

SEEN = []

# ~1,1 km Linie bei Pressel (DE)
ROUTE = [[51.5000 + i * 0.0010, 12.8000] for i in range(11)]  # 1.11 km


def gut():
    return {
        "mit_dossier": True,
        "trail": {
            "id": "naturlehrpfad-test", "name": "Test", "typ": "wald", "form": "linie", "land": "DE",
            "kurzbeschreibung": "Kurz.", "beschreibung": "x" * 500, "markierung": "grüner Punkt",
            "betreiber": "Verein", "region": "Pressel", "anreise": "Parkplatz", "start_name": "Parkplatz",
            "dauer_min": 30, "naturraum": "norddt-tiefland", "lebensraeume": ["buchenwald"],
            "laenge_km": 1.1, "start_lat": 51.5001, "start_lon": 12.8001,
            "route": ROUTE, "area": [], "hoertext": " ".join(["wort"] * 90), "besuchshinweise": "",
            "tags": [],
        },
        "stationen": [{"reihenfolge": i, "lat": 51.5 + i * 0.002, "lon": 12.8001, "titel": "S%d" % i,
                       "kurztext": "k" * 60, "erlebnisse": []} for i in (1, 2, 3)],
        "arten": [{"name_de": "Kranich", "species_id": "kranich"}],
        "bilder": [{"license": "cc-by-4.0", "datei": "a.avif"}],
        "meta": {"template_version": 3, "abschnitte": {str(n): "fertig" for n in (1, 2, 3, 4, 6, 7)},
                 "quellen_je_abschnitt": {str(n): 1 for n in (1, 2, 3, 4, 6, 7)}, "slug_gueltig": True},
        "kandidat_vorhanden": True,
    }


def codes(ctx):
    r = rules.run_rules(ctx)
    SEEN.extend(r)
    return r, [e["code"] for e in r]


def test_baseline_sauber():
    r, c = codes(gut())
    assert c == [], c


def test_pflichtfelder():
    ctx = gut()
    ctx["trail"]["name"] = ""
    ctx["trail"]["dauer_min"] = None
    r, c = codes(ctx)
    felder = {e["feld"] for e in r if e["code"] == "PFLICHT"}
    assert {"name", "dauer_min"} <= felder
    assert all(e["severity"] == "hart" for e in r if e["code"] == "PFLICHT")


def test_laenge_nur_bei_linie_pflicht():
    ctx = gut()
    ctx["trail"].update(form="flaeche", laenge_km=None, route=[], area=[[51.5, 12.8], [51.5, 12.81], [51.51, 12.81]])
    r, c = codes(ctx)
    assert "PFLICHT" not in c


def test_slug():
    ctx = gut()
    ctx["meta"]["slug_gueltig"] = False
    ctx["meta"]["slug_roh"] = "Ungültig!"
    _, c = codes(ctx)
    assert "SLUG" in c
    ctx = gut()
    ctx["slug_kollision"] = True
    assert "SLUG" in codes(ctx)[1]


def test_template_version_und_status():
    ctx = gut()
    ctx["meta"]["template_version"] = 1
    ctx["meta"]["abschnitte"]["2"] = "in Arbeit"
    r, c = codes(ctx)
    assert "TEMPLATE_VERSION" in c
    e = [e for e in r if e["code"] == "DOSSIER_UNVOLLSTAENDIG"]
    assert len(e) == 1 and e[0]["severity"] == "uebersteuerbar" and e[0]["feld"] == "abschnitt2"
    assert e[0]["abschnitt"] == 2


def test_koordinaten_ausserhalb():
    ctx = gut()
    ctx["trail"]["start_lat"], ctx["trail"]["start_lon"] = 12.8, 51.5  # vertauscht
    _, c = codes(ctx)
    assert "KOORD_AUSSERHALB" in c


def test_geometrie_fehlt_und_abweichungen():
    ctx = gut()
    ctx["trail"]["route"] = []
    r, c = codes(ctx)
    assert "GEOMETRIE_FEHLT" in c and "START_ABWEICHUNG" not in c

    ctx = gut()
    ctx["trail"]["start_lat"] = 51.6
    assert "START_ABWEICHUNG" in codes(ctx)[1]

    ctx = gut()
    ctx["trail"]["laenge_km"] = 3.0
    r, c = codes(ctx)
    e = [e for e in r if e["code"] == "LAENGE_ABWEICHUNG"][0]
    assert e["vorschlag"] == pytest.approx(1.11, abs=0.02)

    ctx = gut()
    ctx["stationen"][0]["lon"] = 12.9
    r, c = codes(ctx)
    assert [e["feld"] for e in r if e["code"] == "STATION_ABSEITS"] == ["stationen[1]"]


def test_geo_issues_werden_durchgereicht():
    ctx = gut()
    ctx["geo_issues"] = [{"code": "GEOMETRIE_LIZENZ", "wert": "route.gpx"}]
    r, c = codes(ctx)
    assert c == ["GEOMETRIE_LIZENZ"]


def test_werte_plausibel():
    ctx = gut()
    ctx["trail"]["dauer_min"] = 5  # 13 km/h
    r, c = codes(ctx)
    e = [e for e in r if e["code"] == "WERT_UNPLAUSIBEL"]
    assert e and e[0]["severity"] == "uebersteuerbar"
    ctx = gut()
    ctx["trail"]["laenge_km"] = 200
    assert "WERT_UNPLAUSIBEL" in codes(ctx)[1]


def test_lehrpfad_tempo_und_leerer_lebensraum_pilot():
    # Pilot (85 Seeds): Lehrpfade mit vielen Halten gehen 0,3 bis 4,7 km/h. Das darf nicht blockieren.
    ctx = gut()
    ctx["trail"].update(laenge_km=0.2, dauer_min=40)  # 0,3 km/h
    r, c = codes(ctx)
    assert "WERT_UNPLAUSIBEL" not in c
    ctx["trail"].update(laenge_km=5.0, dauer_min=5)  # 60 km/h: Tippfehler
    assert "WERT_UNPLAUSIBEL" in codes(ctx)[1]
    # Leerer Lebensraum ist laut datenmodell.md erlaubt (Spielplatz, Geopfad): Warnung, kein Blocker
    ctx = gut()
    ctx["trail"]["lebensraeume"] = []
    r, c = codes(ctx)
    assert c == ["LEBENSRAUM_LEER"]
    assert rules.blockiert(r) == {"hart": 0, "uebersteuerbar": 0}


def test_texte():
    ctx = gut()
    ctx["trail"]["kurzbeschreibung"] = "x" * 200
    ctx["trail"]["beschreibung"] = "x" * 100
    ctx["trail"]["hoertext"] = "zu kurz"
    ctx["kuerzung"] = lambda feld, text, mx: text[:mx]
    r, c = codes(ctx)
    felder = {e["feld"]: e for e in r if e["code"] == "TEXT_LAENGE"}
    assert set(felder) == {"kurzbeschreibung", "beschreibung", "hoertext"}
    assert felder["kurzbeschreibung"]["vorschlag"] == "x" * 180
    assert felder["hoertext"]["params"]["einheit"] == "Wörter"
    assert all(e["severity"] == "warnung" for e in felder.values())


def test_hoertext_fehlt_ist_warnung():
    ctx = gut()
    ctx["trail"]["hoertext"] = ""
    r, c = codes(ctx)
    assert c == ["HOERTEXT_FEHLT"] and r[0]["severity"] == "warnung"


def test_stationen():
    ctx = gut()
    ctx["stationen"] = []
    r, c = codes(ctx)
    assert [e["severity"] for e in r if e["code"] == "STATIONEN_MIN"] == ["hart"]

    ctx = gut()
    ctx["stationen"] = ctx["stationen"][:2]
    r, c = codes(ctx)
    assert [e["severity"] for e in r if e["code"] == "STATIONEN_MIN"] == ["uebersteuerbar"]

    ctx["trail"]["typ"] = "waldspielplatz"
    r, c = codes(ctx)
    assert [e["severity"] for e in r if e["code"] == "STATIONEN_MIN"] == ["warnung"]

    ctx = gut()
    ctx["stationen"][2]["reihenfolge"] = 5
    r, c = codes(ctx)
    e = [e for e in r if e["code"] == "STATIONEN_MIN"][0]
    assert e["params"]["grund"] == "luecke" and e["severity"] == "uebersteuerbar"

    ctx = gut()
    ctx["stationen_unvollstaendig"] = [{"reihenfolge": 4, "fehlt": "lat"}]
    r, c = codes(ctx)
    assert [e["feld"] for e in r if e["code"] == "PFLICHT"] == ["stationen[4]"]


def test_quellen():
    ctx = gut()
    ctx["meta"]["quellen_je_abschnitt"]["3"] = 0
    r, c = codes(ctx)
    assert [e["feld"] for e in r if e["code"] == "QUELLE_FEHLT"] == ["abschnitt3"]
    # Quelle am Eintrag reicht (Arten, Stationen, Bilder)
    ctx = gut()
    ctx["meta"]["quellen_je_abschnitt"]["4"] = 0
    ctx["arten"][0]["quelle"] = "x"
    assert codes(ctx)[1] == []


def test_arten():
    ctx = gut()
    ctx["arten_offen"] = [{"name_de": "Wolf", "name_lat_guess": "Canis lupus", "grund": "unbekannt"},
                          {"name_de": "Eiche", "grund": "unsicher"}]
    r, c = codes(ctx)
    assert c == ["ART_UNBEKANNT", "ART_UNSICHER"]
    ctx = gut()
    ctx["arten"] = []
    assert "PFLICHT" in codes(ctx)[1]


def test_bilder():
    ctx = gut()
    ctx["bilder"] = [{"license": "freigabe", "datei": "a"}, {"license": "cc-by-4.0", "datei": "b"}]
    r, c = codes(ctx)
    assert [e["feld"] for e in r if e["code"] == "BILD_LIZENZ"] == ["bilder[1]"]
    ctx["bilder"] = [{"license": "freigabe"}]
    r, c = codes(ctx)
    assert [(e["code"], e["feld"]) for e in r] == [("BILD_LIZENZ", "bilder[1]"), ("BILD_FEHLT", "bilder")]
    ctx["bilder"] = []
    assert [e["code"] for e in codes(ctx)[0]] == ["BILD_FEHLT"]


def test_listen_fixes():
    ctx = gut()
    ctx["list_fixes"] = [
        {"feld": "tags", "raw": "Kinderwagen", "mapped": "kinderwagentauglich"},
        {"feld": "typ", "raw": "xyz", "mapped": None},
        {"feld": "stationen[2]", "raw": "foo", "mapped": None},
    ]
    ctx["trail"]["typ"] = None
    r, c = codes(ctx)
    by = {(e["code"], e["feld"]): e["severity"] for e in r}
    assert by[("TAG", "tags")] == "warnung"
    assert by[("TYP", "typ")] == "hart"
    assert by[("ERLEBNIS", "stationen[2]")] == "hart"
    # kein zusaetzliches PFLICHT fuer das unmappbare typ
    assert ("PFLICHT", "typ") not in by


def test_abgleich():
    ctx = gut()
    ctx["duplicates"] = [{"id": "a", "name": "A", "distanz_m": 40, "aehnlichkeit": 0.9, "art": "nah"},
                         {"id": "b", "name": "B", "distanz_m": 300, "aehnlichkeit": 0.7, "art": "moeglich"}]
    ctx["kandidat_vorhanden"] = False
    assert codes(ctx)[1] == ["DUPLIKAT_NAH", "DUPLIKAT_MOEGLICH", "KANDIDAT_FEHLT"]


def test_validate_modus_ohne_dossier():
    ctx = gut()
    ctx["mit_dossier"] = False
    ctx["meta"] = {}
    r, c = codes(ctx)
    assert c == []


# --------------------------------------------------------------------------
def test_overrides_und_blocker():
    alt = [{"code": "STATIONEN_MIN", "feld": "stationen", "severity": "uebersteuerbar", "status": "offen",
            "override": {"reason": "Fläche", "by": "x", "at": "t"}}]
    neu = [rules.E("STATIONEN_MIN", "stationen", anzahl=2, min=3, grund="wenige"),
           rules.E("DOSSIER_UNVOLLSTAENDIG", "abschnitt2", nummer=2, status="entwurf"),
           rules.E("SCHEMA", "form", was="form", erlaubt="")]
    rules.apply_overrides(neu, alt)
    assert neu[0]["override"]["reason"] == "Fläche"
    assert "override" not in neu[1] and "override" not in neu[2]
    assert rules.blockiert(neu) == {"hart": 1, "uebersteuerbar": 1}
    # harte Meldungen lassen sich nicht uebersteuern, auch nicht mit altem Override
    alt2 = [{"code": "SCHEMA", "feld": "form", "override": {"reason": "egal"}}]
    rules.apply_overrides(neu, alt2)
    assert "override" not in neu[2]


def test_blockiert_zaehlt_nur_offene():
    r = [rules.E("SCHEMA", "x", was="x", erlaubt=""), rules.E("SCHEMA", "y", was="y", erlaubt="")]
    r[1]["status"] = "erledigt"
    assert rules.blockiert(r) == {"hart": 1, "uebersteuerbar": 0}


def test_carry_over():
    alt = [rules.E("FORM", "a"), rules.E("PFLICHT", "name"), rules.E("PFLICHT", "stationen[4]", nummer=4),
           rules.E("PFLICHT", "stationen[2]", nummer=2), rules.E("TAG", "tags", severity="warnung"),
           rules.E("TAG", "tags", severity="hart"), rules.E("DATEI_FEHLT", "route")]
    out = rules.carry_over(alt, stationen_in_db=[1, 2, 3])
    assert [(e["code"], e["feld"]) for e in out] == [
        ("FORM", "a"), ("PFLICHT", "stationen[4]"), ("TAG", "tags"), ("DATEI_FEHLT", "route")]


def test_zuletzt_alle_meldungen_rendern():
    assert SEEN
    for e in SEEN:
        r = messages.render(e)
        assert all(r.values())
        fehlt = messages.platzhalter(e["code"]) - set(e["params"]) - {"wert", "feld", "einheit", "bereich"}
        assert not fehlt, (e["code"], fehlt)
