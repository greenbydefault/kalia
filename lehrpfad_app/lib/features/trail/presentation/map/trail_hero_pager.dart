import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/overlay_badge.dart';
import '../../../../shared/widgets/page_dots.dart';
import '../../../../shared/widgets/snapping_page_behavior.dart';
import '../../domain/trail.dart';
import 'trail_hero.dart';
import 'trail_hero_fullscreen.dart';

/// Foto-Pager für die Trail-Detailseite. Höhe/Breite kommen vom Parent;
/// Tap öffnet die TASL-Vollbildansicht.
class TrailHeroPager extends StatefulWidget {
  const TrailHeroPager({super.key, required this.trail});

  final Trail trail;

  @override
  State<TrailHeroPager> createState() => _TrailHeroPagerState();
}

class _TrailHeroPagerState extends State<TrailHeroPager> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    TrailHeroFullscreen.open(
      context,
      trailId: widget.trail.id,
      bilder: TrailHero.pagesFor(widget.trail),
      initialIndex: _index,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bilder = TrailHero.pagesFor(widget.trail);
    final current = bilder[_index];
    return Stack(
      fit: StackFit.expand,
      children: [
        SnappingPager(
          controller: _controller,
          child: PageView.builder(
            controller: _controller,
            itemCount: bilder.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final bild = bilder[i];
              return GestureDetector(
                onTap: _openFullscreen,
                child: TrailHeroImage(
                  trailId: widget.trail.id,
                  bild: bild,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              );
            },
          ),
        ),
        if (current.hasCreditBadge)
          Positioned(
            left: AppSpacing.x3,
            bottom: 30,
            child: GestureDetector(
              onTap: _openFullscreen,
              child: OverlayBadge(text: current.badgeText),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.x3,
          child: PageDots(
            count: bilder.length,
            index: _index,
            activeColor: AppColors.n50,
            inactiveColor: AppColors.onImage54,
          ),
        ),
      ],
    );
  }
}
