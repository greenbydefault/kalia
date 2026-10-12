import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:just_audio/just_audio.dart';

import '../../app/theme/app_colors.dart';
import '../../core/media/media_url.dart';
import '../core/admin_media_service.dart';
import '../core/collection_spec.dart';
import '../core/field_spec.dart';
import 'field_editor.dart';
import 'trail_hero_gallery.dart' show imageTypes;

const _imagePathSpec = FieldSpec(
  'image_path',
  'Bild',
  FieldKind.text,
  nullable: true,
);
const _creditSpec = FieldSpec(
  'image_credit',
  'Bildquelle / Lizenz',
  FieldKind.text,
);
const _audioPathSpec = FieldSpec(
  'audio_path',
  'Audio',
  FieldKind.text,
  nullable: true,
);
const _audioTypes = XTypeGroup(label: 'Audio', extensions: ['mp3', 'm4a']);

/// Bild und Audio einer Art. Uploads landen im Bucket `catalog-media`,
/// die Spalten halten `storage:`-Pfade (siehe [MediaUrl]).
class SpeciesMediaBlock extends StatefulWidget {
  const SpeciesMediaBlock({super.key, required this.ctx});

  final EditorContext ctx;

  @override
  State<SpeciesMediaBlock> createState() => _SpeciesMediaBlockState();
}

class _SpeciesMediaBlockState extends State<SpeciesMediaBlock> {
  late final AdminMediaService _media = AdminMediaService(widget.ctx.client);
  final _player = AudioPlayer();
  bool _busyImage = false;
  bool _busyAudio = false;
  bool _playing = false;

  String get _image => widget.ctx.row['image_path'] as String? ?? '';
  String get _audio => widget.ctx.row['audio_path'] as String? ?? '';

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((s) {
      final playing =
          s.playing && s.processingState != ProcessingState.completed;
      if (mounted && playing != _playing) setState(() => _playing = playing);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _toast(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }

  Future<void> _replace(
    FieldSpec spec,
    String? oldPath,
    String? newPath,
  ) async {
    widget.ctx.autosave.set(spec, newPath);
    await widget.ctx.autosave.flush();
    // Altes Objekt nur wegräumen, wenn der neue Pfad wirklich gespeichert ist.
    if (oldPath != newPath && !widget.ctx.autosave.hasPending) {
      await _media.removeStoragePath(oldPath);
    }
    if (mounted) setState(() {});
  }

  Future<void> _uploadImage() async {
    final file = await openFile(acceptedTypeGroups: const [imageTypes]);
    if (file == null) return;
    setState(() => _busyImage = true);
    try {
      final path = await _media.uploadSpeciesImage(
        widget.ctx.id,
        await file.readAsBytes(),
      );
      await _replace(_imagePathSpec, _image, path);
    } catch (e) {
      _toast(e);
    } finally {
      if (mounted) setState(() => _busyImage = false);
    }
  }

  Future<void> _uploadAudio() async {
    final file = await openFile(acceptedTypeGroups: const [_audioTypes]);
    if (file == null) return;
    setState(() => _busyAudio = true);
    try {
      await _player.stop();
      final ext = file.name.contains('.') ? file.name.split('.').last : 'mp3';
      final path = await _media.uploadSpeciesAudio(
        widget.ctx.id,
        await file.readAsBytes(),
        ext,
      );
      await _replace(_audioPathSpec, _audio, path);
    } catch (e) {
      _toast(e);
    } finally {
      if (mounted) setState(() => _busyAudio = false);
    }
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
      return;
    }
    final url = MediaUrl.resolve(_audio);
    if (url == null) {
      _toast('Gebündeltes Audio ($_audio) lässt sich hier nicht abspielen.');
      return;
    }
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      _toast(e);
    }
  }

  Widget _imagePreview() {
    final path = _image;
    final url = path.isEmpty ? null : MediaUrl.resolve(path);
    const size = 160.0;
    Widget box(Widget child) => ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(width: size, height: size, child: child),
    );
    if (path.isEmpty) {
      return box(
        const ColoredBox(
          color: AppColors.n100,
          child: Icon(Icons.image_outlined, color: AppColors.n400),
        ),
      );
    }
    if (url == null) {
      return box(
        ColoredBox(
          color: AppColors.n100,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Text(
                'Gebündelt:\n$path',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      );
    }
    return box(
      url.endsWith('.avif')
          ? CachedNetworkAvifImage(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.broken_image_outlined),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.broken_image_outlined),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.inkMuted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imagePreview(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _busyImage ? null : _uploadImage,
                        icon: _busyImage
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_outlined, size: 18),
                        label: Text(
                          _image.isEmpty ? 'Bild hochladen' : 'Bild ersetzen',
                        ),
                      ),
                      if (_image.isNotEmpty)
                        TextButton(
                          onPressed: _busyImage
                              ? null
                              : () => _replace(_imagePathSpec, _image, null),
                          child: const Text('Entfernen'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FieldEditor(
                    spec: _creditSpec,
                    row: widget.ctx.row,
                    onChanged: widget.ctx.autosave.set,
                  ),
                  if (_image.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(_image, style: muted, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Audio', style: theme.textTheme.labelMedium),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (_audio.isNotEmpty)
              IconButton.outlined(
                tooltip: _playing ? 'Pause' : 'Abspielen',
                onPressed: _togglePlay,
                icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
              ),
            OutlinedButton.icon(
              onPressed: _busyAudio ? null : _uploadAudio,
              icon: _busyAudio
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_outlined, size: 18),
              label: Text(
                _audio.isEmpty ? 'Audio hochladen' : 'Audio ersetzen',
              ),
            ),
            if (_audio.isNotEmpty)
              TextButton(
                onPressed: _busyAudio
                    ? null
                    : () async {
                        await _player.stop();
                        await _replace(_audioPathSpec, _audio, null);
                      },
                child: const Text('Entfernen'),
              ),
          ],
        ),
        if (_audio.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(_audio, style: muted, overflow: TextOverflow.ellipsis),
        ],
      ],
    );
  }
}
