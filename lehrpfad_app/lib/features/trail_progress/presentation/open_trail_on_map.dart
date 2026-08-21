import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/shell_tab_provider.dart';
import '../../location/location_consent_sheet.dart';
import '../../trail/data/providers.dart';
import '../../trail/domain/trail.dart';
import '../data/trail_progress_providers.dart';
import '../tracking/location_service.dart';
import '../tracking/walk_tracking_controller.dart';

Future<void> openTrailOnMap(
  BuildContext context,
  WidgetRef ref,
  Trail trail, {
  bool resume = false,
}) async {
  ref.read(mapTypFilterProvider.notifier).clear();
  ref.read(selectedTrailProvider.notifier).select(trail);
  ref.read(shellTabIndexProvider.notifier).goToMap();
  if (!resume) return;
  final walk = ref.read(activeWalkProvider).asData?.value;
  if (walk == null || walk.trailId != trail.id) return;
  try {
    await ensureTourLocation(context, ref);
    await ref.read(walkSnapshotProvider.notifier).resumeTour(trail, walk);
  } on LocationException catch (e) {
    if (context.mounted) showLocationError(context, e);
  } catch (_) {}
}
