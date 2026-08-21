import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Animierter Kamera-Flug für flutter_map.
///
/// flutter_map hat keine öffentliche flyTo-API; hier wird der Flug mit einem
/// einzigen [AnimationController] und Tweens für lat/lng/zoom umgesetzt.
/// Der Listener ruft nur [MapController.move] auf — kein setState, kein
/// Widget-Rebuild der Karte pro Frame.
class MapCameraAnimator {
  MapCameraAnimator({
    required this._mapController,
    required this._vsync,
  });

  final MapController _mapController;
  final TickerProvider _vsync;



  static const duration = Duration(milliseconds: 1400);
  static const curve = Curves.easeInOutQuart;

  AnimationController? _controller;
  Completer<void>? _completer;

  bool get isAnimating => _controller?.isAnimating ?? false;

  /// Fliegt die Kamera so, dass [bounds] (mit [padding]) im Viewport liegen.
  ///
  /// Löst sich auf, wenn die Animation abgeschlossen ist. Wird sie durch
  /// [cancel] oder einen erneuten Aufruf abgebrochen, löst sich die Future
  /// ebenfalls auf (ohne Fehler), damit Aufrufer nicht hängen bleiben.
  Future<void> flyToBounds(
    LatLngBounds bounds, {
    EdgeInsets padding = const EdgeInsets.all(48),
  }) {
    cancel();
    final camera = _mapController.camera;
    final fit = CameraFit.bounds(bounds: bounds, padding: padding).fit(camera);
    return _run(endCenter: fit.center, endZoom: fit.zoom);
  }

  /// Fliegt zu [center] / [zoom] (Locate, Cluster-Expansion).
  Future<void> flyTo(LatLng center, double zoom) {
    cancel();
    return _run(endCenter: center, endZoom: zoom);
  }

  Future<void> _run({required LatLng endCenter, required double endZoom}) {
    final camera = _mapController.camera;
    final latTween = Tween<double>(
      begin: camera.center.latitude,
      end: endCenter.latitude,
    );
    final lngTween = Tween<double>(
      begin: camera.center.longitude,
      end: endCenter.longitude,
    );
    final zoomTween = Tween<double>(begin: camera.zoom, end: endZoom);

    final controller = AnimationController(duration: duration, vsync: _vsync);
    final animation = CurvedAnimation(parent: controller, curve: curve);
    final completer = Completer<void>();

    _controller = controller;
    _completer = completer;

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _finish(controller, completer);
      }
    });

    controller.forward();
    return completer.future;
  }

  /// Bricht eine laufende Animation ab. Die Future aus [flyToBounds] /
  /// [flyTo] wird trotzdem aufgelöst.
  void cancel() {
    final controller = _controller;
    final completer = _completer;
    _controller = null;
    _completer = null;
    if (controller != null) {
      controller.stop();
      _finish(controller, completer);
    }
  }

  void _finish(AnimationController controller, Completer<void>? completer) {
    if (identical(_controller, controller)) {
      _controller = null;
      _completer = null;
    }
    controller.dispose();
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void dispose() => cancel();
}
