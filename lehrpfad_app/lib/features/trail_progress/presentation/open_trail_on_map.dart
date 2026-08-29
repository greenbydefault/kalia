import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/shell_tab_provider.dart';
import '../../location/location_consent_sheet.dart';
import '../../location/location_gate.dart';
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
  // Externer Einstieg: Karte darf einmalig zum Trail fliegen (One-Shot).
  ref.read(pendingCameraTrailProvider.notifier).request(trail.id);
  ref.read(selectedTrailProvider.notifier).select(trail);
  ref.read(shellTabIndexProvider.notifier).goToMap();
  if (!resume) return;
  final walk = ref.read(activeWalkProvider).asData?.value;
  if (walk == null || walk.trailId != trail.id) return;
  try {
    await LocationGate.ensureTour(context, ref);
    await ref.read(walkSnapshotProvider.notifier).resumeTour(trail, walk);
  } on LocationException catch (e) {
    if (context.mounted) showLocationError(context, e);
  } catch (_) {}
}
