import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../data/community_providers.dart';
import '../domain/trail_comment.dart';

/// Kommentare zu einem Trail: Liste (neueste zuerst) plus Eingabefeld
/// fuer eingeloggte User. Eigene Kommentare (und als Admin alle) sind
/// loeschbar.
class CommentsSection extends ConsumerStatefulWidget {
  final String trailId;

  const CommentsSection({super.key, required this.trailId});

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final repo = ref.read(commentsRepositoryProvider);
    final text = _controller.text.trim();
    if (repo == null || text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await repo.addComment(widget.trailId, text);
      _controller.clear();
      ref.invalidate(trailCommentsProvider(widget.trailId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kommentar fehlgeschlagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(TrailComment comment) async {
    final repo = ref.read(commentsRepositoryProvider);
    if (repo == null) return;
    try {
      await repo.deleteComment(comment.id);
      ref.invalidate(trailCommentsProvider(widget.trailId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Löschen fehlgeschlagen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(trailCommentsProvider(widget.trailId));
    final loggedIn = ref.watch(authStateProvider).value != null;
    final isAdmin = ref.watch(isAdminProvider);
    final theme = Theme.of(context);
    final comments = commentsAsync.value ?? const <TrailComment>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (comments.isEmpty)
          Text('Noch keine Kommentare.', style: theme.textTheme.bodySmall)
        else
          for (final comment in comments)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    child: Text(
                      comment.authorName.isNotEmpty
                          ? comment.authorName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                comment.authorName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              _formatDate(comment.createdAt),
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                        Text(comment.text, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  if (comment.isMine || isAdmin)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Kommentar löschen',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _delete(comment),
                    ),
                ],
              ),
            ),
        const SizedBox(height: 4),
        if (loggedIn)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLength: 1000,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Kommentar schreiben …',
                    counterText: '',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          )
        else
          Text(
            'Melde dich an, um zu kommentieren.',
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    final d = date.toLocal();
    return '${d.day}.${d.month}.${d.year}';
  }
}
