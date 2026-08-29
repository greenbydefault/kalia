import 'package:flutter/material.dart';

/// Nummer-Avatar einer Station.
class StationNumberAvatar extends StatelessWidget {
  const StationNumberAvatar({
    super.key,
    required this.reihenfolge,
    this.radius = 12,
    this.fontSize = 13,
  });

  final int reihenfolge;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary,
      child: Text(
        '$reihenfolge',
        style: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Barrierefrei-Marker einer Station — Icon oder Chip mit Label.
class StationAccessibleMark extends StatelessWidget {
  const StationAccessibleMark({
    super.key,
    this.showLabel = false,
    this.iconSize = 20,
    this.color,
  });

  final bool showLabel;
  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.accessible, size: iconSize, color: color);
    if (!showLabel) {
      return Tooltip(message: 'Barrierefrei', child: icon);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 3),
        Text('Barrierefrei', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
