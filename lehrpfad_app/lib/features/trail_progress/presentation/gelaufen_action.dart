import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/trail_progress_providers.dart';
import '../domain/completion_source.dart';

/// Full-Sheet-Aktion: als gelaufen markieren / zurücknehmen.
class GelaufenAction extends ConsumerWidget {
  const GelaufenAction({super.key, required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed =
        ref
            .watch(trailCompletionsProvider)
            .asData
            ?.value
            .containsKey(trailId) ??
        false;

    return Align(
      alignment: Alignment.centerLeft,
      child: completed
          ? TextButton.icon(
              onPressed: () => ref
                  .read(trailCompletionsProvider.notifier)
                  .setCompleted(trailId, completed: false),
              icon: const Icon(Icons.undo),
              label: const Text('Gelaufen zurücknehmen'),
            )
          : OutlinedButton.icon(
              onPressed: () => ref
                  .read(trailCompletionsProvider.notifier)
                  .setCompleted(
                    trailId,
                    completed: true,
                    source: CompletionSource.manual,
                  ),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Als gelaufen markieren'),
            ),
    );
  }
}
