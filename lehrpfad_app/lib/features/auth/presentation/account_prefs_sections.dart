import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../location/user_position_provider.dart';
import '../../nearby_trails/presentation/place_pill.dart';
import '../../onboarding/data/onboarding_prefs_provider.dart';
import '../../onboarding/domain/age_group.dart';
import '../../onboarding/presentation/screens/group_screen.dart';
import '../../onboarding/presentation/widgets/stroller_switch.dart';

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

/// „Startpunkt“: gewählter Ort oder Gerätestandort, Wechsel über das Sheet.
class StartpointSection extends ConsumerWidget {
  const StartpointSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final label = PlacePill.label(
      placeName: ref.watch(onboardingPrefsValueProvider).place?.label,
      hasAnchor: ref.watch(mapAnchorProvider) != null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Startpunkt', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.x1),
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            TextButton(
              onPressed: () => showPlaceChangeSheet(context, ref),
              child: const Text('Ändern'),
            ),
          ],
        ),
      ],
    );
  }
}
