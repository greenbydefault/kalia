import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../collections/trails_collection.dart';
import '../core/admin_repository.dart';
import '../core/collection_spec.dart';
import '../core/field_spec.dart';
import '../shell/record_editor.dart';
import 'import_dialogs.dart';
import 'import_frames.dart';
import 'import_models.dart';
import 'import_repository.dart';
import 'import_scope.dart';
import 'proposal_view.dart';
import 'source_panel.dart';

final importTrailProvider = FutureProvider.family<DbRow?, String>(
  (ref, id) => ref.watch(importRepositoryProvider).trailRow(id),
);
final importQuestionsProvider = FutureProvider.family<List<DbRow>, String>(
  (ref, id) => ref.watch(importRepositoryProvider).questions(id),
);
final importEventsProvider = FutureProvider.family<List<DbRow>, String>(
  (ref, id) => ref.watch(importRepositoryProvider).events(id),
);
final importImagesProvider = FutureProvider.family<List<DbRow>, String>(
  (ref, id) => ref.watch(importRepositoryProvider).officialImages(id),
);
final importStationsProvider = FutureProvider.family<List<DbRow>, String>(
  (ref, id) => ref.watch(importRepositoryProvider).stations(id),
);

/// Reihenfolge der Editor-Felder und -Blöcke (für „nächste Meldung“).
final List<String> _editorOrder = [
  for (final b in trailsCollection.blocks)
    if (b is FieldsBlock)
      for (final f in b.fields) f.key
    else
      ?importBlockKey(b.title),
];

