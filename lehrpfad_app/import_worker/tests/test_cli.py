import os

from import_worker import candidates, __main__ as cli

from .conftest import ROOT


def test_kandidaten_parsen(tmp_path):
    d = tmp_path / "Länder" / "Deutschland" / "Sachsen" / "Nordsachsen"
    d.mkdir(parents=True)
    (d / "_kandidaten.md").write_text(
        "# x\n\n## GO\n\n### pfad-a — HAVE\n\n| Feld | Wert |\n|---|---|\n| Ort | [Ort A](http://x), Sachsen |\n\n"
        "### pfad-b — OPEN\n\n| Feld | Wert |\n|---|---|\n| Ort | B |\n\n## NOGO\n\n### pfad-c — OPEN\n\n"
        "| Feld | Wert |\n|---|---|\n| Status | zu klein |\n\n### trischendamm\n", encoding="utf-8")
    rows = {r["id"]: r for r in candidates.lade_alle(str(tmp_path / "Länder"))}
    assert set(rows) == {"pfad-a", "pfad-b", "pfad-c", "trischendamm"}
    assert rows["pfad-a"]["status"] == "freigegeben" and rows["pfad-a"]["ort"] == "Ort A, Sachsen"
    assert rows["pfad-a"]["land"] == "DE" and rows["pfad-a"]["bundesland"] == "Sachsen"
    assert rows["pfad-a"]["kreis"] == "Nordsachsen"
    assert rows["pfad-b"]["status"] == "offen"
    assert rows["pfad-c"]["status"] == "verworfen" and rows["pfad-c"]["verworfen_grund"] == "zu klein"
    assert rows["trischendamm"]["status"] == "verworfen"


def test_echte_kandidaten_vollstaendig():
    root = os.path.join(ROOT, "research", "Länder")
    if not os.path.isdir(root):
        return
    rows = candidates.lade_alle(root)
    assert len(rows) >= 150
    assert all(r["land"] for r in rows)


def test_check_befehl(tmp_path, capsys):
    seed = os.path.join(ROOT, "assets", "seed", "naturlehrpfad-pressel.json")
    out = str(tmp_path)
    assert cli.main(["dossier", seed, out]) == 0
    assert cli.main(["check", os.path.join(out, "naturlehrpfad-pressel")]) == 0
    txt = capsys.readouterr().out
    assert "naturlehrpfad-pressel" in txt and "24 Stationen" in txt
