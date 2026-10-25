import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import 'docx_zip.dart';
import 'import_models.dart';
import 'import_repository.dart';

/// Übersicht: Dropzone, Zähler, Listen nach Status, Batch-Auswertung.
class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  var _tab = ImportTab.imImport;
  var _query = '';

  ImportRepository get _repo => ref.read(importRepositoryProvider);

  void _toast(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _retry(ImportJob j) async {
    try {
      await _repo.retry(j.id);
      ref.invalidate(importJobsProvider);
    } catch (e) {
      _toast('Fehlgeschlagen: $e');
    }
  }

  Future<void> _retryAll(List<ImportJob> jobs) async {
    for (final j in jobs) {
      try {
        await _repo.retry(j.id);
      } catch (_) {}
    }
    ref.invalidate(importJobsProvider);
    _toast('${jobs.length} Jobs neu gestartet.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(importJobsProvider);
    final messages = ref.watch(importMessagesProvider).value;
    final jobs = async.hasValue ? async.requireValue : const <ImportJob>[];
    if (async.hasError && !async.hasValue) {
      return Center(child: Text('Fehler: ${async.error}'));
    }
    final counts = {
      for (final t in ImportTab.values)
        t: jobs.where((j) => t.accepts(j.status)).length,
    };
    final batches = <String, int>{};
    for (final j in jobs) {
      if (j.batchId != null) {
        batches[j.batchId!] = (batches[j.batchId!] ?? 0) + 1;
      }
    }
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final j in jobs)
        if (_tab.accepts(j.status) &&
            (q.isEmpty ||
                j.fileName.toLowerCase().contains(q) ||
                (j.trailId ?? '').toLowerCase().contains(q)))
          j,
    ];
    final reviewable = jobs
        .where(
          (j) =>
              j.status == ImportStatus.bereit ||
              j.status == ImportStatus.wartetAufKlaerung,
        )
        .toList()
        .reversed
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 64),
      children: [
        Row(
          children: [
            Text('Import', style: theme.textTheme.headlineSmall),
            const Spacer(),
            if (reviewable.isNotEmpty)
              FilledButton.icon(
                onPressed: () => context.go('/import/${reviewable.first.id}'),
                icon: const Icon(Icons.play_arrow),
                label: Text('Nächsten prüfen (${reviewable.length})'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Dossier als .docx oder .zip hochladen. Der Worker prüft sie, danach landen sie hier zur Durchsicht. '
          'Angelegt wird erst nach deinem Klick.',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
        ),
        const SizedBox(height: 20),
        _Dropzone(
          repo: _repo,
          onUploaded: () => ref.invalidate(importJobsProvider),
        ),
        const SizedBox(height: 24),
        if (batches.isNotEmpty) ...[
          Text('Batches', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final b in batches.entries)
                ActionChip(
                  avatar: const Icon(Icons.insights, size: 16),
                  label: Text('${b.key.substring(0, 8)} · ${b.value} Jobs'),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _BatchDialog(
                      repo: _repo,
                      batchId: b.key,
                      messages: messages,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final t in ImportTab.values)
              ChoiceChip(
                selected: _tab == t,
                label: Text('${t.label} · ${counts[t]}'),
                onSelected: (_) => setState(() => _tab = t),
              ),
            SizedBox(
              width: 220,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Suchen …',
                  prefixIcon: Icon(Icons.search, size: 18),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            if (_tab == ImportTab.fehlgeschlagen && shown.isNotEmpty)
              OutlinedButton(
                onPressed: () => _retryAll(shown),
                child: Text('Alle ${shown.length} neu starten'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (async.isLoading && !async.hasValue)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Nichts in „${_tab.label}“.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          )
        else
          for (final j in shown)
            _JobRow(
              job: j,
              onOpen: () => context.go('/import/${j.id}'),
              onRetry: j.status == ImportStatus.fehlgeschlagen
                  ? () => _retry(j)
                  : null,
            ),
      ],
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job, required this.onOpen, this.onRetry});

  final ImportJob job;
  final VoidCallback onOpen;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = job.blockers;
    final w = warningCount(job.report);
    final color = switch (job.status) {
      ImportStatus.fehlgeschlagen => AppColors.statusError,
      ImportStatus.bereit => AppColors.statusOk,
      ImportStatus.wartetAufKlaerung || ImportStatus.vorschlag =>
        AppColors.statusInfo,
      ImportStatus.laeuft || ImportStatus.wartet => AppColors.statusWarn,
      _ => AppColors.n500,
    };
    final showCounts =
        job.status == ImportStatus.bereit ||
        job.status == ImportStatus.wartetAufKlaerung;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.circle, size: 10, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.trailId ?? job.fileName,
                      style: theme.textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      [
                        job.status.label,
                        if (job.trailId != null) job.fileName,
                        if (job.status == ImportStatus.fehlgeschlagen &&
                            (job.error ?? '').isNotEmpty)
                          job.error!,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (showCounts) ...[
                if (b.total > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 14,
                          color: AppColors.statusError,
                        ),
                        const SizedBox(width: 4),
                        Text('${b.total}'),
                      ],
                    ),
                  ),
                if (w > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: AppColors.statusWarn,
                        ),
                        const SizedBox(width: 4),
                        Text('$w'),
                      ],
                    ),
                  ),
              ],
              if (onRetry != null)
                TextButton(onPressed: onRetry, child: const Text('Neu starten')),
              const Icon(Icons.chevron_right, color: AppColors.n400),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dropzone
