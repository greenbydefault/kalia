import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../trail_progress/tracking/location_service.dart';

const _mapEnabledKey = 'map_location_enabled';

final locationPermissionProvider =
    NotifierProvider<LocationPermissionController, OsLocationStatus>(
      LocationPermissionController.new,
    );

class LocationPermissionController extends Notifier<OsLocationStatus> {
  @override
  OsLocationStatus build() {
    _refresh();
    return OsLocationStatus.unknown;
  }

  LocationService get _location => ref.read(locationServiceProvider);

  Future<OsLocationStatus> refresh() async {
    final next = await _location.status();
    state = next;
    return next;
  }

  Future<OsLocationStatus> _refresh() => refresh();

  Future<OsLocationStatus> requestWhenInUse() async {
    await _location.ensurePermission(requestAlways: false);
    return refresh();
  }

  Future<void> openSystemSettings() => _location.openSystemSettings();
}

final mapLocationEnabledProvider =
    NotifierProvider<MapLocationEnabledNotifier, bool>(
      MapLocationEnabledNotifier.new,
    );

class MapLocationEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_mapEnabledKey) ?? false;
    if (enabled != state) state = enabled;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mapEnabledKey, enabled);
  }
}
