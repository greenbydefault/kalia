import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../auth/presentation/account_prompt_sheet.dart';
import '../../trail/domain/trail.dart';
import '../../trail_progress/tracking/location_service.dart';
import '../data/point_measurer.dart';
import '../data/report_providers.dart';
import '../data/report_uploader.dart';
import '../domain/report_enums.dart';
import '../domain/report_models.dart';
import '../logic/averaging.dart';
import '../logic/geo.dart';
import '../logic/signal.dart';
import '../report_copy.dart';
import 'marker_sheet.dart';
import 'report_widgets.dart';
import 'sent_screen.dart';

/// Kürzester Abstand eines Punkts zum Pfad (Stützpunkte genügen, die Routen
/// sind dicht gesampelt).
double distanceToTrailM(Trail trail, double lat, double lng) {
  var best = double.infinity;
  final pts = [...trail.mapPoints, ?trail.startOrNull];
  for (final p in pts) {
    final d = distanceM(lat, lng, p.latitude, p.longitude);
    if (d < best) best = d;
  }
  return best;
}

String kmShort(double m) => (m / 1000).toStringAsFixed(1).replaceAll('.', ',');

/// Gemeinsamer Zustand der Schnellmeldungen: Entwurfs-ID, Punkt-ID, Live-Fix,
/// Messung und Foto.
mixin QuickFlowState<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final String draftId = newReportId();
  final String pointId = newReportId();

  LocationFix? fix;
  Averaged? measured;
  int attempts = 0;
  bool measuring = false;
  double progress = 0;
  bool sending = false;
  bool submitted = false;
  int photoCount = 0;

  StreamSubscription<LocationFix>? _quickSub;
  Timer? _quickTick;
  DateTime _lastFixAt = DateTime.now();
  double sinceFix = 0;

  void startWatching() {
    _quickSub = ref
        .read(locationServiceProvider)
        .watchFixes(LocationProfile.pointFix)
        .listen((f) {
          if (!mounted) return;
          setState(() {
            fix = f;
            _lastFixAt = DateTime.now();
          });
        }, onError: (_) {});
    _quickTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        sinceFix = DateTime.now().difference(_lastFixAt).inMilliseconds / 1000;
      });
    });
  }

  void stopWatching() {
    _quickSub?.cancel();
    _quickTick?.cancel();
    if (!submitted) {
      // Fotos eines abgebrochenen Beitrags nicht liegen lassen.
      unawaited(ref.read(reportDraftStoreProvider).deleteDraft(draftId));
    }
  }

  SignalLevel get level =>
      signalLevel(accuracyM: fix?.accuracyM, secondsSinceFix: sinceFix);

  bool get hasGoodEnoughSignal => signalAllowsQuick(fix?.accuracyM);

  /// Misst über 3 bis 8 s. Liefert `null` ohne Fix.
  Future<Averaged?> measure() async {
    setState(() {
      measuring = true;
      progress = 0;
    });
    final avg = await measurePoint(
      ref.read(locationServiceProvider),
      onProgress: (p) {
        if (mounted) setState(() => progress = p);
      },
    );
    if (!mounted) return null;
    setState(() {
      measuring = false;
      measured = avg;
      if (avg != null) attempts++;
    });
    if (avg == null) showReportSnack(context, rt('report.rec.no_fix'));
    return avg;
  }

  Future<void> addPhoto() async {
    final ok = await capturePointPhoto(
      context,
      ref,
      draftId: draftId,
      pointId: pointId,
    );
    if (ok && mounted) setState(() => photoCount++);
  }

  /// Entwurf und Punkt ablegen, Konto abfragen, in die Warteschlange und
  /// weiter zu R6.
  Future<void> submitQuick({
    required QuickIntent intent,
    required Trail trail,
    required DraftPoint point,
    String? note,
  }) async {
    if (sending) return;
    setState(() => sending = true);
    final store = ref.read(reportDraftStoreProvider);
    final now = DateTime.now();
    final draft = ReportDraft(
      id: draftId,
      kind: ReportKind.quick,
      mode: RecordingMode.pointsOnly,
      status: DraftStatus.review,
      createdAt: now,
      updatedAt: now,
      targetTrailId: trail.id,
      targetTrailName: trail.name,
      intent: intent,
      note: note,
    );
    await store.saveDraft(draft);
    await store.savePoint(point);
    if (!mounted) return;
    final signedIn = await requireAccount(
      context,
      reason: rt('report.account.body'),
    );
    if (!mounted) return;
    submitted = true;
    final result = await ref.read(reportUploaderProvider).submit(draft);
    if (!mounted) return;
    if (!signedIn) showReportSnack(context, rt('report.account.saved'));
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SentScreen(
          draftId: result.id,
          awaitingAccount: result.status == DraftStatus.awaitingAccount,
        ),
      ),
    );
  }

  DraftPoint buildPoint({
    required PointType type,
    required Averaged avg,
    String? targetPointId,
    String? title,
    String? note,
    HintKind? hintKind,
    double? oldLat,
    double? oldLng,
    required bool lowAccuracy,
  }) {
    return DraftPoint(
      id: pointId,
      draftId: draftId,
      type: type,
      seq: 0,
      lat: avg.lat,
      lng: avg.lng,
      accuracyM: avg.accuracyM,
      fixCount: avg.fixCount,
      lowAccuracy: lowAccuracy,
      recordedOn: DateTime.now(),
      targetPointId: targetPointId,
      title: title,
      note: note,
      hintKind: hintKind,
      oldLat: oldLat,
      oldLng: oldLng,
    );
  }
}

/// Fläche für Messung, Signal und Hinweise der Schnellmeldungen.
class QuickBody extends StatelessWidget {
  const QuickBody({super.key, required this.children, this.bottom});

  final List<Widget> children;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.page),
              children: children,
            ),
          ),
          if (bottom != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                AppSpacing.x4,
              ),
              child: bottom,
            ),
        ],
      ),
    );
  }
}

/// Foto-Zeile „(optional)“ mit Zähler.
class QuickPhotoRow extends StatelessWidget {
  const QuickPhotoRow({
    super.key,
    required this.label,
    required this.count,
    required this.onAdd,
  });

  final String label;
  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.photo_camera_outlined),
        label: Text(count == 0 ? label : '$label ($count)'),
      ),
    );
  }
}
