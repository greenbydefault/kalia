import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/motion/reduced_motion.dart';

/// Drei Equalizer-Balken. Animiert nur bei [playing] und ohne
/// „Bewegung reduzieren“.
class EqualizerBars extends StatefulWidget {
  const EqualizerBars({
    super.key,
    required this.playing,
    required this.color,
    this.size = 18,
  });

  final bool playing;
  final Color color;
  final double size;

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  static const _phases = [0.0, 0.33, 0.66];

  void _sync() {
    final animate = widget.playing && !context.reduceMotion;
    if (animate && !_c.isAnimating) {
      _c.repeat();
    } else if (!animate && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(EqualizerBars old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _level(double phase, BuildContext context) {
    if (!widget.playing || context.reduceMotion) return 0.55;
    final wave = (math.sin(2 * math.pi * ((_c.value + phase) % 1)) + 1) / 2;
    return 0.3 + 0.7 * wave;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.size / 6;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final phase in _phases)
              Container(
                width: w,
                height: widget.size * _level(phase, context),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(w / 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
