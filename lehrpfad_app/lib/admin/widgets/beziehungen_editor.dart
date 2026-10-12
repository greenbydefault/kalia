import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../collections/admin_catalogs.dart';
import '../core/autosave.dart';
import '../core/collection_spec.dart';
import '../core/field_spec.dart';
import 'field_editor.dart';

const _typSpec = FieldSpec(
  'typ',
  'Beziehung',
  FieldKind.select,
  options: beziehungTypOptions,
  required: true,
);
const _kurztextSpec = FieldSpec(
  'kurztext',
  'Kurztext',
  FieldKind.text,
  limit: FieldLimit(max: 12, unit: LimitUnit.words),
);
const _freitextSpec = FieldSpec('name_de', 'Name (Freitext)', FieldKind.text);

/// `species_beziehungen` einer Art: frisst / bestäubt / wohnt an, Ziel ist
/// eine Katalog-Art (tippbar) oder ein Freitext („Mücke“, „Uhu“).
class BeziehungenEditor extends StatefulWidget {
  const BeziehungenEditor({super.key, required this.ctx});

  final EditorContext ctx;

  @override
  State<BeziehungenEditor> createState() => _BeziehungenEditorState();
}

class _BeziehungenEditorState extends State<BeziehungenEditor> {
  List<DbRow>? _rows;
  Map<String, DbRow> _targets = {};
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = widget.ctx.client;
      final rows = await c
          .from('species_beziehungen')
          .select()
          .eq('from_id', widget.ctx.id)
          .order('sortierung', ascending: true);
      final ids = {
        for (final r in rows)
          if (r['to_species_id'] != null) r['to_species_id'] as String,
      }.toList();
      final targets = <String, DbRow>{};
      if (ids.isNotEmpty) {
        final sp = await c
            .from('species')
            .select('id,name_de,kategorie')
            .inFilter('id', ids);
        for (final s in sp) {
          targets[s['id'] as String] = Map<String, dynamic>.from(s);
        }
      }
      if (!mounted) return;
      setState(() {
        _rows = rows.map((r) => Map<String, dynamic>.from(r)).toList();
        _targets = targets;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _delete(DbRow row) async {
    try {
      await widget.ctx.client
          .from('species_beziehungen')
          .delete()
          .eq('id', row['id']);
      await _load();
    } catch (e) {
      _toast(e);
    }
  }

  void _toast(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }

  Future<void> _add() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _AddBeziehungDialog(ctx: widget.ctx),
    );
    if (created == true) await _load();
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
    final rows = _rows;
    if (rows == null) {
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
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Keine Beziehungen.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ),
        for (final r in rows)
          _BeziehungRow(
            key: ValueKey('bez-${r['id']}'),
            ctx: widget.ctx,
            row: r,
            target: _targets[r['to_species_id']],
            onDelete: () => _delete(r),
          ),
        OutlinedButton.icon(
          onPressed: _add,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Beziehung hinzufügen'),
        ),
      ],
    );
  }
}

class _BeziehungRow extends StatefulWidget {
  const _BeziehungRow({
    super.key,
    required this.ctx,
    required this.row,
    required this.target,
    required this.onDelete,
  });

  final EditorContext ctx;
  final DbRow row;
  final DbRow? target;
  final VoidCallback onDelete;

  @override
  State<_BeziehungRow> createState() => _BeziehungRowState();
}

class _BeziehungRowState extends State<_BeziehungRow> {
  late final AutosaveController _autosave;

  @override
  void initState() {
    super.initState();
    _autosave = AutosaveController(
      row: widget.row,
      hub: widget.ctx.hub,
      save: (patch) async {
        await widget.ctx.client
            .from('species_beziehungen')
            .update(patch)
            .eq('id', widget.row['id']);
      },
    );
  }

