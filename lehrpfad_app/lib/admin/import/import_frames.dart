import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../core/field_spec.dart';
import 'import_models.dart';
import 'import_scope.dart';

Color toneColor(FieldTone t) => switch (t) {
  FieldTone.error => AppColors.statusError,
  FieldTone.warn => AppColors.statusWarn,
  FieldTone.info => AppColors.statusInfo,
  FieldTone.ok => AppColors.statusOk,
  FieldTone.locked => AppColors.statusLocked,
  FieldTone.none => AppColors.n300,
};

IconData toneIcon(FieldTone t) => switch (t) {
  FieldTone.error => Icons.error_outline,
  FieldTone.warn => Icons.warning_amber_rounded,
  FieldTone.info => Icons.auto_fix_high,
  FieldTone.ok => Icons.check_circle_outline,
  FieldTone.locked => Icons.lock_outline,
  FieldTone.none => Icons.circle_outlined,
};

String toneText(FieldState s) {
  switch (s.tone) {
    case FieldTone.error:
      return s.entries.any((e) => e.code == 'PFLICHT') ? 'Fehlt' : 'Klären';
    case FieldTone.warn:
      return 'Prüfen';
    case FieldTone.info:
      return s.fromKi ? 'Von KI ergänzt' : 'Korrigiert';
    case FieldTone.locked:
      return 'Gesperrt (im CMS bearbeitet)';
    case FieldTone.ok:
      return 'OK';
    case FieldTone.none:
      return '';
  }
}

/// Kleines Status-Label: Icon + Text, nie nur Farbe.
class StatusLabel extends StatelessWidget {
  const StatusLabel({super.key, required this.state, this.dense = false});

  final FieldState state;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (state.tone == FieldTone.none) return const SizedBox.shrink();
    final c = toneColor(state.tone);
    final text = toneText(state);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(toneIcon(state.tone), size: 14, color: c),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: c,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (state.locked && state.tone != FieldTone.locked) ...[
          const SizedBox(width: 8),
          const Icon(Icons.lock_outline, size: 13, color: AppColors.statusLocked),
        ],
      ],
    );
  }
}

/// Rahmen um ein Feld im Review: Randfarbe, Status, Meldungen mit Aktionen.
class ImportFieldFrame extends StatelessWidget {
  const ImportFieldFrame({super.key, required this.spec, required this.child});

  final FieldSpec spec;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final data = ImportScope.maybeOf(context);
    if (data == null) return child;
    final st = data.states.of(spec.key);
    final help = data.messages.hilfe[spec.key];
    final c = toneColor(st.tone);
    return Container(
      key: data.controller.keyFor(spec.key),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: c, width: 3)),
        color: st.tone == FieldTone.error
            ? AppColors.statusError.withValues(alpha: 0.04)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusLabel(state: st),
              const Spacer(),
              if (help != null)
                Tooltip(
                  message: help,
                  triggerMode: TooltipTriggerMode.tap,
                  showDuration: const Duration(seconds: 8),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.help_outline,
                      size: 16,
                      color: AppColors.n500,
                    ),
                  ),
                ),
            ],
          ),
          child,
          for (final e in st.entries)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: EntryTile(entry: e, data: data),
            ),
        ],
      ),
    );
  }
}

/// Rahmen um einen Block (Stationen, Arten, Bilder, Lebensräume).
class ImportBlockFrame extends StatelessWidget {
  const ImportBlockFrame({
    super.key,
    required this.blockKey,
    required this.child,
  });

  final String blockKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final data = ImportScope.maybeOf(context);
    if (data == null) return child;
    final st = data.states.of(blockKey);
    // Meldungen der Einzelzeilen (stationen[3]) gehören zum Block.
    final entries = st.entries;
    final tone = entries.isEmpty
        ? (st.locked ? FieldTone.locked : FieldTone.none)
        : st.tone;
    return Container(
      key: data.controller.keyFor(blockKey),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: toneColor(tone), width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tone != FieldTone.none)
            Align(
              alignment: Alignment.centerLeft,
              child: StatusLabel(
                state: FieldState(
                  tone: tone,
                  entries: entries,
                  locked: st.locked,
                ),
              ),
            ),
          if (st.locked)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Im CMS bearbeitet. Ein neuer Import überschreibt diesen Block nicht.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
              ),
            ),
          child,
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: EntryTile(entry: e, data: data),
            ),
        ],
      ),
    );
  }
}

