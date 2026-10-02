import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'community_providers.dart';
import '../domain/photo_geo_check.dart';
import 'image_upload_service.dart';

/// Ein laufender Foto-Upload. Lebt im Speicher und endet mit dem Prozess;
/// es gibt keine Queue (ADR 0001: Community ist live-only).
class UploadJob {
  const UploadJob({
    required this.id,
    required this.trailId,
    required this.phase,
    this.progress = 0,
  });

  final int id;
  final String trailId;
  final UploadPhase phase;

  /// Gesamtfortschritt 0..1 (Verarbeiten, Encodieren, Upload, Eintrag).
  final double progress;

  /// Setzt Phase und Fortschritt; der Fortschritt laeuft nie rueckwaerts.
  UploadJob withProgress(UploadPhase next, double fraction) => UploadJob(
    id: id,
    trailId: trailId,
    phase: next,
    progress: fraction.clamp(progress, 1.0).toDouble(),
  );
}

/// Ausgang eines Uploads, einmal pro Foto.
class UploadResult {
  const UploadResult.success()
    : success = true,
      message = 'Danke! Dein Bild wird geprüft und dann freigeschaltet.';
  const UploadResult.failure(this.message) : success = false;

  final bool success;
  final String message;
}

/// Haelt die laufenden Uploads, unabhaengig vom Upload-Sheet: Schliessen
/// des Sheets bricht nichts ab, mehrere Fotos duerfen parallel laufen.
/// [results] liefert pro Foto genau ein Ergebnis fuer die Snackbar.
final uploadJobsProvider = NotifierProvider<UploadJobs, List<UploadJob>>(
  UploadJobs.new,
);

class UploadJobs extends Notifier<List<UploadJob>> {
  final _results = StreamController<UploadResult>.broadcast();
  int _nextId = 0;

  /// So lange bleibt ein erfolgreicher Job bei 100 % stehen, damit der
  /// Balken sichtbar ankommt. In Tests auf [Duration.zero] setzen.
  Duration doneHold = const Duration(milliseconds: 400);

  Stream<UploadResult> get results => _results.stream;

  @override
  List<UploadJob> build() {
    ref.onDispose(_results.close);
    return const [];
  }

  /// Startet den Upload und kehrt erst nach dem Ende zurueck. Aufrufer
  /// muessen nicht warten; die UI liest [state] und [results].
  Future<void> start({
    required String trailId,
    required int? stationId,
    required String credit,
    required Uint8List bytes,
    PhotoGeoCheck geoCheck = PhotoGeoCheck.none,
  }) async {
    final uploader = ref.read(imageUploadServiceProvider);
    if (uploader == null) return;

    final id = _nextId++;
    state = [
      ...state,
      UploadJob(id: id, trailId: trailId, phase: UploadPhase.verarbeiten),
    ];

    UploadResult result;
    try {
      await uploader.upload(
        trailId: trailId,
        stationId: stationId,
        credit: credit,
        bytes: bytes,
        geoCheck: geoCheck,
        onProgress: (phase, fraction) => _setProgress(id, phase, fraction),
      );
      result = const UploadResult.success();
      _setProgress(id, UploadPhase.hochladen, 1);
      if (doneHold > Duration.zero) await Future<void>.delayed(doneHold);
    } on ImageUploadException catch (e) {
      result = UploadResult.failure(e.message);
    } catch (e) {
      result = UploadResult.failure('Unerwarteter Fehler: $e');
    }

    if (!ref.mounted) return;
    state = [
      for (final job in state)
        if (job.id != id) job,
    ];
    if (result.success) ref.invalidate(trailImagesProvider(trailId));
    _results.add(result);
  }

  void _setProgress(int id, UploadPhase phase, double fraction) {
    if (!ref.mounted) return;
    state = [
      for (final job in state)
        job.id == id ? job.withProgress(phase, fraction) : job,
    ];
  }
}
