import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/widgets/show_app_modal_sheet.dart';
import '../../trail/data/providers.dart';
import '../../trail/domain/station.dart';
import '../../trail/domain/trail.dart';
import '../data/community_providers.dart';
import '../data/image_upload_service.dart';

/// Bottom-Sheet fuer den Bild-Upload: Trail (falls nicht vorgegeben),
/// Zuordnung (ganzer Trail oder eine Station), Credit, Rechte, dann
/// Kamera oder Galerie. Drei AVIF-Groessen, Status pending.
class ImageUploadSheet extends ConsumerStatefulWidget {
  final Trail? trail;

  /// Vorausgewaehlte Station (z. B. beim Aufruf aus einer StationCard).
  final Station? initialStation;

  const ImageUploadSheet({super.key, this.trail, this.initialStation});

  static Future<void> show(
    BuildContext context, {
    Trail? trail,
    Station? initialStation,
  }) {
    return showAppModalSheet(
      context: context,
      padForKeyboard: true,
      builder: (_) =>
          ImageUploadSheet(trail: trail, initialStation: initialStation),
    );
  }

  @override
  ConsumerState<ImageUploadSheet> createState() => _ImageUploadSheetState();
}

class _ImageUploadSheetState extends ConsumerState<ImageUploadSheet> {
  late final TextEditingController _creditController;
  Trail? _trail;
  Station? _station;
  bool _rightsConfirmed = false;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _trail = widget.trail;
    _station = widget.initialStation;
    final profile = ref.read(currentProfileProvider).value;
    _creditController = TextEditingController(text: profile?.displayName ?? '');
  }

  @override
  void dispose() {
    _creditController.dispose();
    super.dispose();
  }

  bool get _canPick => _rightsConfirmed && _trail != null && !_uploading;

  Future<void> _pick(ImageSource source) async {
    final trail = _trail;
    final service = ref.read(imageUploadServiceProvider);
    if (service == null || trail == null) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      await service.pickAndUpload(
        trailId: trail.id,
        stationId: _station?.id,
        credit: _creditController.text.trim(),
        source: source,
      );
      ref.invalidate(trailImagesProvider(trail.id));
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Danke! Dein Bild wird geprüft und dann freigeschaltet.',
          ),
        ),
      );
    } on ImageUploadException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Unerwarteter Fehler: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailsAsync = ref.watch(trailsProvider);
    final stations =
        _trail?.stationen.where((s) => s.id != null).toList() ?? const [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Foto hinzufügen', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),

        if (widget.trail == null) ...[
          trailsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Trails konnten nicht geladen werden: $e',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            data: (trails) {
              final sorted = [...trails]
                ..sort((a, b) => a.name.compareTo(b.name));
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  initialValue: _trail?.id,
                  hint: const Text('Trail wählen'),
                  decoration: const InputDecoration(
                    labelText: 'Trail',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final t in sorted)
                      DropdownMenuItem<String>(
                        value: t.id,
                        child: Text(t.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: _uploading
                      ? null
                      : (id) {
                          Trail? found;
                          if (id != null) {
                            for (final t in sorted) {
                              if (t.id == id) {
                                found = t;
                                break;
                              }
                            }
                          }
                          setState(() {
                            _trail = found;
                            _station = null;
                          });
                        },
                ),
              );
            },
          ),
        ],

        if (_trail != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<Station?>(
              key: ValueKey(_trail!.id),
              initialValue: _station,
              decoration: const InputDecoration(
                labelText: 'Wozu gehört das Foto?',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<Station?>(child: Text('Ganze Strecke')),
                for (final s in stations)
                  DropdownMenuItem<Station?>(
                    value: s,
                    child: Text(
                      'Station ${s.reihenfolge}: ${s.titel}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _uploading
                  ? null
                  : (value) => setState(() => _station = value),
            ),
          ),

        TextField(
          controller: _creditController,
          enabled: !_uploading,
          decoration: const InputDecoration(
            labelText: 'Bildnachweis (z. B. dein Name)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),

        CheckboxListTile(
          value: _rightsConfirmed,
          onChanged: _uploading
              ? null
              : (v) => setState(() => _rightsConfirmed = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'Ich besitze die Rechte an diesem Bild und erlaube der App, '
            'es dauerhaft zu zeigen.',
            style: TextStyle(fontSize: 13),
          ),
        ),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),

        if (_uploading) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            'Bild wird verarbeitet und hochgeladen …',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _canPick ? () => _pick(ImageSource.camera) : null,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Kamera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _canPick ? () => _pick(ImageSource.gallery) : null,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galerie'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
