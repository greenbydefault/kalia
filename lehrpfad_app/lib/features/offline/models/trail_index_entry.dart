/// Ein Trail im lokalen Katalog: Version + Inhalt im Seed-JSON-Format
/// (das, was `Trail.fromJson` erwartet).
class TrailIndexEntry {
  const TrailIndexEntry({
    required this.id,
    required this.dataVersion,
    required this.json,
    this.closed = false,
  });

  final String id;

  /// `trails.data_version` (Paketversion, serverseitig per Trigger erhöht).
  final int dataVersion;

  /// Gesperrt/Gefahr (aktiver `trail_hints` kind closed/danger).
  final bool closed;

  final Map<String, dynamic> json;
}

/// Eine Art im lokalen Katalog.
class SpeciesIndexEntry {
  const SpeciesIndexEntry({
    required this.id,
    required this.version,
    required this.json,
  });

  final String id;
  final int version;
  final Map<String, dynamic> json;
}
