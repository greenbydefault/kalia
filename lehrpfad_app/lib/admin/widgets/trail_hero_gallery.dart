import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../features/community/domain/trail_image.dart';
import '../../shared/widgets/kalia_image.dart';
import '../collections/admin_catalogs.dart';
import '../core/admin_media_service.dart';
import '../core/collection_spec.dart';
import '../core/field_spec.dart';

const imageTypes = XTypeGroup(
  label: 'Bilder',
  extensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
);

/// Offizielle Hero-Bilder eines Trails (`images`, `source=official`).
/// Hochladen, Reihenfolge, Quelle/Lizenz bearbeiten, Löschen.
class TrailHeroGallery extends StatefulWidget {
  const TrailHeroGallery({super.key, required this.ctx});

  final EditorContext ctx;

  @override
  State<TrailHeroGallery> createState() => _TrailHeroGalleryState();
}

class _TrailHeroGalleryState extends State<TrailHeroGallery> {
  late final AdminMediaService _media = AdminMediaService(widget.ctx.client);
  List<DbRow>? _images;
  Object? _error;
  double? _progress;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await widget.ctx.client
          .from('images')
          .select()
          .eq('trail_id', widget.ctx.id)
          .eq('source', 'official')
          .order('sort', ascending: true)
          .order('created_at', ascending: true);
      if (mounted) {
        setState(
          () =>
              _images = rows.map((r) => Map<String, dynamic>.from(r)).toList(),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _toast(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }

  Future<void> _upload() async {
    final file = await openFile(acceptedTypeGroups: const [imageTypes]);
    if (file == null || !mounted) return;
    final meta = await showDialog<HeroMeta>(
      context: context,
      builder: (_) => HeroMetaDialog(
        title: 'Bild hochladen',
        confirmLabel: 'Hochladen',
        fileName: file.name,
      ),
    );
    if (meta == null) return;
    setState(() => _progress = 0);
    try {
      final bytes = await file.readAsBytes();
      await _media.uploadTrailHero(
        widget.ctx.id,
        bytes,
        meta,
        onProgress: (f) {
          if (mounted) setState(() => _progress = f);
        },
      );
      await _load();
    } catch (e) {
      _toast(e);
    } finally {
      if (mounted) setState(() => _progress = null);
    }
  }

  Future<void> _edit(DbRow r) async {
    final meta = await showDialog<HeroMeta>(
      context: context,
      builder: (_) => HeroMetaDialog(
        title: 'Quelle & Lizenz',
        confirmLabel: 'Speichern',
        initial: HeroMeta(
          credit: r['credit'] as String? ?? '',
          caption: r['caption'] as String? ?? '',
          license: r['license'] as String? ?? '',
          licenseUrl: r['license_url'] as String? ?? '',
          sourceUrl: r['source_url'] as String? ?? '',
        ),
      ),
    );
    if (meta == null) return;
    try {
      await _media.updateHero(r['id'] as String, meta);
      await _load();
    } catch (e) {
      _toast(e);
    }
  }

  Future<void> _move(int index, int delta) async {
    final list = _images!;
    final j = index + delta;
    if (j < 0 || j >= list.length) return;
    // sort-Werte können gleich sein (Import): erst durchnummerieren.
    try {
      for (var i = 0; i < list.length; i++) {
        final want = i + 1;
        if ((list[i]['sort'] as num?)?.toInt() != want) {
          list[i]['sort'] = want;
          await widget.ctx.client
              .from('images')
              .update({'sort': want})
              .eq('id', list[i]['id']);
        }
      }
      await _media.swapHeroOrder(
        (id: list[index]['id'] as String, sort: index + 1),
        (id: list[j]['id'] as String, sort: j + 1),
      );
      await _load();
    } catch (e) {
      _toast(e);
    }
  }

  Future<void> _delete(DbRow r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bild löschen?'),
        content: const Text('Dateien und Eintrag werden entfernt.'),
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
    if (ok != true) return;
    try {
      await _media.deleteHero(widget.ctx.id, r['id'] as String);
      await _load();
    } catch (e) {
      _toast(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_error != null) {
      return Text(
        'Konnte nicht laden: $_error',
        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
      );
    }
    final images = _images;
    if (images == null) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Noch keine Bilder in der Datenbank. Die App zeigt solange die '
              'gebündelten Bilder.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < images.length; i++)
                _HeroTile(
                  trailId: widget.ctx.id,
                  imageId: images[i]['id'] as String,
                  row: images[i],
                  first: i == 0,
                  last: i == images.length - 1,
                  onEdit: () => _edit(images[i]),
                  onDelete: () => _delete(images[i]),
                  onLeft: () => _move(i, -1),
                  onRight: () => _move(i, 1),
                ),
            ],
          ),
        const SizedBox(height: 12),
        if (_progress != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(value: _progress),
          )
        else
          OutlinedButton.icon(
            onPressed: _upload,
            icon: const Icon(Icons.upload_outlined, size: 18),
            label: const Text('Bild hochladen'),
          ),
      ],
    );
  }
}

