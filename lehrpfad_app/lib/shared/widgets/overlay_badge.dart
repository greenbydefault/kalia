import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Kleines Scrim-Label über Bildern (Credit, „In Prüfung“).
class OverlayBadge extends StatelessWidget {
  const OverlayBadge({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.scrim54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.n50, fontSize: 11),
      ),
    );
  }
}
