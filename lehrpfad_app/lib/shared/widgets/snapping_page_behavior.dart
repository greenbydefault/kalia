import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// ScrollBehavior für horizontale Pager: Drag zusätzlich per Maus
/// (Click-Drag); Touch/Stylus/Trackpad sind Flutter-Default.
class SnappingPageScrollBehavior extends ScrollBehavior {
  const SnappingPageScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.mouse,
      };
}

/// Wrapper für horizontale [PageView]s: Mausrad-/Trackpad-Scroll blättert
/// pro Geste genau eine Seite weiter und rastet am Geste-Ende sauber ein,
/// statt frei durch alle Slides zu laufen.
///
/// Hintergrund: [PageScrollPhysics] snapt nur nach Drag-Flings. Wheel-
/// Events scrollen als Pixel-Deltas (`pointerScroll`) am Snap vorbei.
/// Der Wrapper begrenzt jede Wheel-Geste auf ±1 Seite um die Startseite
/// und animiert am Ende auf die ganze Seite.
class SnappingPager extends StatefulWidget {
  const SnappingPager({
    super.key,
    required this.controller,
    required this.child,
  });

  final PageController controller;

  /// Der horizontale PageView.
  final Widget child;

  @override
  State<SnappingPager> createState() => _SnappingPagerState();
}

class _SnappingPagerState extends State<SnappingPager> {
  /// Ruhepause, nach der eine Wheel-Geste als beendet gilt.
  static const _wheelIdleTimeout = Duration(milliseconds: 140);

  /// Mindest-Hub in px, ab dem eine Wheel-Geste eine Seite blättert.
  static const _wheelThreshold = 24.0;

  static const _settleDuration = Duration(milliseconds: 250);

  double? _wheelStartPage;
  double _wheelAccum = 0;
  bool _wheelActive = false;
  bool _dragging = false;
  Timer? _wheelIdleTimer;

  PageController get _controller => widget.controller;

  @override
  void dispose() {
    _wheelIdleTimer?.cancel();
    super.dispose();
  }

  double get _pageExtent =>
      _controller.position.viewportDimension * _controller.viewportFraction;

  double _unitsToPixels(double units) {
    final position = _controller.position;
    return (units * _pageExtent)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (!_wheelActive && _controller.hasClients) {
      _wheelStartPage = _controller.page?.roundToDouble();
      _wheelAccum = 0;
    }
    _wheelActive = true;
    _wheelAccum += event.scrollDelta.dx;
    _scheduleWheelSettle();
  }

  void _scheduleWheelSettle() {
    _wheelIdleTimer?.cancel();
    _wheelIdleTimer = Timer(_wheelIdleTimeout, _settleWheelGesture);
  }

  void _resetWheel() {
    _wheelIdleTimer?.cancel();
    _wheelIdleTimer = null;
    _wheelActive = false;
    _wheelStartPage = null;
    _wheelAccum = 0;
  }

  /// Geste-Ende: auf die anvisierte Seite einrasten (max. ±1 ab Start).
  void _settleWheelGesture() {
    final start = _wheelStartPage;
    final accum = _wheelAccum;
    _resetWheel();
    if (_dragging || start == null || !_controller.hasClients) return;
    final position = _controller.position;
    final pageExtent = _pageExtent;
    if (pageExtent <= 0) return;
    final maxUnits = position.maxScrollExtent / pageExtent;
    var target = (position.pixels / pageExtent).roundToDouble();
    if (accum > _wheelThreshold) {
      target = start + 1;
    } else if (accum < -_wheelThreshold) {
      target = start - 1;
    }
    target = target.clamp(0.0, maxUnits);
    final pixels = _unitsToPixels(target);
    if ((position.pixels - pixels).abs() < 1) return;
    _controller.animateTo(
      pixels,
      duration: _settleDuration,
      curve: Curves.easeOutCubic,
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _dragging = notification.dragDetails != null;
      // Echte Drag-Geste: snapt bereits über PageScrollPhysics.
      if (_dragging) _resetWheel();
      return false;
    }
    if (notification is ScrollEndNotification &&
        notification.dragDetails != null) {
      _dragging = false;
      return false;
    }
    if (!_wheelActive ||
        notification is! ScrollUpdateNotification ||
        notification.dragDetails != null ||
        !_controller.hasClients) {
      return false;
    }
    final start = _wheelStartPage;
    if (start == null) return false;
    final position = _controller.position;
    final pageExtent = _pageExtent;
    if (pageExtent <= 0) return false;
    final units = position.pixels / pageExtent;
    final minUnits = (start - 1).clamp(0.0, double.infinity);
    final maxUnits = start + 1;
    // Weitere Deltas derselben Geste hart auf die Nachbarseite begrenzen.
    if (units < minUnits - 0.001) {
      _controller.jumpTo(_unitsToPixels(minUnits));
    } else if (units > maxUnits + 0.001) {
      _controller.jumpTo(_unitsToPixels(maxUnits));
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const SnappingPageScrollBehavior(),
      child: Listener(
        onPointerSignal: _onPointerSignal,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: widget.child,
        ),
      ),
    );
  }
}
