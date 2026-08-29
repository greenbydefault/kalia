import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/scrolling/smooth_scroll.dart';
import '../../../trail_progress/presentation/trail_sheet_peek_actions.dart';
import '../../domain/trail.dart';
import '../map/trail_hero_map.dart';
import '../map/trail_hero_pager.dart';
import 'trail_sheet_body.dart';
import 'trail_sheet_header.dart';

/// Vollbild-Detail zu einem Trail: oben Foto-Pager oder Karte (Toggle),
/// darunter Header + Body. Slidet von rechts über die Karte; horizontales
/// Ziehen nach rechts im Body (oder X / Back) schließt zurück zur
/// Peek-Card. Der Foto-Pager oben behält horizontale Gesten fürs Blättern.
class TrailDetailPage extends StatefulWidget {
  const TrailDetailPage({
    super.key,
    required this.trail,
    required this.onClose,
    this.onTourStarted,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
  });

  final Trail trail;
  final VoidCallback onClose;
  final VoidCallback? onTourStarted;

  /// Swipe-right-to-dismiss; der Parent (MapScreen) fährt den Controller.
  final GestureDragUpdateCallback? onHorizontalDragUpdate;
  final GestureDragEndCallback? onHorizontalDragEnd;

  /// Anteil der Screen-Höhe für den Hero (Foto-Pager oder Karte) oben.
  static const heroFraction = 0.38;

  @override
  State<TrailDetailPage> createState() => _TrailDetailPageState();
}

class _TrailDetailPageState extends State<TrailDetailPage> {
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          SizedBox(
            height: media.size.height * TrailDetailPage.heroFraction,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                IndexedStack(
                  index: _showMap ? 1 : 0,
                  children: [
                    TrailHeroPager(trail: widget.trail),
                    TrailHeroMap(
                      trail: widget.trail,
                      animateWhenVisible: _showMap,
                    ),
                  ],
                ),
                Positioned(
                  top: media.padding.top + AppSpacing.x2,
                  left: AppSpacing.x3,
                  child: _HeroButton(
                    tooltip: 'Schließen',
                    icon: PhosphorIcons.x,
                    onTap: widget.onClose,
                  ),
                ),
                Positioned(
                  top: media.padding.top + AppSpacing.x2,
                  right: AppSpacing.x3,
                  child: _HeroButton(
                    tooltip: _showMap ? 'Fotos zeigen' : 'Karte zeigen',
                    icon: _showMap
                        ? PhosphorIcons.images
                        : PhosphorIcons.mapTrifold,
                    onTap: () => setState(() => _showMap = !_showMap),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: widget.onHorizontalDragUpdate,
              onHorizontalDragEnd: widget.onHorizontalDragEnd,
              child: SmoothScroll(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.x5,
                    AppSpacing.x2,
                    AppSpacing.x5,
                    AppSpacing.x8 + media.padding.bottom,
                  ),
                  children: [
                    TrailSheetHeader(
                      trail: widget.trail,
                      onClose: widget.onClose,
                      showClose: false,
                      showHandle: false,
                      peekActions: TrailSheetPeekActions(
                        trail: widget.trail,
                        onTourStarted: widget.onTourStarted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    TrailSheetBody(trail: widget.trail),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Runder Scrim-Button über dem Hero (Schließen, Foto/Karte-Toggle).
class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.scrim54,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: PhosphorIcon(icon, size: 18, color: AppColors.n50),
            ),
          ),
        ),
      ),
    );
  }
}
