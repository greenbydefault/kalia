# Waldlehrpfad Haus des Waldes – Research

## Entscheidung

| Feld | Wert |
|---|---|
| `id` | `haus-des-waldes` |
| Name | Waldlehrpfad Haus des Waldes |
| typ | `walderlebnispfad` |
| Region | Heidesee OT Gräbendorf, Dahme-Spreewald |
| Adresse | Frauenseestraße 18a, 15754 Heidesee |
| Länge | Forst BB: **700 m** (erneuert); Natur Brandenburg: 1,5 km / 29 Stationen — vor Seed Verlauf prüfen |
| Zugang | Lehrpfad ganzjährig Mo–So, ohne Anmeldung |

Waldschul-Führungen / Hirschkäferwelt-Programm = Buchung, **nicht Scope**. Gelände-Öffnung Mo–Do 8–15 / Fr 8–12 ist nur der Hof, nicht der Lehrpfad.

Quelle: [`_kandidaten.md`](_kandidaten.md). Filter: [`README.md`](../../../README.md).

## Quellen

- Forst BB: https://forst.brandenburg.de/lfb/de/ueber-uns/waldpaedagogik/waldpaedagogische-einrichtungen/haus-des-waldes/
- Natur Brandenburg (29 Stationen): https://www.natur-brandenburg.de/themen/routen-touren/waldlehrpfad-am-haus-des-waldes/

## Stationen (Natur Brandenburg, ≥3)

1. Märkische Findlinge  
2. Eberesche  
3. Benjeshecke  
4. Zapfenwurf  
5. Roteiche  
6. Altkiefern  
7. Trauf  
8. Holzklotzlauf  
9. Weißdornbusch  
10. Weidenhütte  
11. Försterwiesen  
12. Höhlenbaum  
13. Käferteiche  
14. Baumriesen  
15. Totholz  
16. Niedermoor  
17. Hexenbesen  
18. Kastanienwäldchen  
19. Frauensee  
20. Robinienhain  
21. Baumholz  
22. Sitka-Fichten  
23. Baumtelefon  
24. Waldränder  
25. Trafohaus  
26. Waldameisen  
27. Mistel  
28. Streuobstwiese  
29. Preußische Forsthäuser  

Mitmach im Katalog-Sinn: Zapfenwurf, Holzklotzlauf, Baumtelefon.

## Go / No-Go

**Go:** Lehrpfad frei & spontan; ≥3 benannte Stationen.

**No-Go:** Seed der gebuchten Waldschule; unkritisch 29er-Liste auf den 700-m-Neuweg mappen ohne Begehung.

## Pipeline

1. Vor-Ort: welche der 29 Stationen stehen nach der Erneuerung noch?
2. Config `tools/trails/haus-des-waldes.json`
3. `build_seed.py` + `validate_seeds.py`
