import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../location/location_consent_sheet.dart';
import '../../../location/map_radius.dart';
import '../../../location/user_position_provider.dart';
import '../../../trail_progress/tracking/location_service.dart';
import 'map_typ_filter_bar.dart';

/// Chip-Leiste: 20 / 50 / 100 km / Alle.
class MapRadiusFilterBar extends ConsumerWidget {
  const MapRadiusFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferred = ref.watch(mapRadiusProvider);
    final effective = ref.watch(effectiveMapRadiusProvider);
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
        itemCount: MapRadius.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.x2),
        itemBuilder: (context, index) {
          final radius = MapRadius.values[index];
          return Center(
            child: MapFilterChip(
              label: radius.label,
              selected: effective == radius,
              scheme: scheme,
              onSelected: (_) => _onSelect(context, ref, radius, preferred),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onSelect(
    BuildContext context,
    WidgetRef ref,
    MapRadius radius,
    MapRadius preferred,
  ) async {
    await ref.read(mapRadiusProvider.notifier).select(radius);
    if (radius.isAll) return;
    if (!context.mounted) return;
    try {
      final ok = await ensureMapLocation(context, ref);
      if (!ok && context.mounted) {
        await ref.read(mapRadiusProvider.notifier).select(MapRadius.all);
      }
    } on LocationException catch (e) {
      if (context.mounted) showLocationError(context, e);
      await ref.read(mapRadiusProvider.notifier).select(
        preferred.isAll ? MapRadius.all : preferred,
      );
    }
  }
}
