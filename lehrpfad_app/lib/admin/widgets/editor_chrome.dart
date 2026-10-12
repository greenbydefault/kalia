import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../core/autosave.dart';

/// Abschnitt im Editor: Titel, optional Hinweis, darunter der Inhalt.
class EditorSection extends StatelessWidget {
  const EditorSection({
    super.key,
    required this.title,
    required this.child,
    this.description,
  });

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (description != null) ...[
            const SizedBox(height: 2),
            Text(
              description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// „Gespeichert“ / „Speichert …“ / Fehler aus dem [AutosaveHub].
class AutosaveIndicator extends StatelessWidget {
  const AutosaveIndicator({super.key, required this.hub});

  final AutosaveHub hub;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: hub,
      builder: (context, _) {
        final theme = Theme.of(context);
        final muted = theme.textTheme.bodySmall?.copyWith(
          color: AppColors.inkMuted,
        );
        switch (hub.state) {
          case SaveState.idle:
            return const SizedBox.shrink();
          case SaveState.dirty:
          case SaveState.saving:
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
                const SizedBox(width: 8),
                Text('Speichert …', style: muted),
              ],
            );
          case SaveState.saved:
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, size: 14, color: AppColors.inkMuted),
                const SizedBox(width: 6),
                Text('Gespeichert', style: muted),
              ],
            );
          case SaveState.error:
            return Tooltip(
              message: hub.lastError ?? 'Speichern fehlgeschlagen',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 14,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Nicht gespeichert',
                    style: muted?.copyWith(color: AppColors.error),
                  ),
                ],
              ),
            );
        }
      },
    );
  }
}
