import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../location/location_consent_sheet.dart';
import '../../../location/location_gate.dart';
import '../../../location/location_permission_controller.dart';
import '../../../location/map_radius.dart';
import '../../../location/user_position_provider.dart';
import '../../../location/visible_trails_provider.dart';
import '../../../trail_progress/tracking/location_service.dart';
import '../../domain/trail.dart';
import 'map_radius_filter_bar.dart';
import 'map_typ_filter_bar.dart';

/// Typ-Chips, Umkreis-Chips, Banner und Leermeldung.
class MapFiltersOverlay extends ConsumerWidget {
  const MapFiltersOverlay({super.key, required this.allTrails});

  final List<Trail> allTrails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(visibleTrailsProvider) ?? const <Trail>[];
    final preferred = ref.watch(mapRadiusProvider);
    final effective = ref.watch(effectiveMapRadiusProvider);
    final enabled = ref.watch(mapLocationEnabledProvider);
    final hasFix = ref.watch(userPositionProvider).fix != null;
    final showBanner = !preferred.isAll && (!enabled || !hasFix);
    final emptyRadius =
        visible.isEmpty && allTrails.isNotEmpty && !effective.isAll;

    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.x1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MapTypFilterBar(trails: allTrails),
              const MapRadiusFilterBar(),
              if (showBanner)
                _BannerCard(
                  text: 'Standort teilen, um Orte in der Nähe zu sehen.',
                  action: 'Erlauben',
                  onAction: () async {
                    try {
                      await LocationGate.ensureMap(context, ref);
                    } on LocationException catch (e) {
                      if (context.mounted) showLocationError(context, e);
                    }
                  },
                ),
              if (emptyRadius)
                _BannerCard(
                  text: 'Keine Orte im Umkreis',
                  action: 'Umkreis vergrößern',
                  onAction: () =>
                      ref.read(mapRadiusProvider.notifier).enlarge(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.text,
    required this.action,
    required this.onAction,
  });

  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x3,
        AppSpacing.x1,
        AppSpacing.x3,
        0,
      ),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: [
              Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
              TextButton(onPressed: onAction, child: Text(action)),
            ],
          ),
        ),
      ),
    );
  }
}
