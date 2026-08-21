import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_spacing.dart';
import '../../shared/widgets/show_app_modal_sheet.dart';
import '../trail_progress/tracking/location_service.dart';
import 'location_permission_controller.dart';
import 'user_position_provider.dart';

enum LocationConsentKind { map, tour }

/// Copy für Map- und Tour-Consent — Onboarding und Sheet lesen dieselben Texte.
abstract final class LocationConsentCopy {
  static const mapTitle = 'Orte in deiner Nähe';
  static const mapBody =
      'Wir nutzen deinen Standort, um Orte im Umkreis zu zeigen. '
      'Der Standort bleibt auf dem Gerät, wir speichern ihn nicht.';
  static const tourTitle = 'Standort für die Tour';
  static const tourBody =
      'Für die Tour brauchen wir GPS, um Stationen zu erkennen. '
      'Solange die Tour läuft, kann das auch im Hintergrund weiterlaufen.';

  static String title(LocationConsentKind kind) =>
      kind == LocationConsentKind.map ? mapTitle : tourTitle;

  static String body(LocationConsentKind kind) =>
      kind == LocationConsentKind.map ? mapBody : tourBody;
}

Future<bool> showLocationConsentSheet(
  BuildContext context,
  LocationConsentKind kind,
) async {
  final result = await showAppModalSheet<bool>(
    context: context,
    builder: (ctx) => _LocationConsentSheet(kind: kind),
  );
  return result ?? false;
}

class _LocationConsentSheet extends StatelessWidget {
  const _LocationConsentSheet({required this.kind});

  final LocationConsentKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          LocationConsentCopy.title(kind),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.x3),
        Text(LocationConsentCopy.body(kind), style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.x5),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Erlauben'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Nicht jetzt'),
        ),
      ],
    );
  }
}

Future<bool> ensureMapLocation(BuildContext context, WidgetRef ref) async {
  final enabled = ref.read(mapLocationEnabledProvider);
  final status = await ref.read(locationPermissionProvider.notifier).refresh();
  if (enabled && status.isGranted) return true;

  if (status == OsLocationStatus.deniedForever) {
    throw LocationException(
      LocationFailure.deniedForever,
      'Standortberechtigung dauerhaft verweigert. Bitte in den Einstellungen aktivieren.',
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
    final ok = await showLocationConsentSheet(context, LocationConsentKind.map);
    if (!ok) return false;
    await ref.read(locationPermissionProvider.notifier).requestWhenInUse();
  }
  await ref.read(mapLocationEnabledProvider.notifier).setEnabled(true);
  await ref.read(userPositionProvider.notifier).refresh(force: true);
  return ref.read(locationPermissionProvider).isGranted;
}

Future<void> ensureTourLocation(BuildContext context, WidgetRef ref) async {
  final status = await ref.read(locationPermissionProvider.notifier).refresh();
  if (status.isGranted) return;

  if (status == OsLocationStatus.deniedForever) {
    throw LocationException(
      LocationFailure.deniedForever,
      'Standortberechtigung dauerhaft verweigert. Bitte in den Einstellungen aktivieren.',
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

void showLocationError(BuildContext context, Object error) {
  final messenger = ScaffoldMessenger.of(context);
  final text = error is LocationException ? error.message : '$error';
  final forever =
      error is LocationException && error.kind == LocationFailure.deniedForever;
  messenger.showSnackBar(
    SnackBar(
      content: Text(text),
      action: forever
          ? SnackBarAction(
              label: 'Einstellungen',
              onPressed: () {
                LocationService().openSystemSettings();
              },
            )
          : null,
    ),
  );
}
