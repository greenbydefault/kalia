import 'package:flutter/material.dart';

import '../../../domain/steckbrief.dart';

/// Steckbrief-Werte (Größe, Alter, Tiefe, ...) als beschriftete Zeilen.
/// Nur gesetzte Felder werden angezeigt.
class SteckbriefTable extends StatelessWidget {
  final Steckbrief steckbrief;

  const SteckbriefTable({super.key, required this.steckbrief});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zeilen = <(String, String)>[
      if (steckbrief.groesseHa != null) ('Größe', '${steckbrief.groesseHa} ha'),
      if (steckbrief.alterJahre != null)
        ('Alter', '${steckbrief.alterJahre} Jahre'),
      if (steckbrief.tiefeM != null) ('Tiefe', '${steckbrief.tiefeM} m'),
      if (steckbrief.lebenselixier != null)
        ('Lebenselixier', steckbrief.lebenselixier!),
      if (steckbrief.werdegang != null) ('Werdegang', steckbrief.werdegang!),
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          for (final (label, wert) in zeilen)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(child: Text(wert, style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
