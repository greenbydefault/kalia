import 'package:latlong2/latlong.dart';

import 'amenity.dart';
import 'eignung_score.dart';
import 'haversine.dart';
import 'station.dart';
import 'trail_bild.dart';

/// Summary-Tags, die in der Chip-Row entfallen (Eignungs-Meter).
const _eignungSummaryTags = {'kinderfreundlich', 'rollstuhltauglich'};

/// Typen, die ohne explizites `form` als Fläche gelten.
const flaecheDefaultTypen = {
  'wasserspielplatz',
  'waldspielplatz',
  'waldspazierplatz',
  'kinderbauernhof',
};

/// Ein Lehrpfad (Linie) oder Spiel-/Erlebnisplatz (Fläche).
class Trail {
  final String id;
  final String name;
  final String typ;

  /// `linie` (Polyline) oder `flaeche` (Polygon).
  final String form;
  final String kurzbeschreibung;
  final String beschreibung;
  final double laengeKm;
  final int dauerMin;
  final bool rundkurs;
  final String markierung;
  final String betreiber;
  final String region;
  final String? website;
  final bool eintritt;
  final String? eintrittPreise;
  final String? oeffnungszeiten;
  final String? besuchshinweise;
  final String anreise;
  final String startName;
  final List<String> arten;
  final List<String> tags;
  final List<LatLng> route;
  final List<LatLng> area;
  final List<Station> stationen;
  final List<Amenity> amenities;
  final List<TrailBild> bilder;

  const Trail({
    required this.id,
    required this.name,
    required this.typ,
    this.form = 'linie',
    required this.kurzbeschreibung,
    required this.beschreibung,
    required this.laengeKm,
    required this.dauerMin,
    required this.rundkurs,
    required this.markierung,
    required this.betreiber,
    required this.region,
    this.website,
    this.eintritt = false,
    this.eintrittPreise,
    this.oeffnungszeiten,
    this.besuchshinweise,
    required this.anreise,
    required this.startName,
    required this.arten,
    this.tags = const [],
    this.route = const [],
    this.area = const [],
    required this.stationen,
    required this.amenities,
    this.bilder = const [],
  });

  bool get isFlaeche => form == 'flaeche';
  bool get isLinie => !isFlaeche;

  /// Echte Redaktionsfotos (nicht der zentrale Platzhalter).
  bool get hasHeroBilder => bilder.isNotEmpty;

  /// Linie A→B, kein Rundkurs — Start und Ziel sind verschiedene Punkte.
  bool get isPointToPoint => isLinie && !rundkurs;

  /// Punkte für Karten-Bounds / Fit.
  List<LatLng> get mapPoints => isFlaeche ? area : route;

  /// Start-Marker: Centroid der Fläche bzw. erster Routenpunkt.
  LatLng get start {
    final value = startOrNull;
    if (value == null) {
      throw StateError('Trail $id hat weder area, route noch Stationen');
    }
    return value;
  }

  /// Wie [start], aber `null` statt [StateError] bei kaputten Datensätzen.
  LatLng? get startOrNull {
    if (isFlaeche && area.isNotEmpty) return centroidOf(area);
    if (route.isNotEmpty) return route.first;
    if (stationen.isNotEmpty) return stationen.first.position;
    return null;
  }

  /// Zielpunkt nur bei A→B mit ausreichendem Abstand zum Start.
  ///
  /// `null` bei Fläche, Rundkurs, zu kurzer Route oder Fast-Loop (< 40 m).
  LatLng? get end {
    if (!isPointToPoint || route.length < 2) return null;
    final last = route.last;
    if (haversineMeters(route.first, last) < _endMinSeparationM) {
      return null;
    }
    return last;
  }

  static const _endMinSeparationM = 40.0;

  String get laengeLabel => '$laengeKm km';

  String get dauerLabel => '~$dauerMin Min';

  String get laengeDauerLabel => '$laengeLabel · $dauerLabel';

  /// Aus den Amenities abgeleitete Tags (keine DB-Pflege nötig).
  List<String> get autoTags => [
    if (amenities.any((a) => a.kategorie == 'parking')) 'parkplatz-nahe',
    if (amenities.any((a) => a.kategorie == 'wc')) 'wc-am-weg',
    if (amenities.any((a) => a.kategorie == 'playground')) 'spielplatz',
  ];

  /// Redaktionelle + abgeleitete Tags, dedupliziert.
  List<String> get alleTags => {...tags, ...autoTags}.toList();

