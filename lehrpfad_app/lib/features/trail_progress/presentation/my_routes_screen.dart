import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/shell_tab_provider.dart';
import '../../../app/theme/app_spacing.dart';
import '../../trail/data/providers.dart';
import '../../trail/domain/trail.dart';
import '../data/trail_list_providers.dart';
import '../data/trail_progress_providers.dart';
import '../domain/trail_list.dart';
import 'list_name_dialog.dart';
import 'my_routes_section.dart';
import 'open_trail_on_map.dart';
import 'trail_list_detail_screen.dart';

/// Tab: Unterwegs · Listen · Gelaufen.
class MyRoutesScreen extends ConsumerWidget {
  const MyRoutesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trailsAsync = ref.watch(trailsProvider);
    final bookmarks = ref.watch(trailBookmarksProvider).asData?.value ?? {};
    final completions = ref.watch(trailCompletionsProvider).asData?.value ?? {};
    final activeWalk = ref.watch(activeWalkProvider).asData?.value;
    final lists = ref.watch(trailListsProvider).asData?.value ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Meine Listen')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createList(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Neue Liste'),
      ),
      body: trailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (trails) {
          final byId = {for (final t in trails) t.id: t};
          final unterwegs = <Trail>[
            if (activeWalk != null && byId.containsKey(activeWalk.trailId))
              byId[activeWalk.trailId]!,
          ];
          final gelaufen = [
            for (final id in completions.keys)
              if (byId.containsKey(id)) byId[id]!,
          ]..sort((a, b) => a.name.compareTo(b.name));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
            children: [
              MyRoutesSection(
                title: 'Unterwegs',
                trails: unterwegs,
                statusLabel: 'Unterwegs',
                onTrailTap: (t) =>
                    openTrailOnMap(context, ref, t, resume: true),
              ),
              _ListsBlock(
                lists: lists,
                bookmarkCount: bookmarks.length,
                onOpenGemerkte: () => _openDetail(context, null),
                onOpenList: (list) => _openDetail(context, list.id),
              ),
              MyRoutesSection(
                title: 'Gelaufen',
                trails: gelaufen,
                statusLabel: 'Gelaufen',
                onTrailTap: (t) => openTrailOnMap(context, ref, t),
              ),
              if (unterwegs.isEmpty &&
                  gelaufen.isEmpty &&
                  bookmarks.isEmpty &&
                  lists.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.x4),
                  child: Column(
                    children: [
                      const Text(
                        'Noch keine gemerkten Trails oder Listen.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () =>
                            ref.read(shellTabIndexProvider.notifier).goToMap(),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Zur Karte'),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createList(BuildContext context, WidgetRef ref) async {
    final name = await showListNameDialog(context, title: 'Neue Liste');
    if (name == null) return;
    try {
      await ref.read(trailListsProvider.notifier).createList(name);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _openDetail(BuildContext context, String? listId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TrailListDetailScreen(listId: listId),
      ),
    );
  }
}

class _ListsBlock extends StatelessWidget {
  const _ListsBlock({
    required this.lists,
    required this.bookmarkCount,
    required this.onOpenGemerkte,
    required this.onOpenList,
  });

  final List<TrailList> lists;
  final int bookmarkCount;
  final VoidCallback onOpenGemerkte;
  final ValueChanged<TrailList> onOpenList;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Listen', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _ListRow(
          icon: PhosphorIconsFill.bookmarkSimple,
          title: 'Gemerkte',
          count: bookmarkCount,
          onTap: onOpenGemerkte,
        ),
        for (final list in lists)
          _ListRow(
            icon: PhosphorIcons.listBullets,
            title: list.name,
            count: list.trailCount,
            onTap: () => onOpenList(list),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: PhosphorIcon(icon, color: theme.colorScheme.onPrimaryContainer),
      ),
      title: Text(title),
      subtitle: Text(count == 1 ? '1 Trail' : '$count Trails'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
