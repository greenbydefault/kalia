import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_colors.dart';

/// Icon + Label + Anzahl (Art/Arten bzw. Gerät/Geräte).
class SpeciesCategoryHeader extends StatelessWidget {
  const SpeciesCategoryHeader({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    required this.isGeraete,
    this.padding,
  });

  final String label;
  final int count;
  final IconData icon;
  final bool isGeraete;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countLabel = isGeraete
        ? (count == 1 ? 'Gerät' : 'Geräte')
        : (count == 1 ? 'Art' : 'Arten');
    final row = Row(
      children: [
        PhosphorIcon(icon, size: 18, color: AppColors.ink),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(color: AppColors.ink),
        ),
        const SizedBox(width: 8),
        Text(
          '$count $countLabel',
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
        ),
      ],
    );
    if (padding == null) return row;
    return Padding(padding: padding!, child: row);
  }
}
