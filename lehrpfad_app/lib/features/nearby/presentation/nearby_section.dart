import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../data/nearby_providers.dart';
import 'nearby_carousel.dart';

/// Peek-Slider der Orte im Umkreis (Accordion-Inhalt).
class NearbySection extends ConsumerWidget {
  const NearbySection({super.key, required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(nearbyPlacesProvider(trailId));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (e, _) => Text(
        'Orte konnten nicht geladen werden.',
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
      ),
      data: (treffer) {
        if (treffer.isEmpty) {
          return Text(
            'Keine Orte im Umkreis hinterlegt.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.inkMuted,
            ),
          );
        }
        return NearbyCarousel(
          treffer: treffer,
          onTap: (t) =>
              ref.read(selectedNearbyPlaceProvider.notifier).select(t),
        );
      },
    );
  }
}
