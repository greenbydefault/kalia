#!/usr/bin/env python3
"""Einmal-Import: Arten-Illustrationen (SVG) ins CMS.

Quelle  site/public/img/arten/<id>.svg   (oder --src <ordner>)
Ziel    Bucket catalog-media: species/<id>/illu-<hash>.svg
        + species.illustration_path = 'storage:catalog-media/species/<id>/illu-<hash>.svg'

Die SVGs werden vorher mit svgo verschlankt (Pfade auf 2 Nachkommastellen,
Metadaten raus, IDs je Art praefixiert, ca. 15-30 % kleiner). Ohne node/npx oder mit --no-optimize
gehen die Dateien unveraendert hoch.

Der Dateiname traegt den Inhalts-Hash: gleicher Inhalt = gleicher Pfad, neuer
Inhalt = neue URL (Cache-Control: 1 Jahr bleibt korrekt). Das Skript ist
idempotent, Arten mit unveraendertem Pfad werden uebersprungen.
Arten, die es im Katalog nicht gibt, werden gemeldet und nicht angelegt.

Nutzung:
  export SUPABASE_URL="https://<projekt>.supabase.co"
  export SUPABASE_SERVICE_KEY="<service_role key>"   # niemals in die App!
  python3 tools/upload_illustrations.py [--only <id>] [--src <ordner>] [--no-optimize] [--dry-run]

Nur Stdlib (plus npx fuer svgo).
"""
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
DEFAULT_SRC = os.path.join(ROOT, "..", "site", "public", "img", "arten")
BUCKET = "catalog-media"


def env():
    key = os.environ.get("SUPABASE_SERVICE_KEY")
    url = os.environ.get("SUPABASE_URL", "").rstrip("/")
    if not key or not url:
        sys.exit("SUPABASE_URL und SUPABASE_SERVICE_KEY muessen gesetzt sein.")
    return url, key


def http(method, url, key, body=None, headers=None):
    h = {"apikey": key, "Authorization": "Bearer " + key}
    h.update(headers or {})
    request = urllib.request.Request(url, data=body, headers=h, method=method)
    try:
        with urllib.request.urlopen(request) as resp:
            raw = resp.read()
            return json.loads(raw) if raw and raw[:1] in (b"{", b"[") else raw
    except urllib.error.HTTPError as e:
        sys.exit("HTTP %s bei %s %s: %s" % (e.code, method, url, e.read().decode()))


def optimize(files, tmp):
    """svgo in tmp/out; gibt {id: bytes} zurueck. Faellt bei Fehler auf Original zurueck."""
    out = os.path.join(tmp, "out")
    if shutil.which("npx"):
        # IDs pro Datei praefixen: gen_card_fronts.py setzt mehrere Arten in ein SVG,
        # gleiche (gekuerzte) IDs wuerden sich dort gegenseitig ueberschreiben.
        config = os.path.join(tmp, "svgo.config.cjs")
        with open(config, "w") as f:
            f.write(
                "const path = require('path');\n"
                "module.exports = { multipass: true, floatPrecision: 2, plugins: ["
                "'preset-default', "
                "{ name: 'prefixIds', params: { prefix: (node, info) => "
                "path.basename(info.path || '', '.svg') } }] };\n"
            )
        # Ordner-Modus: svgo schreibt bei mehreren Einzeldateien nichts
        inp = os.path.join(tmp, "in")
        os.makedirs(inp, exist_ok=True)
        for f in files:
            shutil.copy(f, inp)
        cmd = ["npx", "--yes", "svgo@3", "--config", config, "-q", "-f", inp, "-o", out]
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode == 0:
            return {
                os.path.basename(f)[:-4]: open(os.path.join(out, os.path.basename(f)), "rb").read()
                for f in files
                if os.path.isfile(os.path.join(out, os.path.basename(f)))
            }
        print("svgo fehlgeschlagen, lade Originale hoch: " + res.stderr.strip()[:200])
    else:
        print("npx nicht gefunden, lade Originale hoch.")
    return {os.path.basename(f)[:-4]: open(f, "rb").read() for f in files}


def main():
    args = sys.argv[1:]
    dry = "--dry-run" in args
    only = args[args.index("--only") + 1] if "--only" in args else None
    src = args[args.index("--src") + 1] if "--src" in args else DEFAULT_SRC
    url, key = env()

    files = sorted(
        os.path.join(src, n) for n in os.listdir(src)
        if n.endswith(".svg") and (not only or n[:-4] == only)
    )
    if not files:
        sys.exit("Keine SVGs in %s" % src)

    rows = http("GET", url + "/rest/v1/species?select=id,illustration_path&limit=2000", key)
    current = {r["id"]: r.get("illustration_path") for r in rows}

    with tempfile.TemporaryDirectory() as tmp:
        if "--no-optimize" in args:
            data = {os.path.basename(f)[:-4]: open(f, "rb").read() for f in files}
        else:
            data = optimize(files, tmp)

        done = skipped = 0
        before = after = 0
        missing = []
        for sid in sorted(data):
            if sid not in current:
                missing.append(sid)
                continue
            payload = data[sid]
            before += os.path.getsize(os.path.join(src, sid + ".svg"))
            after += len(payload)
            digest = hashlib.sha1(payload).hexdigest()[:10]
            obj = "species/%s/illu-%s.svg" % (sid, digest)
            path = "storage:%s/%s" % (BUCKET, obj)
            if current[sid] == path:
                skipped += 1
                continue
            if not dry:
                http("POST", "%s/storage/v1/object/%s/%s" % (url, BUCKET, obj), key, payload,
                     {"Content-Type": "image/svg+xml", "x-upsert": "true",
                      "Cache-Control": "max-age=31536000"})
                http("PATCH", "%s/rest/v1/species?id=eq.%s" % (url, sid), key,
                     json.dumps({"illustration_path": path}).encode(),
                     {"Content-Type": "application/json", "Prefer": "return=minimal"})
            done += 1
            print("  %s (%d KB)" % (sid, len(payload) // 1024))

    print("Illustrationen: %d hochgeladen, %d unveraendert%s" % (done, skipped, " (dry-run)" if dry else ""))
    print("Groesse: %d KB -> %d KB" % (before // 1024, after // 1024))
    if missing:
        print("Nicht im Katalog (uebersprungen): " + ", ".join(missing))


if __name__ == "__main__":
    main()
