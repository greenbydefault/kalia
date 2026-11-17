import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../data/community_providers.dart';
import '../domain/trail_comment.dart';
import 'my_contributions_support.dart';

/// Eine Kommentar-Zeile: Trailname, Text (2 Zeilen), Datum.
class MyCommentTile extends ConsumerWidget {
  const MyCommentTile({super.key, required this.comment, this.maxLines = 2});

  final TrailComment comment;
  final int maxLines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final names = ref.watch(trailNamesProvider);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        names[comment.trailId] ?? comment.trailId,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        comment.text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        formatDay(comment.createdAt),
        style: Theme.of(context).textTheme.labelSmall,
      ),
      onTap: () => openContributionTrail(context, ref, comment.trailId),
    );
  }
}

/// Alle eigenen Kommentare. Wischen nach links löscht (mit Rückfrage),
/// Tippen öffnet den Pfad.
class MyCommentsScreen extends ConsumerWidget {
  const MyCommentsScreen({super.key});

  Future<bool> _delete(
    BuildContext context,
    WidgetRef ref,
    TrailComment c,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kommentar löschen?'),
        content: const Text('Der Kommentar verschwindet auch beim Pfad.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    final repo = ref.read(commentsRepositoryProvider);
    if (repo == null) return false;
    try {
      await repo.deleteComment(c.id);
      ref.invalidate(myCommentsProvider);
      ref.invalidate(trailCommentsProvider(c.trailId));
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Löschen fehlgeschlagen: $e')));
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myCommentsProvider);
    final comments = async.value ?? const <TrailComment>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Meine Kommentare')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myCommentsProvider);
          await ref.read(myCommentsProvider.future);
        },
        child: async.isLoading && comments.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : comments.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Noch keine Kommentare.')),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                itemCount: comments.length,
                itemBuilder: (context, i) {
                  final c = comments[i];
                  return Dismissible(
                    key: ValueKey('comment-${c.id}'),
                    direction: DismissDirection.endToStart,
                    // Immer false: die Zeile verschwindet, sobald die Liste
                    // nach dem Löschen neu geladen ist.
                    confirmDismiss: (_) async {
                      await _delete(context, ref, c);
                      return false;
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: AppSpacing.x4),
                      color: AppColors.n200,
                      child: const Icon(Icons.delete_outline),
                    ),
                    child: MyCommentTile(comment: c, maxLines: 4),
                  );
                },
              ),
      ),
    );
  }
}