/// Eine Meldung: Titel, Was/Warum/Wie, passende Ein-Klick-Aktionen.
class EntryTile extends StatefulWidget {
  const EntryTile({
    super.key,
    required this.entry,
    required this.data,
    this.showField = false,
  });

  final ReportEntry entry;
  final ImportScopeData data;

  /// In der Sammelliste: Feldname voranstellen.
  final bool showField;

  @override
  State<EntryTile> createState() => _EntryTileState();
}

class _EntryTileState extends State<EntryTile> {
  var _open = false;
  var _busy = false;

  ReportEntry get e => widget.entry;
  ImportReviewActions get actions => widget.data.actions;

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehlgeschlagen: $err')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = widget.data.messages.render(e);
    final tone = switch (e.severity) {
      Severity.hart => FieldTone.error,
      Severity.uebersteuerbar =>
        e.isOverridden ? FieldTone.info : FieldTone.error,
      Severity.warnung => e.code == 'FORM' ? FieldTone.info : FieldTone.warn,
    };
    final c = toneColor(tone);
    final buttons = <Widget>[
      if (e.vorschlag is String &&
          (e.code == 'TEXT_LAENGE') &&
          (e.vorschlag as String).isNotEmpty)
        FilledButton.tonalIcon(
          onPressed: _busy ? null : () => _run(() => actions.applyFix(e)),
          icon: const Icon(Icons.auto_fix_high, size: 16),
          label: const Text('Kürzungsvorschlag übernehmen'),
        ),
      if (e.code == 'ART_UNBEKANNT' || e.code == 'ART_UNSICHER')
        FilledButton.tonalIcon(
          onPressed: _busy ? null : () => _run(() => actions.resolveSpecies(e)),
          icon: const Icon(Icons.pets_outlined, size: 16),
          label: const Text('Zuordnen oder anlegen'),
        ),
      if (e.code == 'DUPLIKAT_NAH' || e.code == 'DUPLIKAT_MOEGLICH')
        FilledButton.tonalIcon(
          onPressed: _busy
              ? null
              : () => _run(() => actions.resolveDuplicate(e)),
          icon: const Icon(Icons.compare_arrows, size: 16),
          label: const Text('Vergleichen'),
        ),
      if (e.code == 'STATIONEN_MIN')
        FilledButton.tonalIcon(
          onPressed: _busy ? null : () => _run(actions.addStation),
          icon: const Icon(Icons.add_location_alt_outlined, size: 16),
          label: const Text('Station hinzufügen'),
        ),
      if (e.severity == Severity.uebersteuerbar && !e.isOverridden)
        OutlinedButton(
          onPressed: _busy ? null : () => _run(() => actions.overrideEntry(e)),
          child: const Text('Übersteuern …'),
        ),
      if (e.severity == Severity.warnung &&
          e.code != 'ART_UNBEKANNT' &&
          e.code != 'ART_UNSICHER' &&
          e.code != 'DUPLIKAT_NAH' &&
          e.code != 'DUPLIKAT_MOEGLICH')
        OutlinedButton(
          onPressed: _busy ? null : () => _run(() => actions.ack(e)),
          child: Text(e.code == 'FORM' ? 'Passt so' : 'Erledigt'),
        ),
      TextButton(
        onPressed: _busy ? null : () => _run(() => actions.ask(e)),
        child: const Text('Frage stellen'),
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(toneIcon(tone), size: 16, color: c),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.showField
                            ? '${widget.data.messages.feldLabel(e.feld)}: ${m.titel}'
                            : m.titel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (m.was.isNotEmpty)
                        Text(m.was, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppColors.n500,
                ),
              ],
            ),
          ),
          if (_open) ...[
            const SizedBox(height: 6),
            if (m.warum.isNotEmpty)
              Text(
                'Warum: ${m.warum}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            if (m.wie.isNotEmpty)
              Text(
                'Wie: ${m.wie}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
          ],
          if (e.isOverridden)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Übersteuert: ${e.overrideReason}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: buttons),
        ],
      ),
    );
  }
}
