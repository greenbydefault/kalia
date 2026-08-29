import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../trail/domain/trail.dart';
import '../trail_progress/tracking/location_service.dart';
import 'location_consent_sheet.dart';
import 'location_permission_controller.dart';
import 'proximity.dart';
import 'user_position_provider.dart';

/// Consent, Permission und Vor-Ort-Eligibility für Karte und Tour.
abstract final class LocationGate {
  static Future<bool> ensureMap(BuildContext context, WidgetRef ref) async {
    final enabled = ref.read(mapLocationEnabledProvider);
    final status = await ref.read(locationPermissionProvider.notifier).refresh();
    if (enabled && status.isGranted) return true;

    if (status == OsLocationStatus.deniedForever) {
      throw LocationException(
        LocationFailure.deniedForever,
        LocationException.deniedForeverMessage,
      );
    }
    if (status == OsLocationStatus.servicesDisabled) {
      throw LocationException(
        LocationFailure.servicesDisabled,
        'Standortdienste sind deaktiviert.',
      );
    }

    if (!status.isGranted) {
      if (!context.mounted) return false;
      final ok = await showLocationConsentSheet(
        context,
        LocationConsentKind.map,
      );
      if (!ok) return false;
      await ref.read(locationPermissionProvider.notifier).requestWhenInUse();
    }
    await ref.read(mapLocationEnabledProvider.notifier).setEnabled(true);
    await ref.read(userPositionProvider.notifier).refresh(force: true);
    return ref.read(locationPermissionProvider).isGranted;
  }

  static Future<void> ensureTour(BuildContext context, WidgetRef ref) async {
    final status = await ref.read(locationPermissionProvider.notifier).refresh();
    if (status.isGranted) return;

    if (status == OsLocationStatus.deniedForever) {
      throw LocationException(
        LocationFailure.deniedForever,
        LocationException.deniedForeverMessage,
      );
    }
    if (status == OsLocationStatus.servicesDisabled) {
      throw LocationException(
        LocationFailure.servicesDisabled,
        'Standortdienste sind deaktiviert.',
      );
    }

    if (!context.mounted) {
      throw LocationException(
        LocationFailure.denied,
        'Standortberechtigung wurde verweigert.',
      );
    }
    final ok = await showLocationConsentSheet(context, LocationConsentKind.tour);
    if (!ok) {
      throw LocationException(
        LocationFailure.denied,
        'Standortberechtigung wurde verweigert.',
      );
    }
    await ref.read(locationPermissionProvider.notifier).requestWhenInUse();
  }

  static TourEligibility tourEligibility(Trail trail, LocationFix? fix) {
    final site = onSiteResult(trail, fix);
    final distanceM = fix == null
        ? null
        : distanceToTrailM(trail, fix.position);
    final blocked = site == OnSiteResult.no;
    if (!blocked || distanceM == null) {
      return TourEligibility(blocked: blocked, distanceM: distanceM);
    }
    final formatted = formatDistanceM(distanceM);
    return TourEligibility(
      blocked: true,
      distanceM: distanceM,
      label: 'Noch $formatted',
      tooltip: 'Noch $formatted zum Start',
    );
  }
}

class TourEligibility {
  const TourEligibility({
    required this.blocked,
    this.distanceM,
    this.label,
    this.tooltip,
  });

  final bool blocked;
  final double? distanceM;
  final String? label;
  final String? tooltip;
}
