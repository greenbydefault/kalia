import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/pressable.dart';

/// Toggle „Merken“ (Pressable wie GesehenToggle).
class MerkenToggle extends StatelessWidget {
  const MerkenToggle({
    super.key,
    required this.bookmarked,
    required this.onChanged,
    this.iconOnly = false,
  });

  final bool bookmarked;
  final ValueChanged<bool> onChanged;

  /// Kompakt ohne Label — für enge Peek-CTA-Zeilen.
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const radius = BorderRadius.all(Radius.circular(12));
    final tooltip = bookmarked ? 'Gemerkte' : 'Merken';

    final child = Pressable(
      borderRadius: radius,
      onPressed: () => onChanged(!bookmarked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: iconOnly
            ? const EdgeInsets.all(AppSpacing.x2)
            : const EdgeInsets.symmetric(
                horizontal: AppSpacing.x3,
                vertical: AppSpacing.x2,
              ),
        decoration: BoxDecoration(
          color: bookmarked ? AppColors.n900 : AppColors.n100,
          borderRadius: radius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              bookmarked
                  ? PhosphorIconsFill.bookmarkSimple
                  : PhosphorIcons.bookmarkSimple,
              size: iconOnly ? 18 : 20,
              color: bookmarked ? AppColors.paper : AppColors.ink,
            ),
            if (!iconOnly) ...[
              const SizedBox(width: AppSpacing.x2),
              Text(
                bookmarked ? 'Gemerkte' : 'Merken',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: bookmarked ? AppColors.paper : AppColors.ink,
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
