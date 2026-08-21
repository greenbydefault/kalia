import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/show_app_modal_sheet.dart';
import '../../trail/domain/trail.dart';
import '../data/trail_list_providers.dart';
import '../data/trail_progress_providers.dart';
import 'list_name_dialog.dart';

/// Zuordnen eines Trails zu Gemerkte und eigenen Listen. Dismiss speichert nicht.
class SaveToListSheet extends ConsumerWidget {
  const SaveToListSheet({super.key, required this.trail});

  final Trail trail;

  static Future<void> show(BuildContext context, Trail trail) {
    return showAppModalSheet<void>(
      context: context,
      padForKeyboard: true,
      builder: (_) => SaveToListSheet(trail: trail),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bookmarked =
        ref.watch(trailBookmarksProvider).asData?.value.contains(trail.id) ??
        false;
    final lists = ref.watch(trailListsProvider).asData?.value ?? const [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('In Liste merken', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.x1),
        Text(
          trail.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.x3),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: bookmarked,
          onChanged: (value) {
            ref
                .read(trailBookmarksProvider.notifier)
                .setBookmarked(trail.id, value ?? false);
          },
          secondary: PhosphorIcon(
            bookmarked
                ? PhosphorIconsFill.bookmarkSimple
                : PhosphorIcons.bookmarkSimple,
            size: 22,
          ),
          title: const Text('Gemerkte'),
        ),
        for (final list in lists)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: list.containsTrail(trail.id),
            onChanged: (value) {
              ref
                  .read(trailListsProvider.notifier)
                  .setInList(
                    listId: list.id,
                    trailId: trail.id,
                    inList: value ?? false,
                  );
            },
            secondary: const PhosphorIcon(PhosphorIcons.listBullets, size: 22),
            title: Text(list.name),
            subtitle: Text(_countLabel(list.trailCount)),
          ),
        const SizedBox(height: AppSpacing.x2),
        OutlinedButton.icon(
          onPressed: () => _createList(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Neue Liste anlegen'),
        ),
      ],
    );
  }

  Future<void> _createList(BuildContext context, WidgetRef ref) async {
    final name = await showListNameDialog(context, title: 'Neue Liste');
    if (name == null) return;
    try {
      final list = await ref.read(trailListsProvider.notifier).createList(name);
      await ref
          .read(trailListsProvider.notifier)
          .setInList(listId: list.id, trailId: trail.id, inList: true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

String _countLabel(int count) {
  if (count == 1) return '1 Trail';
  return '$count Trails';
}
