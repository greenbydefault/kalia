import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'import_models.dart';

/// Änderungsvorschlag eines Re-Imports bei einem sichtbaren Pfad.
/// Der Pfad bleibt live unverändert, bis Teile angenommen werden.
class ProposalView extends StatefulWidget {
  const ProposalView({
    super.key,
    required this.job,
    required this.messages,
    required this.onApply,
    required this.onReject,
  });

  final ImportJob job;
  final ImportMessages messages;

  /// `null` = alles annehmen.
  final Future<void> Function(List<String>? teile) onApply;
  final Future<void> Function() onReject;

  @override
  State<ProposalView> createState() => _ProposalViewState();
}

class _ProposalViewState extends State<ProposalView> {
  late final Map<String, dynamic> _felder;
  late final Map<String, dynamic> _bloecke;
  final _sel = <String>{};
  var _busy = false;

  @override
  void initState() {
    super.initState();
    final p = widget.job.proposal ?? const {};
    _felder = Map<String, dynamic>.from((p['felder'] as Map?) ?? {});
    _bloecke = Map<String, dynamic>.from((p['bloecke'] as Map?) ?? {});
    // Gesperrte (im CMS bearbeitete) Felder sind vorab nicht angehakt.
    for (final e in _felder.entries) {
      if ((e.value as Map)['gesperrt'] != true) _sel.add(e.key);
    }
    _sel.addAll(_bloecke.keys);
  }

  Future<void> _go(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehlgeschlagen: $e')));
        setState(() => _busy = false);
      }
    }
  }

  String _show(dynamic v) {
    if (v == null || '$v'.isEmpty) return '(leer)';
    final t = '$v';
    return t.length > 400 ? '${t.substring(0, 400)} …' : t;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = [..._felder.keys, ..._bloecke.keys];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Neue Fassung des Dossiers', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Der Pfad ist sichtbar und bleibt unverändert, bis du Änderungen annimmst.',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
        ),
        const SizedBox(height: 16),
        if (all.isEmpty) const Text('Keine Unterschiede.'),
        for (final e in _felder.entries)
          _DiffTile(
            checked: _sel.contains(e.key),
            onChanged: (v) => setState(() {
              v == true ? _sel.add(e.key) : _sel.remove(e.key);
            }),
            title: widget.messages.feldLabel(e.key),
            locked: (e.value as Map)['gesperrt'] == true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Side(
                    label: 'Jetzt',
                    text: _show((e.value as Map)['alt']),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Side(
                    label: 'Neu',
                    text: _show((e.value as Map)['neu']),
                    highlight: true,
                  ),
                ),
              ],
            ),
          ),
        for (final e in _bloecke.entries)
          _DiffTile(
            checked: _sel.contains(e.key),
            onChanged: (v) => setState(() {
              v == true ? _sel.add(e.key) : _sel.remove(e.key);
            }),
            title: widget.messages.feldLabel(e.key),
            locked: ((widget.job.proposal?['gesperrt'] as List?) ?? const [])
                .contains(e.key),
            child: Text(
              '${(e.value as Map)['alt']} → ${(e.value as Map)['neu']}: '
              '${((e.value as Map)['aenderungen'] as List? ?? const []).join(', ')}',
            ),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: _busy || _sel.isEmpty
                  ? null
                  : () => _go(
                      () => widget.onApply(
                        _sel.length == all.length ? null : _sel.toList(),
                      ),
                    ),
              child: Text(
                _sel.length == all.length
                    ? 'Alles annehmen'
                    : 'Auswahl annehmen (${_sel.length})',
              ),
            ),
            OutlinedButton(
              onPressed: _busy ? null : () => _go(widget.onReject),
              child: const Text('Vorschlag verwerfen'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DiffTile extends StatelessWidget {
  const _DiffTile({
    required this.checked,
    required this.onChanged,
    required this.title,
    required this.child,
    this.locked = false,
  });

  final bool checked;
  final ValueChanged<bool?> onChanged;
  final String title;
  final Widget child;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: checked, onChanged: onChanged),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (locked) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: AppColors.statusLocked,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'im CMS bearbeitet',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.label, required this.text, this.highlight = false});

  final String label;
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.statusInfo.withValues(alpha: 0.08)
            : AppColors.n100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
          ),
          SelectableText(text),
        ],
      ),
    );
  }
}
