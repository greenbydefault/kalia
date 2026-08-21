import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import 'sheet_motion.dart';

/// Chrome für content-sized Bottom-Cards (Handle, Radius, Shadow, maxHeight).
class BottomContentCard extends StatelessWidget {
  const BottomContentCard({
    super.key,
    required this.child,
    this.showHandle = true,
    this.maxHeightFraction = 0.85,
    this.padForKeyboard = false,
  });

  final Widget child;
  final bool showHandle;
  final double maxHeightFraction;
  final bool padForKeyboard;

  static const BorderRadius topRadius = BorderRadius.vertical(
    top: Radius.circular(AppSpacing.x6),
  );

  static BoxDecoration decoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: topRadius,
      boxShadow: const [BoxShadow(blurRadius: 20, color: AppColors.scrim26)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final maxH = media.size.height * maxHeightFraction;
    final keyboard = padForKeyboard ? media.viewInsets.bottom : 0.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: DecoratedBox(
            decoration: decoration(theme),
            child: ClipRRect(
              borderRadius: topRadius,
              child: AnimatedSize(
                duration: SheetMotion.size,
                curve: SheetMotion.enterCurve,
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.x5,
                      showHandle ? 0 : AppSpacing.x2,
                      AppSpacing.x5,
                      AppSpacing.x5 + media.padding.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showHandle) const BottomContentCardHandle(),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BottomContentCardHandle extends StatelessWidget {
  const BottomContentCardHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
