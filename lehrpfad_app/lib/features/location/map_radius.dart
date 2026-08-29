import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../trail/domain/trail.dart';
import 'proximity.dart';

enum MapRadius {
  km20(20),
  km50(50),
  km100(100),
  all(null);

  const MapRadius(this.km);
  final int? km;

  bool get isAll => km == null;
  double? get meters => km == null ? null : km! * 1000.0;

  String get label => switch (this) {
    MapRadius.km20 => '20 km',
    MapRadius.km50 => '50 km',
    MapRadius.km100 => '100 km',
    MapRadius.all => 'Alle',
  };

  String get wire => switch (this) {
    MapRadius.km20 => '20',
    MapRadius.km50 => '50',
    MapRadius.km100 => '100',
    MapRadius.all => 'all',
  };

  static MapRadius fromWire(String? raw) => switch (raw) {
    '20' => MapRadius.km20,
    '50' => MapRadius.km50,
    '100' => MapRadius.km100,
    'all' => MapRadius.all,
    _ => MapRadius.all,
  };

  MapRadius get enlarged => switch (this) {
    MapRadius.km20 => MapRadius.km50,
    MapRadius.km50 => MapRadius.km100,
    MapRadius.km100 => MapRadius.all,
    MapRadius.all => MapRadius.all,
  };
}

const _radiusKey = 'map_radius';

final mapRadiusProvider = NotifierProvider<MapRadiusNotifier, MapRadius>(
  MapRadiusNotifier.new,
);

class MapRadiusNotifier extends Notifier<MapRadius> {
  @override
  MapRadius build() {
    _load();
    return MapRadius.all;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final parsed = MapRadius.fromWire(prefs.getString(_radiusKey));
    if (parsed != state) state = parsed;
  }

  Future<void> select(MapRadius radius) async {
    state = radius;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_radiusKey, radius.wire);
  }

  Future<void> enlarge() => select(state.enlarged);
}

List<Trail> filterTrailsByRadius(
  List<Trail> trails, {
  required MapRadius radius,
  LatLng? user,
}) {
  if (radius.isAll || user == null) return trails;
  final maxM = radius.meters!;
  return [
    for (final trail in trails)
      if (_within(trail, user, maxM)) trail,
  ];
}

bool _within(Trail trail, LatLng user, double maxM) {
  final d = distanceToTrailM(trail, user);
  return d != null && d <= maxM;
}
