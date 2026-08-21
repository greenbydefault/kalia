import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/pressable.dart';

/// Kompakter Toggle „Hab gesehen“.
class GesehenToggle extends StatelessWidget {
  const GesehenToggle({
    super.key,
    required this.seen,
    required this.onChanged,
  });

  final bool seen;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const radius = BorderRadius.all(Radius.circular(10));

    return Pressable(
      borderRadius: radius,
      onPressed: () => onChanged(!seen),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: seen ? AppColors.n900 : AppColors.n100,
          borderRadius: radius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              seen ? PhosphorIcons.checkCircle : PhosphorIcons.eye,
              size: 20,
              color: seen ? AppColors.paper : AppColors.ink,
            ),
            const SizedBox(width: 8),
            Text(
              seen ? 'Gesehen' : 'Hab gesehen',
              style: theme.textTheme.labelLarge?.copyWith(
                color: seen ? AppColors.paper : AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
