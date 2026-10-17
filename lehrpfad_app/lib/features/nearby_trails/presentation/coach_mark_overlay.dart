import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/shell_tab_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/motion/reduced_motion.dart';
import '../../onboarding/data/onboarding_prefs_provider.dart';
import '../../player/data/mini_player_provider.dart';
import '../../trail/data/providers.dart';
import '../data/karte_state.dart';

/// Zeigt den Coach-Mark genau einmal über der ersten Karte der Nähe-Liste.
class CoachMarkHost extends ConsumerStatefulWidget {
  const CoachMarkHost({super.key});

  @override
  ConsumerState<CoachMarkHost> createState() => _CoachMarkHostState();
}

class _CoachMarkHostState extends ConsumerState<CoachMarkHost> {
  Timer? _timer;
  Rect? _rect;
  var _tries = 0;

  /// Wartet, bis der Karten-Einstieg durch ist, dann messen.
  static const _settleDelay = Duration(milliseconds: 1300);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule(Duration after) {
    _timer?.cancel();
    _timer = Timer(after, _measure);
  }

  void _measure() {
    if (!mounted) return;
    final ctx = ref.read(coachTargetKeyProvider).currentContext;
    final box = ctx?.findRenderObject();
    if (box is RenderBox && box.attached && box.hasSize) {
      final topLeft = box.localToGlobal(Offset.zero);
      final rect = topLeft & box.size;
      final screen = MediaQuery.sizeOf(context);
      final visible =
          rect.top >= 0 && rect.bottom <= screen.height && rect.width > 0;
      if (visible) {
        setState(() => _rect = rect);
        return;
      }
    }
    if (++_tries < 8) _schedule(const Duration(milliseconds: 400));
  }

  void _reset() {
    _timer?.cancel();
    _timer = null;
    _tries = 0;
    if (_rect != null) setState(() => _rect = null);
  }

  Future<void> _finish({bool play = false}) async {
    if (play) {
      final treffer = ref
          .read(karteAnzeigeProvider)
          ?.sichtbar
          .where((t) => t.eintrag.audio != null)
          .firstOrNull;
      final trail = treffer == null
          ? null
          : ref.read(trailsByIdProvider)[treffer.eintrag.id];
      if (treffer != null && trail != null) {
        await ref
            .read(miniPlayerProvider.notifier)
            .play(trail, treffer.eintrag.audio!);
      }
    }
    await ref.read(onboardingPrefsProvider.notifier).markCoachMarkSeen();
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(onboardingPrefsProvider);
    final seen = prefsAsync.asData?.value.coachMarkSeen ?? true;
    final onMap = ref.watch(shellTabIndexProvider) == 0;
    final noSelection = ref.watch(selectedTrailProvider) == null;
    final hasCards =
        ref
            .watch(karteAnzeigeProvider)
            ?.sichtbar
            .any((t) => t.eintrag.audio != null) ??
        false;
    final eligible = !seen && onMap && noSelection && hasCards;

    if (!eligible) {
      if (_rect != null || _timer != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _reset();
        });
      }
      return const SizedBox.shrink();
    }
    if (_rect == null && _timer == null) {
      _schedule(context.motion(_settleDelay));
    }
    final rect = _rect;
    if (rect == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: CoachMarkOverlay(
        target: rect,
        onTargetTap: () => _finish(play: true),
        onDismiss: _finish,
      ),
    );
  }
}

/// Spotlight auf [target], Rest abgedunkelt, Bubble mit „Verstanden“.
class CoachMarkOverlay extends StatelessWidget {
  const CoachMarkOverlay({
    super.key,
    required this.target,
    required this.onTargetTap,
    required this.onDismiss,
  });

  final Rect target;
  final VoidCallback onTargetTap;
  final VoidCallback onDismiss;

  static const title = 'Erst mal reinhören';
  static const body = 'Jeder Pfad erzählt schon zu Hause, was euch erwartet.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screen = MediaQuery.sizeOf(context);
    final hole = RRect.fromRectAndRadius(
      target.inflate(6),
      Radius.circular((target.height + 12) / 2),
    );
    final bubbleAbove = target.top > 240;

    final bubble = Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(AppSpacing.x5),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.x2),
            Text(body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.x4),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: onDismiss,
              child: const Text('Verstanden'),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      label: '$title. $body',
      child: Stack(
        children: [
          // Fängt Taps und Scrollen ab, solange der Coach-Mark steht.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              onVerticalDragUpdate: (_) {},
              child: CustomPaint(painter: _SpotlightPainter(hole)),
            ),
          ),
          Positioned.fromRect(
            rect: hole.outerRect,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTargetTap,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: AppSpacing.x5,
            right: AppSpacing.x5,
            top: bubbleAbove ? null : hole.bottom + AppSpacing.x4,
            bottom: bubbleAbove
                ? screen.height - hole.top + AppSpacing.x4
                : null,
            child: bubble
                .animate(
                  delay: context.motion(const Duration(milliseconds: 150)),
                )
                .fadeIn(
                  duration: context.motion(const Duration(milliseconds: 300)),
                )
                .moveY(
                  begin: bubbleAbove ? 12 : -12,
                  end: 0,
                  duration: context.motion(const Duration(milliseconds: 400)),
                  curve: Curves.easeOutCubic,
                ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter(this.hole);
  final RRect hole;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(hole),
    );
    canvas.drawPath(path, Paint()..color = AppColors.scrim54);
    canvas.drawRRect(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.onImage70,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.hole != hole;
}
