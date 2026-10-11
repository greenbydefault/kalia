import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Grauer Platzhalter, bis echte Bilder oder Illustrationen da sind.
class PlaceholderBlock extends StatelessWidget {
  const PlaceholderBlock({
    super.key,
    this.width,
    this.height,
    this.radius = 0,
    this.color = AppColors.n200,
    this.child,
  });

  final double? width;
  final double? height;
  final double radius;
  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}
