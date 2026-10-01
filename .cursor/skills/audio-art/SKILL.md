---
name: audio-art
description: >-
  Writes flora or fauna content into species.json: scan fields and a hoertext (90–120 words, narrated without direct address, doku tone, habitat instead of trail name).
  Also handles device (Gerät) content on its own branch.
  Use when the user asks for a Hörtext, Steckbrief, or content for an Art, Pflanze, Tier, Flora, Fauna, or Gerät.
  Not a trail overview.
---

# Audio · Art

cwd: `lehrpfad_app/`. `Read` auf die Pfade, Glob unter `tools/` findet nicht alles.

Flora und Fauna: Form, Ton, Bau, Gold `tools/ART_HOERTEXT.md`. Felder und Limits `tools/SPECIES_CONTENT.md`. Aus `docs/audio/GRUND.md` Kernidee, fünf Schläge als Zettel, Kind, Unslop. Belege `docs/audio/quellen-art.md`, nur bei Zweifel an einer Regel.

Geräte: eigener Zweig, siehe unten.

## 1. Ziel

`id` in `assets/seed/species.json`, sonst neue Art. Kategorie `flora` / `fauna` (Gerät → Zweig unten).

Modus: ganzes `content`, oder nur `hoertext` wenn der Scan schon steht. Neue Art ist immer ganzes `content`.

Lebensräume: an welchen Trails hängt die Art?

```
rg -l '"<nameDe>"' assets/seed/*.json
```

Aus diesen Trails die Lebensraum-Typen notieren (Buchenwald, Bachufer, Sandheide), nicht die Orte.

Done: `id`, Kategorie, Modus, Lebensraum-Typen.

## 2. Spec

`Read tools/ART_HOERTEXT.md`, `Read tools/SPECIES_CONTENT.md`, `Read docs/audio/GRUND.md`. Gold-Beispiel der Kategorie und Gegenbeispiel laut im Kopf lesen, bevor du schreibst.

Done: Ton, Bau, Gold präsent.

## 3. Rohstoff

Notiz, nicht ins JSON:

- Fakten aus dem Eintrag, aus `research/` oder `docs/arten-luecken.md`, Fachliteratur. Jede Zeile mit Quelle. Ortsbezogenes aus dem alten Eintrag (Trailname, Region) fliegt.
- Anker: was an jedem Exemplar oder in jedem Lebensraum der Art wahrnehmbar ist. Fauna: Laut, Spur, Fraß, Bau. Flora: Blatt, Blüte, Frucht, Rinde, Boden darunter.
- Flora: welcher Bruch trägt (Tempo, Abwehr, Tier an der Pflanze, Nutzen heute)?
- Fauna: was tut das Tier, wenn es nicht da ist?
- Zwei, drei starke Verben, die die Art handeln lassen.

Done: Faktenliste mit Quellen, ein Anker, ein Bruch oder eine Abwesenheit, Verben.

## 4. Kernidee

Ein Satz mit Verb, der Groschen-Moment. Getrennt vom `hook`, bleibt Notiz. Muss an jedem Trail der Art stimmen.

Done: der Satz steht und nennt keinen Ort.

## 5. Scan

Nur Modus ganzes `content`. Felder und Limits aus `SPECIES_CONTENT.md`. Neue Art: Profil aus der Spec. Bestehende Art: Profil stehen lassen.

Done: Scan im Limit, oder Modus ist nur `hoertext`.

## 6. Erzählen

Fünf Schläge als Zettel, dann ein Entwurf als Erzähler ohne Anrede. Die Art ist Subjekt, sie handelt und will nichts. Erster Satz am Anker, Aussage dahinter. Ein langer Satz trägt die Bewegung der Geschichte. Nicht auf Länge achten.

Done: ein durchgehender Entwurf, kein du/ihr/Sie, kein Befehl, kein Ortsname.

## 7. Klang

```
python3 ../.cursor/skills/audio-trail/klang.py --art <id> <<< "<text>"
```

Prüft 90–120 Wörter, Satzlängen-Mix, Gleichtakt, Satzanfänge, Da/Dann, Anrede, Befehl am Satzanfang, „man“ ≤ 1, Floskeln aus GRUND, Ortsnamen aus den Trail-Seeds, Wollen-/Fühlen-Verben, „damit“ ≤ 1, Artname und Hook im ersten Satz. Markiert schwache Verben und „um … zu“. Jede markierte Stelle ersetzen, außer sie ist dort das Genaueste.

Neue Art, noch nicht im Seed: Name und Hook prüft das Script nicht, selbst gegenlesen.

Done: Exit 0, Markierungen begründet oder ersetzt.

## 8. Aufräumen

Etwa 20 Prozent kürzen, Fett und Adjektive zuerst, *wenn*/*deshalb*/*und* bleiben. `Read ../.cursor/skills/unslop/SKILL.md` und anwenden. Laut lesen. Neben das Gold-Beispiel legen: Hält es im Ton mit? Danach `klang.py` nochmal.

Done: QA in `ART_HOERTEXT.md` und GRUND geht auf, `klang.py` grün.

## 9. Ablage

Nur diesen Eintrag in `assets/seed/species.json`.

```
python3 tools/validate_seeds.py
```

Exit 0. Rot → der Eintrag, nicht das Script.

Done: JSON geschrieben, Validator grün.

## 10. Trello

[Kalia · Audio](https://trello.com/b/7dzAKbdB/kalia-audio): erst suchen. Sammelkarte Flora oder Fauna, Checkliste Hörtext. Neue Art → neues Item. Haken und Zähler im Titel erst nach Commit. Ist der Haken schon gesetzt und der Text neu, das in der Antwort sagen.

Done: Item gefunden oder angelegt, Stand genannt.

---

## Zweig Geräte

Form bleibt GRUND (fünf Schläge, Register „tun, dann beschreiben“), Limits `tools/GERAETE_CONTENT.md`. Keine Profilfelder.

1. `Read tools/GERAETE_CONTENT.md`, `Read docs/audio/GRUND.md`.
2. Fakten mit Quelle, Kernidee als Satz, getrennt vom `hook`.
3. Scan nach Spec, wenn Modus ganzes `content`.
4. Fünf Schläge als Zettel, ein Stück, 90–120 Wörter.
5. Etwa 20 Prozent kürzen, unslop, laut lesen. Wortzahl erneut.
6. Ablage wie Schritt 9, Trello Sammelkarte Geräte wie Schritt 10.

Done: JSON geschrieben, Validator grün, Trello-Item existiert und ist offen.
