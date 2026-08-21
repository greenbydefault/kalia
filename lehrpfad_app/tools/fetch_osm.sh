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

echo "DONE"
