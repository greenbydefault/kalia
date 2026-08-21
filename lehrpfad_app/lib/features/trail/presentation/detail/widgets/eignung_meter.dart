import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../shared/catalogs/icon_catalog.dart';
import '../../../domain/eignung_score.dart';

/// Ein Signal-Balken-Meter für eine abgeleitete Trail-Eignung (1–5).
class EignungMeter extends StatelessWidget {
  const EignungMeter({super.key, required this.score});

  final EignungScore score;

  static const _barHeights = <double>[8, 11, 14, 17, 20];
  static const _barWidth = 5.0;
  static const _barGap = 3.0;

  String get _tagKey => switch (score.art) {
    EignungArt.kinderfreundlich => 'kinderfreundlich',
    EignungArt.barrierefreundlich => 'rollstuhltauglich',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eintrag = tagEintrag(_tagKey);
    final level = score.level.clamp(1, 5);

    return Semantics(
      label: '${score.artLabel}: ${score.label} ($level von 5)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              eintrag.buildIcon(
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  score.artLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 5; i++) ...[
                if (i > 0) const SizedBox(width: _barGap),
                _SignalBar(
                  height: _barHeights[i],
                  active: i < level,
                  color: AppColors.eignungSpectrum[i],
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  score.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignalBar extends StatelessWidget {
  const _SignalBar({
    required this.height,
    required this.active,
    required this.color,
  });

  final double height;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: EignungMeter._barWidth,
      height: height,
      decoration: BoxDecoration(
        color: active ? color : AppColors.n200,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
