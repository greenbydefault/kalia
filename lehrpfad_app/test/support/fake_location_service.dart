import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/features/trail_progress/tracking/location_service.dart';

/// Steuerbarer Standort-Fake. [status] ist der OS-Zustand, [onRequest]
/// simuliert die Antwort des System-Dialogs.
class FakeLocationService extends LocationService {
  FakeLocationService({
    this.status0 = OsLocationStatus.denied,
    this.afterRequest = OsLocationStatus.whileInUse,
  });

  OsLocationStatus status0;
  OsLocationStatus afterRequest;
  int requests = 0;

  @override
  Future<OsLocationStatus> status() async => status0;

  @override
  Future<bool> ensurePermission({bool requestAlways = false}) async {
    requests++;
    status0 = afterRequest;
    if (!status0.isGranted) {
      throw LocationException(
        LocationFailure.denied,
        'Standortberechtigung wurde verweigert.',
      );
    }
    return true;
  }

  @override
  Future<void> openSystemSettings() async {}

  @override
  Stream<LatLng> watchPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 3,
  }) => const Stream.empty();

  @override
  Future<LocationFix> getFix({
    Duration timeLimit = const Duration(seconds: 8),
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async =>
      LocationFix(position: const LatLng(51.34, 12.37), at: DateTime.now());
}
