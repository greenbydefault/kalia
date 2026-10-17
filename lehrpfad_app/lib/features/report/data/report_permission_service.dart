import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../trail_progress/tracking/location_service.dart';
import '../logic/permission_logic.dart';

final reportPermissionServiceProvider = Provider<ReportPermissionService>(
  (ref) => ReportPermissionService(ref.watch(locationServiceProvider)),
);

/// Brücke zwischen [LocationService] und der Berechtigungslogik (Spec 3).
class ReportPermissionService {
  ReportPermissionService(this._location);

  final LocationService _location;

  static const _askedKey = 'report.perm.asked';

  Future<bool> _asked() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_askedKey) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _markAsked() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_askedKey, true);
    } catch (_) {}
  }

  /// Aktueller Stand. „denied“ des Systems heißt „noch nicht gefragt“ oder
  /// „einmal abgelehnt“. Wir merken uns, ob wir schon gefragt haben.
  Future<PermSnapshot> snapshot() async {
    final status = await _location.status();
    final serviceEnabled = status != OsLocationStatus.servicesDisabled;
    ReportPermission permission;
    switch (status) {
      case OsLocationStatus.unknown:
        permission = ReportPermission.notDetermined;
      case OsLocationStatus.servicesDisabled:
      case OsLocationStatus.denied:
        permission = await _asked()
            ? ReportPermission.denied
            : ReportPermission.notDetermined;
      case OsLocationStatus.deniedForever:
        permission = ReportPermission.deniedForever;
      case OsLocationStatus.whileInUse:
      case OsLocationStatus.always:
        permission = ReportPermission.whileInUse;
    }
    final precise =
        permission == ReportPermission.whileInUse &&
        await _location.isPrecise();
    return PermSnapshot(
      serviceEnabled: serviceEnabled,
      permission: permission,
      precise: precise || permission != ReportPermission.whileInUse,
    );
  }

  /// Systemdialog Standort. Fehler heißen „abgelehnt“, der Stand wird danach
  /// über [snapshot] neu gelesen.
  Future<void> requestPermission() async {
    await _markAsked();
    try {
      await _location.ensurePermission();
    } on LocationException {
      // Stand kommt aus snapshot().
    }
  }

  Future<void> requestPrecise() => _location.requestPreciseAccuracy();

  Future<void> openAppSettings() => _location.openSystemSettings();

  Future<void> openLocationSettings() => _location.openLocationSettings();
}

/// Einmal pro Installation: Akku-Hinweis (Android, Spec 3.4 Schritt 5).
class BatteryHintFlag {
  static const _key = 'report.battery_hint_shown';

  static Future<bool> shouldShow() async {
    try {
      return !((await SharedPreferences.getInstance()).getBool(_key) ?? false);
    } catch (_) {
      return false;
    }
  }

  static Future<void> markShown() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, true);
    } catch (_) {}
  }
}
