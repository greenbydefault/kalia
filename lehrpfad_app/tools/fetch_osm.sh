#!/bin/bash
# Zieht OSM-Rohdaten (Relation mit Geometrie, POI-Nodes, Amenities) fuer
# weitere Lehrpfad-Seeds nach tools/osm/ (Rohdaten gehoeren nicht ins
# App-Bundle unter assets/). Sequenziell mit Pausen
# (Overpass-Rate-Limits), Retry bei Fehler/Rate-Limit.
set -u
cd "$(dirname "$0")/osm"

fetch() { # $1 = Query, $2 = Zieldatei
  local q="$1" out="$2" attempt
  for attempt in 1 2 3 4 5; do
    curl -s -G "https://overpass-api.de/api/interpreter" --data-urlencode "data=$q" -o "$out"
    if [ "$(head -c 1 "$out" 2>/dev/null)" = "{" ]; then
      echo "OK   $out ($(wc -c < "$out" | tr -d ' ') bytes)"
      sleep 12
      return 0
    fi
    echo "RETRY($attempt) $out"
    sleep 50
  done
  echo "FAIL $out"
  return 1
}

rel_geom() { echo "[out:json][timeout:180];rel($1);out geom;"; }
pois() { echo "[out:json][timeout:180];rel($1)->.rel;node(r.rel)->.m;way(r.rel)->.w;node(w.w)->.r;(node.m;node(around.r:120)[\"tourism\"=\"information\"];);out;"; }
amen() { echo "[out:json][timeout:180];rel($1)->.rel;way(r.rel)->.w;node(w.w)->.r;(node(around.r:400)[\"amenity\"];node(around.r:400)[\"leisure\"=\"playground\"];node(around.r:400)[\"tourism\"=\"viewpoint\"];);out;"; }

for spec in "raddusch 3687015" "rauener-berge 9502745" "lehde 3652856" "ravensberge 2890426"; do
  set -- $spec
  name="$1"; id="$2"
  fetch "$(rel_geom "$id")" "${name}_rel.json"
  fetch "$(pois "$id")" "${name}_pois.json"
  fetch "$(amen "$id")" "${name}_amenities.json"
done

