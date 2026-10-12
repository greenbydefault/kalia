import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../core/autosave.dart';
import '../core/collection_spec.dart';
import '../core/field_spec.dart';
import 'field_editor.dart';

/// Untergeordnete Zeilen eines Datensatzes (Stationen, Amenities), je
/// aufklappbar und mit eigenem Autosave. Anlegen gibt es nicht: neue Zeilen
/// brauchen Koordinaten aus der Pipeline.
class ChildRowsEditor extends StatefulWidget {
  const ChildRowsEditor({
    super.key,
    required this.ctx,
    required this.table,
    required this.fkColumn,
    required this.orderColumn,
    required this.title,
    required this.fields,
    this.info,
    this.canDelete = false,
    this.emptyText = 'Keine Einträge.',
  });

  final EditorContext ctx;
  final String table;
  final String fkColumn;
  final String orderColumn;
  final String Function(DbRow row) title;
  final String Function(DbRow row)? info;
  final List<FieldSpec> fields;
  final bool canDelete;
  final String emptyText;

  @override
  State<ChildRowsEditor> createState() => _ChildRowsEditorState();
}

class _ChildRowsEditorState extends State<ChildRowsEditor> {
  List<DbRow>? _rows;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await widget.ctx.client
          .from(widget.table)
          .select()
          .eq(widget.fkColumn, widget.ctx.id)
          .order(widget.orderColumn, ascending: true);
      if (mounted) {
        setState(
          () => _rows = rows.map((r) => Map<String, dynamic>.from(r)).toList(),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _delete(DbRow row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eintrag löschen?'),
        content: Text(widget.title(row)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.ctx.client.from(widget.table).delete().eq('id', row['id']);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Löschen fehlgeschlagen: $e')));
    }
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
    if (rows.isEmpty) {
      return Text(
        widget.emptyText,
        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.hairline),
            _ChildRow(
              key: ValueKey('${widget.table}-${rows[i]['id']}'),
              row: rows[i],
              widget: widget,
              onDelete: widget.canDelete ? () => _delete(rows[i]) : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _ChildRow extends StatefulWidget {
  const _ChildRow({
    super.key,
    required this.row,
    required this.widget,
    required this.onDelete,
  });

  final DbRow row;
  final ChildRowsEditor widget;
  final VoidCallback? onDelete;

  @override
  State<_ChildRow> createState() => _ChildRowState();
}

class _ChildRowState extends State<_ChildRow> {
  late final AutosaveController _autosave;

  @override
  void initState() {
    super.initState();
    final w = widget.widget;
    _autosave = AutosaveController(
      row: widget.row,
      hub: w.ctx.hub,
      save: (patch) async {
        await w.ctx.client
            .from(w.table)
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
    final w = widget.widget;
    final theme = Theme.of(context);
    final info = w.info?.call(widget.row);
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        title: Text(w.title(widget.row), style: theme.textTheme.bodyMedium),
        subtitle: info == null
            ? null
            : Text(
                info,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.n400,
                ),
              ),
        children: [
          for (final f in w.fields) ...[
            FieldEditor(
              key: ValueKey('${widget.row['id']}-${f.key}'),
              spec: f,
              row: widget.row,
              onChanged: (spec, value) {
                _autosave.set(spec, value);
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
          ],
          if (widget.onDelete != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Löschen'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }
}
