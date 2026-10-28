import pytest

from import_worker import ai, config


def fake(values, usage=(500, 20)):
    calls = []

    def tr(payload):
        calls.append(payload)
        v = values.pop(0)
        if isinstance(v, str) and payload.get("tools") is None:
            content = [{"type": "text", "text": v}]
        else:
            content = [{"type": "tool_use", "name": "antwort", "input": {"value": v}}]
        return {"content": content, "usage": {"input_tokens": usage[0], "output_tokens": usage[1]}}
    tr.calls = calls
    return tr


def test_inaktiv_ruft_nichts():
    tr = fake([])
    k = ai.KI(aktiv=False, transport=tr)
    assert k.normalize_with_ai("tags", "x", ["a"]) is None
    assert k.kuerzung("kurzbeschreibung", "t" * 300, 180) is None
    assert tr.calls == [] and k.events == []


def test_normalize_enum_und_cache():
    tr = fake(["picknick"])
    k = ai.KI(aktiv=True, transport=tr)
    assert k.normalize_with_ai("tags", "Grillplatz", ["picknick", "einkehr"]) == "picknick"
    assert k.normalize_with_ai("tags", "Grillplatz", ["picknick", "einkehr"]) == "picknick"
    assert len(tr.calls) == 1
    assert tr.calls[0]["model"] == config.KI_MODELL
    assert tr.calls[0]["tool_choice"]["name"] == "antwort"
    assert k.field_meta()["tags"]["quelle"] == "ki"


def test_normalize_verwirft_werte_ausserhalb_liste():
    k = ai.KI(aktiv=True, transport=fake(["erfunden"]))
    assert k.normalize_with_ai("tags", "x", ["a", "b"]) is None


def test_lateinischer_name():
    k = ai.KI(aktiv=True, transport=fake(["Grus grus", "Kranich"]))
    assert k.normalize_with_ai("name_lat", "Kranich", None) == "Grus grus"
    assert k.normalize_with_ai("name_lat", "Vogel", None) is None


def test_kuerzung_nur_wenn_kurz_genug():
    k = ai.KI(aktiv=True, transport=fake(["k" * 150, "k" * 200]))
    assert k.kuerzung("kurzbeschreibung", "t" * 300, 180) == "k" * 150
    assert k.kuerzung("kurzbeschreibung", "u" * 300, 180) is None


def test_kosten_und_deckel():
    k = ai.KI(aktiv=True, deckel_usd=0.0001, transport=fake(["a", "a"], usage=(1000, 100)))
    k.normalize_with_ai("tags", "x", ["a"])
    assert k.kosten == pytest.approx((1000 * 0.10 + 100 * 0.50) / 1e6)
    with pytest.raises(ai.Kostendeckel):
        k.normalize_with_ai("tags", "y", ["a"])
    assert k.suggest("tags", "z", ["a"]) is None  # Adapter schluckt den Deckel


def test_netzfehler_ist_kein_vorschlag():
    def boom(payload):
        raise OSError("offline")
    k = ai.KI(aktiv=True, transport=boom)
    assert k.normalize_with_ai("tags", "x", ["a"]) is None
    assert k.aufrufe == 0
