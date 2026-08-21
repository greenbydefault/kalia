import 'package:flutter/material.dart';

import '../domain/station.dart';
import '../domain/trail.dart';
import '../presentation/detail/widgets/station_info_overlay.dart';
import 'terrain_contours.dart';
import 'track_layout.dart';
import 'track_painter.dart';
import 'track_style.dart';

/// Isolierter Track im Content-Sheet. Cache bei Size-/Trail-Content-Wechsel.
class TrailTrackView extends StatefulWidget {
  final Trail trail;
  const TrailTrackView({super.key, required this.trail});

  @override
  State<TrailTrackView> createState() => _TrailTrackViewState();
}

class _TrailTrackViewState extends State<TrailTrackView> {
  Station? _selected;
  TrackLayout? _layout;
  List<ContourLine> _contours = const [];
  List<TextPainter> _labels = const [];
  String? _cacheKey;

  @override
  void didUpdateWidget(covariant TrailTrackView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trail.id != widget.trail.id ||
        oldWidget.trail.route.length != widget.trail.route.length ||
        oldWidget.trail.stationen.length != widget.trail.stationen.length) {
      _cacheKey = null;
      _selected = null;
    }
  }

  void _ensureCache(Size size, Color labelColor) {
    final key =
        '${widget.trail.id}|${widget.trail.route.length}|'
        '${widget.trail.stationen.length}|${size.width.toStringAsFixed(1)}x'
        '${size.height.toStringAsFixed(1)}|${labelColor.toARGB32()}';
    if (_cacheKey == key && _layout != null) return;

    final layout = TrackLayout.build(
      route: widget.trail.route,
      stations: widget.trail.stationen,
      width: size.width,
      height: size.height,
      rundkurs: widget.trail.rundkurs,
    );
    _layout = layout;
    _contours = buildContours(layout, seed: widget.trail.id.hashCode);
    _labels = TrackPainter.buildLabelPainters(layout, color: labelColor);
    _cacheKey = key;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.trail.route.length < 2) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(TrackStyle.borderRadius),
        child: Container(
          height: TrackStyle.height,
          color: TrackStyle.background,
          alignment: Alignment.center,
          child: Text(
            'Keine Routendaten',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final labelColor = theme.colorScheme.onPrimary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(TrackStyle.borderRadius),
      child: SizedBox(
        height: TrackStyle.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            _ensureCache(size, labelColor);
            final layout = _layout!;

            return Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final hit = layout.hitTest(
                      TrackPoint(
                        details.localPosition.dx,
                        details.localPosition.dy,
                      ),
                    );
                    setState(() => _selected = hit);
                  },
                  child: CustomPaint(
                    size: size,
                    painter: TrackPainter(
                      layout: layout,
                      contours: _contours,
                      selected: _selected,
                      stationFill: theme.colorScheme.primary,
                      stationSelected: theme.colorScheme.tertiary,
                      labelPainters: _labels,
                      showAbEndpoints: widget.trail.end != null,
                    ),
                  ),
                ),
                if (_selected != null)
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: StationInfoOverlay(
                      station: _selected!,
                      onClose: () => setState(() => _selected = null),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
