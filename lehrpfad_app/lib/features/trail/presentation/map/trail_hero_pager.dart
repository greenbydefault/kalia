import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/overlay_badge.dart';
import '../../../../shared/widgets/page_dots.dart';
import '../../../../shared/widgets/snapping_page_behavior.dart';
import '../../../community/data/community_providers.dart';
import '../../domain/trail.dart';
import 'trail_hero.dart';
import 'trail_hero_fullscreen.dart';

/// Foto-Pager für die Trail-Detailseite. Höhe/Breite kommen vom Parent;
/// Tap öffnet die TASL-Vollbildansicht. Seed-Fotos plus freigegebene
/// Community-Uploads.
class TrailHeroPager extends ConsumerStatefulWidget {
  const TrailHeroPager({super.key, required this.trail});

  final Trail trail;

  @override
  ConsumerState<TrailHeroPager> createState() => _TrailHeroPagerState();
}

class _TrailHeroPagerState extends ConsumerState<TrailHeroPager> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullscreen(List<HeroSlide> slides) {
    TrailHeroFullscreen.open(
      context,
      trailId: widget.trail.id,
      slides: slides,
      initialIndex: _index.clamp(0, slides.length - 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final community =
        ref.watch(trailImagesProvider(widget.trail.id)).value ?? const [];
    final slides = TrailHero.slidesFor(widget.trail, community);
    final index = _index.clamp(0, slides.length - 1);
    final current = slides[index];
    return Stack(
      fit: StackFit.expand,
      children: [
        SnappingPager(
          controller: _controller,
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final slide = slides[i];
              return GestureDetector(
                onTap: () => _openFullscreen(slides),
                child: TrailHeroImage(
                  trailId: widget.trail.id,
                  slide: slide,
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
              onTap: () => _openFullscreen(slides),
              child: OverlayBadge(text: current.badgeText),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.x3,
          child: PageDots(
            count: slides.length,
            index: index,
            activeColor: AppColors.n50,
            inactiveColor: AppColors.onImage54,
          ),
        ),
      ],
    );
  }
}
