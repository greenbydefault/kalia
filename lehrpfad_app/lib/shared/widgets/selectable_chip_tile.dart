import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/motion/reduced_motion.dart';

/// Große Mehrfachauswahl-Kachel mit Häkchen-Badge und Tap-Pop.
class SelectableChipTile extends StatefulWidget {
  const SelectableChipTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<SelectableChipTile> createState() => _SelectableChipTileState();
}

class _SelectableChipTileState extends State<SelectableChipTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: OnboardingMotion.chipPop,
    value: 1,
  );

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _tap() {
    if (!context.reduceMotion) _pop.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = widget.selected;

    return Semantics(
      button: true,
      selected: selected,
      label: '${widget.title}, ${widget.subtitle}',
      excludeSemantics: true,
      onTap: _tap,
      child: AnimatedBuilder(
        animation: _pop,
        builder: (context, child) => Transform.scale(
          scale: 0.94 + 0.06 * Curves.easeOutBack.transform(_pop.value),
          child: child,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _tap,
          child: AnimatedContainer(
            duration: context.motion(const Duration(milliseconds: 180)),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 80),
            padding: const EdgeInsets.all(AppSpacing.x4),
            decoration: BoxDecoration(
              color: selected ? AppColors.n200 : AppColors.n100,
              borderRadius: BorderRadius.circular(AppSpacing.x4),
              border: Border.all(
                color: selected ? AppColors.ink : AppColors.hairline,
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.x5),
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      widget.subtitle,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: context.motion(const Duration(milliseconds: 320)),
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.ink,
                        shape: BoxShape.circle,
                      ),
                      child: const PhosphorIcon(
                        PhosphorIconsBold.check,
                        size: 14,
                        color: AppColors.paper,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