class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage>
    implements ImportReviewActions {
  final _ctl = ImportEditorController();
  final _scaffold = GlobalKey<ScaffoldState>();
  final _focus = FocusNode(debugLabel: 'import-review');
  Timer? _revTimer;
  var _nIndex = -1;
  var _busy = false;

  ImportRepository get _repo => ref.read(importRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _ctl.onSaved = _onSaved;
  }

  @override
  void dispose() {
    _revTimer?.cancel();
    _ctl.dispose();
    _focus.dispose();
    super.dispose();
  }

  // -- Aktualisieren --------------------------------------------------------
  void _refresh({bool job = true, bool trail = true}) {
    final j = ref.read(importJobProvider(widget.jobId)).value;
    if (job) ref.invalidate(importJobProvider(widget.jobId));
    if (trail && j?.trailId != null) {
      ref.invalidate(importTrailProvider(j!.trailId!));
    }
    ref.invalidate(importQueueProvider);
    ref.invalidate(importJobsProvider);
  }

  void _onSaved() {
    final j = ref.read(importJobProvider(widget.jobId)).value;
    if (j?.trailId != null) ref.invalidate(importTrailProvider(j!.trailId!));
    _scheduleRevalidate();
  }

  void _scheduleRevalidate() {
    _revTimer?.cancel();
    _revTimer = Timer(const Duration(milliseconds: 1800), _revalidate);
  }

  Future<void> _revalidate({bool toast = false}) async {
    _revTimer?.cancel();
    final j = ref.read(importJobProvider(widget.jobId)).value;
    if (j == null ||
        (j.status != ImportStatus.bereit &&
            j.status != ImportStatus.wartetAufKlaerung)) {
      return;
    }
    try {
      await _ctl.flush?.call();
      await _repo.revalidate(widget.jobId);
      _refresh();
      if (toast) _toast('Wird neu geprüft …');
    } catch (e) {
      _toast('Neuprüfung fehlgeschlagen: $e');
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<T?> _guard<T>(Future<T> Function() f) async {
    try {
      return await f();
    } catch (e) {
      _toast('Fehlgeschlagen: $e');
      return null;
    }
  }

  // -- Navigation ----------------------------------------------------------------
  Future<void> _goNeighbor(int dir) async {
    final q = await ref.read(importQueueProvider.future);
    if (!mounted) return;
    if (q.isEmpty) {
      context.go('/import');
      return;
    }
    final i = q.indexOf(widget.jobId);
    final n = i < 0 ? 0 : (i + dir) % q.length;
    final next = q[n < 0 ? n + q.length : n];
    if (next == widget.jobId) {
      context.go('/import');
    } else {
      context.go('/import/$next');
    }
  }

  void _nextMessage(ImportJob job) {
    final open = <String>{
      for (final e in job.report)
        if (e.isOpen) e.anzeigeKey,
    };
    final keys = [
      for (final k in _editorOrder)
        if (open.contains(k) && _ctl.contextFor(k) != null) k,
    ];
    if (keys.isEmpty) return;
    _nIndex = (_nIndex + 1) % keys.length;
    Scrollable.ensureVisible(
      _ctl.contextFor(keys[_nIndex])!,
      alignment: 0.1,
      duration: const Duration(milliseconds: 250),
    );
  }

  // -- Kopf-Aktionen --------------------------------------------------------------
  Future<void> _publish(ImportJob job) async {
    setState(() => _busy = true);
    try {
      await _ctl.flush?.call();
      _revTimer?.cancel();
      final res = await _repo.publish(job.id);
      _refresh();
      if (!mounted) return;
      final next = res['next_job_id'] as String?;
      final messenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 10),
            content: Text('„${job.title}“ ist jetzt sichtbar.'),
            action: SnackBarAction(
              label: 'Rückgängig',
              onPressed: () async {
                try {
                  await _repo.unpublish(job.id);
                  ref.invalidate(importJobsProvider);
                  ref.invalidate(importQueueProvider);
                  ref.invalidate(importJobProvider(job.id));
                  router.go('/import/${job.id}');
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Rückgängig fehlgeschlagen: $e')),
                  );
                }
              },
            ),
          ),
        );
      router.go(next == null ? '/import' : '/import/$next');
    } catch (e) {
      _toast(_publishError('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _publishError(String e) {
    if (e.contains('import_blocked_hart')) {
      return 'Es gibt noch harte Fehler. Erst beheben.';
    }
    if (e.contains('import_blocked_uebersteuerbar')) {
      return 'Es gibt noch Meldungen, die du beheben oder übersteuern musst.';
    }
    return 'Anlegen fehlgeschlagen: $e';
  }

  Future<void> _discard(ImportJob job) async {
    final grund = await askText(
      context,
      title: 'Pfad verwerfen?',
      message: 'Der Entwurf bleibt unsichtbar, die Kandidatenliste vermerkt den Grund.',
      hint: 'Grund (Pflicht)',
      confirm: 'Verwerfen',
    );
    if (grund == null) return;
    await _guard(() => _repo.discard(job.id, grund));
    if (!mounted) return;
    _refresh();
    await _goNeighbor(1);
  }

  Future<void> _askGeneral() async {
    final j = ref.read(importJobProvider(widget.jobId)).value;
    if (j == null) return;
    final q = await askQuestion(context, feldLabel: 'ganzer Pfad');
    if (q == null) return;
    await _guard(
      () => _repo.ask(j.id, field: null, frage: q.frage, adressat: q.adressat),
    );
    _refresh();
    if (j.trailId != null) ref.invalidate(importQuestionsProvider(j.trailId!));
  }

  Future<void> _unpublish(ImportJob job) async {
    await _guard(() => _repo.unpublish(job.id));
    _refresh();
    _toast('Pfad ist wieder unsichtbar.');
  }

  // -- ImportReviewActions ------------------------------------------------------------
  ImportJob? get _job => ref.read(importJobProvider(widget.jobId)).value;

  @override
  Future<void> applyFix(ReportEntry e) async {
    final v = e.vorschlag;
    if (v is! String || v.isEmpty) return;
    final job = _job;
    if (e.baseFeld == 'stationen' && e.index != null && job?.trailId != null) {
      await _repo.updateStationText(job!.trailId!, e.index!, v);
      _ctl.refreshBlocks();
      _scheduleRevalidate();
      return;
    }
    if (_ctl.applyValue == null) return;
    _ctl.applyValue!(e.baseFeld, v);
  }

  @override
  Future<void> overrideEntry(ReportEntry e) async {
    final job = _job;
    if (job == null) return;
    final grund = await askText(
      context,
      title: 'Bewusst durchlassen?',
      message: 'Die Meldung zählt dann nicht mehr als Blocker. Der Grund wird protokolliert.',
      hint: 'Begründung (Pflicht)',
      confirm: 'Übersteuern',
      minLines: 2,
    );
    if (grund == null) return;
    await _repo.override(job.id, e, grund);
    _refresh(trail: false);
  }

  @override
  Future<void> ack(ReportEntry e) async {
    final job = _job;
    if (job == null) return;
    await _repo.ack(job.id, e);
    _refresh(trail: false);
  }

  @override
  Future<void> ask(ReportEntry e) async {
    final job = _job;
    if (job == null) return;
    final messages = ref.read(importMessagesProvider).value;
    final q = await askQuestion(
      context,
      feldLabel: messages?.feldLabel(e.feld) ?? e.feld,
    );
    if (q == null) return;
    await _repo.ask(job.id, field: e.feld, frage: q.frage, adressat: q.adressat);
    _refresh(trail: false);
    if (job.trailId != null) {
      ref.invalidate(importQuestionsProvider(job.trailId!));
    }
  }

  @override
  Future<void> resolveSpecies(ReportEntry e) async {
    final job = _job;
    if (job?.trailId == null) return;
    final trailId = job!.trailId!;
    final name = '${e.wert ?? e.params['name'] ?? ''}';
    final sugg = await _repo.speciesSuggestions(trailId);
    final match = sugg.where((s) => s['name_de'] == name).toList();
    if (!mounted) return;
    final res = await speciesDialog(
      context,
      repo: _repo,
      trailId: trailId,
      name: name,
      latGuess: '${e.vorschlag ?? e.params['lat'] ?? ''}',
      suggestion: match.isEmpty ? null : match.first,
    );
    if (res == null) return;
    _ctl.refreshBlocks();
    await _revalidate();
  }

  @override
  Future<void> resolveDuplicate(ReportEntry e) async {
    final job = _job;
    if (job?.trailId == null) return;
    final altId = '${e.params['id'] ?? e.wert ?? ''}';
    final neu = await _repo.trailRow(job!.trailId!);
    final alt = altId.isEmpty ? null : await _repo.trailRow(altId);
    if (!mounted || neu == null) return;
    final res = await duplicateDialog(context, neu: neu, alt: alt, altId: altId);
    if (res == null) return;
    switch (res) {
      case DuplicateAction.istNeu:
        await ack(e);
      case DuplicateAction.zusammenfuehren:
        await _repo.discard(job.id, 'Zusammengeführt mit $altId');
        _refresh();
        if (mounted) context.go('/trails/${Uri.encodeComponent(altId)}');
      case DuplicateAction.verwerfen:
        await _repo.discard(job.id, 'Duplikat von $altId');
        _refresh();
        await _goNeighbor(1);
    }
  }

  @override
  Future<void> addStation() async {
    final job = _job;
    if (job?.trailId == null) return;
    final trailId = job!.trailId!;
    final trail = await _repo.trailRow(trailId);
    final stations = await _repo.stations(trailId);
    if (!mounted || trail == null) return;
    final route = _routePoints(trail);
    final sLat = (trail['start_lat'] as num?)?.toDouble();
    final sLon = (trail['start_lon'] as num?)?.toDouble();
    final center = sLat != null && sLon != null
        ? LatLng(sLat, sLon)
        : (route.isNotEmpty ? route.first : const LatLng(53.114, 13.02));
    final next =
        stations.fold<int>(
          0,
          (m, s) => ((s['reihenfolge'] as num?)?.toInt() ?? 0) > m
              ? (s['reihenfolge'] as num).toInt()
              : m,
        ) +
        1;
    final row = await stationDialog(
      context,
      route: route,
      center: center,
      reihenfolge: next,
    );
    if (row == null) return;
    await _repo.addStation(trailId, row);
    ref.invalidate(importStationsProvider(trailId));
    _ctl.refreshBlocks();
    await _revalidate();
  }

  List<LatLng> _routePoints(DbRow trail) {
    final raw = (trail['area'] is List && (trail['area'] as List).isNotEmpty)
        ? trail['area']
        : trail['route'];
    if (raw is! List) return const [];
    return [
      for (final p in raw)
        if (p is List && p.length >= 2 && p[0] is num && p[1] is num)
          LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()),
    ];
  }

  void _setStart(LatLng p) {
    double r(double v) => (v * 1e6).roundToDouble() / 1e6;
    _ctl.applyValue?.call('start_lat', r(p.latitude));
    _ctl.applyValue?.call('start_lon', r(p.longitude));
    _toast('Start gesetzt.');
  }

  // -- Tastatur ------------------------------------------------------------------------------
  KeyEventResult _onKey(FocusNode _, KeyEvent ev, ImportJob? job) {
    if (ev is! KeyDownEvent || job == null) return KeyEventResult.ignored;
    final k = ev.logicalKey;
    final mod =
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;
    if (mod && (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter)) {
      if (job.canPublish && !_busy) unawaited(_publish(job));
      return KeyEventResult.handled;
    }
    if (mod || HardwareKeyboard.instance.isAltPressed) {
      return KeyEventResult.ignored;
    }
    // Einzeltasten nie beim Tippen abfangen.
    final inText =
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<EditableText>() !=
        null;
    if (inText) return KeyEventResult.ignored;
    if (k == LogicalKeyboardKey.keyJ) {
      unawaited(_goNeighbor(1));
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.keyK) {
      unawaited(_goNeighbor(-1));
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.keyN) {
      _nextMessage(job);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // -- Build ---------------------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(importJobProvider(widget.jobId));
    final messagesAsync = ref.watch(importMessagesProvider);
    final job = async.hasValue ? async.requireValue : null;
    final messages = messagesAsync.hasValue ? messagesAsync.requireValue : null;
    if (job == null || messages == null) {
      if (async.hasError || messagesAsync.hasError) {
        return Center(child: Text('Fehler: ${async.error ?? messagesAsync.error}'));
      }
      return const Center(child: CircularProgressIndicator());
    }
    final trailId = job.trailId;
    final trail = trailId == null
        ? null
        : ref.watch(importTrailProvider(trailId)).value;
    final questions = trailId == null
        ? const <DbRow>[]
        : (ref.watch(importQuestionsProvider(trailId)).value ?? const []);
    final openQuestions = questions.where((q) => q['status'] == 'offen').toList();

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: (n, e) => _onKey(n, e, job),
      child: Scaffold(
        key: _scaffold,
        backgroundColor: AppColors.paper,
        endDrawer: Drawer(
          width: 420,
          child: _HistoryDrawer(trailId: trailId, questions: questions),
        ),
        body: Column(
          children: [
            _Header(
              job: job,
              trail: trail,
              busy: _busy,
              openQuestions: openQuestions.length,
              onBack: () => context.go('/import'),
              onLater: () => _goNeighbor(1),
              onAsk: _askGeneral,
              onDiscard: () => _discard(job),
              onRevalidate: () => _revalidate(toast: true),
              onHistory: () => _scaffold.currentState?.openEndDrawer(),
              onPublish: () => _publish(job),
              onUnpublish: () => _unpublish(job),
            ),
            const Divider(height: 1, color: AppColors.n200),
            Expanded(child: _body(job, trail, messages, openQuestions)),
          ],
        ),
      ),
    );
  }

  Widget _body(
    ImportJob job,
    DbRow? trail,
    ImportMessages messages,
    List<DbRow> openQuestions,
  ) {
    switch (job.status) {
      case ImportStatus.fehlgeschlagen:
        return _ErrorView(
          job: job,
          onRetry: () async {
            await _guard(() => _repo.retry(job.id));
            _refresh();
          },
          onReplace: () => _replaceFile(job),
          onDiscard: () => _discard(job),
        );
      case ImportStatus.vorschlag:
        return ProposalView(
          key: ValueKey('proposal-${job.id}-${job.updatedAt}'),
          job: job,
          messages: messages,
          onApply: (teile) async {
            await _repo.applyProposal(job.id, teile);
            _refresh();
            _toast('Wird angewendet …');
          },
          onReject: () async {
            await _repo.rejectProposal(job.id);
            _refresh();
            await _goNeighbor(1);
          },
        );
      case ImportStatus.verworfen:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Dieser Import wurde verworfen.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/import'),
                child: const Text('Zur Übersicht'),
              ),
              if (job.trailId != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go(
                    '/trails/${Uri.encodeComponent(job.trailId!)}',
                  ),
                  child: const Text('Pfad im Katalog öffnen'),
                ),
              ],
            ],
          ),
        );
      default:
        break;
    }
    if (job.trailId == null || trail == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              job.pruefend
                  ? 'Dossier wird geprüft (Versuch ${job.attempts + 1}) …'
                  : 'Entwurf wird geladen …',
            ),
          ],
        ),
      );
    }
    return _SplitReview(
      job: job,
      trail: trail,
      messages: messages,
      ctl: _ctl,
      actions: this,
      openQuestions: openQuestions,
      onSetStart: _setStart,
      onQuestion: _answerQuestion,
    );
  }

  Future<void> _answerQuestion(DbRow q, {required bool answer}) async {
    String? text;
    if (answer) {
      text = await askText(
        context,
        title: 'Antwort',
        message: '${q['frage']}',
        hint: 'Antwort',
        confirm: 'Speichern',
        minLines: 2,
      );
      if (text == null) return;
    }
    await _guard(
      () => _repo.setQuestion(
        (q['id'] as num).toInt(),
        answer ? 'beantwortet' : 'erledigt',
        antwort: text,
      ),
    );
    final job = _job;
    if (job?.trailId != null) {
      ref.invalidate(importQuestionsProvider(job!.trailId!));
    }
    _refresh(trail: false);
  }

  Future<void> _replaceFile(ImportJob job) async {
    final f = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Dossier (ZIP)', extensions: ['zip']),
      ],
    );
    if (f == null) return;
    final bytes = await f.readAsBytes();
    await _guard(
      () => _repo.replaceUpload(job.id, name: f.name, bytes: bytes),
    );
    _refresh();
  }
}

