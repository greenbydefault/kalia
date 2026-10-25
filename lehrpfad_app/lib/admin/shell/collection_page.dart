import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../core/admin_repository.dart';
import '../core/collection_spec.dart';
import '../core/field_spec.dart';
import 'record_editor.dart';

/// Ordner im Katalog: links die Liste, rechts der Editor des gewählten
/// Eintrags. Schmal (< 760 px) wechselt es zwischen Liste und Editor.
class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key, required this.spec, this.itemId});

  final CollectionSpec spec;
  final String? itemId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 760;
        final list = _ListPane(spec: spec, selectedId: itemId);
        if (wide) {
          return Row(
            children: [
              SizedBox(width: 320, child: list),
              const VerticalDivider(width: 1, color: AppColors.n200),
              Expanded(
                child: itemId == null
                    ? _EmptyEditor(spec: spec)
                    : RecordEditor(
                        key: ValueKey('${spec.id}/$itemId'),
                        spec: spec,
                        id: itemId!,
                      ),
              ),
            ],
          );
        }
        if (itemId == null) return list;
        return Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go(spec.path),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(spec.label),
              ),
            ),
            Expanded(
              child: RecordEditor(
                key: ValueKey('${spec.id}/$itemId'),
                spec: spec,
                id: itemId!,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyEditor extends ConsumerWidget {
  const _EmptyEditor({required this.spec});

  final CollectionSpec spec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(collectionRowsProvider(spec)).value;
    final gaps = spec.gaps;
    final withGaps = rows == null || gaps == null
        ? 0
        : rows.where((r) => gaps(r).isNotEmpty).length;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(spec.icon, size: 32, color: AppColors.n400),
          const SizedBox(height: 12),
          Text(
            '${spec.singular} links auswählen',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
          ),
          if (withGaps > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$withGaps mit Lücken',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _ListPane extends ConsumerStatefulWidget {
  const _ListPane({required this.spec, required this.selectedId});

  final CollectionSpec spec;
  final String? selectedId;

  @override
  ConsumerState<_ListPane> createState() => _ListPaneState();
}

class _ListPaneState extends ConsumerState<_ListPane> {
  String _query = '';
  final _filters = <String, String>{};
  bool _onlyGaps = false;

  bool _matches(DbRow r) {
    final spec = widget.spec;
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      final hay = [
        r[spec.titleColumn],
        r[spec.idColumn],
        spec.subtitle?.call(r),
      ].whereType<String>().join(' ').toLowerCase();
      if (!hay.contains(q)) return false;
    }
    for (final e in _filters.entries) {
      final v = r[e.key];
      if (v is List ? !v.contains(e.value) : v != e.value) return false;
    }
    if (_onlyGaps && (spec.gaps?.call(r).isEmpty ?? true)) return false;
    return true;
  }

  Future<void> _create() async {
    final spec = widget.spec;
    final repo = ref.read(adminRepositoryProvider);
    final title = await showDialog<String>(
      context: context,
      builder: (_) => _NewDialog(spec: spec),
    );
    if (title == null || title.trim().isEmpty) return;
    final id = slugify(title);
    try {
      if (id.isEmpty || await repo.exists(spec, id)) {
        _toast(
          id.isEmpty ? 'Name ergibt keine gültige ID.' : '„$id“ gibt es schon.',
        );
        return;
      }
      await repo.insert(spec, spec.newRow(id, title.trim()));
      ref.invalidate(collectionRowsProvider(spec));
      ref.invalidate(collectionCountProvider(spec));
      if (mounted) context.go(spec.itemPath(id));
    } catch (e) {
      _toast('Anlegen fehlgeschlagen: $e');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final theme = Theme.of(context);
    final async = ref.watch(collectionRowsProvider(spec));
    final rows = async.value;
    final hasGaps = spec.gaps != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(spec.label, style: theme.textTheme.titleLarge),
              ),
              if (spec.importPath != null)
                IconButton.filledTonal(
                  tooltip: 'Dossiers importieren',
                  icon: const Icon(Icons.upload_file_outlined),
                  onPressed: () => context.go(spec.importPath!),
                ),
              if (spec.canCreate)
                IconButton.filledTonal(
                  tooltip: '${spec.singular} anlegen',
                  icon: const Icon(Icons.add),
                  onPressed: _create,
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Suchen …',
              prefixIcon: Icon(Icons.search, size: 18),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        if (spec.listFilters.isNotEmpty || hasGaps)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final f in spec.listFilters)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _FilterChip(
                      filter: f,
                      value: _filters[f.column],
                      onChanged: (v) => setState(() {
                        if (v == null) {
                          _filters.remove(f.column);
                        } else {
                          _filters[f.column] = v;
                        }
                      }),
                    ),
                  ),
                if (hasGaps)
                  FilterChip(
                    label: const Text('Lücken'),
                    selected: _onlyGaps,
                    onSelected: (v) => setState(() => _onlyGaps = v),
                  ),
              ],
            ),
          )
        else
          const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.n200),
        Expanded(
          child: rows == null
              ? (async.hasError
                    ? Center(child: Text('Fehler: ${async.error}'))
                    : const Center(child: CircularProgressIndicator()))
              : _buildList(rows),
        ),
      ],
    );
  }

  Widget _buildList(List<DbRow> rows) {
    final spec = widget.spec;
    final shown = rows.where(_matches).toList();
    if (shown.isEmpty) {
      return Center(
        child: Text(
          rows.isEmpty ? 'Noch nichts angelegt.' : 'Nichts gefunden.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
        ),
      );
    }
    return ListView.builder(
      itemCount: shown.length,
      itemBuilder: (context, i) {
        final r = shown[i];
        final id = r[spec.idColumn] as String;
        final gaps = spec.gaps?.call(r) ?? const <String>[];
        final sub = spec.subtitle?.call(r);
        final thumb = spec.thumbUrl?.call(r);
        return ListTile(
          dense: true,
          selected: id == widget.selectedId,
          selectedTileColor: AppColors.n100,
          leading: thumb == null
              ? null
              : ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Image.network(
                      thumb,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
          title: Text(
            (r[spec.titleColumn] as String?) ?? id,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: sub == null || sub.isEmpty
              ? null
              : Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: gaps.isEmpty
              ? null
              : Tooltip(
                  message: gaps.join('\n'),
                  child: const Icon(
                    Icons.circle,
                    size: 8,
                    color: AppColors.eignung2,
                  ),
                ),
          onTap: () => context.go(spec.itemPath(id)),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.value,
    required this.onChanged,
  });

  final ListFilterSpec filter;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: filter.label,
      onSelected: (v) => onChanged(v.isEmpty ? null : v),
      itemBuilder: (_) => [
        PopupMenuItem(value: '', child: Text('Alle · ${filter.label}')),
        for (final e in filter.options.entries)
          PopupMenuItem(value: e.key, child: Text(e.value)),
      ],
      child: Chip(
        label: Text(
          value == null ? filter.label : (filter.options[value] ?? value!),
        ),
        backgroundColor: value == null ? null : AppColors.n200,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _NewDialog extends StatefulWidget {
  const _NewDialog({required this.spec});

  final CollectionSpec spec;

  @override
  State<_NewDialog> createState() => _NewDialogState();
}

class _NewDialogState extends State<_NewDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = slugify(_name.text);
    return AlertDialog(
      title: Text('${widget.spec.singular} anlegen'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (_) => setState(() {}),
              onSubmitted: (v) =>
                  v.trim().isEmpty ? null : Navigator.pop(context, v),
            ),
            const SizedBox(height: 8),
            Text(
              id.isEmpty ? 'ID entsteht aus dem Namen' : 'ID: $id',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: id.isEmpty
              ? null
              : () => Navigator.pop(context, _name.text),
          child: const Text('Anlegen'),
        ),
      ],
    );
  }
}
