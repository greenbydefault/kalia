from import_worker import lists, messages, rules
from import_worker.lists_fix import fix_lists, deterministisch
from import_worker.matching import SpeciesIndex, match_arten


def test_jeder_code_hat_meldung():
    assert set(rules.SEVERITY) <= set(messages.CODES)
    for code, m in messages.CODES.items():
        for k in ("titel", "was", "warum", "wie"):
            assert m[k].strip(), (code, k)


def test_render_ohne_fehlende_platzhalter():
    e = rules.E("TEXT_LAENGE", "kurzbeschreibung", wert=200, laenge=200, min=0, max=180)
    r = messages.render(e)
    assert "200 Zeichen" in r["was"] and "bis 180" in r["was"] and "Kurzbeschreibung" in r["was"]
    e = rules.E("TEXT_LAENGE", "hoertext", wert=50, laenge=50, min=70, max=110, einheit="Wörter")
    assert "50 Wörter" in messages.render(e)["was"]
    e = rules.E("TEXT_LAENGE", "stationen[3]", wert=20, laenge=20, min=50, max=0)
    assert "mindestens 50" in messages.render(e)["was"]
    assert "Station 3" in messages.render(e)["was"]


def test_render_wert_und_was():
    e = rules.E("WERT_UNPLAUSIBEL", "dauer_min", wert=5, was="tempo", kmh=0.1)
    r = messages.render(e)
    assert "Tempo" in r["was"]


def test_fix_lists_deterministisch():
    assert deterministisch("tags", "Kinderwagen") == "kinderwagentauglich"
    assert deterministisch("tags", "hunde-erlaubt") == "hunde-erlaubt"
    assert deterministisch("lebensraeume", "Fließgewässer") == "fliessgewaesser"
    assert deterministisch("typ", "Küstenpfad") == "kueste"
    assert deterministisch("typ", "voellig-unbekannt") is None


def test_fix_lists_entfernt_und_meldet():
    d = {"trail": {"typ": "xyz", "naturraum": "Ostsee", "lebensraeume": ["Buchen", "unsinn", "buchenwald"],
                   "tags": ["Kinderwagen", "foo"]},
         "stationen": [{"reihenfolge": 1, "erlebnisse": ["Tafel", "raetselhaft"]}]}
    fx = fix_lists(d, None)
    t = d["trail"]
    assert t["typ"] is None and t["naturraum"] == "ostsee"
    assert t["lebensraeume"] == ["buchenwald"]
    assert t["tags"] == ["kinderwagentauglich"]
    assert d["stationen"][0]["erlebnisse"] == ["tafel"]
    mapped = {(f["feld"], f["raw"]): f["mapped"] for f in fx}
    assert mapped[("typ", "xyz")] is None
    assert mapped[("lebensraeume", "unsinn")] is None
    assert mapped[("stationen[1]", "raetselhaft")] is None
    assert ("lebensraeume", "buchenwald") not in mapped  # gueltig = lautlos


def test_fix_lists_ki_rueckfall_nur_aus_liste():
    d = {"trail": {"typ": "wald", "naturraum": "ostsee", "lebensraeume": [], "tags": ["Pilzesammeln"]}, "stationen": []}
    fix_lists(d, lambda feld, raw, allowed: "picknick")
    assert d["trail"]["tags"] == ["picknick"]
    d["trail"]["tags"] = ["Pilzesammeln"]
    fix_lists(d, lambda feld, raw, allowed: "nicht-in-liste")
    assert d["trail"]["tags"] == []


ROWS = [
    {"id": "kranich", "name_lat": "Grus grus", "name_de": "Kranich", "aliases": ["Grauer Kranich"]},
    {"id": "buche", "name_lat": "Fagus sylvatica", "name_de": "Rotbuche", "aliases": ["Buche"]},
    {"id": "eiche-a", "name_lat": "Quercus robur", "name_de": "Stieleiche", "aliases": ["Eiche"]},
    {"id": "eiche-b", "name_lat": "Quercus petraea", "name_de": "Traubeneiche", "aliases": ["Eiche"]},
]


def test_matching():
    idx = SpeciesIndex(ROWS)
    r = match_arten([
        {"name_de": "Kranich", "name_lat": "Grus grus (Linnaeus, 1758)"},
        {"name_de": "Buche", "name_lat": None},
        {"name_de": "Eiche", "name_lat": None},
        {"name_de": "Wolf", "name_lat": "Canis lupus"},
        {"name_de": "Kranich", "name_lat": "Grus grus"},
        {"name_de": "Rotbuche", "name_lat": "Quercus robur"},
    ], idx)
    assert [a["species_id"] for a in r["zugeordnet"]] == ["kranich", "buche"]
    assert [a["name_de"] for a in r["unbekannt"]] == ["Wolf"]
    gruende = {a["name_de"]: a["grund"] for a in r["unsicher"]}
    assert gruende == {"Eiche": "mehrdeutig", "Rotbuche": "widerspruch"}
