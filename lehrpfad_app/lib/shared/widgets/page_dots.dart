import 'package:flutter/material.dart';

import 'content_carousel_style.dart';

/// Page-Index-Dots. Größe und Abstand kommen aus [ContentCarouselStyle].
class PageDots extends StatelessWidget {
  const PageDots({
    super.key,
    required this.count,
    required this.index,
    this.activeColor,
    this.inactiveColor,
  });

  final int count;
  final int index;
  final Color? activeColor;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Container(
            width: ContentCarouselStyle.dotSize,
            height: ContentCarouselStyle.dotSize,
            margin: const EdgeInsets.symmetric(
              horizontal: ContentCarouselStyle.dotGap,
            ),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == index
                  ? (activeColor ?? theme.colorScheme.primary)
                  : (inactiveColor ?? theme.colorScheme.outlineVariant),
            ),
          ),
      ],
    );
  }
}
