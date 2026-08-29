import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return GeolocatorLocationService();
});

enum LocationFailure {
  servicesDisabled,
  denied,
  deniedForever,
  timeout,
  inaccurate,
  tooFar,
  unavailable,
}

class LocationException implements Exception {
  LocationException(this.kind, this.message);
  final LocationFailure kind;
  final String message;

  @override
  String toString() => message;
}

class LocationFix {
  const LocationFix({
    required this.position,
    required this.at,
    this.accuracyM,
  });

  final LatLng position;
  final DateTime at;
  final double? accuracyM;
}

enum OsLocationStatus {
  unknown,
  servicesDisabled,
  denied,
  deniedForever,
  whileInUse,
  always,
}

extension OsLocationStatusX on OsLocationStatus {
  bool get isGranted =>
      this == OsLocationStatus.whileInUse || this == OsLocationStatus.always;
}

/// Seam zum Standort-Subsystem. Tests injizieren Fakes über
/// `locationServiceProvider.overrideWithValue(...)`, ohne dass
/// Geolocator/Plattform-Kanäle nötig sind.
abstract class LocationService {
  Future<OsLocationStatus> status();

  /// Wirft [LocationException], wenn Dienste deaktiviert oder die
  /// Berechtigung verweigert ist.
  Future<bool> ensurePermission({bool requestAlways = false});

  Future<void> openSystemSettings();

  Stream<LatLng> watchPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 3,
  });

  Future<LocationFix> getFix({
    Duration timeLimit = const Duration(seconds: 8),
    LocationAccuracy accuracy = LocationAccuracy.high,
  });

  /// Letzte bekannte Position oder null — wirft nie.
  Future<LatLng?> currentPosition() async {
    try {
      return (await getFix()).position;
    } catch (_) {
      return null;
    }
  }
}

/// Adapter um Geolocator + Permissions.
class GeolocatorLocationService extends LocationService {
  @override
  Future<OsLocationStatus> status() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return OsLocationStatus.servicesDisabled;
    switch (await Geolocator.checkPermission()) {
      case LocationPermission.denied:
        return OsLocationStatus.denied;
      case LocationPermission.deniedForever:
        return OsLocationStatus.deniedForever;
      case LocationPermission.whileInUse:
        return OsLocationStatus.whileInUse;
      case LocationPermission.always:
        return OsLocationStatus.always;
      case LocationPermission.unableToDetermine:
        return OsLocationStatus.unknown;
    }
  }

  @override
  Future<bool> ensurePermission({bool requestAlways = false}) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw LocationException(
        LocationFailure.servicesDisabled,
        'Standortdienste sind deaktiviert.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw LocationException(
        LocationFailure.denied,
        'Standortberechtigung wurde verweigert.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        LocationFailure.deniedForever,
        'Standortberechtigung dauerhaft verweigert. Bitte in den Einstellungen aktivieren.',
      );
    }

    // Always nur auf Mobile sinnvoll; Web ignoriert.
    if (requestAlways && !kIsWeb) {
      if (permission == LocationPermission.whileInUse) {
        permission = await Geolocator.requestPermission();
      }
    }
    return true;
  }

  @override
  Future<void> openSystemSettings() => Geolocator.openAppSettings();

  @override
  Stream<LatLng> watchPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 3,
  }) {
    final settings = kIsWeb
        ? LocationSettings(accuracy: accuracy, distanceFilter: distanceFilter)
        : defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: accuracy,
            distanceFilter: distanceFilter,
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Tour aktiv',
              notificationText: 'Standort wird für deine Tour erfasst.',
              enableWakeLock: true,
            ),
          )
        : AppleSettings(
            accuracy: accuracy,
            distanceFilter: distanceFilter,
            activityType: ActivityType.fitness,
            pauseLocationUpdatesAutomatically: false,
            showBackgroundLocationIndicator: true,
          );

    return Geolocator.getPositionStream(
      locationSettings: settings,
    ).map((p) => LatLng(p.latitude, p.longitude));
  }

  @override
  Future<LocationFix> getFix({
    Duration timeLimit = const Duration(seconds: 8),
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        ),
      );
      return LocationFix(
        position: LatLng(p.latitude, p.longitude),
        accuracyM: p.accuracy,
        at: DateTime.now(),
      );
    } on TimeoutException {
      throw LocationException(
        LocationFailure.timeout,
        'Standort nicht gefunden. Bitte erneut versuchen.',
      );
    } on LocationException {
      rethrow;
    } catch (_) {
      throw LocationException(
        LocationFailure.unavailable,
        'Standort nicht verfügbar.',
      );
    }
  }
}