// ---------------------------------------------------------------------------
// Kopf
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.job,
    required this.trail,
    required this.busy,
    required this.openQuestions,
    required this.onBack,
    required this.onLater,
    required this.onAsk,
    required this.onDiscard,
    required this.onRevalidate,
    required this.onHistory,
    required this.onPublish,
    required this.onUnpublish,
  });

  final ImportJob job;
  final DbRow? trail;
  final bool busy;
  final int openQuestions;
  final VoidCallback onBack;
  final VoidCallback onLater;
  final VoidCallback onAsk;
  final VoidCallback onDiscard;
  final VoidCallback onRevalidate;
  final VoidCallback onHistory;
  final VoidCallback onPublish;
  final VoidCallback onUnpublish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = job.blockers;
    final w = warningCount(job.report);
    final name = (trail?['name'] as String?) ?? job.title;
    final proposal = job.status == ImportStatus.vorschlag;
    final String? why = job.canPublish && openQuestions == 0 && !busy
        ? null
        : job.pruefend
        ? 'Wird gerade geprüft'
        : b.any
        ? '${b.total} Blocker offen'
        : openQuestions > 0
        ? 'Offene Frage'
        : 'Nicht anlegbar im Status „${job.status.label}“';
    return Material(
      color: AppColors.n50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: 'Zur Übersicht',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    job.status.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (job.pruefend)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (!proposal && job.status != ImportStatus.fehlgeschlagen) ...[
              _Count(
                icon: Icons.error_outline,
                color: AppColors.statusError,
                n: b.hart,
                label: 'hart',
              ),
              _Count(
                icon: Icons.report_gmailerrorred_outlined,
                color: AppColors.statusError,
                n: b.uebersteuerbar,
                label: 'zu klären',
              ),
              _Count(
                icon: Icons.warning_amber_rounded,
                color: AppColors.statusWarn,
                n: w,
                label: 'Warnungen',
              ),
            ],
            const SizedBox(width: 8),
            if (!proposal && job.status != ImportStatus.fehlgeschlagen) ...[
              TextButton(onPressed: onLater, child: const Text('Später')),
              TextButton(onPressed: onAsk, child: const Text('Klären')),
              TextButton(onPressed: onDiscard, child: const Text('Verwerfen')),
              IconButton(
                tooltip: 'Neu prüfen',
                onPressed: job.pruefend ? null : onRevalidate,
                icon: const Icon(Icons.refresh),
              ),
            ],
            IconButton(
              tooltip: 'Verlauf und Fragen',
              onPressed: onHistory,
              icon: const Icon(Icons.history),
            ),
            if (job.status == ImportStatus.angelegt)
              OutlinedButton(
                onPressed: onUnpublish,
                child: const Text('Unsichtbar schalten'),
              ),
            if (!proposal &&
                job.status != ImportStatus.angelegt &&
                job.status != ImportStatus.fehlgeschlagen &&
                job.status != ImportStatus.verworfen)
              Tooltip(
                message: why ?? 'Cmd/Strg + Enter',
                child: FilledButton.icon(
                  onPressed: why == null ? onPublish : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Anlegen'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({
    required this.icon,
    required this.color,
    required this.n,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final int n;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = n == 0 ? AppColors.n400 : color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 4),
        Text(
          '$n $label',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: n == 0 ? AppColors.inkMuted : c,
            fontWeight: n == 0 ? null : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Split-Screen
// ---------------------------------------------------------------------------

class _SplitReview extends ConsumerWidget {
  const _SplitReview({
    required this.job,
    required this.trail,
    required this.messages,
    required this.ctl,
    required this.actions,
    required this.openQuestions,
    required this.onSetStart,
    required this.onQuestion,
  });

  final ImportJob job;
  final DbRow trail;
  final ImportMessages messages;
  final ImportEditorController ctl;
  final ImportReviewActions actions;
  final List<DbRow> openQuestions;
  final void Function(LatLng) onSetStart;
  final Future<void> Function(DbRow q, {required bool answer}) onQuestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trailId = job.trailId!;
    final images = ref.watch(importImagesProvider(trailId)).value ?? const [];
    final stations = ref.watch(importStationsProvider(trailId)).value ?? const [];
    final states = FieldStates(
      report: job.report,
      locked: {for (final k in (trail['locked_fields'] as List? ?? const [])) '$k'},
      fieldMeta: Map<String, dynamic>.from((trail['field_meta'] as Map?) ?? {}),
      row: trail,
    );
    final data = ImportScopeData(
      job: job,
      messages: messages,
      states: states,
      controller: ctl,
      actions: actions,
    );
    final shown = {..._editorOrder};
    final orphans = [
      for (final e in job.report)
        if (e.isOpen && !shown.contains(e.anzeigeKey)) e,
    ];

    final editor = ImportScope(
      data: data,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (job.pruefend)
            const LinearProgressIndicator(minHeight: 2),
          for (final q in openQuestions)
            _QuestionBanner(q: q, onQuestion: onQuestion),
          if (orphans.isNotEmpty)
            _OrphanPanel(entries: orphans, data: data),
          Expanded(
            child: RecordEditor(spec: trailsCollection, id: trailId),
          ),
        ],
      ),
    );

    final source = SourcePanel(
      job: job,
      trail: trail,
      images: images,
      stations: stations,
      onSetStart: onSetStart,
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 1000) {
          return Row(
            children: [
              Expanded(flex: 5, child: source),
              const VerticalDivider(width: 1, color: AppColors.n200),
              Expanded(flex: 6, child: editor),
            ],
          );
        }
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [Tab(text: 'Editor'), Tab(text: 'Quelle')],
              ),
              Expanded(
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [editor, source],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrphanPanel extends StatelessWidget {
  const _OrphanPanel({required this.entries, required this.data});

  final List<ReportEntry> entries;
  final ImportScopeData data;

  @override
  Widget build(BuildContext context) {
    final sorted = [...entries]
      ..sort((a, b) => a.severity.index.compareTo(b.severity.index));
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      color: AppColors.n100,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        children: [
          Text(
            'Weitere Meldungen (${sorted.length})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          for (final e in sorted)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EntryTile(entry: e, data: data, showField: true),
            ),
        ],
      ),
    );
  }
}