# Alt Daber: keine OSM-Lehrpfad-Relation – BBox um Forsthof/Daberturm.
# Route kommt nach Feldcapture als alt-daber_route.json (siehe trails/alt-daber.capture.json).
alt_daber_bbox='[out:json][timeout:60];(
  node(53.200,12.490,53.215,12.515)["tourism"];
  way(53.200,12.490,53.215,12.515)["tourism"];
  node(53.200,12.490,53.215,12.515)["amenity"];
  node(53.200,12.490,53.215,12.515)["leisure"];
  node(53.200,12.490,53.215,12.515)["historic"];
  way(53.200,12.490,53.215,12.515)["historic"];
  way(53.200,12.490,53.215,12.515)["leisure"];
);out center tags;'
fetch "$alt_daber_bbox" "alt-daber_bbox.json"
# Split bbox → pois/amenities (Ways bekommen center-lat/lon)
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("alt-daber_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    if (
        tags.get("tourism") in ("information", "attraction", "museum", "yes")
        or tags.get("information") == "board"
        or "historic" in tags
        or tags.get("leisure") == "garden"
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("alt-daber_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("alt-daber_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   alt-daber_pois.json ({len(pois)}), alt-daber_amenities.json ({len(amenities)})")
PY

# Heide-Erlebnisweg: Rel 12688859 ist ein Wegenetz (linear=no) – Route liegt als
# heide-erlebnisweg_route.json (Dijkstra entlang der Rel-Ways). POIs/Amenities per BBox.
# Rel-Geometrie separat (Referenz; Seed nutzt heide-erlebnisweg_route.json)
fetch "$(rel_geom 12688859)" "heide-erlebnisweg_rel.json"
heide_bbox='[out:json][timeout:90];(
  node(53.040,12.560,53.070,12.745)["tourism"];
  node(53.040,12.560,53.070,12.745)["amenity"];
  node(53.040,12.560,53.070,12.745)["leisure"="picnic_table"];
  node(3004806058);
);out;'
fetch "$heide_bbox" "heide-erlebnisweg_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("heide-erlebnisweg_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint", "picnic_site", "museum", "yes")
        or tags.get("information") in ("board", "guidepost")
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("heide-erlebnisweg_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("heide-erlebnisweg_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   heide-erlebnisweg_pois.json ({len(pois)}), heide-erlebnisweg_amenities.json ({len(amenities)})")
PY

# Waldlehrpark Wahrberge: keine Hiking-Relation – BBox um Park-Node.
# Route: tools/osm/wahrberge_route.json (kuratierte Park-Runde + Picnic).
wahrberge_bbox='[out:json][timeout:60];(
  node(53.078,12.150,53.095,12.175)["tourism"];
  way(53.078,12.150,53.095,12.175)["tourism"];
  node(53.078,12.150,53.095,12.175)["amenity"];
  node(53.078,12.150,53.095,12.175)["leisure"];
  node(53.078,12.150,53.095,12.175)["historic"];
  way(53.078,12.150,53.095,12.175)["historic"];
  way(53.078,12.150,53.095,12.175)["leisure"];
);out center tags;'
fetch "$wahrberge_bbox" "wahrberge_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("wahrberge_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    if (
        tags.get("tourism") in ("information", "attraction", "museum", "yes", "picnic_site")
        or tags.get("information") == "board"
        or "historic" in tags
        or tags.get("leisure") in ("garden", "park", "playground")
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("wahrberge_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("wahrberge_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   wahrberge_pois.json ({len(pois)}), wahrberge_amenities.json ({len(amenities)})")
PY

# Natter-Pfad Goyatz: Rel 4082598 (alt_name=Natterpfad) – nur die 2-km-Schleife.
fetch "$(rel_geom 4082598)" "natter-pfad-goyatz_rel.json"
fetch "$(pois 4082598)" "natter-pfad-goyatz_pois.json"
fetch "$(amen 4082598)" "natter-pfad-goyatz_amenities.json"

# Naturerlebnisraum SPO: keine Hiking-Relation. Route liegt als
# naturerlebnisraum-spo_route.json (Vorland-Pfad + Deich-Schleife südlich
# der Seebrücke). POIs/Amenities per BBox.
spo_bbox='[out:json][timeout:90];(
  node(54.305,8.588,54.316,8.608)["tourism"];
  node(54.305,8.588,54.316,8.608)["amenity"];
  node(54.305,8.588,54.316,8.608)["leisure"="picnic_table"];
  node(54.305,8.588,54.316,8.608)["leisure"="playground"];
);out;'
fetch "$spo_bbox" "naturerlebnisraum-spo_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("naturerlebnisraum-spo_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint", "picnic_site")
        or tags.get("information") in ("board", "guidepost")
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("naturerlebnisraum-spo_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("naturerlebnisraum-spo_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   naturerlebnisraum-spo_pois.json ({len(pois)}), naturerlebnisraum-spo_amenities.json ({len(amenities)})")
PY

# Rittbrookpfad Lauerholz: keine Hiking-Relation. Route liegt als
# rittbrookpfad_route.json (Fußwege zwischen den 7 Boards). POIs/Amenities per BBox.
rittbrook_bbox='[out:json][timeout:90];(
  node(53.874,10.714,53.891,10.736)["tourism"];
  node(53.874,10.714,53.891,10.736)["amenity"];
  node(53.874,10.714,53.891,10.736)["leisure"="picnic_table"];
  node(53.874,10.714,53.891,10.736)["leisure"="playground"];
);out;'
fetch "$rittbrook_bbox" "rittbrookpfad_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("rittbrookpfad_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint", "picnic_site")
        or tags.get("information") in ("board", "guidepost")
        or tags.get("network") == "Rittbrookpfad"
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("rittbrookpfad_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("rittbrookpfad_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   rittbrookpfad_pois.json ({len(pois)}), rittbrookpfad_amenities.json ({len(amenities)})")
PY

# Naturwaldpfad Lauerholz: keine Hiking-Relation. Route liegt als
# naturwaldpfad_route.json (Fußwege zwischen den 8 Boards). POIs/Amenities per BBox.
naturwald_bbox='[out:json][timeout:90];(
  node(53.886,10.732,53.895,10.752)["tourism"];
  node(53.886,10.732,53.895,10.752)["amenity"];
  node(53.886,10.732,53.895,10.752)["leisure"="picnic_table"];
  node(53.886,10.732,53.895,10.752)["leisure"="playground"];
  node["network"="Naturwaldpfad"];
);out;'
fetch "$naturwald_bbox" "naturwaldpfad_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("naturwaldpfad_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    if e.get("id") == 10989998447:
        continue
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint", "picnic_site")
        or tags.get("information") in ("board", "guidepost")
        or tags.get("network") == "Naturwaldpfad"
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("naturwaldpfad_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("naturwaldpfad_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   naturwaldpfad_pois.json ({len(pois)}), naturwaldpfad_amenities.json ({len(amenities)})")
PY

# Waldhusen: Rel 72962 (educational). Rel-Geometrie nicht naiv stitchen
# (doppelte Way-Mitglieder) – Route liegt als waldhusen_route.json.
# Boards + historic POIs (Ringwall, Großsteingrab, Grenzstein, Lager).
fetch "$(rel_geom 72962)" "waldhusen_rel.json"
fetch "$(pois 72962)" "waldhusen_pois.json"
fetch "$(amen 72962)" "waldhusen_amenities.json"
waldhusen_bbox='[out:json][timeout:90];(
  node(53.918,10.788,53.938,10.825)["tourism"];
  node(53.918,10.788,53.938,10.825)["historic"];
  way(53.918,10.788,53.938,10.825)["historic"];
  node(53.918,10.788,53.938,10.825)["amenity"];
  node(53.918,10.788,53.938,10.825)["leisure"="picnic_table"];
  node(53.918,10.788,53.938,10.825)["leisure"="playground"];
  node(3399641147);
);out center tags;'
fetch "$waldhusen_bbox" "waldhusen_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("waldhusen_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint", "picnic_site")
        or tags.get("information") in ("board", "guidepost", "map")
        or "historic" in tags
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
# Rel-POIs mergen, damit Boards nicht verloren gehen
rel_pois = json.loads(Path("waldhusen_pois.json").read_text(encoding="utf-8"))
for e in rel_pois.get("elements", rel_pois if isinstance(rel_pois, list) else []):
    if "lat" not in e:
        continue
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    pois.append(slim)
Path("waldhusen_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("waldhusen_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   waldhusen_pois.json ({len(pois)}), waldhusen_amenities.json ({len(amenities)})")
PY

# Schwartautal: keine Hiking-Rel. Route liegt als schwartautal_route.json
# (Pfadnetz Kurparksee–Mönchkamp–Bohlenweg, 3 km). POIs/Amenities per BBox.
schwartau_bbox='[out:json][timeout:90];(
  node(53.918,10.696,53.932,10.714)["tourism"];
  node(53.918,10.696,53.932,10.714)["amenity"];
  node(53.918,10.696,53.932,10.714)["leisure"="picnic_table"];
  node(53.918,10.696,53.932,10.714)["leisure"="playground"];
  node(409767221);
  node(8572349117);
  node(951849944);
);out;'
fetch "$schwartau_bbox" "schwartautal_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("schwartautal_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint", "picnic_site")
        or tags.get("information") in ("board", "guidepost", "map")
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("schwartautal_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("schwartautal_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   schwartautal_pois.json ({len(pois)}), schwartautal_amenities.json ({len(amenities)})")
PY

# Oher Gräberfeld Reinbek: Rel 223552 ist unvollständig (6 Ways, Lücken).
# Route liegt als oher-graeberfeld_route.json (Pfadnetz durchs Gräberfeld, 3 km).
# Historic-Nodes + Amenities per BBox. Rel 5332285/5334288 sind Ahrensburg, nicht Ohe.
oher_bbox='[out:json][timeout:90];(
  node(53.545,10.275,53.565,10.305)["tourism"];
  node(53.545,10.275,53.565,10.305)["historic"];
  way(53.545,10.275,53.565,10.305)["historic"];
  node(53.545,10.275,53.565,10.305)["amenity"];
  node(53.545,10.275,53.565,10.305)["leisure"="picnic_table"];
  node(53.545,10.275,53.565,10.305)["leisure"="playground"];
);out center tags;'
fetch "$oher_bbox" "oher-graeberfeld_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("oher-graeberfeld_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint", "picnic_site")
        or tags.get("information") in ("board", "guidepost", "map")
        or "historic" in tags
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("oher-graeberfeld_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("oher-graeberfeld_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   oher-graeberfeld_pois.json ({len(pois)}), oher-graeberfeld_amenities.json ({len(amenities)})")
PY

# Naturerlebnis Grabau: keine Hiking-Rel. Route liegt als
# naturerlebnis-grabau_route.json (Eichhörnchen-/Wildschwein-/Fledermaus-/Käferweg).
# POIs/Amenities per BBox um Hoherdamm / Grabauer See.
grabau_bbox='[out:json][timeout:90];(
  node(53.788,10.245,53.812,10.285)["tourism"];
  node(53.788,10.245,53.812,10.285)["historic"];
  way(53.788,10.245,53.812,10.285)["historic"];
  node(53.788,10.245,53.812,10.285)["amenity"];
  node(53.788,10.245,53.812,10.285)["leisure"];
);out center tags;'
fetch "$grabau_bbox" "naturerlebnis-grabau_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("naturerlebnis-grabau_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint", "picnic_site")
        or tags.get("information") in ("board", "guidepost", "map")
        or "historic" in tags
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("naturerlebnis-grabau_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("naturerlebnis-grabau_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   naturerlebnis-grabau_pois.json ({len(pois)}), naturerlebnis-grabau_amenities.json ({len(amenities)})")
PY

# Lehrpfad biologischer Pflanzenschutz Schwentinental: keine Hiking-Rel.
# OSM-Park-Way 1531343618 + 8 Nature-Boards. Route liegt als
# lehrpfad-pflanzenschutz-schwentinental_route.json (Jahnstraße–Tafeln–Freibad).
schwentinental_bbox='[out:json][timeout:90];(
  node(54.2835,10.2440,54.2875,10.2500)["tourism"];
  node(54.2835,10.2440,54.2875,10.2500)["amenity"];
  node(54.2835,10.2440,54.2875,10.2500)["leisure"];
  way(54.2835,10.2440,54.2875,10.2500)["leisure"];
  way(1531343618);
);out center tags;'
fetch "$schwentinental_bbox" "lehrpfad-pflanzenschutz-schwentinental_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("lehrpfad-pflanzenschutz-schwentinental_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if e.get("id") == 10712655943:
        continue
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint", "picnic_site")
        or tags.get("information") in ("board", "guidepost", "map")
        or e.get("id") == 12037119972
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("lehrpfad-pflanzenschutz-schwentinental_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("lehrpfad-pflanzenschutz-schwentinental_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   lehrpfad-pflanzenschutz-schwentinental_pois.json ({len(pois)}), amenities ({len(amenities)})")
PY

# Naturlehrpfad Ellerbek: keine Hiking-Rel. Alter Kirchenstieg + Kleingartenpfade
# + Graben Rehsenbach. Route liegt als naturerlebnispfad-ellerbek_route.json.
ellerbek_bbox='[out:json][timeout:90];(
  node(54.3145,10.1780,54.3225,10.1910)["tourism"];
  node(54.3145,10.1780,54.3225,10.1910)["amenity"];
  node(54.3145,10.1780,54.3225,10.1910)["leisure"];
  way(54.3145,10.1780,54.3225,10.1910)["amenity"="parking"];
  way(156439601);
  way(30726324);
  way(935336732);
);out center tags;'
fetch "$ellerbek_bbox" "naturerlebnispfad-ellerbek_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("naturerlebnispfad-ellerbek_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint", "picnic_site")
        or tags.get("information") in ("board", "guidepost", "map")
        or tags.get("waterway") == "ditch"
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("naturerlebnispfad-ellerbek_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("naturerlebnispfad-ellerbek_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   naturerlebnispfad-ellerbek_pois.json ({len(pois)}), amenities ({len(amenities)})")
PY

# Naturerlebnisweg Plöner Seeufer: keine Hiking-Rel. Strandweg Fegetasche–
# Schlosswald–Prinzeninsel. Route liegt als
# naturerlebnisweg-ploener-seeufer_route.json. PlanetenPfad Rel 1172519
# und Evolutionpfad-Boards nicht mergen.
seeufer_bbox='[out:json][timeout:90];(
  node(54.138,10.395,54.165,10.455)["tourism"="information"];
  node(54.138,10.395,54.165,10.455)["amenity"~"parking|toilets|bench|cafe|restaurant|fast_food"];
  node(54.138,10.395,54.165,10.455)["leisure"="playground"];
  node(54.138,10.395,54.165,10.455)["leisure"="picnic_table"];
  node(54.138,10.395,54.165,10.455)["tourism"="viewpoint"];
  way(54.138,10.395,54.165,10.455)["amenity"="parking"];
  node(11111216331);
  node(11111216333);
  node(11111216335);
  node(11111216336);
  node(11111216339);
);out center tags;'
fetch "$seeufer_bbox" "naturerlebnisweg-ploener-seeufer_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
PLANET = {"merkur", "mars", "jupiter", "venus", "erde", "sonne", "uranus", "saturn", "neptun", "pluto"}
raw = json.loads(Path("naturerlebnisweg-ploener-seeufer_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    name = (tags.get("name") or tags.get("board:title") or "").casefold()
    note = (tags.get("note") or "").casefold()
    if name in PLANET or "planeten" in name or "evolution" in name or "evolutionpfad" in note:
        continue
    if (
        tags.get("note") == "Naturerlebnisweg Plöner Seeufer"
        or tags.get("tourism") in ("information", "attraction", "viewpoint", "picnic_site")
        or tags.get("information") in ("board", "guidepost", "map")
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("naturerlebnisweg-ploener-seeufer_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("naturerlebnisweg-ploener-seeufer_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   naturerlebnisweg-ploener-seeufer_pois.json ({len(pois)}), amenities ({len(amenities)})")
PY

# Waldlehrpfad Silberbergen: Rel 374177 (ref=LEHR). Rel-Geometrie + POIs/Amenities.
# Aschberg-Gipfel (Bismarck, Turm, Hotel) nicht in die Stationen — extra, anderer Einstieg.
fetch "$(rel_geom 374177)" "waldlehrpfad-silberbergen_rel.json"
fetch "$(pois 374177)" "waldlehrpfad-silberbergen_pois.json"
fetch "$(amen 374177)" "waldlehrpfad-silberbergen_amenities.json"

# SL-C 73 Les alzines de Can Portell: Rel 7165940 (ref=SL-C 73). Rundkurs Hortsavinyà.
fetch "$(rel_geom 7165940)" "sl-c-73-alzines-can-portell_rel.json"
fetch "$(pois 7165940)" "sl-c-73-alzines-can-portell_pois.json"
fetch "$(amen 7165940)" "sl-c-73-alzines-can-portell_amenities.json"

# Parc Forestal Mataró: keine Hiking-Rel (SL-C 74 gesperrt). Fläche Park-Way
# 436431758 + recreation_ground 921523117. POIs/Amenities per BBox.
# Route liegt als parc-forestal-mataro_route.json (Stations-Walk, Seed nutzt area[]).
mataro_bbox='[out:json][timeout:90];(
  node(41.563,2.424,41.571,2.434)["amenity"];
  node(41.563,2.424,41.571,2.434)["leisure"];
  node(41.563,2.424,41.571,2.434)["tourism"];
  node(41.563,2.424,41.571,2.434)["natural"];
  way(41.563,2.424,41.571,2.434)["amenity"="parking"];
  way(436431758);
  way(921523117);
);out center tags;'
fetch "$mataro_bbox" "parc-forestal-mataro_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("parc-forestal-mataro_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint", "picnic_site")
        or tags.get("information") in ("board", "guidepost", "map")
        or tags.get("natural") in ("spring", "hill")
        or tags.get("name") in ("Font dels Tres Raigs", "Turó d'en Dori", "Font del Parc Forestal")
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("parc-forestal-mataro_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("parc-forestal-mataro_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   parc-forestal-mataro_pois.json ({len(pois)}), amenities ({len(amenities)})")
PY

# Parc de Can Jalpí, Arenys de Munt: keine Hiking-Rel (SL-C 76 extra).
# Fläche Park-Way 550972835 + See 550973163. POIs/Amenities per BBox.
# Overpass overpass-api.de 406 — Files liegen aus OSM API 0.6 (map bbox).
# Route liegt als can-jalpi-arenys_route.json (Stations-Walk, Seed nutzt area[]).
jalpi_bbox='[out:json][timeout:90];(
  node(41.5925,2.5370,41.6025,2.5450)["amenity"];
  node(41.5925,2.5370,41.6025,2.5450)["leisure"];
  node(41.5925,2.5370,41.6025,2.5450)["tourism"];
  node(41.5925,2.5370,41.6025,2.5450)["natural"="tree"];
  way(550972835);
  way(550973163);
  way(1417965120);
  way(1076287093);
  way(1076287098);
);out center tags;'
fetch "$jalpi_bbox" "can-jalpi-arenys_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("can-jalpi-arenys_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint", "picnic_site")
        or tags.get("information") in ("board", "guidepost", "map", "office")
        or tags.get("natural") in ("tree", "water")
        or tags.get("water") in ("lake", "pond")
        or tags.get("historic") == "castle"
        or tags.get("name") in (
            "Parc de Can Jalpí",
            "Llac de Can Jalpí",
            "Castell de Can Jalpí",
            "Gernikaco arbola",
            "Plaça del Roure de Guernika",
        )
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("can-jalpi-arenys_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("can-jalpi-arenys_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   can-jalpi-arenys_pois.json ({len(pois)}), amenities ({len(amenities)})")
PY

# Quellenrunde Vallvidrera: keine Hiking-Rel (itinerari groc). Fläche Infohaus–
# Font Joana/Vella/Nova – FGC Baixador. Overpass overpass-api.de 406 —
# Files liegen aus OSM API 0.6 (map bbox). Route liegt als
# fonts-vallvidrera_route.json (Fußweg-Dijkstra, Seed nutzt die Polyline).
vallvidrera_bbox='[out:json][timeout:90];(
  node(41.413,2.095,41.423,2.112)["amenity"];
  node(41.413,2.095,41.423,2.112)["leisure"];
  node(41.413,2.095,41.423,2.112)["tourism"];
  node(41.413,2.095,41.423,2.112)["natural"="spring"];
  way(142899276);
  way(647512618);
  way(120443050);
  way(48870167);
  way(197748294);
);out center tags;'
fetch "$vallvidrera_bbox" "fonts-vallvidrera_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("fonts-vallvidrera_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint", "picnic_site", "museum")
        or tags.get("information") in ("board", "guidepost", "map", "tactile_model")
        or tags.get("natural") == "spring"
        or tags.get("name") in (
            "Font Joana",
            "Font Vella",
            "Font Nova",
            "Font dels Platans",
            "Vil·la Joana",
            "Centre d'Informació del Parc",
            "Baixador de Vallvidrera",
            "Passeig dels Platans",
            "Àrea de lleure de Santa Maria de Vallvidrera",
        )
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("fonts-vallvidrera_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("fonts-vallvidrera_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   fonts-vallvidrera_pois.json ({len(pois)}), amenities ({len(amenities)})")
PY

# Baumwipfelpfad Rügen: keine Hiking-Rel. Boardwalk-Ways 306013375 + 255505968,
# Adlerhorst Rel 3473538, Kasse Node 3107713187. Overpass oft 504 —
# Files liegen aus OSM API 0.6 (map bbox). Route liegt als
# baumwipfelpfad-ruegen_route.json (Einstieg–Turm–Ausstieg).
ruegen_bbox='[out:json][timeout:90];(
  node(54.430,13.552,54.439,13.564)["amenity"];
  node(54.430,13.552,54.439,13.564)["leisure"];
  node(54.430,13.552,54.439,13.564)["tourism"];
  way(306013375);
  way(255505968);
  way(255505956);
  way(255505957);
  way(255505975);
  way(255505976);
  way(1553692719);
  node(3107713187);
);out center tags;'
fetch "$ruegen_bbox" "baumwipfelpfad-ruegen_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("baumwipfelpfad-ruegen_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint", "picnic_site", "museum")
        or tags.get("information") in ("board", "guidepost", "map", "office")
        or tags.get("man_made") == "tower"
        or tags.get("name") in (
            "Adlerhorst",
            "Ausstiegsturm",
            "Umweltinformationszentrum",
            "Mit Rügens Natur auf Augenhöhe",
        )
        or tags.get("shop") == "ticket"
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("baumwipfelpfad-ruegen_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("baumwipfelpfad-ruegen_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   baumwipfelpfad-ruegen_pois.json ({len(pois)}), amenities ({len(amenities)})")
PY

# Baumwipfelpfad Usedom: keine Hiking-Rel. Boardwalk-Ways 965642367 + 965642366,
# Turm Way 1249838655, Kasse Node 11616727509. Overpass oft 504 —
# Files liegen aus OSM API 0.6 (map bbox). Route liegt als
# baumwipfelpfad-usedom_route.json (Einstieg–Steg–Turm).
usedom_bbox='[out:json][timeout:90];(
  node(53.946,14.164,53.953,14.176)["amenity"];
  node(53.946,14.164,53.953,14.176)["leisure"];
  node(53.946,14.164,53.953,14.176)["tourism"];
  way(965642366);
  way(965642367);
  way(1036309160);
  way(1249838655);
  way(1249838660);
  way(604683048);
  way(179414668);
  node(11616727509);
);out center tags;'
fetch "$usedom_bbox" "baumwipfelpfad-usedom_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("baumwipfelpfad-usedom_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint")
        or tags.get("information") in ("board", "guidepost", "map", "office")
        or tags.get("man_made") == "tower"
        or tags.get("name") in ("Baumwipfelpfad Usedom", "Baumwipfelpfad")
        or tags.get("shop") == "ticket"
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("baumwipfelpfad-usedom_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("baumwipfelpfad-usedom_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   baumwipfelpfad-usedom_pois.json ({len(pois)}), amenities ({len(amenities)})")
PY

# Baumkronenpfad Ivenack: keine Hiking-Rel. Boardwalk-Ways 620844961 + 620844951,
# Turm Way 620844962, Attraction-Node 5865391645. Overpass oft 504 —
# Files liegen aus OSM API 0.6 (map bbox). Route liegt als
# baumkronenpfad-ivenack_route.json (Rampe–Steg–Turm).
ivenack_bbox='[out:json][timeout:90];(
  node(53.712,12.938,53.721,12.955)["amenity"];
  node(53.712,12.938,53.721,12.955)["leisure"];
  node(53.712,12.938,53.721,12.955)["tourism"];
  way(620844961);
  way(620844951);
  way(620844952);
  way(620844959);
  way(620844962);
  way(620844953);
  way(75284858);
  way(977804340);
  way(1419931725);
  node(5865391645);
  node(5865391646);
);out center tags;'
fetch "$ivenack_bbox" "baumkronenpfad-ivenack_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("baumkronenpfad-ivenack_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint")
        or tags.get("information") in ("board", "guidepost", "map", "office")
        or tags.get("man_made") == "tower"
        or tags.get("highway") == "elevator"
        or tags.get("name") in (
            "Baumkronenpfad Ivenacker Eichen",
            "Kasse",
            "Ringeiche - Naturdenkmal",
            "Pferdekopfeiche",
        )
        or tags.get("shop") == "ticket"
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("baumkronenpfad-ivenack_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("baumkronenpfad-ivenack_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   baumkronenpfad-ivenack_pois.json ({len(pois)}), amenities ({len(amenities)})")
PY

# Baumwipfelpfad Steigerwald: keine Hiking-Rel. Boardwalk-Ways 404732181 +
# 404732189 + 404732193, Kasse Node 6677814773. Overpass oft 504 —
# Files liegen aus OSM API 0.6 (map bbox). Route liegt als
# baumwipfelpfad-steigerwald_route.json (Kasse–Steg–Turm–Ausgang).
steigerwald_bbox='[out:json][timeout:90];(
  node(49.847,10.454,49.854,10.471)["amenity"];
  node(49.847,10.454,49.854,10.471)["leisure"];
  node(49.847,10.454,49.854,10.471)["tourism"];
  way(404732181);
  way(404732189);
  way(404732193);
  way(911869775);
  way(404732192);
  way(710355646);
  node(6677814773);
  node(4171763490);
);out center tags;'
fetch "$steigerwald_bbox" "baumwipfelpfad-steigerwald_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("baumwipfelpfad-steigerwald_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint")
        or tags.get("information") in ("board", "guidepost", "map", "office")
        or tags.get("man_made") == "tower"
        or tags.get("name") in (
            "Hochsitz",
            "Nest",
            "Kletterröhre",
            "Fällschnitte",
            "Baumwipfelpfad Turm",
            "Kasse",
            "Ausgang Baumwipfelpfad",
        )
        or tags.get("vending") == "admission_tickets"
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("baumwipfelpfad-steigerwald_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("baumwipfelpfad-steigerwald_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   baumwipfelpfad-steigerwald_pois.json ({len(pois)}), amenities ({len(amenities)})")
PY

# Baumkronenweg Ziegelwies: keine Hiking-Rel. Boardwalk-Ways 297524986 +
# 297524983, Museum-Node 8797478108. Route liegt als
# baumkronenweg-ziegelwies_route.json (Kasse Bayern–Steg–P2 Tirol).
ziegel_bbox='[out:json][timeout:90];(
  node(47.554,10.685,47.562,10.697)["amenity"];
  node(47.554,10.685,47.562,10.697)["leisure"];
  node(47.554,10.685,47.562,10.697)["tourism"];
  way(297524983);
  way(297524986);
  way(26815396);
  way(456761089);
  node(8797478108);
  node(6715602485);
  node(5025024162);
  node(7780172703);
);out center tags;'
fetch "$ziegel_bbox" "baumkronenweg-ziegelwies_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("baumkronenweg-ziegelwies_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if (
        tags.get("tourism") in ("information", "attraction", "museum", "viewpoint")
        or tags.get("information") in ("board", "guidepost", "map", "office")
        or tags.get("name") in (
            "Baumkronenweg",
            "Walderlebniszentrum Ziegelwies",
            "Waldimbiss",
            "Lechfall",
        )
        or tags.get("amenity") in ("parking", "toilets", "fast_food")
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("baumkronenweg-ziegelwies_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("baumkronenweg-ziegelwies_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   baumkronenweg-ziegelwies_pois.json ({len(pois)}), amenities ({len(amenities)})")
PY

# Skywalk Allgäu: keine Hiking-Rel. Theme-Park 1356156188, Boardwalk-Ways
# 85033497–501 + 118321627, Eingang 4349445594. Route liegt als
# skywalk-allgaeu_route.json (Kasse–Turm–Steg).
skywalk_bbox='[out:json][timeout:90];(
  node(47.561,9.822,47.567,9.830)["amenity"];
  node(47.561,9.822,47.567,9.830)["leisure"];
  node(47.561,9.822,47.567,9.830)["tourism"];
  way(85033497);
  way(85033498);
  way(85033499);
  way(85033500);
  way(85033501);
  way(118321627);
  way(1356156188);
  way(631637800);
  way(340296717);
  node(4349445594);
  node(986795753);
  node(4349445598);
  node(13672499219);
);out center tags;'
fetch "$skywalk_bbox" "skywalk-allgaeu_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("skywalk-allgaeu_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if (
        tags.get("tourism") in ("information", "attraction", "museum", "viewpoint", "theme_park")
        or tags.get("information") in ("board", "guidepost", "map", "office")
        or tags.get("name") in (
            "Baumwipfelpfad",
            "Waldwelt Skywalk Allgäu",
            "Aussichtspunkt Skywalk",
            "Eingang Waldwelt Skywalk Allgäu",
            "Restaurant Waldglück",
            "Plenterwald",
        )
        or tags.get("amenity") in ("parking", "toilets", "restaurant")
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("skywalk-allgaeu_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("skywalk-allgaeu_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   skywalk-allgaeu_pois.json ({len(pois)}), amenities ({len(amenities)})")
PY

# Baumwipfelpfad Panarbora: keine Hiking-Rel. Theme-Park 295246664,
# Boardwalk 370149641 + 374914849, Turm 370147558, Eingang 3738738120.
# Route liegt als baumwipfelpfad-panarbora_route.json (Kasse–Turm–Steg).
panarbora_bbox='[out:json][timeout:90];(
  node(50.857,7.603,50.863,7.612)["amenity"];
  node(50.857,7.603,50.863,7.612)["leisure"];
  node(50.857,7.603,50.863,7.612)["tourism"];
  way(295246664);
  way(370147558);
  way(370149641);
  way(374914849);
  way(374914847);
  way(374914848);
  way(374914852);
  way(374914854);
  node(3738738120);
  node(3641186860);
  node(3641186861);
  node(4109129471);
  node(3782978743);
  node(14041234305);
);out center tags;'
fetch "$panarbora_bbox" "baumwipfelpfad-panarbora_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("baumwipfelpfad-panarbora_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint", "theme_park")
        or tags.get("information") in ("board", "guidepost", "map", "office")
        or tags.get("man_made") == "tower"
        or tags.get("name") in (
            "Panarbora",
            "Panarbora-Turm",
            "Eingang",
            "Panarbora Baumwipfelpfad und Aussichtsturm",
        )
        or tags.get("loc_name") == "Baumwipfelpfad"
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("baumwipfelpfad-panarbora_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("baumwipfelpfad-panarbora_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   baumwipfelpfad-panarbora_pois.json ({len(pois)}), amenities ({len(amenities)})")
PY

# Baumkronenweg Waldkirch: Site-Rel 3965076, kein Hiking-Rel.
# Boardwalk 1286931429 + 41955965, Kasse 519860290. Route liegt als
# baumkronenweg-waldkirch_route.json (Kasse–Steg–Viewpoint).
waldkirch_bbox='[out:json][timeout:90];(
  node(48.081,7.950,48.090,7.962)["amenity"];
  node(48.081,7.950,48.090,7.962)["leisure"];
  node(48.081,7.950,48.090,7.962)["tourism"];
  way(1286931429);
  way(41955965);
  way(360018444);
  way(41955974);
  way(298197562);
  way(360017981);
  way(360017980);
  way(610194359);
  way(425207541);
  node(519860290);
  node(519871062);
  node(3441299160);
  rel(3965076);
);out center tags;'
fetch "$waldkirch_bbox" "baumkronenweg-waldkirch_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("baumkronenweg-waldkirch_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint", "picnic_site")
        or tags.get("information") in ("board", "guidepost", "map", "office")
        or tags.get("name") in (
            "Baumkronenweg",
            "Kasse/Eingang Baumkronenweg",
            "Riesenröhrenrutsche",
        )
        or tags.get("shop") == "kiosk"
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("baumkronenweg-waldkirch_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("baumkronenweg-waldkirch_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   baumkronenweg-waldkirch_pois.json ({len(pois)}), amenities ({len(amenities)})")
PY

# Baumkronenpfad Hoherodskopf: keine Hiking-Rel. Kasse Node 3111464039,
# Kletterwald-Fläche 157953350 (Nachbar, gleiche Waldinsel). Boardwalk
# nicht gemappt. Overpass oft 406 — Files liegen aus OSM API 0.6 (map bbox).
# Route liegt als baumkronenpfad-hoherodskopf_route.json (Kasse–Wald–Kasse).
hoherodskopf_bbox='[out:json][timeout:90];(
  node(50.508,9.223,50.514,9.232)["amenity"];
  node(50.508,9.223,50.514,9.232)["leisure"];
  node(50.508,9.223,50.514,9.232)["tourism"];
  node(50.508,9.223,50.514,9.232)["shop"];
  way(157953350);
  way(123930544);
  way(199713912);
  way(263137006);
  way(265082159);
  way(813477372);
  node(3111464039);
  node(2707296660);
);out center tags;'
fetch "$hoherodskopf_bbox" "baumkronenpfad-hoherodskopf_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("baumkronenpfad-hoherodskopf_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint", "picnic_site")
        or tags.get("information") in ("board", "guidepost", "map", "office")
        or tags.get("shop") == "ticket"
        or tags.get("name") in (
            "Kasse Baumkronenpfad",
            "Cafe Baumhaus",
            "Kletterwald Hoherodskopf",
            "Informationszentrum Hoherodskopf",
        )
        or tags.get("amenity") in ("parking", "toilets", "cafe", "restaurant", "fast_food")
        or tags.get("leisure") in ("playground", "miniature_golf")
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism", "shop")):
        amenities.append(slim)
Path("baumkronenpfad-hoherodskopf_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("baumkronenpfad-hoherodskopf_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   baumkronenpfad-hoherodskopf_pois.json ({len(pois)}), amenities ({len(amenities)})")
PY

# Waldwipfelweg Sankt Englmar: keine Hiking-Rel. Theme-Park 183039734,
# Boardwalk 25686663 +, Aussicht 280047448, Turm/Rutsche 10601248953.
# Overpass oft 406 — Files liegen aus OSM API 0.6 (map bbox).
# Route liegt als waldwipfelweg-sankt-englmar_route.json (Kasse–Steg–Turm).
englmar_bbox='[out:json][timeout:90];(
  node(49.007,12.775,49.016,12.790)["amenity"];
  node(49.007,12.775,49.016,12.790)["leisure"];
  node(49.007,12.775,49.016,12.790)["tourism"];
  way(183039734);
  way(25686663);
  way(45173075);
  way(332727147);
  way(39173883);
  node(3398631836);
  node(280047448);
  node(10601248953);
  node(3823616589);
  node(3398631829);
);out center tags;'
fetch "$englmar_bbox" "waldwipfelweg-sankt-englmar_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("waldwipfelweg-sankt-englmar_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint", "theme_park", "picnic_site")
        or tags.get("information") in ("board", "guidepost", "map", "office")
        or tags.get("name") in (
            "WaldWipfelWeg",
            "Woid-Wipfe-Häusl",
            "Rutsche im Baumturm",
            "Optische Phänomene",
        )
        or tags.get("amenity") in ("parking", "toilets", "cafe", "restaurant", "fast_food")
        or tags.get("leisure") == "playground"
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism", "shop")):
        amenities.append(slim)
Path("waldwipfelweg-sankt-englmar_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("waldwipfelweg-sankt-englmar_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   waldwipfelweg-sankt-englmar_pois.json ({len(pois)}), amenities ({len(amenities)})")
PY

# TreeTopWalk Edersee: keine Hiking-Rel. Boardwalk 172527503 + 1391896686,
# Eichhörnchenpfad 72037269 + 1412983609, Kasse Node 11055278159.
# Overpass oft 504 — Files liegen aus OSM API 0.6 (map bbox).
# Route liegt als treetopwalk-edersee_route.json (Kasse–Steg–Aussicht).
edersee_bbox='[out:json][timeout:90];(
  node(51.1868,9.0185,51.1905,9.0315)["amenity"];
  node(51.1868,9.0185,51.1905,9.0315)["leisure"];
  node(51.1868,9.0185,51.1905,9.0315)["tourism"];
  node(51.1868,9.0185,51.1905,9.0315)["shop"];
  way(172527503);
  way(1391896686);
  way(72037269);
  way(1412983609);
  way(1391896690);
  way(172527518);
  way(172527521);
  way(1391896688);
  node(11055278159);
  node(9026288442);
  node(9026284587);
  node(856417789);
);out center tags;'
fetch "$edersee_bbox" "treetopwalk-edersee_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("treetopwalk-edersee_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if e.get("id") == 277612854:
        continue
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint", "picnic_site")
        or tags.get("information") in ("board", "guidepost", "map", "office")
        or tags.get("shop") == "ticket"
        or tags.get("name") in (
            "TreeTopWalk",
            "Eichhörnchenpfad",
            "Rotbuche",
            "Das Bauwerk & Die Erstellung",
            "Der Edersee",
        )
        or tags.get("amenity") in ("parking", "toilets", "bench")
        or tags.get("leisure") in ("playground", "picnic_table")
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism", "shop")):
        amenities.append(slim)
Path("treetopwalk-edersee_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("treetopwalk-edersee_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   treetopwalk-edersee_pois.json ({len(pois)}), amenities ({len(amenities)})")
PY

# Baumwipfelweg Bad Camberg: keine Hiking-Rel. Boardwalk 1272271776–1782,
# Gebäude 1178811064, Attraction 10900405243, Lodge 13258099117,
# Parkplatz 1178811066. Overpass oft 406 — Files liegen aus OSM API 0.6.
# Route liegt als baumwipfelweg-bad-camberg_route.json (Lodge–Steg–Türme).
camberg_bbox='[out:json][timeout:90];(
  node(50.290,8.298,50.301,8.314)["amenity"];
  node(50.290,8.298,50.301,8.314)["leisure"];
  node(50.290,8.298,50.301,8.314)["tourism"];
  way(1272271776);
  way(1272271777);
  way(1272271778);
  way(1272271779);
  way(1272271780);
  way(1272271781);
  way(1272271782);
  way(1178811064);
  way(1178811066);
  node(10900405243);
  node(13258099117);
  node(11403857604);
);out center tags;'
fetch "$camberg_bbox" "baumwipfelweg-bad-camberg_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("baumwipfelweg-bad-camberg_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if (
        tags.get("tourism") in ("information", "attraction", "viewpoint")
        or tags.get("information") in ("board", "guidepost", "map", "office")
        or tags.get("name") in (
            "Baumwipfelweg / Bad Camberg",
            "Baumwipfelweg",
            "Baumwipfelweg-Parkplatz",
        )
        or tags.get("amenity") in ("parking", "toilets", "restaurant", "bench")
    ):
        pois.append(slim)
    if any(k in tags for k in ("amenity", "leisure", "tourism")):
        amenities.append(slim)
Path("baumwipfelweg-bad-camberg_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("baumwipfelweg-bad-camberg_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   baumwipfelweg-bad-camberg_pois.json ({len(pois)}), amenities ({len(amenities)})")
PY


# Auwald-Erlebnispfad: keine Hiking-Rel. Anker Auwaldstation Way 97101007
# (51.37730, 12.28057). Route: tools/osm/auwald-erlebnispfad_route.json
# (Kastanienallee – Herkules – Brücke Neue Luppe Way 4409722 – Schleife Burgaue).
# Overpass-Timeout — Geometrie aus OSM API 0.6 map bbox 12.255,51.365,12.295,51.382.
auwald_bbox='[out:json][timeout:90];(
  node(51.370,12.268,51.382,12.295)["amenity"];
  node(51.370,12.268,51.382,12.295)["leisure"];
  node(51.370,12.268,51.382,12.295)["tourism"];
  node(415268850);
  node(4108447339);
  way(97101007);
  way(493657695);
);out center tags;'
fetch "$auwald_bbox" "auwald-erlebnispfad_bbox.json"
python3 - <<'PY'
import json
from pathlib import Path
raw = json.loads(Path("auwald-erlebnispfad_bbox.json").read_text(encoding="utf-8"))
pois, amenities = [], []
seen = set()
for e in raw.get("elements", []):
    tags = e.get("tags", {})
    if "lat" not in e and "center" in e:
        e = {**e, "lat": e["center"]["lat"], "lon": e["center"]["lon"]}
    if "lat" not in e:
        continue
    slim = {k: e[k] for k in ("type", "id", "lat", "lon", "tags") if k in e}
    key = (e.get("type"), e.get("id"))
    if key in seen:
        continue
    seen.add(key)
    if (
        tags.get("tourism") in ("information", "attraction", "artwork")
        or tags.get("information") in ("board", "map", "office")
        or tags.get("name") in ("Auwaldstation Lützschena", "Herkules", "Auwaldstation")
    ):
        pois.append(slim)
    if tags.get("amenity") in ("toilets", "parking", "picnic_table") or tags.get("leisure") == "playground":
        if tags.get("access") == "private":
            continue
        amenities.append(slim)
Path("auwald-erlebnispfad_pois.json").write_text(
    json.dumps({"elements": pois}, ensure_ascii=False, indent=1), encoding="utf-8"
)
Path("auwald-erlebnispfad_amenities.json").write_text(
    json.dumps({"elements": amenities}, ensure_ascii=False, indent=1), encoding="utf-8"
)
print(f"OK   auwald-erlebnispfad_pois.json ({len(pois)}), amenities ({len(amenities)})")
PY

# Naturlehrpfad Dahlenberg: keine Hiking-Rel. Pfadstück Way 43125971.
# Route: tools/osm/naturlehrpfad-dahlenberg_route.json
# (Jagdhausweg – Nordufer Way 59407014 – Way 43125971 – Dorf – Südufer – Steinertsplan).
# Overpass-Timeout — Geometrie aus OSM API 0.6 map bbox 12.758,51.636,12.802,51.656
# (tools/osm/naturlehrpfad-dahlenberg_map.osm). POIs/Amenities daraus gesplittet.

# Ostsee-Lehrpfad Graal-Müritz: keine Rel. Promenade Way 122157821,
# westlich der Seebrücke (Way 849310161) bis Strandaufgang 35, 1,0 km.
# Acht Tafeln als Nodes. Route: tools/osm/ostsee-lehrpfad-graal-mueritz_route.json
# Geometrie OSM API 0.6, 2026-10-07 (map bbox + way/122157821/full).

echo "DONE"


