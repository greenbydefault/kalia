import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_spacing.dart';
import '../../location/location_permission_controller.dart';
import '../../nearby_trails/data/bezug_provider.dart';
import '../../nearby_trails/domain/bezugspunkt.dart';
import '../../nearby_trails/presentation/startpunkt_sheet.dart';
import '../../onboarding/data/onboarding_prefs_provider.dart';
import '../../onboarding/domain/age_group.dart';
import '../../onboarding/presentation/screens/group_screen.dart';
import '../../onboarding/presentation/widgets/stroller_switch.dart';
import '../../trail_progress/tracking/location_service.dart';

/// „Für euch“: Altersgruppen und Kinderwagen aus dem Onboarding, änderbar.
class GroupPrefsSection extends ConsumerWidget {
  const GroupPrefsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prefs = ref.watch(onboardingPrefsValueProvider);
    final notifier = ref.read(onboardingPrefsProvider.notifier);

    void toggle(AgeGroup g) {
      final groups = {...prefs.ageGroups};
      var stroller = prefs.stroller;
      if (!groups.remove(g)) {
        groups.add(g);
        if (g == AgeGroup.under3) stroller = true;
      }
      notifier.setGroups(groups, stroller: stroller);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Für euch', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.x2),
        Text('Mit wem seid ihr unterwegs?', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.x1),
        Wrap(
          spacing: AppSpacing.x2,
          children: [
            for (final g in AgeGroup.values)
              FilterChip(
                label: Text(g.title),
                selected: prefs.ageGroups.contains(g),
                onSelected: (_) => toggle(g),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.x2),
        StrollerSwitch(
          value: prefs.stroller,
          onChanged: (v) => notifier.setGroups(prefs.ageGroups, stroller: v),
        ),
        const SizedBox(height: AppSpacing.x2),
        GroupHintBox(groups: prefs.ageGroups, stroller: prefs.stroller),
      ],
    );
  }
}

/// „Startpunkt“: eine Zeile für Ort, Standort oder keinen. Liest denselben
/// Bezug wie die Karte, Wechsel über das Sheet.
class StartpointCard extends ConsumerWidget {
  const StartpointCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bezug = ref.watch(aktuellerBezugProvider);
    final zustand = ref.watch(standortZustandProvider);
    final status = ref.watch(locationPermissionProvider);
    final hasPlace = ref.watch(onboardingPrefsValueProvider).place != null;

    final gesperrt =
        !kIsWeb &&
        !hasPlace &&
        (status == OsLocationStatus.deniedForever ||
            status == OsLocationStatus.servicesDisabled);
    final titel = startpunktTitel(
      bezug: bezug,
      ermittelt: zustand == StandortZustand.erteiltErmittelt,
    );
    final icon = bezug?.quelle == BezugQuelle.gps
        ? PhosphorIcons.navigationArrow
        : PhosphorIcons.mapPin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Startpunkt', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.x2),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: PhosphorIcon(icon),
            title: Text(titel),
            subtitle: Text(
              gesperrt
                  ? 'Standort ist gesperrt. Einen Ort eingeben geht trotzdem.'
                  : 'Von hier rechnen wir die Anfahrt.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showStartpunktSheet(context, ref),
          ),
        ),
        if (gesperrt)
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
          'Der Standort bleibt auf dem Gerät. Während einer Tour speichern '
          'wir die Position nur, solange die Tour läuft.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
