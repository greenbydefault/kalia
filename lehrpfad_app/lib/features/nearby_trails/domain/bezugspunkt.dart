import 'package:latlong2/latlong.dart';

import '../../trail_progress/tracking/location_service.dart';
import 'eintrag.dart';
import 'karte_copy.dart';
import 'karte_logik.dart';

/// Woher der Bezugspunkt kommt: GPS, gesuchter Ort oder Kartenmitte.
enum BezugQuelle { gps, suche, karte }

/// Punkt, ab dem die Anfahrt berechnet wird.
class Bezugspunkt {
  const Bezugspunkt({required this.quelle, required this.coords, this.ortName});

  final BezugQuelle quelle;
  final LatLng coords;

  /// Pflicht bei [BezugQuelle.suche], sonst per Reverse-Geocoding.
  final String? ortName;

  Map<String, Object?> toJson() => {
    'quelle': quelle.name,
    'lat': coords.latitude,
    'lon': coords.longitude,
    if (ortName != null) 'ortName': ortName,
  };

  static Bezugspunkt? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final lat = raw['lat'];
    final lon = raw['lon'];
    if (lat is! num || lon is! num) return null;
    final quelle = BezugQuelle.values.where((q) => q.name == raw['quelle']);
    if (quelle.isEmpty) return null;
    return Bezugspunkt(
      quelle: quelle.first,
      coords: LatLng(lat.toDouble(), lon.toDouble()),
      ortName: raw['ortName'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Bezugspunkt &&
      other.quelle == quelle &&
      other.coords == coords &&
      other.ortName == ortName;

  @override
  int get hashCode => Object.hash(quelle, coords, ortName);
}

/// Standort-Zustände der Tabelle in Abschnitt 3. „Ungenau“ (iOS) zählt als
/// erteilt.
enum StandortZustand {
  /// erteilt, Position da
  erteiltPositionDa,

  /// erteilt, wird ermittelt
  erteiltErmittelt,

  /// erteilt, Timeout
  erteiltTimeout,

  /// abgelehnt (mit oder ohne gesuchten Ort)
  abgelehnt,

  /// dauerhaft abgelehnt
  dauerhaftAbgelehnt,
}

StandortZustand bestimmeStandortZustand({
  required OsLocationStatus status,
  required bool enabled,
  required bool loading,
  required bool hasFix,
  required LocationFailure? fehler,
}) {
  if (status == OsLocationStatus.deniedForever) {
    return StandortZustand.dauerhaftAbgelehnt;
  }
  final erteilt =
      enabled && (status.isGranted || status == OsLocationStatus.unknown);
  if (!erteilt) return StandortZustand.abgelehnt;
  if (loading) return StandortZustand.erteiltErmittelt;
  if (fehler == LocationFailure.timeout) {
    return StandortZustand.erteiltTimeout;
  }
  return hasFix
      ? StandortZustand.erteiltPositionDa
      : StandortZustand.erteiltErmittelt;
}

/// „Rund um {ort}, {umkreisText}“ und die Sonderfälle.
String bezugszeileText({
  required Bezugspunkt? bezug,
  required Umkreis umkreis,
  bool ermittelt = false,
}) {
  if (ermittelt && bezug == null) return kt('bezug.ermittelt');
  if (bezug == null) return kt('bezug.keinStart');
  final args = {'umkreisText': umkreis.text};
  final name = bezug.ortName;
  if (name != null && name.isNotEmpty) {
    return kt('bezug.ort', {...args, 'ort': name});
  }
  return switch (bezug.quelle) {
    BezugQuelle.gps => kt('bezug.gpsOhneName', args),
    BezugQuelle.karte => kt('bezug.karteOhneName', args),
    BezugQuelle.suche => kt('bezug.keinStart'),
  };
}

/// Kurzname des Bezugs ohne Umkreis, z. B. für das Konto: „Leipzig“,
/// „Euer Standort“, „Kein Startpunkt gewählt“.
String startpunktTitel({required Bezugspunkt? bezug, bool ermittelt = false}) {
  if (ermittelt && bezug == null) return kt('bezug.ermittelt');
  if (bezug == null) return kt('bezug.keinStart');
  final name = bezug.ortName;
  if (name != null && name.isNotEmpty) return name;
  return switch (bezug.quelle) {
    BezugQuelle.gps => kt('startpunkt.gps'),
    BezugQuelle.karte => kt('startpunkt.karte'),
    BezugQuelle.suche => kt('bezug.keinStart'),
  };
}

String _fold(String s) => s
    .toLowerCase()
    .replaceAll('ä', 'ae')
    .replaceAll('ö', 'oe')
    .replaceAll('ü', 'ue')
    .replaceAll('ß', 'ss');

/// Katalogsuche nach Name (lokal, offline). Ab 2 Zeichen, Treffer am Anfang
/// zuerst, höchstens [limit].
List<Eintrag> sucheEintraege(
  Iterable<Eintrag> alle,
  String query, {
  int limit = 5,
}) {
  final q = _fold(query.trim());
  if (q.length < 2) return const [];
  final treffer = <(int, Eintrag)>[];
  for (final e in alle) {
    final n = _fold(e.name);
    final rang = n.startsWith(q) ? 0 : (n.contains(q) ? 1 : -1);
    if (rang >= 0) treffer.add((rang, e));
  }
  treffer.sort((a, b) {
    final r = a.$1.compareTo(b.$1);
    return r != 0 ? r : a.$2.name.compareTo(b.$2.name);
  });
  return [for (final t in treffer.take(limit)) t.$2];
}
