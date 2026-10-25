import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../core/admin_repository.dart';
import '../core/autosave.dart';
import '../core/collection_spec.dart';
import '../core/field_spec.dart';
import '../widgets/editor_chrome.dart';
import '../widgets/field_editor.dart';
import '../widgets/relation_field.dart';
import '../import/import_frames.dart';
import '../import/import_scope.dart';

/// Editor eines Datensatzes: Kopf (Titel, Autosave, Löschen) und die
/// Blöcke der [CollectionSpec] untereinander.
class RecordEditor extends ConsumerWidget {
  const RecordEditor({super.key, required this.spec, required this.id});

  final CollectionSpec spec;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(collectionRowProvider((spec: spec, id: id)));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (row) {
        if (row == null) {
          return Center(child: Text('${spec.singular} „$id“ gibt es nicht.'));
        }
        return _EditorBody(
          key: ValueKey('${spec.id}/$id'),
          spec: spec,
          row: row,
        );
      },
    );
  }
}

class _EditorBody extends ConsumerStatefulWidget {
  const _EditorBody({super.key, required this.spec, required this.row});

  final CollectionSpec spec;
  final DbRow row;

  @override
  ConsumerState<_EditorBody> createState() => _EditorBodyState();
}

class _EditorBodyState extends ConsumerState<_EditorBody> {
  late final AutosaveHub _hub = AutosaveHub();
  late final AutosaveController _autosave;
  late final EditorContext _ctx;
  late final AdminRepository _repo;
  late final ProviderContainer _container;
  var _containerReady = false;

  // Import-Review: Feld-Revisionen, damit ein übernommener Vorschlag im Feld erscheint.
  final _fieldRev = <String, int>{};
  ImportEditorController? _importCtl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inherited-Lookup ist in initState verboten (roter Screen beim Öffnen).
    final ctl = ImportScope.maybeOf(context)?.controller;
    if (!identical(ctl, _importCtl)) {
      _importCtl?.removeListener(_onImportCtl);
      _importCtl?.applyValue = null;
      _importCtl?.currentRow = null;
      _importCtl?.flush = null;
      _importCtl = ctl;
      ctl?.addListener(_onImportCtl);
      ctl?.applyValue = _applyImportValue;
      ctl?.currentRow = () => widget.row;
      ctl?.flush = _autosave.flush;
    }
    if (_containerReady) return;
    _container = ProviderScope.containerOf(context);
    _containerReady = true;
  }

  void _onImportCtl() {
    if (mounted) setState(() {});
  }

  FieldSpec? _fieldByKey(String key) {
    for (final b in widget.spec.blocks) {
      if (b is FieldsBlock) {
        for (final f in b.fields) {
          if (f.key == key) return f;
        }
      }
    }
    return null;
  }

  void _applyImportValue(String key, dynamic value) {
    final f = _fieldByKey(key);
    if (f == null) return;
    _autosave.set(f, value);
    setState(() => _fieldRev[key] = (_fieldRev[key] ?? 0) + 1);
  }

  @override
  void initState() {
    super.initState();
    _repo = ref.read(adminRepositoryProvider);
    final spec = widget.spec;
    final id = widget.row[spec.idColumn] as String;
    _autosave = AutosaveController(
      row: widget.row,
      hub: _hub,
      save: (patch) async {
        await _repo.update(spec, id, patch);
        _importCtl?.onSaved?.call();
        // Titel/Lücken in der Liste nachziehen, ohne den Editor neu zu laden.
        if (patch.keys.any(
          (k) =>
              k == spec.titleColumn ||
              spec.listColumns.split(',').contains(k) ||
              k == 'content',
        )) {
          _container.invalidate(collectionRowsProvider(spec));
        }
      },
    );
    _ctx = EditorContext(
      spec: spec,
      row: widget.row,
      client: ref.read(adminClientProvider),
      hub: _hub,
      autosave: _autosave,
    );
  }

  @override
  void dispose() {
    _importCtl?.removeListener(_onImportCtl);
    _importCtl?.applyValue = null;
    _importCtl?.currentRow = null;
    _importCtl?.flush = null;
    _autosave.dispose();
    _hub.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final spec = widget.spec;
    final id = _ctx.id;
    final counts = await _repo.dependentCounts(spec, id);
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(spec: spec, id: id, counts: counts),
    );
    if (ok != true) return;
    try {
      await _repo.delete(spec, id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Löschen fehlgeschlagen: $e')));
      return;
    }
    _container.invalidate(collectionRowsProvider(spec));
    _container.invalidate(collectionCountProvider(spec));
    if (mounted) context.go(spec.path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = widget.spec;
    final importing = _importCtl != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (importing)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
            child: Row(
              children: [
                const Spacer(),
                AutosaveIndicator(hub: _hub),
              ],
            ),
          )
        else
          Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 24, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListenableBuilder(
                      listenable: _hub,
                      builder: (context, _) => Text(
                        (widget.row[spec.titleColumn] as String?) ?? _ctx.id,
                        style: theme.textTheme.headlineSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _ctx.id,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              AutosaveIndicator(hub: _hub),
              if (spec.canDelete)
                IconButton(
                  tooltip: '${spec.singular} löschen',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _delete,
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.n200),
        Expanded(
          child: SingleChildScrollView(
            padding: importing
                ? const EdgeInsets.fromLTRB(20, 16, 20, 64)
                : const EdgeInsets.fromLTRB(32, 24, 32, 64),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final block in spec.blocks)
                      EditorSection(
                        title: block.title,
                        description: block.description,
                        child: _wrapBlock(context, block),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _wrapBlock(BuildContext context, EditorBlock block) {
    final built = _buildBlock(context, block);
    final key = importBlockKey(block.title);
    if (_importCtl == null || key == null) return built;
    return ImportBlockFrame(
      blockKey: key,
      child: KeyedSubtree(
        key: ValueKey('$key#${_importCtl!.blockRev}'),
        child: built,
      ),
    );
  }

  Widget _buildBlock(BuildContext context, EditorBlock block) {
    switch (block) {
      case FieldsBlock():
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final f in block.fields)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: ImportFieldFrame(
                  spec: f,
                  child: FieldEditor(
                    key: ValueKey('${f.key}#${_fieldRev[f.key] ?? 0}'),
                    spec: f,
                    row: widget.row,
                    onChanged: _autosave.set,
                  ),
                ),
              ),
          ],
        );
      case RelationBlock():
        return RelationField(ctx: _ctx, relation: block.relation);
      case CustomBlock():
        return block.builder(context, _ctx);
    }
  }
}

class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog({
    required this.spec,
    required this.id,
    required this.counts,
  });

  final CollectionSpec spec;
  final String id;
  final Map<String, int> counts;

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final needTyping = spec.confirmDeleteByTyping;
    final allowed = !needTyping || _confirm.text.trim() == widget.id;
    return AlertDialog(
      title: Text('${spec.singular} löschen?'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.counts.isEmpty
                  ? '„${widget.id}“ wird dauerhaft gelöscht.'
                  : 'Mit „${widget.id}“ gehen auch verknüpfte Daten verloren:',
            ),
            if (widget.counts.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final e in widget.counts.entries)
                Text('• ${e.value} ${e.key}'),
            ],
            if (needTyping) ...[
              const SizedBox(height: 16),
              Text('Zur Bestätigung „${widget.id}“ eintippen:'),
              const SizedBox(height: 8),
              TextField(
                controller: _confirm,
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: allowed ? () => Navigator.pop(context, true) : null,
          child: const Text('Löschen'),
        ),
      ],
    );
  }
}
