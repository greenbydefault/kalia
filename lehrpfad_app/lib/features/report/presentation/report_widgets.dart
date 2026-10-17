import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/config/map_config.dart';
import '../domain/report_enums.dart';
import '../domain/report_models.dart';
import '../logic/geo.dart';
import '../logic/signal.dart';
import '../report_copy.dart';

String pointTypeLabel(PointType t) => rt('report.marker.type.${t.name}');

String hintKindLabel(HintKind k) => rt(switch (k) {
  HintKind.closed => 'report.hint.kind.closed',
  HintKind.danger => 'report.hint.kind.danger',
  HintKind.stairsRoots => 'report.hint.kind.stairs',
  HintKind.viewpoint => 'report.hint.kind.viewpoint',
  HintKind.facility => 'report.hint.kind.facility',
  HintKind.other => 'report.hint.kind.other',
});

String signalLabel(SignalLevel l) => rt(switch (l) {
  SignalLevel.good => 'report.signal.good',
  SignalLevel.mid => 'report.signal.mid',
  SignalLevel.weak => 'report.signal.weak',
  SignalLevel.none => 'report.signal.none',
});

/// Titel für Listen: „Station 3“ oder der Tafeltitel.
String markerLabel(DraftPoint p) {
  final base = p.type == PointType.station && p.number != null
      ? '${pointTypeLabel(p.type)} ${p.number}'
      : pointTypeLabel(p.type);
  final title = p.title?.trim();
  return title == null || title.isEmpty ? base : '$base · $title';
}

IconData pointTypeIcon(PointType t) => switch (t) {
  PointType.start => Icons.flag_outlined,
  PointType.end => Icons.sports_score,
  PointType.parking => Icons.local_parking,
  PointType.station => Icons.place_outlined,
  PointType.waypoint => Icons.circle_outlined,
  PointType.hint => Icons.warning_amber_outlined,
};

/// Kleine Signal-Anzeige (Spec 3.5). Farben aus dem Eignungs-Spektrum, plus
/// Text, damit die Farbe nie allein trägt.
class SignalPill extends StatelessWidget {
  const SignalPill({super.key, required this.level, this.accuracyM});

  final SignalLevel level;
  final double? accuracyM;

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      SignalLevel.good => AppColors.eignung5,
      SignalLevel.mid => AppColors.eignung3,
      SignalLevel.weak => AppColors.eignung2,
      SignalLevel.none => AppColors.eignung1,
    };
    final text = level == SignalLevel.none || accuracyM == null
        ? signalLabel(level)
        : '${signalLabel(level)} · ±${accuracyM!.round()} m';
    return Semantics(
      label: text,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x3,
            vertical: AppSpacing.x2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 10, color: color),
              const SizedBox(width: AppSpacing.x2),
              Text(text, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartenmarker eines Punkts.
class PointDot extends StatelessWidget {
  const PointDot({super.key, required this.point, this.selected = false});

  final DraftPoint point;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStation = point.type == PointType.station && point.number != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.brand : theme.colorScheme.surface,
        border: Border.all(
          color: point.lowAccuracy ? AppColors.eignung2 : AppColors.brand,
          width: 2,
        ),
      ),
      child: Center(
        child: isStation
            ? Text(
                '${point.number}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected ? AppColors.paper : AppColors.ink,
                ),
              )
            : Icon(
                pointTypeIcon(point.type),
                size: 18,
                color: selected ? AppColors.paper : AppColors.ink,
              ),
      ),
    );
  }
}

/// Karte für Aufnahme, Prüfen und Moderation der eigenen Meldung.
class ReportMap extends StatelessWidget {
  const ReportMap({
    super.key,
    required this.controller,
    this.segments = const [],
    this.points = const [],
    this.user,
    this.center,
    this.zoom = 16,
    this.selectedId,
    this.onPointTap,
    this.onUserGesture,
    this.existingRoute = const [],
    this.extraMarkers = const [],
    this.interactive = true,
  });

  final MapController controller;
  final TrackSegments segments;
  final List<DraftPoint> points;
  final LatLng? user;
  final LatLng? center;
  final double zoom;
  final String? selectedId;
  final ValueChanged<DraftPoint>? onPointTap;
  final VoidCallback? onUserGesture;

  /// Bestehender Pfad (Revision), gestrichelt unter dem neuen Track.
  final List<LatLng> existingRoute;
  final List<Marker> extraMarkers;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final all = <LatLng>[
      for (final s in segments)
        for (final p in s) LatLng(p.lat, p.lng),
      for (final p in points) LatLng(p.lat, p.lng),
    ];
    final fit = all.length >= 2
        ? CameraFit.coordinates(
            coordinates: all,
            padding: const EdgeInsets.all(48),
            maxZoom: 18,
          )
        : null;
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center ?? user ?? MapConfig.defaultCenter,
        initialZoom: zoom,
        initialCameraFit: fit,
        interactionOptions: interactive
            ? MapConfig.interactionOptions
            : const InteractionOptions(flags: InteractiveFlag.none),
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture) onUserGesture?.call();
        },
      ),
      children: [
        MapConfig.buildOsmTileLayer(),
        if (existingRoute.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: existingRoute,
                strokeWidth: 4,
                color: AppColors.n400,
                pattern: const StrokePattern.dotted(),
              ),
            ],
          ),
        PolylineLayer(
          polylines: [
            for (final s in segments)
              if (s.length >= 2)
                Polyline(
                  points: [for (final p in s) LatLng(p.lat, p.lng)],
                  strokeWidth: 5,
                  color: AppColors.brand,
                ),
          ],
        ),
        MarkerLayer(
          markers: [
            for (final p in points)
              Marker(
                point: LatLng(p.lat, p.lng),
                width: 34,
                height: 34,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onPointTap == null ? null : () => onPointTap!(p),
                  child: PointDot(point: p, selected: p.id == selectedId),
                ),
              ),
            ...extraMarkers,
            if (user != null)
              Marker(
                point: user!,
                width: 22,
                height: 22,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.ink,
                    border: Border.fromBorderSide(
                      BorderSide(color: AppColors.paper, width: 3),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

void showReportSnack(
  BuildContext context,
  String text, {
  Duration duration = const Duration(seconds: 4),
  SnackBarAction? action,
}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: duration,
      content: Text(text),
      action: action,
    ),
  );
}

/// Primärer Seiten-Button in voller Breite, ≥ 52 dp wie im Rest der App.
class ReportPrimaryButton extends StatelessWidget {
  const ReportPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 52,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(minimumSize: Size.fromHeight(height)),
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
