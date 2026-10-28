"""Kleine python-docx-Helfer fuer Vorlage und Parser."""
from __future__ import annotations

import copy

from docx.table import Table
from docx.text.paragraph import Paragraph


def set_text(paragraph: Paragraph, text: str) -> None:
    """Setzt den Text des Absatzes, erhaelt die Formatierung des ersten Runs."""
    if paragraph.runs:
        paragraph.runs[0].text = text
        for r in paragraph.runs[1:]:
            r._r.getparent().remove(r._r)
    else:
        paragraph.add_run(text)


def set_cell(cell, text: str) -> None:
    paras = cell.paragraphs
    set_text(paras[0], text)
    for p in paras[1:]:
        p._p.getparent().remove(p._p)


def drop_col(table: Table, idx: int) -> None:
    grid = table._tbl.tblGrid
    cols = grid.findall(grid.tag.replace("tblGrid", "gridCol"))
    if idx < len(cols):
        grid.remove(cols[idx])
    for row in table.rows:
        tcs = row._tr.findall(row._tr.tag.replace("}tr", "}tc"))
        if idx < len(tcs):
            row._tr.remove(tcs[idx])


def add_row_like_last(table: Table):
    last = table.rows[-1]._tr
    new = copy.deepcopy(last)
    last.addnext(new)
    return table.rows[-1]


def iter_body(doc):
    """Liefert ('p', Paragraph) und ('t', Table) in Dokumentreihenfolge."""
    for ch in doc.element.body.iterchildren():
        tag = ch.tag.split("}")[1]
        if tag == "p":
            yield "p", Paragraph(ch, doc)
        elif tag == "tbl":
            yield "t", Table(ch, doc)
