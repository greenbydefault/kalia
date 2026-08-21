import 'package:flutter/material.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../domain/eignung_score.dart';
import '../../../domain/trail.dart';
import 'eignung_meter.dart';

/// Zwei Eignungs-Meter nebeneinander, klar getrennt von den Tag-Chips.
class EignungSection extends StatelessWidget {
  const EignungSection({super.key, required this.trail});

  final Trail trail;

  @override
  Widget build(BuildContext context) {
    final scores = scoreEignungen(trail);
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.x3),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: AppSpacing.x3,
        ),
        child: Row(
          children: [
            Expanded(child: EignungMeter(score: scores.kinder)),
            const SizedBox(width: AppSpacing.x4),
            Expanded(child: EignungMeter(score: scores.barriere)),
          ],
        ),
      ),
    );
  }
}
