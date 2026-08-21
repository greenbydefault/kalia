import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../trail/data/providers.dart';
import '../../trail/domain/trail.dart';
import '../data/trail_list_providers.dart';
import '../data/trail_progress_providers.dart';
import '../domain/trail_list.dart';
import 'list_name_dialog.dart';
import 'my_routes_section.dart';
import 'open_trail_on_map.dart';

/// Detail einer User-Liste oder der virtuellen Gemerkte-Sammlung.
class TrailListDetailScreen extends ConsumerWidget {
  const TrailListDetailScreen({super.key, this.listId});

  /// `null` = Gemerkte (Bookmark-Set).
  final String? listId;

  bool get _isGemerkte => listId == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trailsAsync = ref.watch(trailsProvider);
    final bookmarks = ref.watch(trailBookmarksProvider).asData?.value ?? {};
    final lists = ref.watch(trailListsProvider).asData?.value ?? const [];
    TrailList? list;
    if (listId != null) {
      for (final item in lists) {
        if (item.id == listId) {
          list = item;
          break;
        }
      }
    }

    if (!_isGemerkte && list == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Liste')),
        body: const Center(child: Text('Liste nicht gefunden.')),
      );
    }

    final title = _isGemerkte ? 'Gemerkte' : list!.name;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (list != null)
            PopupMenuButton<_ListMenu>(
              onSelected: (value) => _handleMenu(context, ref, list!, value),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _ListMenu.rename,
                  child: Text('Umbenennen'),
                ),
                PopupMenuItem(value: _ListMenu.delete, child: Text('Löschen')),
              ],
            ),
        ],
      ),
      body: trailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (trails) {
          final byId = {for (final trail in trails) trail.id: trail};
          final selected = _isGemerkte
              ? [
                  for (final id in bookmarks)
                    if (byId.containsKey(id)) byId[id]!,
                ]
              : _trailsForList(list!, byId);
          if (_isGemerkte) {
            selected.sort((a, b) => a.name.compareTo(b.name));
          }

          if (selected.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.x6),
                child: Text(
                  'Noch keine Trails in dieser Liste.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              MyRoutesSection(
                title: '',
                trails: selected,
                onTrailTap: (trail) => openTrailOnMap(context, ref, trail),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Trail> _trailsForList(TrailList list, Map<String, Trail> byId) {
    final ordered = [...list.items]
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return [
      for (final item in ordered)
        if (byId.containsKey(item.trailId)) byId[item.trailId]!,
    ];
  }

  Future<void> _handleMenu(
    BuildContext context,
    WidgetRef ref,
    TrailList list,
    _ListMenu value,
  ) async {
    switch (value) {
      case _ListMenu.rename:
        final name = await showListNameDialog(
          context,
          title: 'Liste umbenennen',
          initial: list.name,
          confirmLabel: 'Speichern',
        );
        if (name == null) return;
        await ref.read(trailListsProvider.notifier).renameList(list.id, name);
      case _ListMenu.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Liste löschen?'),
            content: Text(
              '„${list.name}“ wird gelöscht. Gemerkte Trails bleiben gemerkt.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Löschen'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        await ref.read(trailListsProvider.notifier).deleteList(list.id);
        if (context.mounted) Navigator.of(context).pop();
    }
  }
}

enum _ListMenu { rename, delete }
