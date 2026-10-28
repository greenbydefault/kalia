"""Zentrale Einstellungen des Import-Workers.

Alles Veraenderliche (Modell, Schwellen, Budgets) steht hier, nicht im Code der Stufen.
Secrets nur ueber Umgebungsvariablen:
  SUPABASE_URL, SUPABASE_SERVICE_KEY   (service_role, niemals in die App)
  ANTHROPIC_API_KEY                    (nur fuer ai.py)
"""
from __future__ import annotations

import os

# ---- Worker -----------------------------------------------------------------
PARALLELITAET = 5
POLL_SEKUNDEN = 5
RETRY_SEKUNDEN = (30, 120, 600)          # Wartezeit vor Versuch 2, 3, 4
MAX_VERSUCHE = len(RETRY_SEKUNDEN) + 1
LOCK_TIMEOUT_SEKUNDEN = 900              # haengender Job gilt danach als frei

# ---- Dateien ----------------------------------------------------------------
MAX_ZIP_MB = 250
MAX_BILD_MB = 40
BUCKET_IMPORTS = "imports"
BUCKET_TRAIL_IMAGES = "trail-images"

# ---- Bilder -----------------------------------------------------------------
# Laengste Kante, wie _resizeWith in lib/.../image_variants.dart
BILD_VARIANTEN = (("thumb", 480), ("small", 900), ("medium", 2000))
# Byte-Budget je Variante (kalibriert gegen die vorhandenen Assets)
BILD_ZIEL_BYTES = {"thumb": 45_000, "small": 120_000, "medium": 500_000}
AVIF_QUALITAET_START = {"thumb": 60, "small": 55, "medium": 55}
AVIF_QUALITAET_MIN = 25
IMAGE_NAMESPACE = "6f1c1d5e-0a5b-4f43-9a6a-1e6f2b8f0c11"   # wie tools/upload_catalog_media.py (stabile images.id)

# ---- Pruefregeln ------------------------------------------------------------
# Laender-Boxen (lat_min, lat_max, lon_min, lon_max), grob, mit Rand
LAENDER_BOX = {
    "DE": (47.2, 55.1, 5.8, 15.1),
    "DK": (54.5, 57.8, 8.0, 15.3),
    "ES": (35.9, 43.9, -9.4, 4.4),
}
DUPLIKAT_NAH_M = 150
DUPLIKAT_MOEGLICH_M = 500
DUPLIKAT_TRIGRAM = 0.6
START_ABWEICHUNG_M = 250                 # Start vs. erster Routenpunkt
LAENGE_ABWEICHUNG_PROZENT = 20
STATION_ABSEITS_M = 300                  # Station weiter als das von der Route
DAUER_KMH_MIN, DAUER_KMH_MAX = 0.2, 8.0   # Tempo aus Laenge/Dauer inkl. Stationenhalte; echte Lehrpfade liegen bei 0,3 bis 4,7 km/h (Pilot, 85 Seeds)
MAX_LAENGE_KM = 80
MAX_DAUER_MIN = 600

# ---- KI (nur Rueckfall) ------------------------------------------------------
KI_AKTIV = bool(os.environ.get("ANTHROPIC_API_KEY"))
KI_MODELL = os.environ.get("KALIA_KI_MODELL", "claude-haiku-5-5")
KI_MODELL_VERGLEICH = "claude-sonnet-5-5"
KI_MAX_TOKENS = 400
KI_KOSTEN_DECKEL_USD_BATCH = 5.0
# Preise je 1 Mio. Token (Input, Output), Stand 07.10.2026
KI_PREISE = {
    "claude-haiku-5-5": (0.10, 0.50),
    "claude-sonnet-5-5": (2.0, 10.0),
}
KI_API_URL = "https://api.anthropic.com/v1/messages"
KI_API_VERSION = "2023-06-01"

# ---- Batches ------------------------------------------------------------------
BATCH_MIN_JOBS = 10                       # erst ab so vielen fertigen Jobs gilt die Quote
BATCH_ABBRUCH_FEHLERQUOTE = 0.10         # nach Pilot 50: Abbruch bei > 10 % Fehlern

# ---- Geo-Check von Bildern (wie lib/features/location/proximity.dart) ----------
FOTO_NAH_M_LINIE = 250.0
FOTO_NAH_M_FLAECHE = 150.0
FOTO_GEGEND_M = 2000.0

# ---- Geometrie ------------------------------------------------------------------
ROUTE_SIMPLIFY_M = 1.5          # Douglas-Peucker, nur bei sehr dichten GPX-Spuren
ROUTE_MAX_PUNKTE = 1500
MAX_SPRUNG_M = 800              # wie tools/validate_seeds.py
