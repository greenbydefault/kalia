import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../tracking/walk_snapshot.dart';
import '../tracking/walk_tracking_controller.dart';

/// Kompakte Bottom-Bar im Walk-Mode.
class WalkModeBar extends ConsumerWidget {
  const WalkModeBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(walkSnapshotProvider);
    if (snapshot == null) return const SizedBox.shrink();

    return AnimatedSlide(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      offset: Offset.zero,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (snapshot.locationError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        snapshot.locationError!,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    )
                  else if (snapshot.offTrack)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Du bist abseits der Route',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (snapshot.showRouteProgress)
                              Text(
                                '${snapshot.progressPercent} %',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            Text(
                              _nextLabel(snapshot),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Tour beenden',
                        onPressed: () => ref
                            .read(walkSnapshotProvider.notifier)
                            .stopTour(abandon: true),
                        icon: const Icon(Icons.stop_circle_outlined),
                      ),
                      IconButton(
                        tooltip: 'Als gelaufen abschließen',
                        onPressed: () => ref
                            .read(walkSnapshotProvider.notifier)
                            .endTourCompleted(),
                        icon: const Icon(Icons.check_circle_outline),
                        color: AppColors.brand,
                      ),
                    ],
                  ),
                  if (snapshot.showRouteProgress) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: snapshot.progressRatio.clamp(0.0, 1.0),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _nextLabel(WalkSnapshot snapshot) {
    final next = snapshot.nextStation;
    if (next == null) return 'Fast geschafft';
    return 'Nächste Station: ${next.titel}';
  }
}
