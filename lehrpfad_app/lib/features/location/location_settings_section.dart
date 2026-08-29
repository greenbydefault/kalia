import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_spacing.dart';
import '../trail_progress/tracking/location_service.dart';
import 'location_consent_sheet.dart';
import 'location_gate.dart';
import 'location_permission_controller.dart';
import 'map_radius.dart';
import 'user_position_provider.dart';

/// Standort-Einstellungen — in allen drei Konto-Zuständen.
class LocationSettingsSection extends ConsumerWidget {
  const LocationSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final enabled = ref.watch(mapLocationEnabledProvider);
    final radius = ref.watch(mapRadiusProvider);
    final status = ref.watch(locationPermissionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Standort', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.x2),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Standort für die Karte'),
          subtitle: const Text('Umkreis und Locate. Die Tour fragt separat.'),
          value: enabled,
          onChanged: (value) => _onToggle(context, ref, value),
        ),
        const SizedBox(height: AppSpacing.x2),
        Text('Umkreis', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.x1),
        Wrap(
          spacing: AppSpacing.x2,
          children: [
            for (final option in MapRadius.values)
              ChoiceChip(
                label: Text(option.label),
                selected: radius == option,
                onSelected: (_) =>
                    ref.read(mapRadiusProvider.notifier).select(option),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.x3),
        Text(_statusLabel(status), style: theme.textTheme.bodySmall),
        if (!kIsWeb &&
            (status == OsLocationStatus.deniedForever ||
                status == OsLocationStatus.servicesDisabled))
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => ref
                  .read(locationPermissionProvider.notifier)
                  .openSystemSettings(),
              child: const Text('In den Systemeinstellungen öffnen'),
            ),
          ),
        const SizedBox(height: AppSpacing.x2),
        Text(
          'Umkreis und Vor-Ort bleiben auf dem Gerät. '
          'Während einer Tour speichern wir die letzte Position nur, '
          'solange die Tour läuft — danach wird sie gelöscht.',
          style: theme.textTheme.bodySmall,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () =>
                ref.read(userPositionProvider.notifier).clearStored(),
            child: const Text('Letzte bekannte Position löschen'),
          ),
        ),
      ],
    );
  }

  Future<void> _onToggle(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    if (!value) {
      await ref.read(mapLocationEnabledProvider.notifier).setEnabled(false);
      return;
    }
    try {
      final ok = await LocationGate.ensureMap(context, ref);
      if (!ok) {
        await ref.read(mapLocationEnabledProvider.notifier).setEnabled(false);
      }
    } on LocationException catch (e) {
      await ref.read(mapLocationEnabledProvider.notifier).setEnabled(false);
      if (context.mounted) showLocationError(context, e);
    }
  }

  String _statusLabel(OsLocationStatus status) => switch (status) {
    OsLocationStatus.whileInUse ||
    OsLocationStatus.always => 'Status: Standort erlaubt',
    OsLocationStatus.denied => 'Status: Standort verweigert',
    OsLocationStatus.deniedForever => 'Status: dauerhaft verweigert',
    OsLocationStatus.servicesDisabled => 'Status: Standortdienste aus',
    OsLocationStatus.unknown => 'Status: unbekannt',
  };
}
