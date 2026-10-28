import 'package:flutter/material.dart';

/// Größenstufe. Höhe, Icon und Padding stehen in [_Metrics].
enum AppButtonSize { klein, mittel, gross }

/// Zentraler Button. Call-Sites wählen Größe, Icon und ob ein Label dabei ist.
///
/// Mit Label: die Pill des Karte-Buttons (extended FAB, Ecken aus dem Theme).
/// [AppButton.icon]: Kreis in derselben Stufe, Tooltip ist Pflicht.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required String this.label,
    this.icon,
    this.size = AppButtonSize.mittel,
    this.tooltip,
  });

  /// Nur das Icon, Kreis in [size]. [tooltip] ersetzt das fehlende Label.
  const AppButton.icon({
    super.key,
    required this.onPressed,
    required IconData this.icon,
    required String this.tooltip,
    this.size = AppButtonSize.mittel,
  }) : label = null;

  final VoidCallback? onPressed;
  final String? label;
  final IconData? icon;
  final AppButtonSize size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final metrics = _Metrics.of(size);
    final theme = Theme.of(context);
    final iconWidget = icon == null ? null : Icon(icon, size: metrics.icon);

    return Theme(
      data: theme.copyWith(
        floatingActionButtonTheme: theme.floatingActionButtonTheme.copyWith(
          sizeConstraints: BoxConstraints.tightFor(
            width: metrics.extent,
            height: metrics.extent,
          ),
          iconSize: metrics.icon,
          extendedSizeConstraints: BoxConstraints.tightFor(
            height: metrics.extent,
          ),
          extendedPadding: EdgeInsetsDirectional.only(
            start: metrics.padStart,
            end: metrics.padEnd,
          ),
          extendedIconLabelSpacing: metrics.gap,
        ),
      ),
      child: label == null
          ? FloatingActionButton(
              heroTag: null,
              tooltip: tooltip,
              onPressed: onPressed,
              shape: const CircleBorder(),
              child: iconWidget,
            )
          : FloatingActionButton.extended(
              heroTag: null,
              tooltip: tooltip,
              onPressed: onPressed,
              icon: iconWidget,
              label: Text(label!),
            ),
    );
  }
}

class _Metrics {
  const _Metrics({
    required this.extent,
    required this.icon,
    required this.padStart,
    required this.padEnd,
    required this.gap,
  });

  final double extent;
  final double icon;
  final double padStart;
  final double padEnd;
  final double gap;

  static const klein = _Metrics(
    extent: 36,
    icon: 16,
    padStart: 12,
    padEnd: 12,
    gap: 4,
  );
  static const mittel = _Metrics(
    extent: 44,
    icon: 18,
    padStart: 14,
    padEnd: 16,
    gap: 6,
  );
  static const gross = _Metrics(
    extent: 56,
    icon: 24,
    padStart: 16,
    padEnd: 20,
    gap: 8,
  );

  static _Metrics of(AppButtonSize size) => switch (size) {
    AppButtonSize.klein => klein,
    AppButtonSize.mittel => mittel,
    AppButtonSize.gross => gross,
  };
}
