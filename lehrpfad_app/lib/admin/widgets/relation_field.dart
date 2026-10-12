import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../collections/registry.dart';
import '../core/admin_repository.dart';
import '../core/collection_spec.dart';
import '../core/relation.dart';
import 'field_editor.dart';

/// Multi-Reference-Feld: Chips der verknüpften Datensätze. Klick springt
/// zum Datensatz, `x` entfernt, „Hinzufügen“ öffnet die Suche. Alle
/// Änderungen wirken sofort auf die Join-Zeile.
class RelationField extends StatefulWidget {
  const RelationField({super.key, required this.ctx, required this.relation});

  final EditorContext ctx;
  final RelationSpec relation;

  @override
  State<RelationField> createState() => _RelationFieldState();
}

class _RelationFieldState extends State<RelationField> {
  late final RelationBackend _backend;
  List<RelationLink>? _links;
  Object? _error;

  String get _ownId => widget.ctx.id;
  RelationSpec get _spec => widget.relation;

  @override
  void initState() {
    super.initState();
    _backend = _spec.backend(widget.ctx.client);
    _load();
  }

  Future<void> _load() async {
    try {
      final links = await _backend.load(_ownId);
      if (mounted) setState(() => _links = links);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _toast(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
    );
  }

  Future<void> _remove(RelationLink l) async {
    try {
      await _backend.remove(_ownId, l.otherId);
      await _load();
    } catch (e) {
      _toast(e);
    }
  }

  Future<void> _openPicker() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _RelationPicker(
        ctx: widget.ctx,
        spec: _spec,
        backend: _backend,
        initial: _links ?? const [],
        onChanged: _load,
      ),
    );
    await _load();
  }

  Future<void> _editExtras(RelationLink l) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.title),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final f in _spec.extraFields) ...[
                FieldEditor(
                  spec: f,
                  row: l.extras,
                  onChanged: (spec, value) async {
                    l.extras[spec.key] = value;
                    try {
                      await _backend.updateExtras(_ownId, l.otherId, {
                        spec.key: value,
                      });
                    } catch (e) {
                      _toast(e);
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
    await _load();
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
    final links = _links;
    if (links == null) {
      return const SizedBox(
        height: 32,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (links.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _spec.emptyText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final l in links)
              _LinkChip(
                link: l,
                extra: _spec.extraLabel?.call(l),
                editable: _backend.editable,
                hasExtras: _spec.extraFields.isNotEmpty && _backend.editable,
                onOpen: () {
                  final route = _spec.routeFor(l);
                  if (route.isNotEmpty) context.go(route);
                },
                onRemove: () => _remove(l),
                onEditExtras: () => _editExtras(l),
              ),
            if (_backend.editable)
              OutlinedButton.icon(
                onPressed: _openPicker,
                icon: const Icon(Icons.add, size: 18),
                label: Text(_spec.addLabel),
              ),
          ],
        ),
        if (_spec.limitHint != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _spec.limitHint!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.n400,
              ),
            ),
          ),
      ],
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({
    required this.link,
    required this.extra,
    required this.editable,
    required this.hasExtras,
    required this.onOpen,
    required this.onRemove,
    required this.onEditExtras,
  });

  final RelationLink link;
  final String? extra;
  final bool editable;
  final bool hasExtras;
  final VoidCallback onOpen;
  final VoidCallback onRemove;
  final VoidCallback onEditExtras;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.n50,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(8),
            ),
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(link.title, style: theme.textTheme.bodyMedium),
                  if (link.subtitle != null && link.subtitle!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      link.subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.n400,
                      ),
                    ),
                  ],
                  if (extra != null && extra!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.n100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        extra!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (hasExtras)
            InkWell(
              onTap: onEditExtras,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Icon(Icons.tune, size: 16, color: AppColors.n500),
              ),
            ),
          if (editable)
            InkWell(
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(8),
              ),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(4, 6, 8, 6),
                child: Icon(Icons.close, size: 16, color: AppColors.n500),
              ),
            )
          else
            const SizedBox(width: 6),
        ],
      ),
    );
  }
}

/// Suche + Toggle. Bleibt offen, damit man mehrere Einträge hintereinander
/// verknüpfen kann; Häkchen = verknüpft, Klick schaltet um.
class _RelationPicker extends StatefulWidget {
  const _RelationPicker({
    required this.ctx,
    required this.spec,
    required this.backend,
    required this.initial,
    required this.onChanged,
  });

  final EditorContext ctx;
  final RelationSpec spec;
  final RelationBackend backend;
  final List<RelationLink> initial;
  final Future<void> Function() onChanged;

  @override
  State<_RelationPicker> createState() => _RelationPickerState();
}

class _RelationPickerState extends State<_RelationPicker> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<RelationLink> _results = const [];
  late final Set<String> _linked = widget.initial.map((l) => l.otherId).toSet();
  bool _loading = true;
  String? _busy;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    try {
      final res = await widget.backend.search(q);
      if (!mounted || q != _query.text) return;
      setState(() {
        _results = res;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _search(q));
  }

  void _toast(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
    );
  }

  Future<void> _toggle(RelationLink l) async {
    setState(() => _busy = l.otherId);
    try {
      if (_linked.contains(l.otherId)) {
        await widget.backend.remove(widget.ctx.id, l.otherId);
        _linked.remove(l.otherId);
      } else {
        await widget.backend.add(widget.ctx.id, l.otherId);
        _linked.add(l.otherId);
      }
      await widget.onChanged();
    } catch (e) {
      _toast(e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _create(String kind) async {
    final target = collectionById(kind);
    if (target == null) return;
    final title = _query.text.trim();
    final id = slugify(title);
    if (id.isEmpty) return;
    setState(() => _busy = '__new$kind');
    try {
      final repo = AdminRepository(widget.ctx.client);
      if (await repo.exists(target, id)) {
        throw StateError('„$id“ gibt es schon, bitte in der Liste wählen.');
      }
      await repo.insert(target, target.newRow(id, title));
      await widget.backend.add(widget.ctx.id, id);
      _linked.add(id);
      await widget.onChanged();
      _query.clear();
      await _search('');
    } catch (e) {
      _toast(e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _query.text.trim();
    final kinds = [
      for (final k in widget.spec.createKinds)
        if (collectionById(k) != null) collectionById(k)!,
    ];
    return Dialog(
      backgroundColor: AppColors.n50,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _query,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Suchen …',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) {
                  setState(() {});
                  _onQuery(v);
                },
              ),
              const SizedBox(height: 8),
              Flexible(
                child: _loading && _results.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final l in _results)
                            ListTile(
                              dense: true,
                              enabled: _busy == null,
                              title: Text(l.title),
                              subtitle:
                                  l.subtitle == null || l.subtitle!.isEmpty
                                  ? null
                                  : Text(l.subtitle!),
                              trailing: _busy == l.otherId
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      _linked.contains(l.otherId)
                                          ? Icons.check_circle
                                          : Icons.add_circle_outline,
                                      color: _linked.contains(l.otherId)
                                          ? AppColors.n900
                                          : AppColors.n400,
                                    ),
                              onTap: () => _toggle(l),
                            ),
                          if (_results.isEmpty && !_loading)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Nichts gefunden.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ),
                          if (q.isNotEmpty)
                            for (final k in kinds)
                              ListTile(
                                dense: true,
                                enabled: _busy == null,
                                leading: const Icon(Icons.add),
                                title: Text(
                                  '„$q“ neu als ${k.singular} anlegen',
                                ),
                                onTap: () => _create(k.id),
                              ),
                        ],
                      ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fertig'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
