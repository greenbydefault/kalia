import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../location/location_consent_sheet.dart';
import '../../../location/user_position_provider.dart';
import '../../../trail_progress/tracking/location_service.dart';

class LocateFab extends ConsumerWidget {
  const LocateFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(userPositionProvider).loading;
    return FloatingActionButton.small(
      heroTag: 'locate',
      tooltip: 'Meinen Standort',
      onPressed: loading ? null : () => _locate(context, ref),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location),
    );
  }

  Future<void> _locate(BuildContext context, WidgetRef ref) async {
    try {
      final ok = await ensureMapLocation(context, ref);
      if (!ok) return;
      final fix = await ref
          .read(userPositionProvider.notifier)
          .refresh(force: true);
      if (fix != null) {
        ref.read(locateTargetProvider.notifier).goTo(fix.position);
      }
    } on LocationException catch (e) {
      if (context.mounted) showLocationError(context, e);
    }
  }
}
