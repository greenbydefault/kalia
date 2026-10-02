import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/images/exif_gps.dart';
import '../../../shared/widgets/show_app_modal_sheet.dart';
import '../../trail/data/providers.dart';
import '../../trail/domain/station.dart';
import '../../trail/domain/trail.dart';
import '../data/community_providers.dart';
import '../data/image_upload_service.dart';
import '../data/upload_jobs.dart';
import '../domain/photo_geo_check.dart';

/// Bottom-Sheet fuer den Bild-Upload: Trail (falls nicht vorgegeben),
/// Zuordnung (ganzer Trail oder eine Station), Credit, Rechte, dann
/// Kamera oder Galerie. Das Sheet bleibt nach jedem Foto offen; der
/// Upload selbst laeuft als [UploadJobs]-Job und ueberlebt das Schliessen.
class ImageUploadSheet extends ConsumerStatefulWidget {
  final Trail? trail;

  /// Vorausgewaehlte Station (z. B. beim Aufruf aus einer StationCard).
  final Station? initialStation;

  /// Foto-Quelle, in Tests austauschbar.
  final ImagePicker? picker;

  const ImageUploadSheet({
    super.key,
    this.trail,
    this.initialStation,
    this.picker,
  });

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
  bool _picking = false;
  String? _error;
  UploadResult? _lastResult;
  StreamSubscription<UploadResult>? _resultSub;
  late final ImagePicker _picker = widget.picker ?? ImagePicker();

  @override
  void initState() {
    super.initState();
    _trail = widget.trail;
    _station = widget.initialStation;
    final profile = ref.read(currentProfileProvider).value;
    _creditController = TextEditingController(text: profile?.displayName ?? '');
    // Das Sheet deckt die Shell-Snackbar ab; das Ergebnis erscheint
    // deshalb zusaetzlich inline, solange das Sheet offen ist.
    _resultSub = ref
        .read(uploadJobsProvider.notifier)
        .results
        .listen((r) => setState(() => _lastResult = r));
  }

  @override
  void dispose() {
    _resultSub?.cancel();
    _creditController.dispose();
    super.dispose();
  }

  bool get _canPick => _rightsConfirmed && _trail != null && !_picking;

  /// Erst Picker, dann Job. Abbruch im Picker laesst das Sheet stehen.
  /// Der Job startet auch, wenn das Sheet waehrenddessen geschlossen wurde.
  Future<void> _pick(ImageSource source) async {
    final trail = _trail;
    if (trail == null) return;
    final jobs = ref.read(uploadJobsProvider.notifier);
    final stationId = _station?.id;
    final credit = _creditController.text.trim();
    setState(() {
      _picking = true;
      _error = null;
      _lastResult = null;
    });

    final Uint8List bytes;
    try {
      // imageQuality < 100 zwingt iOS zu JPEG- statt HEIF-Ausgabe,
      // damit das Dekodieren garantiert klappt.
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 95,
      );
      if (picked == null) {
        if (mounted) setState(() => _picking = false);
        return;
      }
      bytes = await picked.readAsBytes();
    } catch (e) {
      if (mounted) {
        setState(() {
          _picking = false;
          _error = 'Foto konnte nicht geladen werden: $e';
        });
      }
      return;
    }

    if (mounted) setState(() => _picking = false);
    // Der EXIF-Ort bleibt lokal: er wird hier gegen den Trail verdichtet
    // und danach verworfen. Nur die Ampel geht in den Upload.
    final geoCheck = PhotoGeoCheck.evaluate(trail, readExifGps(bytes));
    unawaited(
      jobs.start(
        trailId: trail.id,
        stationId: stationId,
        credit: credit,
        bytes: bytes,
        geoCheck: geoCheck,
      ),
    );
  }

  static String _jobLabel(UploadJob job) {
    final text = switch (job.phase) {
      UploadPhase.verarbeiten => 'Foto wird verarbeitet …',
      UploadPhase.hochladen => 'Foto wird hochgeladen …',
    };
    return '$text ${(job.progress * 100).round()} %';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailsAsync = ref.watch(trailsProvider);
    final jobs = ref.watch(uploadJobsProvider);
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
                  onChanged: (id) {
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
              onChanged: (value) => setState(() => _station = value),
            ),
          ),

        TextField(
          controller: _creditController,
          decoration: const InputDecoration(
            labelText: 'Bildnachweis (z. B. dein Name)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),

        CheckboxListTile(
          value: _rightsConfirmed,
          onChanged: (v) => setState(() => _rightsConfirmed = v ?? false),
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

        if (_lastResult case final result?)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              result.message,
              style: TextStyle(
                color: result.success
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
            ),
          ),

        for (final job in jobs)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: job.progress),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (_, value, _) =>
                      LinearProgressIndicator(value: value),
                ),
                const SizedBox(height: 4),
                Text(
                  _jobLabel(job),
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

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
