import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/show_app_modal_sheet.dart';
import '../data/report_permission_service.dart';
import '../data/report_photo_service.dart';
import '../data/report_providers.dart';
import '../domain/report_enums.dart';
import '../domain/report_models.dart';
import '../report_config.dart';
import '../report_copy.dart';
import 'report_widgets.dart';

/// R3 „Marker-Details“. Speichert beim Schließen über [onSave].
///
/// [onRemeasure] gibt `true` zurück, wenn neu gemessen wurde. Danach lädt
/// [reload] den Punkt neu.
Future<void> showMarkerSheet(
  BuildContext context, {
  required DraftPoint point,
  required Future<void> Function(DraftPoint) onSave,
  Future<void> Function()? onDelete,
  Future<bool> Function()? onRemeasure,
  Future<DraftPoint?> Function()? reload,
}) async {
  final holder = ValueNotifier<DraftPoint>(point);
  var deleted = false;
  await showAppModalSheet<void>(
    context: context,
    padForKeyboard: true,
    builder: (_) => _MarkerSheet(
      holder: holder,
      onDelete: onDelete == null
          ? null
          : () async {
              deleted = true;
              await onDelete();
            },
      onRemeasure: onRemeasure,
      reload: reload,
    ),
  );
  if (!deleted) await onSave(holder.value);
  holder.dispose();
}

class _MarkerSheet extends ConsumerStatefulWidget {
  const _MarkerSheet({
    required this.holder,
    this.onDelete,
    this.onRemeasure,
    this.reload,
  });

  final ValueNotifier<DraftPoint> holder;
  final Future<void> Function()? onDelete;
  final Future<bool> Function()? onRemeasure;
  final Future<DraftPoint?> Function()? reload;

  @override
  ConsumerState<_MarkerSheet> createState() => _MarkerSheetState();
}

class _MarkerSheetState extends ConsumerState<_MarkerSheet> {
  late final TextEditingController _number;
  late final TextEditingController _title;
  late final TextEditingController _note;
  List<DraftPhoto> _photos = const [];
  bool _busy = false;

  DraftPoint get _p => widget.holder.value;

  @override
  void initState() {
    super.initState();
    _number = TextEditingController(text: _p.number?.toString() ?? '');
    _title = TextEditingController(text: _p.title ?? '');
    _note = TextEditingController(text: _p.note ?? '');
    _loadPhotos();
  }