  /// Tags für die Chip-Row — ohne Summary-Tags der Eignungs-Meter.
  List<String> get displayTags =>
      alleTags.where((t) => !_eignungSummaryTags.contains(t)).toList();

  /// Website, Preise, Öffnung oder Hinweise — Accordion-Block.
  bool get hasBesuchInfos =>
      eintritt ||
      (eintrittPreise != null && eintrittPreise!.isNotEmpty) ||
      (oeffnungszeiten != null && oeffnungszeiten!.isNotEmpty) ||
      (besuchshinweise != null && besuchshinweise!.isNotEmpty) ||
      (website != null && website!.isNotEmpty);

  /// Abgeleitete Kinder-Eignung (1–5). Für beide Scores lieber
  /// [scoreEignungen] einmal aufrufen.
  EignungScore get kinderScore => scoreEignungen(this).kinder;

  /// Abgeleitete Barriere-Eignung (1–5).
  EignungScore get barriereScore => scoreEignungen(this).barriere;

  static LatLng centroidOf(List<LatLng> points) {
    var lat = 0.0;
    var lon = 0.0;
    for (final p in points) {
      lat += p.latitude;
      lon += p.longitude;
    }
    final n = points.length;
    return LatLng(lat / n, lon / n);
  }

  static List<LatLng> _parsePoints(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList();
  }

  static String resolveForm({
    required String typ,
    required String? formRaw,
    required List<LatLng> area,
  }) {
    if (formRaw == 'flaeche' || formRaw == 'linie') return formRaw!;
    if (area.length >= 3) return 'flaeche';
    if (flaecheDefaultTypen.contains(typ)) return 'flaeche';
    return 'linie';
  }

  factory Trail.fromJson(Map<String, dynamic> json) {
    final typ = json['typ'] as String;
    final area = _parsePoints(json['area']);
    final route = _parsePoints(json['route']);
    final form = resolveForm(
      typ: typ,
      formRaw: json['form'] as String?,
      area: area,
    );
    return Trail(
      id: json['id'] as String,
      name: json['name'] as String,
      typ: typ,
      form: form,
      kurzbeschreibung: json['kurzbeschreibung'] as String,
      beschreibung: json['beschreibung'] as String,
      laengeKm: (json['laengeKm'] as num).toDouble(),
      dauerMin: json['dauerMin'] as int,
      rundkurs: json['rundkurs'] as bool? ?? false,
      markierung: json['markierung'] as String,
      betreiber: json['betreiber'] as String,
      region: json['region'] as String,
      website: json['website'] as String?,
      eintritt: json['eintritt'] as bool? ?? false,
      eintrittPreise: json['eintrittPreise'] as String?,
      oeffnungszeiten: json['oeffnungszeiten'] as String?,
      besuchshinweise: json['besuchshinweise'] as String?,
      anreise: json['anreise'] as String,
      startName: json['startName'] as String,
      arten: (json['arten'] as List).cast<String>(),
      tags: (json['tags'] as List? ?? []).cast<String>(),
      route: route,
      area: area,
      stationen: (json['stationen'] as List)
          .map((s) => Station.fromJson(s as Map<String, dynamic>))
          .toList(),
      amenities: (json['amenities'] as List)
          .map((a) => Amenity.fromJson(a as Map<String, dynamic>))
          .toList(),
      bilder: (json['bilder'] as List? ?? const [])
          .map((b) => TrailBild.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'typ': typ,
    'form': form,
    'kurzbeschreibung': kurzbeschreibung,
    'beschreibung': beschreibung,
    'laengeKm': laengeKm,
    'dauerMin': dauerMin,
    'rundkurs': rundkurs,
    'markierung': markierung,
    'betreiber': betreiber,
    'region': region,
    'website': website,
    'eintritt': eintritt,
    if (eintrittPreise != null) 'eintrittPreise': eintrittPreise,
    if (oeffnungszeiten != null) 'oeffnungszeiten': oeffnungszeiten,
    if (besuchshinweise != null) 'besuchshinweise': besuchshinweise,
    'anreise': anreise,
    'startName': startName,
    'arten': arten,
    'tags': tags,
    'route': route.map((p) => [p.latitude, p.longitude]).toList(),
    if (area.isNotEmpty)
      'area': area.map((p) => [p.latitude, p.longitude]).toList(),
    'stationen': stationen.map((s) => s.toJson()).toList(),
    'amenities': amenities.map((a) => a.toJson()).toList(),
    if (bilder.isNotEmpty) 'bilder': bilder.map((b) => b.toJson()).toList(),
  };
}
