import 'package:flutter/material.dart';

import '../../../../../shared/widgets/erlebnis_chip.dart';
import '../../../domain/station.dart';

/// Wegpunkt-Info-Karte, die als Overlay über der Detail-Karte liegt,
/// wenn eine Station angetippt wurde.
class StationInfoOverlay extends StatelessWidget {
  final Station station;
  final VoidCallback onClose;

  const StationInfoOverlay({
    super.key,
    required this.station,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    '${station.reihenfolge}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(station.titel, style: theme.textTheme.titleSmall),
                ),
                Text('km ${station.km}', style: theme.textTheme.bodySmall),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: onClose,
                ),
              ],
            ),
            Text(station.thema, style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              children: [
                for (final e in station.erlebnisse)
                  ErlebnisChip(erlebnisKey: e, iconSize: 15),
                if (station.barrierefrei)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.accessible, size: 15),
                      const SizedBox(width: 3),
                      Text('Barrierefrei', style: theme.textTheme.bodySmall),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
