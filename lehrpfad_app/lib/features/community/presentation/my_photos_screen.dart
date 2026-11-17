import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../data/community_providers.dart';
import '../domain/trail_image.dart';
import 'my_contributions_support.dart';
import 'my_photo_detail_screen.dart';

/// Alle eigenen Fotos mit Filter nach Status.
class MyPhotosScreen extends ConsumerStatefulWidget {
  const MyPhotosScreen({super.key, this.initialFilter});

  /// Vorbelegter Filter, `null` = alle.
  final TrailImageStatus? initialFilter;

  @override
  ConsumerState<MyPhotosScreen> createState() => _MyPhotosScreenState();
}

class _MyPhotosScreenState extends ConsumerState<MyPhotosScreen> {
  late TrailImageStatus? _filter = widget.initialFilter;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myImagesProvider);
    final all = async.value ?? const <TrailImage>[];
    final shown = _filter == null
        ? all
        : all.where((i) => i.status == _filter).toList();

    int count(TrailImageStatus? s) =>
        s == null ? all.length : all.where((i) => i.status == s).length;

    Widget chip(TrailImageStatus? s, String label) {
      final n = count(s);
      // Leere Filter nur zeigen, wenn sie gerade aktiv sind.
      if (s != null && n == 0 && _filter != s) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.chip),
        child: ChoiceChip(
          label: Text('$label ($n)'),
          selected: _filter == s,
          onSelected: (_) => setState(() => _filter = s),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Meine Fotos')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myImagesProvider);
          await ref.read(myImagesProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.x2,
                  AppSpacing.page,
                  AppSpacing.x2,
                ),
                child: Row(
                  children: [
                    chip(null, 'Alle'),
                    chip(TrailImageStatus.pending, 'In Prüfung'),
                    chip(TrailImageStatus.approved, 'Freigegeben'),
                    chip(TrailImageStatus.rejected, 'Abgelehnt'),
                  ],
                ),
              ),
            ),
            if (async.isLoading && all.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (shown.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Keine Fotos in dieser Ansicht.')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.page),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: AppSpacing.x2,
                    crossAxisSpacing: AppSpacing.x2,
                  ),
                  itemCount: shown.length,
                  itemBuilder: (context, i) => MyPhotoTile(
                    image: shown[i],
                    onTap: () => MyPhotoDetailScreen.open(context, shown[i]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
