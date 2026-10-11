import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/motion/reduced_motion.dart';

/// Schalter-Zeile „Kinderwagen dabei“. Knob mit leichtem Overshoot.
class StrollerSwitch extends StatelessWidget {
  const StrollerSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dur = context.motion(const Duration(milliseconds: 350));
    return Semantics(
      toggled: value,
      label: 'Kinderwagen dabei',
      excludeSemantics: true,
      onTap: () => onChanged(!value),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kinderwagen dabei',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      'Befahrbare Wege zeigen wir zuerst.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              AnimatedContainer(
                duration: dur,
                curve: Curves.easeOutCubic,
                width: 52,
                height: 32,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: value ? AppColors.ink : AppColors.n300,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AnimatedAlign(
                  duration: dur,
                  curve: Curves.easeOutBack,
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.paper,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
