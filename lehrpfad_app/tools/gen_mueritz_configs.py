#!/usr/bin/env python3
"""Schreibt tools/trails/<id>.json für die Müritz-GO-Orte."""
import json
import math
import os

DIR = os.path.dirname(__file__)
TRAILS = os.path.join(DIR, "trails")
OSM = os.path.join(DIR, "osm")


def st(lat, lon, titel, thema, kurztext, erlebnisse, bf=False):
    return {
        "lat": lat,
        "lon": lon,
        "titel": titel,
        "thema": thema,
        "kurztext": kurztext,
        "erlebnisse": erlebnisse,
        "barrierefrei": bf,
        "steckbrief": None,
    }


def write_cfg(cfg):
    path = os.path.join(TRAILS, cfg["id"] + ".json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(cfg, f, ensure_ascii=False, indent=1)
    print("config", path, "stationen", len(cfg["stationen"]))


# --- Wolfspfad ---
write_cfg({
    "id": "wolfspfad-zwenzow",
    "rohdaten": "wolfspfad-zwenzow",
    "name": "Wolfspfad Zwenzow",
    "typ": "walderlebnispfad",
    "kurzbeschreibung": "Zwei Kilometer Waldpfad bei Zwenzow – Wolfswissen zum Mitmachen, historische Fanggrube und eine Märchenhütte. Frei, ohne Ticket.",
    "beschreibung": "Südlich von Zwenzow, an der Straße nach Wesenberg, liegt der Wolfspfad des Müritz-Nationalparks. Auf rund zwei Kilometern erzählen die fiktiven Junior Ranger Lotta und Lars, seit wann Wölfe wieder hier leben, wo sie jagen und wie man sich ihnen gegenüber verhält. Stationen verlangen Köpfchen und Körpereinsatz: Wolfsquiz, Sprache der Wölfe, Spurenlesen. Die historische Wolfsfanggrube (1710, nach einem Schafsriss bei Userin) ist als Modell und Relikt präsent. In der Märchenhütte werden Mythen vom Wolf aufgegriffen. Ein Glöckchenspiel sitzt am Pfad. Der Outdoor-Besuch ist frei – ohne Ticket, ohne Anmeldung. Führungen sind optional und nicht Scope. Hunde im Nationalpark an der Leine. Der 5 km-Windwurf-Rundweg (Sturm Ela 2014) tangiert den Pfad, ist aber ein eigener Weg.",
    "markierung": "Wolfspfad / lokale NP-Wegweisung",
    "betreiber": "Nationalparkamt Müritz",
    "region": "Zwenzow / Userin, Mecklenburgische Seenplatte, NP Müritz",
    "website": "https://www.mueritz-nationalpark.de/erleben-erholen/aktiv-in-der-natur/erlebnispfade/wolfspfad-zwenzow",
    "anreise": "Auto: Parkplatz am Wolfsfang, Straße Zwenzow–Wesenberg, ca. 2 km südlich Zwenzow (nicht den oft vollen Parkplatz am Familotel Rookhus südlich des Pfades nutzen). ÖPNV dünn; Fahrrad von Wesenberg/Userin.",
    "startName": "Parkplatz am Wolfsfang",
    "arten": ["Kiefer", "Stieleiche", "Rote Waldameise", "Igel"],
    "tags": ["kinderfreundlich", "spielplatz", "hunde-erlaubt"],
    "rundkurs": True,
    "dauerMin": 50,
    "richtung": ["start-parkplatz", "wolfsfang"],
    "startAm": "start-parkplatz",
    "stationen": {
        "start-parkplatz": st(53.3092791, 12.9373789, "Willkommen am Wolfspfad", "Start am Parkplatz Wolfsfang",
            "Hier beginnt der freie Rundweg. Zwei Kilometer Wald, Stationen von Lotta und Lars – ohne Ticket. Parke am nördlichen Wolfsfang-Platz, nicht am Familotel.",
            ["tafel"]),
        "wolfsfang": st(53.3093819, 12.9354615, "Die Wolfsfanggrube", "Historische Falle von 1710",
            "1710 rissen Wölfe bei Userin Schafe. Die Leute bauten eine Fanggrube. Reste und ein Modell stehen hier. Schau in die Grube – und denk nach, warum der Wolf damals Feind war.",
            ["tafel", "mitmach-modell"]),
        "verhaeltnis-wolf": st(53.309292, 12.9334639, "Unser Verhältnis zum Wolf", "Mythen und Angst",
            "Angst, Märchen, Bewunderung. Diese Tafel stellt die Beziehung Mensch–Wolf gerade. Was weißt du wirklich – und was ist Geschichte?",
            ["tafel"]),
        "maerchenhuette": st(53.3093979, 12.9334684, "Märchenhütte", "Geschichten vom Wolf",
            "In der Hütte werden Mythen vom bösen Wolf aufgegriffen. Setz dich, lies, widersprich. Draußen wartet der echte Wald, in dem heute wieder Wölfe leben.",
            ["tafel", "quiz"]),
        "wolfsspuren": st(53.3083818, 12.9330806, "Wolfsspuren", "Spuren lesen",
            "Trittsiegel, Losung, Riss – so wird der Wolf sichtbar, ohne dass du ihn siehst. Vergleich die Größe. Bleib auf dem Weg.",
            ["tafel", "bestimmung"]),
        "woelfe-mv": st(53.3078403, 12.9329462, "Wölfe in Mecklenburg-Vorpommern", "Rückkehr der Art",
            "Rudel gibt es wieder in Mecklenburg-Vorpommern, auch im Nationalpark. Die Tafel sagt, seit wann und wo. Abstand halten ist die Regel, nicht die Ausnahme.",
            ["tafel"]),
        "wolfspirsch": st(53.3076564, 12.9330068, "Auf Wolfspirsch", "Verhalten verstehen",
            "Köpfchen und Körpereinsatz: Wie pirscht ein Wolf? Station zum Nachmachen, nicht zum Nachjagen.",
            ["tafel", "quiz"]),
        "gloeckchenspiel": st(53.3076409, 12.9331045, "Glöckchenspiel", "Mitmachen",
            "Kleines Spielgerät am Pfad. Klang im Wald – und Pause für kürzere Beine.",
            ["mitmach-modell"]),
        "verstaendigung": st(53.3046502, 12.9326769, "Wie verständigen sich Wölfe?", "Körpersprache / Laut",
            "Heulen, Mimik, Rute. Wölfe sprechen, ohne Wörter. Probier die Haltung, die die Tafel zeigt.",
            ["tafel", "quiz"]),
        "wolfswissen": st(53.3037528, 12.932747, "Wolfswissen", "Quiz / Abschluss Südschleife",
            "Südlicher Wendepunkt. Quiz und Fakten, bevor es zurück zum Parkplatz geht.",
            ["tafel", "quiz"]),
    },
})

write_cfg({
    "id": "wald-erlebnispfad-serrahn",
    "rohdaten": "wald-erlebnispfad-serrahn",
    "name": "Wald-Erlebnispfad Serrahn",
    "typ": "walderlebnispfad",
    "kurzbeschreibung": "Vom Kiefernforst in den Buchen-Urwald: Erlebnispfad Zinow–Serrahn mit Tafeln, Moorsteg und Turm am Serrahnsee. Frei, ohne Ticket.",
    "beschreibung": "Der Wald-Erlebnispfad verbindet Zinow mit Serrahn und weiter zum Parkplatz Dianenhof. Am Anfang stehen Wirtschaftswald und Pionierbäume, am Ende mächtige Buchen im UNESCO-Welterbe. Entlang des Weges stehen Stationen zu Fichte, Eiche, Kiefer, Waldgärtner, Rotbuche und Moor. Am Großen Serrahnsee liegt ein Aussichtspunkt. Ein Holzsteg führt durch Moor. In Serrahn gibt es Gartencafé (Saison) und die Ausstellung – die Ausstellung ist optional, der Pfad nicht. Empfehlung: Start Zinow, Richtung Dianenhof. Rückweg Radweg oder Bus 619. Hunde an der Leine. Wege nicht verlassen.",
    "markierung": "Grünes Buchenblatt auf weißem Grund",
    "betreiber": "Nationalparkamt Müritz",
    "region": "Zinow / Serrahn / Carpin, Mecklenburgische Seenplatte, NP Müritz",
    "website": "https://www.mueritz-nationalpark.de/erleben-erholen/aktiv-in-der-natur/erlebnispfade/wald-erlebnispfad-serrahn",
    "anreise": "Auto: B 198 Neustrelitz–Feldberg, Abzweig Zinow, nach ca. 150 m Wanderparkplatz rechts (kostenlos). Weitere Parkplätze Dianenhof und Carpin. Bus 619 (MVVG) Haltestelle Welterbe Zinow / Dianenhof / Carpin.",
    "startName": "Wanderparkplatz / Eingangsbereich Zinow",
    "arten": ["Kiefer", "Stieleiche", "Kranich", "Torfmoos", "Wollgras"],
    "tags": ["kinderfreundlich", "picknick", "einkehr", "hunde-erlaubt"],
    "rundkurs": False,
    "dauerMin": 150,
    "stationen": {
        "start-zinow": st(53.3613708, 13.1745291, "Eingang Zinow", "Start Welterbe-Pfad",
            "Parkplatz am Waldrand, Tafeln zum Welterbe. Ab hier führt das Buchenblatt vom Forst in den Urwald. Bleib auf dem markierten Weg.",
            ["tafel"]),
        "fichte": st(53.3615519, 13.1759677, "Die Fichte ist hier nicht verwurzelt", "Pionier / Fehlstandort",
            "Die Fichte steht, ist hier aber fehl am Platz. Warum, sagt die Tafel – und der Boden darunter.",
            ["tafel", "bestimmung"]),
        "pioniere": st(53.3615435, 13.1778512, "Pioniere!", "Erste Bäume nach Störung",
            "Nach Sturm oder Hieb kommen zuerst die Schnellen. Welche Art siehst du in den ersten Metern?",
            ["tafel"]),
        "kiefern-brotbaum": st(53.3570065, 13.1882854, "Gemeine Kiefer – der Brotbaum", "Wirtschaftswald",
            "Die Kiefer hat den Forst ernährt. Hier beginnt der Kontrast zum Buchenwald, der später kommt.",
            ["tafel", "bestimmung"]),
        "waldgaertner": st(53.3545776, 13.1921873, "Der gefiederte Waldgärtner", "Tiere pflanzen Wald",
            "Wer hat die kleinen Bäume gepflanzt? Oft ein Vogel. Die nächste Tafel nennt ihn.",
            ["tafel"]),
        "turm-serrahnsee": st(53.3534676, 13.1990094, "Großer Serrahnsee", "Aussicht, Adler, Kranich",
            "Blick über Moor und See. Seeadler, Fischadler, Kranich – Glückssache. Glas und Abstand.",
            ["tafel"]),
        "rotbuche": st(53.3493763, 13.2003116, "Rotbuche – die Dominante", "Urwald / Welterbe",
            "Die Dominante des Welterbes. Totholz, Lichtflecken, Jungbuchen. So sieht Wald aus, den niemand mehr aufräumt.",
            ["tafel", "bestimmung"]),
        "moor": st(53.3467817, 13.20229, "Ein lebendiges Moor ist baumfrei", "Moorsteg-Thema",
            "Lebendiges Moor bleibt offen. Der Steg schützt die Fläche – und dich vor nassen Füßen.",
            ["tafel", "steg"]),
        "unesco": st(53.3484349, 13.1945904, "UNESCO-Welterbe", "Alte Buchenwälder",
            "Seit 2011 Teil der Alten Buchenwälder Deutschlands. Kein Extra-Ticket, aber Regeln: Weg, Leine, keine Souvenirs aus dem Reservat.",
            ["tafel"]),
        "dorfstelle-saran": st(53.3482422, 13.2005317, "Dorfstelle Saran", "Menschliche Spur im Wald",
            "Hier lag eine Siedlung. Der Wald hat sie übernommen. Menschliche Spuren unter Buchen.",
            ["tafel"]),
        "serrahn-forsthaus": st(53.3442857, 13.2020332, "Forsthaus Serrahn", "Zielort / Pause",
            "Dorf im Wald. Café in der Saison, Ausstellung hinter der Tür – der Pfad endet draußen.",
            ["tafel"]),
    },
})

write_cfg({
    "id": "spurenweg-kratzeburg",
    "rohdaten": "spurenweg-kratzeburg",
    "name": "Spurenweg Kratzeburg",
    "typ": "sinnespfad",
    "kurzbeschreibung": "Barrierefreier Rundweg zwischen Kratzeburg und Dambeck – Spuren von Mensch und Natur, taktil markiert, frei begehbar.",
    "beschreibung": "Der SpurenWeg folgt dem, was Menschen im Wald hinterlassen haben – und dem, was die Natur daraus macht. Betonfundamente aus den 1950ern tragen Moose und Flechten. Alte Siedlungsplätze sind heute Revier von Greifvögeln und Füchsen. Der Rundweg ist 3,5 km, barrierearm und für Kinderwagen gedacht; für blinde Menschen mit Begleitung: Reliefkarte am Start, Braille, Wegmarkierung als waagerechte Stämme. Start Ortsausgang Kratzeburg Richtung Dalmsdorf. Frei, ganzjährig Outdoor. Hunde an der Leine.",
    "markierung": "Spuren-Weg; taktile Baumstämme, Relief-Tafeln",
    "betreiber": "Nationalparkamt Müritz",
    "region": "Kratzeburg–Dambeck, Mecklenburgische Seenplatte, NP Müritz",
    "website": "https://www.mueritz-nationalpark.de/erleben-erholen/aktiv-in-der-natur/erlebnispfade/spurenweg-kratzeburg",
    "anreise": "Bahn: RE Berlin–Rostock, Bahnhof Kratzeburg, 400 m Fußweg Richtung Dalmsdorf/Dambeck. Auto: B 193 Neustrelitz–Penzlin, Abzweig Kratzeburg, kostenlose Parkplätze im Ort.",
    "startName": "Ortsausgang Kratzeburg Richtung Dalmsdorf / Dambeck",
    "arten": ["Stieleiche", "Kiefer", "Igel", "Eisvogel", "Hummel"],
    "tags": ["kinderfreundlich", "kinderwagentauglich", "rollstuhltauglich", "hunde-erlaubt", "picknick"],
    "rundkurs": True,
    "dauerMin": 90,
    "richtung": ["start-relief", "fundamente"],
    "startAm": "start-relief",
    "stationen": {
        "start-relief": st(53.4295435, 12.9379185, "Spuren-Weg Start", "Reliefkarte, Braille",
            "Relief und Großdruck zeigen den Rundweg. Nach links in den Wald; rechts unten die Stamm-Markierung zum Ertasten.",
            ["tafel"], True),
        "fundamente": st(53.4311054, 12.9370064, "Fundamente im Wald", "Beton, Moos, Flechten",
            "1950er-Beton, darauf Moos. Der Mensch ging, die Kruste bleibt, das Leben zieht ein.",
            ["tafel"], True),
        "die-bahn": st(53.431229, 12.9383124, "Die Bahn", "Verkehrsspur",
            "Schienen und Takt haben den Ort geprägt. Heute hörst du den Wald dazwischen.",
            ["tafel"], True),
        "schirmeiche": st(53.4352437, 12.932275, "Schirmeiche", "Baum als Zeuge",
            "Eine Eiche als Dach. Tast die Rinde, miss den Schatten.",
            ["tafel", "bestimmung"], True),
        "pause-dambeck": st(53.4377021, 12.9354718, "Eine Pause", "Dambeck, zweite Tafel",
            "Dorf im Grünen. Hier kannst du wenden oder den zweiten Abschnitt beginnen.",
            ["tafel"], True),
        "siedlungen": st(53.4364961, 12.938279, "Ehemalige Siedlungsplätze", "Natur übernimmt",
            "Fundamente, dann Fuchs und Greif. Natur auf den Spuren der Menschen.",
            ["tafel"], True),
        "ural": st(53.4418844, 12.9375508, "URAL 72", "Fahrzeugspur / Relikt",
            "Ein Relikt mit Namen. Technik rostet langsamer als Erinnerung.",
            ["tafel"], True),
        "ufer": st(53.4409782, 12.9377988, "Am Ufer entlang", "See / Havelquelle-Nähe",
            "Wasser, Schilf, vielleicht Eisvogel. Bleib auf dem Weg, das Ufer ist weich.",
            ["tafel"], True),
    },
})

write_cfg({
    "id": "hullerbusch",
    "rohdaten": "hullerbusch",
    "name": "Naturlehrpfad Hullerbusch und Hauptmannsberg",
    "typ": "wald",
    "kurzbeschreibung": "Rundweg über Hauptmannsberg und Hullerbusch – 13 Tafeln, Kesselmoor-Steg, Teufelsstein. Frei, 2023ff. erneuert.",
    "beschreibung": "Zwischen Carwitzer See, Zansen und Schmalem Luzin liegt der modernisierte Naturlehrpfad. Start typisch: Parken am Fuß des Hauptmannsbergs in Carwitz, hinauf zur Aussicht, dann zum Zansen, Schäferwiese oder lang durch den Hullerbusch. 13 Informationstafeln, Moorsteg ins Kesselmoor, Teufelsstein. Nicht kinderwagen- oder rollstuhltauglich. Frei, kein Ticket. Hotel/Schäferladen Hullerbusch = Einkehr optional.",
    "markierung": "Naturlehrpfad-Wegweiser (erneuert 2023–2026)",
    "betreiber": "Naturpark Feldberger Seenlandschaft",
    "region": "Carwitz / Hullerbusch, Naturpark Feldberger Seenlandschaft",
    "website": "https://www.nordkurier.de/regional/neustrelitz/zwischen-teufelsstein-und-kesselmoor-modernes-wandern-im-hullerbusch-4441941",
    "anreise": "Auto: Carwitz, Parkplatz am Fuß des Hauptmannsbergs. Saison: Anreise Feldberg + Luzinfähre. Bus in die Feldberger Seenlandschaft, dann Fußweg.",
    "startName": "Parkplatz Fuß Hauptmannsberg / Carwitz",
    "arten": ["Kiefer", "Stieleiche", "Torfmoos", "Wollgras"],
    "tags": ["kinderfreundlich", "picknick", "einkehr", "hunde-erlaubt"],
    "rundkurs": True,
    "dauerMin": 150,
    "richtung": ["start-nsg", "hauptmannsberg"],
    "startAm": "start-nsg",
    "stationen": {
        "start-nsg": st(53.3056144, 13.4410754, "Naturschutzgebiet Hauptmannsberg", "Einstieg Carwitz",
            "Unten am Berg. Tafel zum Schutzgebiet, dann hoch – der See kommt später ins Bild.",
            ["tafel"]),
        "hauptmannsberg": st(53.3082835, 13.4428084, "Hauptmannsberg", "Aussicht Carwitzer See",
            "Endmoräne, Blick auf den Carwitzer See. Geschichte des Berges auf der Nachbartafel.",
            ["tafel"]),
        "schaeferwiese": st(53.3151891, 13.4450432, "Die Schäferwiese", "Weide, Rast",
            "Offenland, Schafe, Rast. Natur zuerst – kein Spielplatz-Set.",
            ["tafel"]),
        "start-huller": st(53.3219789, 13.4435602, "Naturlehrpfad Hullerbusch", "Dorf Hullerbusch / Fähre",
            "Siedlung Hullerbusch, Luzinfähre in der Saison. Hier teilt sich oft kurz und lang.",
            ["tafel"]),
        "waldgeschichte": st(53.3197959, 13.4503852, "Waldgeschichte des Hullerbuschs", "Waldwandel",
            "Wer hier holzte, jagte, aufforstete. Der Hullerbusch ist Kultur und Wildnis in einem Satz.",
            ["tafel"]),
        "kesselmoor": st(53.3255356, 13.4548817, "Das Kesselmoor", "Eiszeit, Sonnentau, Steg",
            "Toteisloch, Steg, Sonnentau winzig und selten. Bleib auf dem Steg.",
            ["tafel", "steg"]),
        "teufelsstein": st(53.3220247, 13.4585681, "Der Teufelsstein", "Findling",
            "Findling mit Schrammen. Die Tafel erklärt Eis, nicht den Teufel.",
            ["tafel"]),
        "pilze": st(53.3236047, 13.4579237, "Im Reich der Pilze", "Totholz",
            "Totholz als Speisekammer. Bestimmen ohne zu pflücken.",
            ["tafel", "bestimmung"]),
        "huenenwall": st(53.327708, 13.4493371, "Der Hünenwall", "Satzendmoräne",
            "Satzendmoräne, Eiszeit im Anschnitt. Nicht mit dem Hühnenfriedhof verwechseln.",
            ["tafel"]),
    },
})

def densify(pts, max_m=150):
    """Zwischenpunkte, damit validate_seeds keine Sprünge >800 m sieht."""
    out = [pts[0]]
    for a, b in zip(pts, pts[1:]):
        lat1, lon1 = a
        lat2, lon2 = b
        p1, p2 = math.radians(lat1), math.radians(lat2)
        dp = math.radians(lat2 - lat1)
        dl = math.radians(lon2 - lon1)
        x = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
        dist = 2 * 6371000 * math.asin(math.sqrt(x))
        n = max(1, int(dist // max_m))
        for i in range(1, n + 1):
            t = i / n
            out.append([lat1 + t * (lat2 - lat1), lon1 + t * (lon2 - lon1)])
    return out


# Routes without OSM relation: station polyline (+ Baumlehrpfad loop)
with open(os.path.join(OSM, "heilige_way_1258341179.json"), encoding="utf-8") as f:
    baum = json.load(f)

hallen_route = densify(
    [[53.33360, 13.37252], [53.3338778, 13.3727533], [53.3334458, 13.3725761]]
    + baum
    + [[53.3332, 13.3785], [53.3328793, 13.3847518], [53.33360, 13.37252]]
)
with open(os.path.join(OSM, "heilige-hallen_route.json"), "w", encoding="utf-8") as f:
    json.dump(hallen_route, f)
print("route heilige-hallen", len(hallen_route))

write_cfg({
    "id": "heilige-hallen",
    "rohdaten": "heilige-hallen",
    "name": "Heilige Hallen",
    "typ": "wald",
    "kurzbeschreibung": "Alter Buchenwald als Totalreservat bei Lüttenhagen – Pfad durch Wildnis, Arboretum Paradiesgarten am Start. Frei, Museum extra.",
    "beschreibung": "Großherzog Georg ließ den hallenartigen Buchenwald schonen; heute NSG und Referenzwald ohne Bewirtschaftung. Die Hallen aus 350-jährigen Säulen sind teilweise zusammengebrochen – Jungbuchen und Totholz bestimmen das Bild. Parkplatz Lüttenhagen, Paradiesgarten (Arboretum), Pflasterstraße, Infotafel, Pfad durchs Reservat. Waldmuseum Lütt Holthus hat Eintritt und gehört nicht zum Ort. Frei für Wald und Arboretum. Wege nicht verlassen.",
    "markierung": "Wanderweg Heilige Hallen / lokale Forst-Wegweisung",
    "betreiber": "Forstamt / Naturpark Feldberger Seenlandschaft",
    "region": "Lüttenhagen, Feldberger Seenlandschaft, Mecklenburgische Seenplatte",
    "website": "https://www.mecklenburgische-seenplatte.de/wandertour-heilige-hallen",
    "anreise": "Auto: L 341, Wanderparkplatz Ortsausgang Lüttenhagen. Bus 619 Neustrelitz–Feldberg, Halt Lüttenhagen Museum, dann zum Parkplatz/Wald.",
    "startName": "Wanderparkplatz Ortsausgang Lüttenhagen (L 341)",
    "arten": ["Kiefer", "Stieleiche", "Igel", "Rote Waldameise"],
    "tags": ["kinderfreundlich", "hunde-erlaubt"],
    "rundkurs": True,
    "dauerMin": 120,
    "startAm": "parkplatz",
    "stationen": {
        "parkplatz": st(53.33360, 13.37252, "Wanderparkplatz Lüttenhagen", "Start",
            "Ortsausgang, kostenlos parken. Gegenüber der Straße liegt der Wald, den niemand mehr aufräumt.",
            ["tafel"]),
        "paradiesgarten": st(53.3338778, 13.3727533, "Paradiesgarten", "Arboretum",
            "Arboretum des alten Oberförsters, wieder in Pflege. Exoten und Heimische – bestimmen, nicht pflücken.",
            ["tafel", "bestimmung"]),
        "wanderweg-tafel": st(53.3334458, 13.3725761, "Wanderweg Heilige Hallen", "Orientierung",
            "Die Runde ist ausgeschildert. Pflasterstraße zuerst, dann quer durchs Reservat.",
            ["tafel"]),
        "baumlehrpfad": st(53.3341863, 13.3748208, "Baumlehrpfad", "Gehölze am Rand",
            "Kurzer Lehrbogen am Rand, bevor es in die Wildnis geht.",
            ["tafel", "bestimmung"]),
        "totholz": st(53.3332, 13.3785, "Totholz und Jungbuchen", "Hallen zerfallen",
            "Die Säulenhallen kippen. Dazwischen stehen junge Buchen. Das ist kein Schaden, das ist der Plan seit 160 Jahren ohne Axt.",
            ["tafel"]),
        "nsg-tafel": st(53.3328793, 13.3847518, "Lehrpfad Heilige Hallen", "Fakten Schutzgebiet",
            "Schutzgeschichte, Totalreservat, was erlaubt ist: gucken, Weg bleiben.",
            ["tafel"]),
    },
})

fledermaus_route = densify([
    [53.61083, 12.23211],
    [53.6100875, 12.2315048],
    [53.6098888, 12.2307353],
    [53.60863, 12.23066],
    [53.6080, 12.2285],
    [53.6092, 12.2295],
    [53.61083, 12.23211],
])
with open(os.path.join(OSM, "fledermauspfad-bossow_route.json"), "w", encoding="utf-8") as f:
    json.dump(fledermaus_route, f)

write_cfg({
    "id": "fledermauspfad-bossow",
    "rohdaten": "fledermauspfad-bossow",
    "name": "Fledermauspfad Bossow",
    "typ": "walderlebnispfad",
    "kurzbeschreibung": "1,3 km Lehrpfad auf dem ehemaligen Militärgelände Bossow – Fledermäuse verstehen, auch ohne Führung. Bunker extra.",
    "beschreibung": "Auf befestigten Wegen zwischen alten Bunkern stehen interaktive Stationen: Orientierung im Dunkeln, Gedränge im Kasten, Schall und Tonhöhe. Der Outdoor-Pfad ist frei und ohne Anmeldung nutzbar. Volle Interaktivität und Blick ins Winterquartier nur mit gebuchter Führung – das ist nicht Scope. Daneben Sternenbeobachtungsplatz und Tafel Lichtverschmutzung.",
    "markierung": "Fledermauspfad / Stationstafeln",
    "betreiber": "Naturpark Nossentiner/Schwinzer Heide",
    "region": "Bossow, Krakow am See, Naturpark Nossentiner/Schwinzer Heide",
    "website": "https://www.naturpark-nossentiner-schwinzer-heide.de/fledermaus-lehrpfad",
    "anreise": "Bossow, Straße nach Schwinz, ca. 400 m nach Bahnübergang links. Parkplatz am Gelände.",
    "startName": "Parkplatz / Kartentafel an der Straße Bossow–Schwinz",
    "arten": ["Kiefer", "Igel", "Hummel"],
    "tags": ["kinderfreundlich", "hunde-erlaubt"],
    "rundkurs": True,
    "dauerMin": 45,
    "startAm": "start-karte",
    "stationen": {
        "start-karte": st(53.6100875, 12.2315048, "Stationen auf dem Fledermauspfad", "Übersicht",
            "Parken, Karte der Stationen. Draußen kannst du mehrere mitnehmen – den Bunker nur mit Führung.",
            ["tafel"]),
        "lichtverschmutzung": st(53.6098888, 12.2307353, "Die Lichtverschmutzung", "Nacht, Sterne, Fledermaus",
            "Nacht wird hell, Fledermäuse verlieren Insektenstraßen. Der Sternenpark fängt hier thematisch an.",
            ["tafel"]),
        "dunkel-orientierung": st(53.60863, 12.23066, "Orientierung im Dunkeln", "Echoortung nachfühlen",
            "Augen zu, Ohren auf. Die Station spielt Echoortung nach, ohne dass du eine Fledermaus brauchst.",
            ["tafel", "mitmach-modell"]),
        "gedraenge": st(53.6080, 12.2285, "Dicht an dicht", "Winterquartier-Metapher",
            "Im Winter hängen sie eng. Die Outdoor-Station zeigt das Prinzip – das Quartier selbst bleibt zu.",
            ["tafel", "mitmach-modell"]),
        "schall": st(53.6092, 12.2295, "Schall und Tonhöhe", "Reichweite",
            "Hohe Töne tragen anders. Quiz am Kasten, dann weiter auf dem befestigten Weg.",
            ["tafel", "quiz"]),
    },
})

sandhof_route = densify([
    [53.5744344, 12.1947004],
    [53.57330, 12.19326],
    [53.5743305, 12.1866557],
    [53.5784532, 12.1979495],
    [53.580, 12.200],
    [53.5876949, 12.2142194],
    [53.58549, 12.227],
    [53.575, 12.210],
    [53.5744344, 12.1947004],
])
with open(os.path.join(OSM, "lehrpfad-sandhof_route.json"), "w", encoding="utf-8") as f:
    json.dump(sandhof_route, f)

write_cfg({
    "id": "lehrpfad-sandhof",
    "rohdaten": "lehrpfad-sandhof",
    "name": "Naturlehrpfad Sandhof",
    "typ": "wald",
    "kurzbeschreibung": "Acht Kilometer durch Heidewälder und an Klarwasserseen – Lehrpfad ab Festplatz Sandhof bis zum Aussichtsturm Rothirsch. Frei.",
    "beschreibung": "Ausgangspunkt ist der Pavillon auf dem Festplatz in Sandhof. Beschilderte Stationen: Park Sandhof mit fast 100 Gehölzarten, Aussichtsturm Rothirsch am NSG Großer Serrahn (nicht der NP-Teil Serrahn), Paschensee, Wooster Teerofen, Damerower See, Moor am Langhagensee, Kieferndünen. Seeadler und Fischadler sind Park-Charakterarten. Frei, Outdoor. Lang für kleine Kinder – als Ganztag oder Teilstrecke planen.",
    "markierung": "Lehrpfad Sandhof / beschilderte Wanderwege",
    "betreiber": "Forstamt Sandhof / Naturpark Nossentiner/Schwinzer Heide",
    "region": "Sandhof / Wooster-Teerofen, Ludwigslust-Parchim",
    "website": "https://www.wald-mv.de/static/WALDMV/Inhalte/Landesforst%20MV/Struktur%20und%20Organisation/Forst%C3%A4mter/Sandhof/Waldbesucher%20Sandhof.pdf",
    "anreise": "Auto: B 192 Goldberg–Karow, Abzweig Sandhof. Parken am Festplatz/Dorf. ÖPNV dünn.",
    "startName": "Pavillon auf dem Festplatz Sandhof",
    "arten": ["Kiefer", "Stieleiche", "Fischotter", "Kranich", "Libelle"],
    "tags": ["kinderfreundlich", "picknick", "hunde-erlaubt"],
    "rundkurs": True,
    "dauerMin": 180,
    "startAm": "festplatz",
    "stationen": {
        "festplatz": st(53.5744344, 12.1947004, "Pavillon Festplatz", "Start Lehrpfad",
            "Pavillon, Dorf, Start. Acht Kilometer sind eine Ansage – Teilstrecke ist erlaubt.",
            ["tafel"]),
        "park-sandhof": st(53.57330, 12.19326, "Park Sandhof", "~100 Gehölzarten",
            "Arboretum im Kleinen: fast 100 Arten. Schilder lesen, Blätter vergleichen.",
            ["tafel", "bestimmung"]),
        "turm-rothirsch": st(53.5743305, 12.1866557, "Aussichtsturm Rothirsch", "NSG Großer Serrahn, Adler",
            "Blick ins NSG Großer Serrahn. Adler kreisen lassen, nicht rufen.",
            ["tafel"]),
        "teerofen": st(53.5876949, 12.2142194, "Wooster Teerofen", "Waldgeschichte, Teer",
            "Ortsname ist Arbeitsname. Waldglas und Teer brauchen Holz – die Heide erinnert daran.",
            ["tafel"]),
        "paschensee": st(53.58549, 12.227, "Westufer Paschensee", "Klarwassersee",
            "Klarwasser, Wald bis ans Ufer. Die Seenrunde ist offiziell Teil des Lehrpfads.",
            ["tafel"]),
        "damerow": st(53.575, 12.210, "Westufer Damerower See", "See / Adler",
            "Westufer, weites Wasser. Mit Glück Adler, ohne Glück trotzdem Wind.",
            ["tafel"]),
    },
})

print("done configs")
