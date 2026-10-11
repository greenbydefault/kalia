import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/motion/reduced_motion.dart';

/// Zurück-Pfeil, „Schritt x von 2“ und zwei Fortschrittsbalken.
class OnboardingStepHeader extends StatelessWidget {
  const OnboardingStepHeader({
    super.key,
    required this.step,
    required this.onBack,
    this.total = 2,
  });

  final int step;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Zurück',
              onPressed: onBack,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: const PhosphorIcon(PhosphorIcons.caretLeft, size: 24),
            ),
            const SizedBox(width: AppSpacing.x1),
            Text(
              'Schritt $step von $total',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
          child: Row(
            children: [
              for (var i = 1; i <= total; i++) ...[
                if (i > 1) const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: AnimatedContainer(
                    duration: context.motion(const Duration(milliseconds: 300)),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= step ? AppColors.ink : AppColors.n300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
