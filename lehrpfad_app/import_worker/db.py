"""Minimaler Supabase-Client (REST, RPC, Storage) mit service_role. Nur Stdlib.

Fehler: DBFehler(status, text). `transient` = Netz, 429, 5xx (der Worker versucht es spaeter wieder).
"""
from __future__ import annotations

import json
import os
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Dict, Iterable, List, Optional


class DBFehler(Exception):
    def __init__(self, status: int, text: str, was: str = ""):
        super().__init__("HTTP %s %s: %s" % (status, was, text[:400]))
        self.status = status
        self.text = text
        self.was = was

    @property
    def transient(self) -> bool:
        return self.status in (0, 408, 429) or self.status >= 500


def eq(v: Any) -> str:
    return "eq." + urllib.parse.quote(str(v), safe="")


def in_(vs: Iterable[Any]) -> str:
    return "in.(" + ",".join('"%s"' % str(v).replace('"', '\\"') for v in vs) + ")"


class DB:
    def __init__(self, url: Optional[str] = None, key: Optional[str] = None, timeout: int = 60):
        self.url = (url or os.environ.get("SUPABASE_URL", "")).rstrip("/")
        self.key = key or os.environ.get("SUPABASE_SERVICE_KEY", "")
        if not self.url or not self.key:
            raise RuntimeError("SUPABASE_URL und SUPABASE_SERVICE_KEY muessen gesetzt sein.")
        self.timeout = timeout

    # -- Basis ----------------------------------------------------------
    def _req(self, method: str, url: str, body: Optional[bytes] = None,
             headers: Optional[Dict[str, str]] = None) -> Any:
        h = {"apikey": self.key, "Authorization": "Bearer " + self.key}
        h.update(headers or {})
        r = urllib.request.Request(url, data=body, headers=h, method=method)
        try:
            with urllib.request.urlopen(r, timeout=self.timeout) as resp:
                raw = resp.read()
                ct = resp.headers.get("Content-Type", "")
                if raw and "json" in ct:
                    return json.loads(raw)
                return raw
        except urllib.error.HTTPError as e:
            raise DBFehler(e.code, e.read().decode("utf-8", "replace"), "%s %s" % (method, url.split("/v1/")[-1][:80]))
        except (urllib.error.URLError, TimeoutError, OSError) as e:
            raise DBFehler(0, str(e), "%s %s" % (method, url.split("/v1/")[-1][:80]))

    def _json(self, method: str, path: str, payload: Any = None, prefer: str = "return=minimal",
              params: Optional[Dict[str, str]] = None) -> Any:
        q = ("?" + "&".join("%s=%s" % (k, v) for k, v in params.items())) if params else ""
        data = json.dumps(payload, ensure_ascii=False).encode("utf-8") if payload is not None else None
        return self._req(method, "%s/rest/v1/%s%s" % (self.url, path, q), data,
                         {"Content-Type": "application/json", "Prefer": prefer})

    # -- Tabellen ---------------------------------------------------------
    def select(self, table: str, select: str = "*", **filters: str) -> List[Dict[str, Any]]:
        """filters: Spalte=PostgREST-Ausdruck, z. B. id=eq('x'); order/limit ueber _order/_limit."""
        params = {"select": urllib.parse.quote(select, safe="*,()!:.")}
        for k, v in filters.items():
            if k == "_order":
                params["order"] = v
            elif k == "_limit":
                params["limit"] = str(v)
            else:
                params[k] = v
        return self._json("GET", table, params=params, prefer="") or []

    def insert(self, table: str, rows: Any, upsert_on: Optional[str] = None, ignore: bool = False) -> None:
        if rows == [] or rows is None:
            return
        prefer = "return=minimal"
        params = None
        if upsert_on:
            params = {"on_conflict": upsert_on}
            prefer = "resolution=%s-duplicates,return=minimal" % ("ignore" if ignore else "merge")
        self._json("POST", table, rows, prefer=prefer, params=params)

    def patch(self, table: str, body: Dict[str, Any], **filters: str) -> None:
        self._json("PATCH", table, body, params=filters)

    def delete(self, table: str, **filters: str) -> None:
        self._json("DELETE", table, params=filters)

    def rpc(self, name: str, args: Optional[Dict[str, Any]] = None) -> Any:
        return self._json("POST", "rpc/" + name, args or {}, prefer="")

    # -- Storage ----------------------------------------------------------
    def upload(self, bucket: str, path: str, data: bytes, content_type: str) -> None:
        self._req("POST", "%s/storage/v1/object/%s/%s" % (self.url, bucket, urllib.parse.quote(path)), data,
                  {"Content-Type": content_type, "x-upsert": "true", "Cache-Control": "max-age=31536000"})

    def download(self, bucket: str, path: str) -> bytes:
        return self._req("GET", "%s/storage/v1/object/%s/%s" % (self.url, bucket, urllib.parse.quote(path)))

    def remove(self, bucket: str, paths: List[str]) -> None:
        self._req("DELETE", "%s/storage/v1/object/%s" % (self.url, bucket),
                  json.dumps({"prefixes": paths}).encode(), {"Content-Type": "application/json"})
