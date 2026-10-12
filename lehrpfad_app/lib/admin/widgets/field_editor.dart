import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../core/field_spec.dart';

/// Ein Feld nach [FieldSpec.kind]. Hält den Eingabezustand selbst, meldet
/// jede Änderung über [onChanged] (Autosave sitzt darüber). Beim Wechsel
/// der Zeile neu aufbauen (Key mit Zeilen-ID).
class FieldEditor extends StatefulWidget {
  const FieldEditor({
    super.key,
    required this.spec,
    required this.row,
    required this.onChanged,
  });

  final FieldSpec spec;
  final DbRow row;
  final void Function(FieldSpec spec, dynamic value) onChanged;

  @override
  State<FieldEditor> createState() => _FieldEditorState();
}

class _FieldEditorState extends State<FieldEditor> {
  late final TextEditingController _text;
  late List<String> _list;
  late bool _bool;
  late String _select;

  FieldSpec get spec => widget.spec;

  bool get _isTextual => switch (spec.kind) {
    FieldKind.text ||
    FieldKind.longText ||
    FieldKind.number ||
    FieldKind.integer => true,
    _ => false,
  };

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(
      text: switch (spec.kind) {
        FieldKind.lines => spec.readList(widget.row).join('\n'),
        _ => spec.readText(widget.row),
      },
    );
    _list = spec.readList(widget.row);
    _bool = spec.read(widget.row) == true;
    _select = spec.readText(widget.row);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _emitText(String value) {
    switch (spec.kind) {
      case FieldKind.number:
        final t = value.trim().replaceAll(',', '.');
        widget.onChanged(spec, t.isEmpty ? null : double.tryParse(t));
      case FieldKind.integer:
        final t = value.trim();
        widget.onChanged(spec, t.isEmpty ? null : int.tryParse(t));
      case FieldKind.lines:
        widget.onChanged(spec, [
          for (final l in value.split('\n'))
            if (l.trim().isNotEmpty) l.trim(),
        ]);
      default:
        widget.onChanged(spec, value.isEmpty && spec.nullable ? null : value);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warn = _isTextual || spec.kind == FieldKind.lines
        ? spec.limit?.warn(_text.text)
        : null;

    Widget body;
    switch (spec.kind) {
      case FieldKind.text:
      case FieldKind.longText:
      case FieldKind.number:
      case FieldKind.integer:
      case FieldKind.lines:
        final multi =
            spec.kind == FieldKind.longText || spec.kind == FieldKind.lines;
        body = TextField(
          controller: _text,
          enabled: !spec.readOnly,
          minLines: multi ? spec.minLines.clamp(2, 40) : 1,
          maxLines: multi ? null : 1,
          keyboardType: switch (spec.kind) {
            FieldKind.number => const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            FieldKind.integer => const TextInputType.numberWithOptions(),
            FieldKind.text => TextInputType.text,
            _ => TextInputType.multiline,
          },
          decoration: InputDecoration(
            hintText: spec.hint,
            errorText: warn,
            errorStyle: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.error,
            ),
          ),
          onChanged: _emitText,
        );
      case FieldKind.boolean:
        body = Align(
          alignment: Alignment.centerLeft,
          child: Switch(
            value: _bool,
            onChanged: spec.readOnly
                ? null
                : (v) {
                    setState(() => _bool = v);
                    widget.onChanged(spec, v);
                  },
          ),
        );
      case FieldKind.select:
        final options = Map<String, String>.from(spec.options);
        final allowEmpty = !spec.required || _select.isEmpty;
        if (_select.isNotEmpty && !options.containsKey(_select)) {
          options[_select] = _select;
        }
        body = DropdownButtonFormField<String>(
          initialValue: _select,
          isExpanded: true,
          decoration: InputDecoration(hintText: spec.hint),
          items: [
            if (allowEmpty)
              const DropdownMenuItem(value: '', child: Text('— keine —')),
            for (final e in options.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: spec.readOnly
              ? null
              : (v) {
                  if (v == null) return;
                  setState(() => _select = v);
                  widget.onChanged(spec, v.isEmpty && spec.nullable ? null : v);
                },
        );
      case FieldKind.multiSelect:
        body = Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final e in spec.options.entries)
              FilterChip(
                label: Text(e.value),
                selected: _list.contains(e.key),
                showCheckmark: false,
                onSelected: spec.readOnly
                    ? null
                    : (on) {
                        setState(() {
                          _list = on
                              ? [..._list, e.key]
                              : _list.where((x) => x != e.key).toList();
                        });
                        widget.onChanged(spec, _list);
                      },
              ),
          ],
        );
      case FieldKind.tags:
        body = _TagsInput(
          values: _list,
          hint: spec.hint,
          onChanged: (v) {
            setState(() => _list = v);
            widget.onChanged(spec, v);
          },
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                spec.required ? '${spec.label} *' : spec.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ),
            if (spec.limit != null &&
                (_isTextual || spec.kind == FieldKind.lines))
              Text(
                spec.limit!.counter(_text.text),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: warn == null ? AppColors.n400 : AppColors.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        body,
      ],
    );
  }
}

/// Freie Begriffe als Chips; Enter oder Komma fügt hinzu.
class _TagsInput extends StatefulWidget {
  const _TagsInput({required this.values, required this.onChanged, this.hint});

  final List<String> values;
  final String? hint;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_TagsInput> createState() => _TagsInputState();
}

class _TagsInputState extends State<_TagsInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit(String raw) {
    final parts = [
      for (final p in raw.split(','))
        if (p.trim().isNotEmpty) p.trim(),
    ];
    if (parts.isEmpty) return;
    final next = [...widget.values];
    for (final p in parts) {
      if (!next.contains(p)) next.add(p);
    }
    _controller.clear();
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.values.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final v in widget.values)
                  InputChip(
                    label: Text(v),
                    onDeleted: () => widget.onChanged(
                      widget.values.where((x) => x != v).toList(),
                    ),
                  ),
              ],
            ),
          ),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hint ?? 'Begriff + Enter',
          ),
          onSubmitted: _commit,
          onChanged: (v) {
            if (v.endsWith(',')) _commit(v);
          },
        ),
      ],
    );
  }
}