class _HeroTile extends StatelessWidget {
  const _HeroTile({
    required this.trailId,
    required this.imageId,
    required this.row,
    required this.first,
    required this.last,
    required this.onEdit,
    required this.onDelete,
    required this.onLeft,
    required this.onRight,
  });

  final String trailId;
  final String imageId;
  final DbRow row;
  final bool first;
  final bool last;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final credit = row['credit'] as String? ?? '';
    final license = row['license'] as String? ?? '';
    final missing = credit.isEmpty || license.isEmpty;
    return Container(
      width: 220,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 140,
            width: double.infinity,
            child: KaliaImage(
              trailId: trailId,
              imageId: imageId,
              slot: TrailImageVariant.small,
              thumbhash: row['thumbhash'] as String? ?? '',
              dominantColor: row['dominant_color'] as String? ?? '',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Row(
              children: [
                if (missing)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: AppColors.eignung3,
                    ),
                  ),
                Expanded(
                  child: Text(
                    credit.isEmpty ? 'Quelle fehlt' : credit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Text(
              license.isEmpty
                  ? 'Lizenz fehlt'
                  : (lizenzOptions[license] ?? license),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Nach vorn',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_back, size: 16),
                onPressed: first ? null : onLeft,
              ),
              IconButton(
                tooltip: 'Nach hinten',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_forward, size: 16),
                onPressed: last ? null : onRight,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Quelle & Lizenz',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, size: 16),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Löschen',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 16),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quelle, Lizenz und Bildunterschrift eines Bildes.
class HeroMetaDialog extends StatefulWidget {
  const HeroMetaDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.initial = const HeroMeta(),
    this.fileName,
  });

  final String title;
  final String confirmLabel;
  final HeroMeta initial;
  final String? fileName;

  @override
  State<HeroMetaDialog> createState() => _HeroMetaDialogState();
}

class _HeroMetaDialogState extends State<HeroMetaDialog> {
  late final _credit = TextEditingController(text: widget.initial.credit);
  late final _caption = TextEditingController(text: widget.initial.caption);
  late final _licenseUrl = TextEditingController(
    text: widget.initial.licenseUrl,
  );
  late final _sourceUrl = TextEditingController(text: widget.initial.sourceUrl);
  late String _license = widget.initial.license;

  @override
  void dispose() {
    _credit.dispose();
    _caption.dispose();
    _licenseUrl.dispose();
    _sourceUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.fileName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    widget.fileName!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                  ),
                ),
              TextField(
                controller: _credit,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Urheber / Quelle',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: lizenzOptions.containsKey(_license)
                    ? _license
                    : null,
                decoration: const InputDecoration(labelText: 'Lizenz'),
                items: [
                  for (final e in lizenzOptions.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _license = v ?? ''),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _licenseUrl,
                decoration: const InputDecoration(labelText: 'Lizenz-URL'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sourceUrl,
                decoration: const InputDecoration(labelText: 'Quell-URL'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _caption,
                decoration: const InputDecoration(
                  labelText: 'Bildunterschrift',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            HeroMeta(
              credit: _credit.text.trim(),
              caption: _caption.text.trim(),
              license: _license,
              licenseUrl: _licenseUrl.text.trim(),
              sourceUrl: _sourceUrl.text.trim(),
            ),
          ),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
