import 'package:flutter/material.dart';

/// Wiederverwendbarer Press-Wrapper: Scale + Shadow beim Druecken.
///
/// Dauerhaften Active-Fill steuert das [child]; hier nur Press-Feedback.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onPressed,
    this.enabled = true,
    this.animatePress = true,
    this.pressScale = 1.04,
    this.duration = const Duration(milliseconds: 120),
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool animatePress;
  final double pressScale;
  final Duration duration;
  final BorderRadius? borderRadius;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  bool get _canPress => widget.enabled && widget.onPressed != null;

  void _setPressed(bool value) {
    if (!widget.animatePress || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scale =
        widget.animatePress && _pressed ? widget.pressScale : 1.0;
    final shadow = widget.animatePress && _pressed
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ]
        : const <BoxShadow>[];

    return Semantics(
      button: true,
      enabled: _canPress,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _canPress ? (_) => _setPressed(true) : null,
        onTapUp: _canPress
            ? (_) {
                _setPressed(false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: _canPress ? () => _setPressed(false) : null,
        child: AnimatedScale(
          scale: scale,
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: widget.duration,
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: shadow,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
