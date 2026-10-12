import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../collections/admin_catalogs.dart';
import '../core/collection_spec.dart';
import '../core/field_spec.dart';

/// `species.masse`: Liste aus Maß-Key (Länge, Gewicht …) und Anzeigewert
/// (`80–100 cm`). Gespeichert werden nur Zeilen mit Wert.
class MasseEditor extends StatefulWidget {
  const MasseEditor({super.key, required this.ctx});

  final EditorContext ctx;

  static const _spec = FieldSpec('masse', 'Maße', FieldKind.lines);

  @override
  State<MasseEditor> createState() => _MasseEditorState();
}

class _MasseEditorState extends State<MasseEditor> {
  late List<({String key, TextEditingController wert})> _rows;

  @override
  void initState() {
    super.initState();
    final raw = widget.ctx.row['masse'];
    _rows = [
      if (raw is List)
        for (final e in raw)
          if (e is Map)
            (
              key: '${e['key']}',
              wert: TextEditingController(text: '${e['wert'] ?? ''}'),
            ),
    ];
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.wert.dispose();
    }
    super.dispose();
  }

  void _save() {
    widget.ctx.autosave.set(MasseEditor._spec, [
      for (final r in _rows)
        if (r.wert.text.trim().isNotEmpty)
          {'key': r.key, 'wert': r.wert.text.trim()},
    ]);
  }

  void _add() {
    final used = _rows.map((r) => r.key).toSet();
    final free = masseOptions.keys.firstWhere(
      (k) => !used.contains(k),
      orElse: () => '',
    );
    if (free.isEmpty) return;
    setState(() => _rows.add((key: free, wert: TextEditingController())));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_rows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Keine Maße.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ),
        for (var i = 0; i < _rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: _rows[i].key,
                    isExpanded: true,
                    items: [
                      for (final e in masseOptions.entries)
                        DropdownMenuItem(
                          value: e.key,
                          enabled:
                              e.key == _rows[i].key ||
                              !_rows.any((r) => r.key == e.key),
                          child: Text(e.value),
                        ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _rows[i] = (key: v, wert: _rows[i].wert));
                      _save();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _rows[i].wert,
                    decoration: const InputDecoration(
                      hintText: 'z. B. 80–100 cm',
                    ),
                    onChanged: (_) => _save(),
                  ),
                ),
                IconButton(
                  tooltip: 'Entfernen',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    final removed = _rows[i].wert;
                    setState(() => _rows.removeAt(i));
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => removed.dispose(),
                    );
                    _save();
                  },
                ),
              ],
            ),
          ),
        if (_rows.length < masseOptions.length)
          OutlinedButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Maß hinzufügen'),
          ),
      ],
    );
  }
}
