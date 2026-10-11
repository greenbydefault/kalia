import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_colors.dart';
import '../../core/motion/reduced_motion.dart';

/// Graue Platzhalter-Szene (Himmel, Sonne, Hügel, Weg), bis das
/// Low-Poly-Asset da ist. Ebenen sind einzeln animierbar.
class LowpolyPlaceholderScene extends StatelessWidget {
  const LowpolyPlaceholderScene({
    super.key,
    this.animate = true,
    this.showSun = true,
    this.showPath = true,
  });

  /// Einstiegsanimation (Ebenen gestaffelt, Sonne, Weg).
  final bool animate;
  final bool showSun;
  final bool showPath;

  static const _hills = <_HillSpec>[
    _HillSpec(AppColors.n200, [
      Offset(0, 0.50),
      Offset(0.16, 0.38),
      Offset(0.34, 0.47),
      Offset(0.55, 0.33),
      Offset(0.78, 0.45),
      Offset(1, 0.36),
    ]),
    _HillSpec(AppColors.n300, [
      Offset(0, 0.64),
      Offset(0.22, 0.52),
      Offset(0.42, 0.62),
      Offset(0.66, 0.50),
      Offset(0.86, 0.60),
      Offset(1, 0.54),
    ]),
    _HillSpec(AppColors.n400, [
      Offset(0, 0.78),
      Offset(0.2, 0.68),
      Offset(0.5, 0.76),
      Offset(0.74, 0.66),
      Offset(1, 0.74),
    ]),
  ];

  Widget _layer(BuildContext context, Widget child, int index) {
    if (!animate) return child;
    return child
        .animate(delay: context.motion(OnboardingMotion.sceneStagger * index))
        .fadeIn(
          duration: context.motion(OnboardingMotion.sceneLayer),
          curve: Curves.easeOutCubic,
        )
        .moveY(
          begin: 40,
          end: 0,
          duration: context.motion(OnboardingMotion.sceneLayer),
          curve: Curves.easeOutCubic,
        );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final sunSize = w * 0.2;

        Widget sun = Container(
          width: sunSize,
          height: sunSize,
          decoration: const BoxDecoration(
            color: AppColors.n300,
            shape: BoxShape.circle,
          ),
        );
        if (animate) {
          sun = sun
              .animate(delay: context.motion(const Duration(milliseconds: 250)))
              .scale(
                begin: Offset.zero,
                end: const Offset(1, 1),
                duration: context.motion(OnboardingMotion.sun),
                curve: Curves.easeOutBack,
              );
        }

        Widget path = CustomPaint(
          size: Size(w, h),
          painter: _PathPainter(progress: 1),
        );
        if (animate) {
          path = path
              .animate(delay: context.motion(const Duration(milliseconds: 500)))
              .custom(
                duration: context.motion(OnboardingMotion.path),
                curve: Curves.easeInOutCubic,
                builder: (context, value, _) => CustomPaint(
                  size: Size(w, h),
                  painter: _PathPainter(progress: value),
                ),
              );
        }

        return ClipRect(
          child: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: AppColors.n100)),
              if (showSun)
                Positioned(right: w * 0.16, top: h * 0.12, child: sun),
              for (var i = 0; i < _hills.length; i++)
                Positioned.fill(
                  child: _layer(
                    context,
                    CustomPaint(painter: _HillPainter(_hills[i])),
                    i,
                  ),
                ),
              if (showPath) Positioned.fill(child: path),
            ],
          ),
        );
      },
    );
  }
}

class _HillSpec {
  const _HillSpec(this.color, this.ridge);
  final Color color;
  final List<Offset> ridge;
}

class _HillPainter extends CustomPainter {
  _HillPainter(this.spec);
  final _HillSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final first = spec.ridge.first;
    path.moveTo(first.dx * size.width, first.dy * size.height);
    for (final p in spec.ridge.skip(1)) {
      path.lineTo(p.dx * size.width, p.dy * size.height);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = spec.color);
  }

  @override
  bool shouldRepaint(_HillPainter old) => old.spec != spec;
}

class _PathPainter extends CustomPainter {
  _PathPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final full = Path()
      ..moveTo(w * 0.46, h)
      ..cubicTo(w * 0.18, h * 0.93, w * 0.82, h * 0.86, w * 0.5, h * 0.79)
      ..cubicTo(w * 0.3, h * 0.74, w * 0.64, h * 0.70, w * 0.58, h * 0.64);
    final paint = Paint()
      ..color = AppColors.n700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    if (progress >= 1) {
      canvas.drawPath(full, paint);
      return;
    }
    for (final PathMetric m in full.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.progress != progress;
}