  @override
  void dispose() {
    _autosave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    final isSpecies = widget.row['to_species_id'] != null;
    final k = target?['kategorie'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: FieldEditor(
              spec: _typSpec,
              row: widget.row,
              onChanged: _autosave.set,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: isSpecies
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Art',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.inkMuted),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ActionChip(
                          label: Text(
                            target?['name_de'] as String? ??
                                '${widget.row['to_species_id']}',
                          ),
                          onPressed: () => context.go(
                            '/${k == 'flora' || k == 'geraete' ? k : 'fauna'}/'
                            '${Uri.encodeComponent('${widget.row['to_species_id']}')}',
                          ),
                        ),
                      ),
                    ],
                  )
                : FieldEditor(
                    spec: _freitextSpec,
                    row: widget.row,
                    onChanged: _autosave.set,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: FieldEditor(
              spec: _kurztextSpec,
              row: widget.row,
              onChanged: _autosave.set,
            ),
          ),
          IconButton(
            tooltip: 'Entfernen',
            icon: const Icon(Icons.close, size: 18),
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}

class _AddBeziehungDialog extends StatefulWidget {
  const _AddBeziehungDialog({required this.ctx});

  final EditorContext ctx;

  @override
  State<_AddBeziehungDialog> createState() => _AddBeziehungDialogState();
}

class _AddBeziehungDialogState extends State<_AddBeziehungDialog> {
  final _query = TextEditingController();
  final _kurztext = TextEditingController();
  String _typ = 'frisst';
  List<DbRow> _results = const [];
  DbRow? _picked;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _query.dispose();
    _kurztext.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    final t = q.trim().replaceAll(RegExp(r'[,()*%]'), ' ');
    if (t.isEmpty) {
      setState(() => _results = const []);
      return;
    }
    final rows = await widget.ctx.client
        .from('species')
        .select('id,name_de,kategorie')
        .or('name_de.ilike.*$t*,id.ilike.*$t*')
        .neq('id', widget.ctx.id)
        .order('name_de')
        .limit(8);
    if (mounted && q == _query.text) {
      setState(
        () => _results = rows.map((r) => Map<String, dynamic>.from(r)).toList(),
      );
    }
  }

  Future<void> _save({required bool freitext}) async {
    final name = _query.text.trim();
    if (freitext && name.isEmpty) return;
    if (!freitext && _picked == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final c = widget.ctx.client;
      final last = await c
          .from('species_beziehungen')
          .select('sortierung')
          .eq('from_id', widget.ctx.id)
          .order('sortierung', ascending: false)
          .limit(1);
      final next = last.isEmpty
          ? 0
          : ((last.first['sortierung'] as num?) ?? 0).toInt() + 1;
      await c.from('species_beziehungen').insert({
        'from_id': widget.ctx.id,
        'typ': _typ,
        if (!freitext) 'to_species_id': _picked!['id'] else 'name_de': name,
        'kurztext': _kurztext.text.trim(),
        'sortierung': next,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _query.text.trim();
    return AlertDialog(
      title: const Text('Beziehung hinzufügen'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _typ,
                items: [
                  for (final e in beziehungTypOptions.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _typ = v ?? _typ),
              ),
              const SizedBox(height: 12),
              if (_picked == null)
                TextField(
                  controller: _query,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Art suchen oder Freitext tippen …',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) {
                    setState(() {});
                    _search(v);
                  },
                )
              else
                InputChip(
                  label: Text(_picked!['name_de'] as String),
                  onDeleted: () => setState(() => _picked = null),
                ),
              if (_picked == null) ...[
                for (final r in _results)
                  ListTile(
                    dense: true,
                    title: Text(r['name_de'] as String),
                    subtitle: Text(r['kategorie'] as String),
                    onTap: () => setState(() => _picked = r),
                  ),
                if (q.isNotEmpty)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.edit_outlined),
                    title: Text('„$q“ als Freitext'),
                    onTap: _saving ? null : () => _save(freitext: true),
                  ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _kurztext,
                decoration: const InputDecoration(
                  hintText: 'Kurztext (max. 12 Wörter)',
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _picked == null || _saving
              ? null
              : () => _save(freitext: false),
          child: const Text('Hinzufügen'),
        ),
      ],
    );
  }
}
