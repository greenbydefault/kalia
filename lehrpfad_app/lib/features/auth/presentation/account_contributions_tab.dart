import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/config/supabase_config.dart';
import '../../community/data/community_providers.dart';
import '../../community/domain/trail_comment.dart';
import '../../community/domain/trail_image.dart';
import '../../community/presentation/image_upload_sheet.dart';
import '../../community/presentation/my_comments_screen.dart';
import '../../community/presentation/my_contributions_support.dart';
import '../../community/presentation/my_photo_detail_screen.dart';
import '../../community/presentation/my_photos_screen.dart';
import '../../report/presentation/report_account_tiles.dart';
import '../data/auth_providers.dart';
import 'account_prompt_sheet.dart';

const _photoPreview = 6;
const _commentPreview = 3;

/// Tab „Meine Beiträge“: Fotos mit Status, letzte Kommentare, Meldungen.
/// Alles auf einen Blick; „Alle“ öffnet die volle Liste.
class AccountContributionsTab extends ConsumerWidget {
  const AccountContributionsTab({super.key, this.fresh = const {}});

  /// IDs von Fotos mit neuer, ungesehener Entscheidung.
  final Set<String> fresh;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(myImagesProvider);
    ref.invalidate(myCommentsProvider);
    await Future.wait([
      ref.read(myImagesProvider.future).catchError((_) => <TrailImage>[]),
      ref.read(myCommentsProvider.future).catchError((_) => <TrailComment>[]),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configured = SupabaseConfig.isConfigured;
    final loggedIn = configured && ref.watch(authStateProvider).value != null;

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          AppSpacing.x4,
          20,
          AppSpacing.x6,
        ),
        children: [
          if (!configured)
            const _InfoCard(
              text:
                  'Fotos und Kommentare gibt es mit Serververbindung. '
                  'Meldungen funktionieren auch ohne.',
            )
          else if (!loggedIn)
            const _LoggedOutCard()
          else ...[
            PhotosBlock(fresh: fresh),
            const SizedBox(height: AppSpacing.section),
            const CommentsBlock(),
          ],
          const SizedBox(height: AppSpacing.section),
          Text('Meldungen', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.afterHeading),
          const ReportAccountTiles(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.total = 0,
    this.limit = 0,
    this.onAll,
  });

  final String title;
  final int total;
  final int limit;
  final VoidCallback? onAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (total > limit && onAll != null)
          TextButton(onPressed: onAll, child: Text('Alle ($total)')),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(text, style: Theme.of(context).textTheme.bodyMedium),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.x3),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _LoggedOutCard extends StatelessWidget {
  const _LoggedOutCard();

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      text: AccountReason.contributions,
      action: FilledButton(
        onPressed: () =>
            requireAccount(context, reason: AccountReason.contributions),
        child: const Text('Anmelden'),
      ),
    );
  }
}

class PhotosBlock extends ConsumerWidget {
  const PhotosBlock({required this.fresh});

  final Set<String> fresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myImagesProvider);
    final images = async.value ?? const <TrailImage>[];

    Widget body;
    if (async.hasError && images.isEmpty) {
      body = _InfoCard(
        text: 'Die Fotos konnten nicht geladen werden.',
        action: OutlinedButton(
          onPressed: () => ref.invalidate(myImagesProvider),
          child: const Text('Erneut versuchen'),
        ),
      );
    } else if (async.isLoading && images.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.x6),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (images.isEmpty) {
      body = _InfoCard(
        text: 'Noch keine Fotos. Was ihr hochladet, erscheint hier mit Status.',
        action: OutlinedButton.icon(
          onPressed: () => ImageUploadSheet.show(context),
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Erstes Foto hochladen'),
        ),
      );
    } else {
      final preview = prioritized(images).take(_photoPreview).toList();
      body = GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.x2,
        crossAxisSpacing: AppSpacing.x2,
        children: [
          for (final image in preview)
            MyPhotoTile(
              image: image,
              isNew: fresh.contains(image.id),
              onTap: () => MyPhotoDetailScreen.open(context, image),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Meine Fotos',
          total: images.length,
          limit: _photoPreview,
          onAll: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const MyPhotosScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.afterHeading),
        body,
      ],
    );
  }
}

class CommentsBlock extends ConsumerWidget {
  const CommentsBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myCommentsProvider);
    final comments = async.value ?? const <TrailComment>[];

    Widget body;
    if (async.hasError && comments.isEmpty) {
      body = _InfoCard(
        text: 'Die Kommentare konnten nicht geladen werden.',
        action: OutlinedButton(
          onPressed: () => ref.invalidate(myCommentsProvider),
          child: const Text('Erneut versuchen'),
        ),
      );
    } else if (async.isLoading && comments.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.x4),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (comments.isEmpty) {
      body = const _InfoCard(
        text:
            'Noch keine Kommentare. Tipps zu einem Pfad schreibt ihr direkt '
            'beim Pfad.',
      );
    } else {
      body = Column(
        children: [
          for (final c in comments.take(_commentPreview))
            MyCommentTile(comment: c),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Meine Kommentare',
          total: comments.length,
          limit: _commentPreview,
          onAll: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const MyCommentsScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.afterHeading),
        body,
      ],
    );
  }
}
