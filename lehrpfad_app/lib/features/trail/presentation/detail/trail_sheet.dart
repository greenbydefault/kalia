import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/scrolling/smooth_scroll.dart';
import '../../../../shared/widgets/bottom_content_card.dart';
import '../../../../shared/widgets/sheet_motion.dart';
import '../../../trail_progress/presentation/trail_sheet_peek_actions.dart';
import '../../domain/trail.dart';
import 'trail_sheet_body.dart';
import 'trail_sheet_header.dart';

/// Aufziehbares Detail-Sheet zu einem Trail.
class TrailSheet extends StatefulWidget {
  final Trail trail;
  final VoidCallback onClose;
  final VoidCallback? onTourStarted;

  const TrailSheet({
    super.key,
    required this.trail,
    required this.onClose,
    this.onTourStarted,
  });

  @override
  State<TrailSheet> createState() => _TrailSheetState();
}

class _TrailSheetState extends State<TrailSheet> {
  static const _peek = 0.30;
  static const _full = 0.92;

  final _controller = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.isAttached) {
        _controller.animateTo(
          _peek,
          duration: SheetMotion.enter,
          curve: SheetMotion.enterCurve,
        );
      }
    });
  }

  void _expand() {
    _controller.animateTo(
      _full,
      duration: SheetMotion.enter,
      curve: SheetMotion.enterCurve,
    );
  }

  void _collapseForTour() {
    if (!_controller.isAttached) return;
    _controller.animateTo(
      0.05,
      duration: SheetMotion.size,
      curve: SheetMotion.enterCurve,
    );
    widget.onTourStarted?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trail = widget.trail;

    return Positioned.fill(
      child: DraggableScrollableSheet(
        controller: _controller,
        initialChildSize: 0.05,
        minChildSize: 0.05,
        maxChildSize: _full,
        snap: true,
        snapSizes: const [_peek, _full],
        builder: (context, scrollController) {
          return Container(
            decoration: BottomContentCard.decoration(theme),
            child: SmoothScroll(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x5,
                  AppSpacing.x2,
                  AppSpacing.x5,
                  AppSpacing.x8,
                ),
                children: [
                  TrailSheetHeader(
                    trail: trail,
                    onClose: widget.onClose,
                    peekActions: TrailSheetPeekActions(
                      trail: trail,
                      sheetController: _controller,
                      onExpand: _expand,
                      onTourStarted: _collapseForTour,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  TrailSheetBody(trail: trail),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
