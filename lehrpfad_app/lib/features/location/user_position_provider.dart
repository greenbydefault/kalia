import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../trail_progress/data/trail_progress_providers.dart';
import '../trail_progress/tracking/location_service.dart';
import '../trail_progress/tracking/walk_tracking_controller.dart';
import 'location_permission_controller.dart';
import 'map_radius.dart';

const positionStaleAfter = Duration(minutes: 5);
const _latKey = 'last_map_lat';
const _lonKey = 'last_map_lon';
const _atKey = 'last_map_at';
const _roundStep = 0.001;

class UserPosition {
  const UserPosition({this.fix, this.lastError, this.loading = false});

  final LocationFix? fix;
  final LocationException? lastError;
  final bool loading;

  UserPosition copyWith({
    LocationFix? fix,
    LocationException? lastError,
    bool? loading,
    bool clearError = false,
  }) {
    return UserPosition(
      fix: fix ?? this.fix,
      lastError: clearError ? null : (lastError ?? this.lastError),
      loading: loading ?? this.loading,
    );
  }
}

final userPositionProvider =
    NotifierProvider<UserPositionController, UserPosition>(
      UserPositionController.new,
    );

class UserPositionController extends Notifier<UserPosition> {
  AppLifecycleListener? _lifecycle;

  @override
  UserPosition build() {
    _lifecycle = AppLifecycleListener(onResume: () => unawaitedRefresh());
    ref.onDispose(() => _lifecycle?.dispose());
    _restoreThenRefresh();
    return const UserPosition();
  }

  LocationService get _location => ref.read(locationServiceProvider);

  void unawaitedRefresh() {
    refreshIfStale();
  }

  Future<void> _restoreThenRefresh() async {
    await _restoreStored();
    await refreshIfStale();
  }

  Future<void> _restoreStored() async {
    if (!ref.read(mapLocationEnabledProvider)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_latKey);
      final lon = prefs.getDouble(_lonKey);
      final atMs = prefs.getInt(_atKey);
      if (lat == null || lon == null || atMs == null) return;
      state = UserPosition(
        fix: LocationFix(
          position: LatLng(lat, lon),
          at: DateTime.fromMillisecondsSinceEpoch(atMs),
        ),
      );
    } catch (_) {}
  }

  bool get _tourActive =>
      ref.read(activeWalkProvider).asData?.value != null &&
      ref.read(walkSnapshotProvider) != null;

  Future<LocationFix?> refreshIfStale() async {
    if (_tourActive) return state.fix;
    if (!ref.read(mapLocationEnabledProvider)) return state.fix;
    final status = await ref.read(locationPermissionProvider.notifier).refresh();
    if (!status.isGranted) return state.fix;
    final last = state.fix;
    if (last != null &&
        DateTime.now().difference(last.at) < positionStaleAfter) {
      return last;
    }
    return refresh(force: true);
  }

  Future<LocationFix?> refresh({bool force = false}) async {
    if (_tourActive) return state.fix;
    if (!force && !ref.read(mapLocationEnabledProvider)) return state.fix;
    state = state.copyWith(loading: true, clearError: true);
    try {
      await ref.read(locationPermissionProvider.notifier).requestWhenInUse();
      final fix = await _location.getFix();
      state = UserPosition(fix: fix);
      await _persist(fix);
      return fix;
    } on LocationException catch (e) {
      state = UserPosition(fix: state.fix, lastError: e);
      return null;
    } catch (_) {
      state = UserPosition(
        fix: state.fix,
        lastError: LocationException(
          LocationFailure.unavailable,
          'Standort nicht verfügbar.',
        ),
      );
      return null;
    }
  }

  Future<void> clearStored() async {
    state = const UserPosition();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_latKey);
    await prefs.remove(_lonKey);
    await prefs.remove(_atKey);
  }

  Future<void> _persist(LocationFix fix) async {
    try {
      final rounded = _roundForStorage(fix.position);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_latKey, rounded.latitude);
      await prefs.setDouble(_lonKey, rounded.longitude);
      await prefs.setInt(_atKey, fix.at.millisecondsSinceEpoch);
    } catch (_) {}
  }
}

LatLng _roundForStorage(LatLng p) => LatLng(
  (p.latitude / _roundStep).round() * _roundStep,
  (p.longitude / _roundStep).round() * _roundStep,
);

/// Effektiver Umkreis: ohne Fix oder ohne Consent = Alle.
final effectiveMapRadiusProvider = Provider<MapRadius>((ref) {
  final preferred = ref.watch(mapRadiusProvider);
  final enabled = ref.watch(mapLocationEnabledProvider);
  final fix = ref.watch(userPositionProvider).fix;
  if (!enabled || fix == null) return MapRadius.all;
  return preferred;
});

/// Kamera-Ziel vom FAB „Meinen Standort“. [nonce] macht jeden Tipp einzigartig,
/// auch wenn die Koordinate gleich bleibt (erneutes Zentrieren nach Pan).
@immutable
class LocateTarget {
  const LocateTarget({required this.position, required this.nonce});

  final LatLng position;
  final int nonce;

  @override
  bool operator ==(Object other) =>
      other is LocateTarget &&
      other.nonce == nonce &&
      other.position == position;

  @override
  int get hashCode => Object.hash(nonce, position);
}

final locateTargetProvider =
    NotifierProvider<LocateTargetNotifier, LocateTarget?>(
  LocateTargetNotifier.new,
);

class LocateTargetNotifier extends Notifier<LocateTarget?> {
  int _nonce = 0;

  @override
  LocateTarget? build() => null;

  void goTo(LatLng? target) {
    if (target == null) {
      state = null;
      return;
    }
    state = LocateTarget(position: target, nonce: ++_nonce);
  }
}