  @override
  void dispose() {
    _number.dispose();
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadPhotos() async {
    final all = await ref.read(reportDraftStoreProvider).photos(_p.draftId);
    if (!mounted) return;
    setState(
      () => _photos = [
        for (final p in all)
          if (p.pointId == _p.id) p,
      ],
    );
  }

  void _update(DraftPoint p) {
    widget.holder.value = p;
    setState(() {});
  }

  Future<void> _addPhoto() async {
    if (_busy) return;
    setState(() => _busy = true);
    await capturePointPhoto(context, ref, draftId: _p.draftId, pointId: _p.id);
    await _loadPhotos();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _removePhoto(DraftPhoto photo) async {
    await ReportPhotoService(ref.read(reportDraftStoreProvider)).remove(photo);
    await _loadPhotos();
  }

  Future<void> _remeasure() async {
    final fn = widget.onRemeasure;
    if (fn == null || _busy) return;
    setState(() => _busy = true);
    final ok = await fn();
    final fresh = await widget.reload?.call();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok && fresh != null) widget.holder.value = fresh;
    if (!ok) showReportSnack(context, rt('report.marker.remeasure_far'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = _p;
    final isStation = p.type == PointType.station;
    final isHint = p.type == PointType.hint;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                markerLabel(p.copyWith(title: '')),
                style: theme.textTheme.titleLarge,
              ),
            ),
            if (p.lowAccuracy)
              Chip(label: Text(rt('report.marker.inaccurate'))),
          ],
        ),
        const SizedBox(height: AppSpacing.x1),
        Text(
          rt('report.marker.accuracy', {'a': p.accuracyM.round()}),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.stack),
        if (isStation) ...[
          TextField(
            controller: _number,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 3,
            decoration: InputDecoration(labelText: rt('report.marker.number')),
            onChanged: (v) {
              final n = int.tryParse(v);
              _update(
                n == null
                    ? p.copyWith(clearNumber: true, numberManual: false)
                    : p.copyWith(number: n, numberManual: true),
              );
            },
          ),
          const SizedBox(height: AppSpacing.x2),
          TextField(
            controller: _title,
            maxLength: cfg.titleMaxChars,
            decoration: InputDecoration(labelText: rt('report.marker.title')),
            onChanged: (v) => _update(p.copyWith(title: v)),
          ),
        ],
        if (isHint) ...[
          Wrap(
            spacing: AppSpacing.chip,
            runSpacing: AppSpacing.chip,
            children: [
              for (final k in HintKind.values)
                ChoiceChip(
                  label: Text(hintKindLabel(k)),
                  selected: p.hintKind == k,
                  onSelected: (_) => _update(p.copyWith(hintKind: k)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
        ],
        TextField(
          controller: _note,
          maxLength: cfg.noteMaxChars,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(labelText: rt('report.marker.note')),
          onChanged: (v) => _update(p.copyWith(note: v)),
        ),
        const SizedBox(height: AppSpacing.x2),
        if (_photos.isNotEmpty)
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.x2),
              itemBuilder: (_, i) => _PhotoTile(
                photo: _photos[i],
                onRemove: () => _removePhoto(_photos[i]),
              ),
            ),
          ),
        if (_photos.length < cfg.maxPhotosPerMarker)
          TextButton.icon(
            onPressed: _busy ? null : _addPhoto,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(rt('report.marker.photo_add')),
          ),
        if (widget.onRemeasure != null)
          TextButton.icon(
            onPressed: _busy ? null : _remeasure,
            icon: const Icon(Icons.my_location),
            label: Text(rt('report.marker.remeasure')),
          ),
        const SizedBox(height: AppSpacing.x2),
        ReportPrimaryButton(
          label: rt('report.common.done'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        if (widget.onDelete != null)
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () async {
              await widget.onDelete!();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(rt('report.common.delete')),
          ),
      ],
    );
  }
}

class _PhotoTile extends ConsumerWidget {
  const _PhotoTile({required this.photo, required this.onRemove});

  final DraftPhoto photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.read(reportDraftStoreProvider);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 88,
            height: 88,
            child: FutureBuilder<Uint8List?>(
              future: store.readPhotoBytes(photo.localPath),
              builder: (_, snap) => snap.data == null
                  ? const ColoredBox(color: Colors.black12)
                  : Image.memory(snap.data!, fit: BoxFit.cover),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            tooltip: rt('report.marker.photo_remove'),
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(backgroundColor: Colors.black54),
            color: Colors.white,
            icon: const Icon(Icons.close, size: 16),
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }
}

/// Foto aufnehmen und am Punkt ablegen. Meldet Fehler als Snackbar.
Future<bool> capturePointPhoto(
  BuildContext context,
  WidgetRef ref, {
  required String draftId,
  String? pointId,
}) async {
  try {
    final svc = ReportPhotoService(ref.read(reportDraftStoreProvider));
    final photo = await svc.add(draftId: draftId, pointId: pointId);
    return photo != null;
  } on PhotoSaveException {
    if (context.mounted) showReportSnack(context, rt('report.err.photo_save'));
  } on PlatformException {
    if (context.mounted) {
      showReportSnack(
        context,
        rt('report.perm.camera.title'),
        action: SnackBarAction(
          label: rt('report.perm.camera.cta'),
          onPressed: () =>
              ref.read(reportPermissionServiceProvider).openAppSettings(),
        ),
      );
    }
  }
  return false;
}