class _QuestionBanner extends StatelessWidget {
  const _QuestionBanner({required this.q, required this.onQuestion});

  final DbRow q;
  final Future<void> Function(DbRow q, {required bool answer}) onQuestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.statusInfo.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.help_outline, size: 18, color: AppColors.statusInfo),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offene Frage (${q['adressat']}): ${q['frage']}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => onQuestion(q, answer: true),
            child: const Text('Antwort'),
          ),
          TextButton(
            onPressed: () => onQuestion(q, answer: false),
            child: const Text('Erledigt'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fehler
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.job,
    required this.onRetry,
    required this.onReplace,
    required this.onDiscard,
  });

  final ImportJob job;
  final VoidCallback onRetry;
  final VoidCallback onReplace;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.statusError),
                const SizedBox(width: 8),
                Text('Import fehlgeschlagen', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            Text(job.error ?? 'Der Import ist fehlgeschlagen.'),
            const SizedBox(height: 4),
            Text(
              'Datei: ${job.fileName} · Versuche: ${job.attempts}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
            if ((job.errorDetail ?? '').isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Technische Details'),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      job.errorDetail!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Neu starten'),
                ),
                OutlinedButton(
                  onPressed: onReplace,
                  child: const Text('Datei ersetzen'),
                ),
                TextButton(
                  onPressed: onDiscard,
                  child: const Text('Verwerfen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Verlauf
// ---------------------------------------------------------------------------

class _HistoryDrawer extends ConsumerWidget {
  const _HistoryDrawer({required this.trailId, required this.questions});

  final String? trailId;
  final List<DbRow> questions;

  static const _labels = {
    'import': 'Import gestartet',
    'aenderung': 'Geändert',
    'uebersteuert': 'Übersteuert',
    'frage': 'Frage gestellt',
    'antwort': 'Frage beantwortet',
    'angelegt': 'Angelegt',
    'rueckgaengig': 'Rückgängig',
    'verworfen': 'Verworfen',
    'vorschlag': 'Änderungsvorschlag',
    'vorschlag_angenommen': 'Vorschlag angenommen',
    'vorschlag_abgelehnt': 'Vorschlag abgelehnt',
    'keine_aenderung': 'Keine Änderung',
    'neu_gestartet': 'Neu gestartet',
    'datei_ersetzt': 'Datei ersetzt',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final events = trailId == null
        ? const <DbRow>[]
        : (ref.watch(importEventsProvider(trailId!)).value ?? const []);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Fragen', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (questions.isEmpty) const Text('Keine Fragen.'),
          for (final q in questions)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${q['frage']}'),
              subtitle: Text(
                '${q['adressat']} · ${q['status']}'
                '${q['antwort'] == null ? '' : '\nAntwort: ${q['antwort']}'}',
              ),
            ),
          const Divider(),
          Text('Verlauf', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (events.isEmpty) const Text('Noch nichts protokolliert.'),
          for (final e in events)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${_labels[e['typ']] ?? e['typ']}'
                '${e['feld'] == null ? '' : ' · ${e['feld']}'}',
              ),
              subtitle: Text(
                '${e['created_at']}'.replaceFirst('T', ' ').split('.').first,
              ),
            ),
        ],
      ),
    );
  }
}
