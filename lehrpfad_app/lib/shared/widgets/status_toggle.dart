import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import 'pressable.dart';

/// Kleiner selected/onChanged-Toggle. Domain-Namen bleiben die Wrapper.
class StatusToggle extends StatelessWidget {
  const StatusToggle({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selectedLabel,
    this.iconOnly = false,
  });

  final bool selected;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String selectedLabel;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const radius = BorderRadius.all(Radius.circular(10));
    final tooltip = selected ? selectedLabel : label;

    final child = Pressable(
      borderRadius: radius,
      onPressed: () => onChanged(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: iconOnly
            ? const EdgeInsets.all(AppSpacing.x2)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.n900 : AppColors.n100,
          borderRadius: radius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              selected ? selectedIcon : icon,
              size: iconOnly ? 18 : 20,
              color: selected ? AppColors.paper : AppColors.ink,
            ),
            if (!iconOnly) ...[
              const SizedBox(width: 8),
              Text(
                selected ? selectedLabel : label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected ? AppColors.paper : AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Tooltip(message: tooltip, child: child);
  }
}
