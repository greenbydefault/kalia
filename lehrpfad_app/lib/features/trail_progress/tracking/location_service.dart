import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Profile des einen Standort-Service (Spec 3.1). Es gibt einen Stream, er
/// liefert, was das höchste aktive Profil verlangt.
enum LocationProfile {
  /// Standard: kein Stream.
  idle,

  /// Trail Modus läuft.
  trailMode,

  /// Nur während der Mittelung einer Schnellmeldung (3 bis 8 s).
  pointFix,

  /// Aufnahme läuft oder ist pausiert: höchste Genauigkeit, Vordergrunddienst.
  recording,
}

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

  static const deniedForeverMobile =
      'Standortberechtigung dauerhaft verweigert. Bitte in den Einstellungen aktivieren.';
  static const deniedForeverWeb =
      'Standort ist im Browser blockiert. Schloss in der Adressleiste → '
      'Standort zulassen, dann die Seite neu laden.';

  static String get deniedForeverMessage =>
      kIsWeb ? deniedForeverWeb : deniedForeverMobile;
}

class LocationFix {
  const LocationFix({required this.position, required this.at, this.accuracyM});

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

  /// Fixes mit Genauigkeit für das gegebene Profil. Alle Abonnenten teilen
  /// sich einen Stream, das höchste aktive Profil bestimmt die Einstellung.
  /// Standard: Positionen ohne Genauigkeit aus [watchPosition].
  Stream<LocationFix> watchFixes(LocationProfile profile) =>
      watchPosition().map((p) => LocationFix(position: p, at: DateTime.now()));

  /// iOS „reduced“ / Android „coarse“ ergibt `false`. Ohne Information
  /// (Web, Fehler) gilt der Standort als genau.
  Future<bool> isPrecise() async => true;

  /// iOS: temporär volle Genauigkeit anfragen. Android: nichts anzufragen,
  /// der Nutzer muss „Genau“ in den Einstellungen setzen.
  Future<bool> requestPreciseAccuracy() async => isPrecise();

  /// Systemseite „Standortdienste“.
  Future<void> openLocationSettings() async {}

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
        // geolocator_web mappt Browser-denied immer auf deniedForever.
        return kIsWeb
            ? OsLocationStatus.denied
            : OsLocationStatus.deniedForever;
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
    if (permission == LocationPermission.denied ||
        (kIsWeb && permission == LocationPermission.deniedForever)) {
      permission = await Geolocator.requestPermission();
      // geolocator_web meldet jeden Positionsfehler als deniedForever, auch
      // wenn der Browser die Freigabe erteilt hat. Der Stand der Permissions
      // API entscheidet.
      if (kIsWeb && permission == LocationPermission.deniedForever) {
        permission = await Geolocator.checkPermission();
      }
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
        LocationException.deniedForeverMessage,
      );
    }

    // „Immer“-Zugriff wird nie angefragt; [requestAlways] bleibt wirkungslos.
    return true;
  }

  @override
  Future<void> openSystemSettings() async {
    if (kIsWeb) return;
    await Geolocator.openAppSettings();
  }

  // ── Ein Stream für alle Profile ───────────────────────────────────
  final _active = <Object, LocationProfile>{};
  final _fixes = StreamController<LocationFix>.broadcast();
  StreamSubscription<Position>? _source;
  LocationProfile _open = LocationProfile.idle;

  LocationProfile get _highest {
    var top = LocationProfile.idle;
    for (final p in _active.values) {
      if (p.index > top.index) top = p;
    }
    return top;
  }

  void _reconfigure() {
    final want = _highest;
    if (want == _open && (_source != null || want == LocationProfile.idle)) {
      return;
    }
    unawaited(_source?.cancel());
    _source = null;
    _open = want;
    if (want == LocationProfile.idle) return;
    _source = Geolocator.getPositionStream(locationSettings: _settings(want))
        .listen(
          (p) => _fixes.add(
            LocationFix(
              position: LatLng(p.latitude, p.longitude),
              accuracyM: p.accuracy,
              at: DateTime.now(),
            ),
          ),
          onError: _fixes.addError,
        );
  }

  LocationSettings _settings(LocationProfile profile) {
    if (kIsWeb) {
      return LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      );
    }
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    switch (profile) {
      case LocationProfile.recording:
        return isAndroid
            ? AndroidSettings(
                accuracy: LocationAccuracy.best,
                distanceFilter: 0,
                intervalDuration: const Duration(seconds: 2),
                // Vordergrunddienst mit sichtbarer Benachrichtigung,
                // kein Bildschirm-Dauer-An (Spec 12.3).
                foregroundNotificationConfig:
                    const ForegroundNotificationConfig(
                      notificationTitle: 'Kalia nimmt euren Pfad auf',
                      notificationText: 'Aufnahme läuft',
                    ),
              )
            : AppleSettings(
                accuracy: LocationAccuracy.best,
                distanceFilter: 0,
                activityType: ActivityType.fitness,
                pauseLocationUpdatesAutomatically: false,
                allowBackgroundLocationUpdates: true,
                showBackgroundLocationIndicator: true,
              );
      case LocationProfile.pointFix:
        return isAndroid
            ? AndroidSettings(
                accuracy: LocationAccuracy.best,
                distanceFilter: 0,
                intervalDuration: const Duration(seconds: 1),
              )
            : AppleSettings(
                accuracy: LocationAccuracy.best,
                distanceFilter: 0,
                activityType: ActivityType.fitness,
                pauseLocationUpdatesAutomatically: false,
              );
      case LocationProfile.trailMode:
      case LocationProfile.idle:
        return isAndroid
            ? AndroidSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 3,
                foregroundNotificationConfig:
                    const ForegroundNotificationConfig(
                      notificationTitle: 'Tour aktiv',
                      notificationText: 'Standort wird für deine Tour erfasst.',
                      enableWakeLock: true,
                    ),
              )
            : AppleSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 3,
                activityType: ActivityType.fitness,
                pauseLocationUpdatesAutomatically: false,
                showBackgroundLocationIndicator: true,
              );
    }
  }

  @override
  Stream<LocationFix> watchFixes(LocationProfile profile) {
    return Stream<LocationFix>.multi((controller) {
      final token = Object();
      _active[token] = profile;
      _reconfigure();
      final sub = _fixes.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = () async {
        await sub.cancel();
        _active.remove(token);
        _reconfigure();
      };
    });
  }

  @override
  Stream<LatLng> watchPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 3,
  }) => watchFixes(LocationProfile.trailMode).map((f) => f.position);

  @override
  Future<bool> isPrecise() async {
    if (kIsWeb) return true;
    try {
      return await Geolocator.getLocationAccuracy() ==
          LocationAccuracyStatus.precise;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<bool> requestPreciseAccuracy() async {
    if (kIsWeb) return true;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final r = await Geolocator.requestTemporaryFullAccuracy(
          purposeKey: 'KaliaReport',
        );
        return r == LocationAccuracyStatus.precise;
      }
    } catch (_) {}
    return isPrecise();
  }

  @override
  Future<void> openLocationSettings() async {
    if (kIsWeb) return;
    await Geolocator.openLocationSettings();
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
