import 'package:flutter/material.dart';

import '../../../shared/catalogs/icon_catalog.dart';
import '../../trail/domain/trail.dart';

class MyRoutesSection extends StatelessWidget {
  const MyRoutesSection({
    super.key,
    required this.title,
    required this.trails,
    required this.onTrailTap,
    this.statusLabel,
  });

  final String title;
  final List<Trail> trails;
  final ValueChanged<Trail> onTrailTap;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    if (trails.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
        ],
        for (final trail in trails)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: typEintrag(
                trail.typ,
              ).buildIcon(color: theme.colorScheme.onPrimaryContainer),
            ),
            title: Text(trail.name),
            subtitle: Text('${trail.laengeKm} km · ~${trail.dauerMin} Min'),
            trailing: statusLabel == null
                ? const Icon(Icons.chevron_right)
                : Chip(
                    label: Text(statusLabel!),
                    visualDensity: VisualDensity.compact,
                  ),
            onTap: () => onTrailTap(trail),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