// ---------------------------------------------------------------------------

class _Picked {
  _Picked(this.name, this.bytes, this.hash);

  final String name;
  final Uint8List bytes;
  final String hash;
  String status = 'prüfe';
  String? trailId;
  String? error;
  bool done = false;
}

class _Dropzone extends StatefulWidget {
  const _Dropzone({required this.repo, required this.onUploaded});

  final ImportRepository repo;
  final VoidCallback onUploaded;

  @override
  State<_Dropzone> createState() => _DropzoneState();
}

class _DropzoneState extends State<_Dropzone> {
  var _hover = false;
  var _busy = false;
  var _uploading = false;
  var _priority = false;
  List<_Picked> _files = const [];

  Future<void> _add(List<({String name, Future<Uint8List> Function() read})> raw) async {
    final dossier = raw.where((f) {
      final n = f.name.toLowerCase();
      return n.endsWith('.zip') || n.endsWith('.docx');
    }).toList();
    if (dossier.isEmpty) {
      _toast('Nur .docx oder .zip.');
      return;
    }
    setState(() => _busy = true);
    try {
      final picked = <_Picked>[];
      for (final f in dossier) {
        final rawBytes = await f.read();
        final bytes = dossierBytes(f.name, rawBytes);
        picked.add(_Picked(f.name, bytes, sha256Hex(bytes)));
      }
      final res = await widget.repo.precheck([
        for (final p in picked) (name: p.name, hash: p.hash),
      ]);
      for (final p in picked) {
        final r = res.where((x) => x.hash == p.hash).toList();
        p.status = r.isEmpty ? 'neu' : r.first.status;
        p.trailId = r.isEmpty ? null : r.first.trailId;
      }
      setState(() => _files = [..._files, ...picked]);
    } catch (e) {
      _toast('Prüfung fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _pick() async {
    final files = await openFiles(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Dossier (.docx oder .zip)', extensions: ['docx', 'zip']),
      ],
    );
    if (files.isEmpty) return;
    await _add([for (final f in files) (name: f.name, read: f.readAsBytes)]);
  }

  Future<void> _upload() async {
    final todo = _files.where((f) => f.status != 'bereits_importiert' && !f.done).toList();
    if (todo.isEmpty) return;
    setState(() => _uploading = true);
    try {
      String? batch;
      if (todo.length > 1) {
        batch = await widget.repo.createBatch(
          'Upload ${DateTime.now().toIso8601String().substring(0, 16).replaceFirst('T', ' ')}',
        );
      }
      for (final f in todo) {
        try {
          await widget.repo.upload(
            name: f.name,
            bytes: f.bytes,
            hash: f.hash,
            batch: batch,
            priority: _priority ? 10 : 0,
          );
          f.done = true;
          f.error = null;
        } catch (e) {
          f.error = '$e';
        }
        if (mounted) setState(() {});
      }
      widget.onUploaded();
      if (mounted) {
        setState(() => _files = _files.where((f) => !f.done).toList());
      }
      final failed = _files.where((f) => f.error != null).length;
      _toast(
        failed == 0
            ? '${todo.length} Dossier(s) in der Warteschlange.'
            : '$failed Upload(s) fehlgeschlagen.',
      );
    } catch (e) {
      _toast('Upload fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _statusText(_Picked f) => switch (f.status) {
    'bereits_importiert' => 'Schon importiert (gleiche Datei)',
    'update' => 'Pfad existiert: Re-Import (${f.trailId})',
    'neu' => 'Neu',
    _ => 'Prüfe …',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neu = _files.where((f) => f.status != 'bereits_importiert').length;
    return DropTarget(
      onDragEntered: (_) => setState(() => _hover = true),
      onDragExited: (_) => setState(() => _hover = false),
      onDragDone: (d) {
        setState(() => _hover = false);
        _add([for (final f in d.files) (name: f.name, read: f.readAsBytes)]);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _hover ? AppColors.statusInfo.withValues(alpha: 0.08) : AppColors.n50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hover ? AppColors.statusInfo : AppColors.n300,
            width: _hover ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.upload_file_outlined, color: AppColors.n600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _hover
                        ? 'Loslassen zum Hinzufügen'
                        : 'Dossier (.docx oder .zip) hierher ziehen (mehrere möglich)',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                OutlinedButton(
                  onPressed: _busy || _uploading ? null : _pick,
                  child: const Text('Dateien wählen'),
                ),
              ],
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (_files.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final f in _files)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        f.error != null
                            ? Icons.error_outline
                            : f.status == 'bereits_importiert'
                            ? Icons.block
                            : f.status == 'update'
                            ? Icons.sync
                            : Icons.add_circle_outline,
                        size: 16,
                        color: f.error != null
                            ? AppColors.statusError
                            : f.status == 'bereits_importiert'
                            ? AppColors.n400
                            : AppColors.statusInfo,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${f.name} · ${f.error ?? _statusText(f)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Entfernen',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: _uploading
                            ? null
                            : () => setState(
                                () => _files = _files.where((x) => x != f).toList(),
                              ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton(
                    onPressed: _uploading || neu == 0 ? null : _upload,
                    child: Text(
                      _uploading
                          ? 'Lädt hoch …'
                          : neu == 1
                          ? 'Hochladen'
                          : '$neu hochladen (als Batch)',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Checkbox(
                    value: _priority,
                    onChanged: _uploading
                        ? null
                        : (v) => setState(() => _priority = v ?? false),
                  ),
                  const Text('Vorrang'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Batch-Auswertung
// ---------------------------------------------------------------------------

class _BatchDialog extends StatefulWidget {
  const _BatchDialog({
    required this.repo,
    required this.batchId,
    required this.messages,
  });

  final ImportRepository repo;
  final String batchId;
  final ImportMessages? messages;

  @override
  State<_BatchDialog> createState() => _BatchDialogState();
}

class _BatchDialogState extends State<_BatchDialog> {
  late final Future<Map<String, dynamic>> _f = widget.repo.batchStats(widget.batchId);

  String _title(String code) {
    final m = widget.messages;
    if (m == null || !m.has(code)) return code;
    return m.render(ReportEntry(code: code, severity: Severity.warnung, feld: '')).titel;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Batch ${widget.batchId.substring(0, 8)}'),
      content: SizedBox(
        width: 520,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _f,
          builder: (context, snap) {
            if (snap.hasError) return Text('Fehler: ${snap.error}');
            if (!snap.hasData) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final d = snap.data!;
            final codes = (d['meldungen'] as List? ?? const []);
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${d['jobs']} Pfade · ${d['bereit']} bereit · '
                    '${d['angelegt']} angelegt · ${d['fehlgeschlagen']} fehlgeschlagen',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Häufigste Meldungen',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  if (codes.isEmpty) const Text('Keine Meldungen.'),
                  for (final c in codes)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(child: Text(_title('${(c as Map)['code']}'))),
                          Text('${c['pfade']} Pfade · ${c['prozent']} %'),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await widget.repo.pauseBatch(widget.batchId, true);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Pausieren'),
        ),
        TextButton(
          onPressed: () async {
            await widget.repo.pauseBatch(widget.batchId, false);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Fortsetzen'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Schließen'),
        ),
      ],
    );
  }
}
