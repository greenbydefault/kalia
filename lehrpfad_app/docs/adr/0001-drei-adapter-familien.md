# ADR 0001 — Drei Adapter-Familien

## Status

Accepted

## Context

Katalog, User-State und Community haben unterschiedliche Offline- und Schreib-Semantik. Ein generisches Hybrid-Modul würde die Unterschiede verwischen.

## Decision

Drei Familien, nicht vereinheitlichen:

1. **Katalog** (Trails, Species, Merkmale, Orte in der Nähe): remote → CatalogCache → Seed. Read-only für die App. Unfiltered Catalog cachen.
2. **User-State** (Merken, Gelaufen, Tour, Listen, Gesehen): Prefs local-first + SyncEngine (Queue, Login-Merge).
3. **Community** (Ratings, Comments, Images): live-only, kein Cache, kein Queue.

## Consequences

Neue User-State-Entity kopiert ein Hybrid + `attach()` im Provider. Neue Katalog-Entity nutzt CatalogCache. Community bleibt hinter dem Client-Provider ohne Engine.
