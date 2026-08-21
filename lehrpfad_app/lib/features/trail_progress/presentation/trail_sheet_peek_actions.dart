import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_spacing.dart';
import '../../location/location_consent_sheet.dart';
import '../../location/proximity.dart';
import '../../location/user_position_provider.dart';
import '../../trail/domain/trail.dart';
import '../data/trail_list_providers.dart';
import '../data/trail_progress_providers.dart';
import '../domain/trail_walk.dart';
import '../tracking/location_service.dart';
import '../tracking/walk_tracking_controller.dart';
import 'merken_toggle.dart';
import 'save_to_list_sheet.dart';

/// Peek-CTAs: Merken und Tour immer, Details nur wenn Sheet nicht expanded.
class TrailSheetPeekActions extends ConsumerWidget {
  const TrailSheetPeekActions({
    super.key,
    required this.trail,
    required this.sheetController,
    required this.onExpand,
    this.onTourStarted,
  });

  final Trail trail;
  final DraggableScrollableController sheetController;
  final VoidCallback onExpand;
  final VoidCallback? onTourStarted;

  static final ButtonStyle _compactStyle = FilledButton.styleFrom(
    visualDensity: VisualDensity.compact,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.x3,
      vertical: AppSpacing.x2,
    ),
    minimumSize: const Size(0, 36),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarked =
        ref.watch(trailBookmarksProvider).asData?.value.contains(trail.id) ??
        false;
    final inList =
        ref
            .watch(trailListsProvider)
            .asData
            ?.value
            .any((list) => list.containsTrail(trail.id)) ??
        false;
    final saved = bookmarked || inList;
    final activeWalk = ref.watch(activeWalkProvider).asData?.value;
    final isThisWalk = activeWalk?.trailId == trail.id;
    final tracking = ref.watch(
      walkSnapshotProvider.select((s) => s?.trailId == trail.id),
    );

    final fix = ref.watch(userPositionProvider).fix;
    final site = onSiteResult(trail, fix);
    final distanceM = fix == null
        ? null
        : distanceToTrailM(trail, fix.position);
    final blocked = !tracking && site == OnSiteResult.no;
    final tourLabel = blocked && distanceM != null
        ? 'Noch ${formatDistanceM(distanceM)}'
        : isThisWalk
        ? (tracking ? 'Beenden' : 'Weiter')
        : 'Starten';
    final tourTooltip = blocked && distanceM != null
        ? 'Noch ${formatDistanceM(distanceM)} zum Start'
        : isThisWalk
        ? (tracking ? 'Tour beenden' : 'Tour fortsetzen')
        : 'Tour starten';
    final tourIcon = isThisWalk
        ? (tracking ? PhosphorIcons.pause : PhosphorIcons.play)
        : PhosphorIcons.footprints;

    return AnimatedBuilder(
      animation: sheetController,
      builder: (context, _) {
        final expanded =
            sheetController.isAttached && sheetController.size > 0.6;
        return Wrap(
          spacing: AppSpacing.x2,
          runSpacing: AppSpacing.x2,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.end,
          children: [
            MerkenToggle(
              bookmarked: saved,
              iconOnly: true,
              onChanged: (_) => SaveToListSheet.show(context, trail),
            ),
            if (!expanded)
              Tooltip(
                message: 'Mehr erfahren',
                child: FilledButton.tonalIcon(
                  style: _compactStyle,
                  onPressed: onExpand,
                  icon: const PhosphorIcon(PhosphorIcons.caretUp, size: 18),
                  label: const Text('Details'),
                ),
              ),
            Tooltip(
              message: tourTooltip,
              child: FilledButton.icon(
                style: _compactStyle,
                onPressed: blocked
                    ? null
                    : () => _onTourPressed(
                        context,
                        ref,
                        isThisWalk: isThisWalk,
                        tracking: tracking,
                        activeWalk: activeWalk,
                      ),
                icon: PhosphorIcon(tourIcon, size: 18),
                label: Text(tourLabel),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onTourPressed(
    BuildContext context,
    WidgetRef ref, {
    required bool isThisWalk,
    required bool tracking,
    required TrailWalk? activeWalk,
  }) async {
    try {
      if (isThisWalk && tracking) {
        await ref.read(walkSnapshotProvider.notifier).stopTour(abandon: true);
        return;
      }
      await ensureTourLocation(context, ref);
      if (isThisWalk && activeWalk != null) {
        await ref
            .read(walkSnapshotProvider.notifier)
            .resumeTour(trail, activeWalk);
        onTourStarted?.call();
        return;
      }
      await ref.read(walkSnapshotProvider.notifier).startTour(trail);
      onTourStarted?.call();
    } on LocationException catch (e) {
      if (context.mounted) showLocationError(context, e);
    } catch (e) {
      if (context.mounted) showLocationError(context, e);
    }
  }
}
