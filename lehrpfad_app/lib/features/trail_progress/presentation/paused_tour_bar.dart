import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../location/location_consent_sheet.dart';
import '../../trail/domain/trail.dart';
import '../data/trail_progress_providers.dart';
import '../tracking/location_service.dart';
import '../tracking/walk_tracking_controller.dart';

/// Aktive Tour, aber kein GPS — User ist nicht vor Ort oder Permission weg.
class PausedTourBar extends ConsumerWidget {
  const PausedTourBar({super.key, required this.trail});

  final Trail trail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tour fortsetzen, wenn du wieder am Ort bist.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => _resume(context, ref),
                  child: const Text('Weiter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resume(BuildContext context, WidgetRef ref) async {
    final walk = ref.read(activeWalkProvider).asData?.value;
    if (walk == null) return;
    try {
      await ensureTourLocation(context, ref);
      await ref.read(walkSnapshotProvider.notifier).resumeTour(trail, walk);
    } on LocationException catch (e) {
      if (context.mounted) showLocationError(context, e);
    } catch (e) {
      if (context.mounted) showLocationError(context, e);
    }
  }
}
