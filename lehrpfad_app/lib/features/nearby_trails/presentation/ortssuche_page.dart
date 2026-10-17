import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../onboarding/data/place_search.dart';
import '../../onboarding/domain/user_place.dart';
import '../../trail/data/providers.dart';
import '../../trail_progress/presentation/open_trail_on_map.dart';
import '../data/bezug_provider.dart';
import '../data/karte_state.dart';
import '../domain/bezugspunkt.dart';
import '../domain/eintrag.dart';
import '../domain/karte_copy.dart';
import '../domain/karte_logik.dart';
import 'bezug_aktionen.dart';

/// Vollbild-Ortssuche. Erreichbar über Bezugszeile und „Suchen“ in der
/// Kartenleiste. Die Navigation ist verdeckt, weil das Overlay über der
/// Shell liegt.
Future<void> openOrtssuche(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => const OrtssuchePage(),
      fullscreenDialog: true,
    ),
  );
}

class OrtssuchePage extends ConsumerStatefulWidget {
  const OrtssuchePage({super.key});

  @override
  ConsumerState<OrtssuchePage> createState() => _OrtssuchePageState();
}

class _OrtssuchePageState extends ConsumerState<OrtssuchePage> {
  static const _debounce = Duration(milliseconds: 300);
  static const _minChars = 2;

  final _controller = TextEditingController();
  Timer? _timer;
  String _query = '';

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    _timer?.cancel();
    if (raw.trim().length < _minChars) {
      setState(() => _query = '');
      return;
    }
    _timer = Timer(_debounce, () {
      if (mounted) setState(() => _query = raw.trim());
    });
  }

  Future<void> _waehleOrt(UserPlace place) async {
    final nav = Navigator.of(context);
    await BezugAktionen(ref).waehleOrt(place);
    ref.read(sheetHoeheProvider.notifier).set(SheetHoehe.halb);
    if (mounted) nav.pop();
  }

  Future<void> _waehleEintrag(Eintrag e) async {
    final trails = ref.read(trailsProvider).asData?.value;
    if (trails == null) return;
    final trail = trails.where((t) => t.id == e.id).firstOrNull;
    if (trail == null) return;
    final nav = Navigator.of(context);
    nav.pop();
    // Kontext der Karte, nicht der geschlossenen Seite.
    await openTrailOnMap(nav.context, ref, trail, detail: true);
  }

  Future<void> _meinStandort() async {
    final nav = Navigator.of(context);
    final navContext = nav.context;
    await BezugAktionen(ref).zentriereAufStandort(context);
    if (!mounted) return;
    final zustand = ref.read(standortZustandProvider);
    if (zustand == StandortZustand.erteiltPositionDa) {
      ref.read(sheetHoeheProvider.notifier).set(SheetHoehe.halb);
      if (navContext.mounted) nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: kt('allg.zurueck'),
                  onPressed: () => Navigator.of(context).pop(),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const PhosphorIcon(PhosphorIcons.caretLeft, size: 24),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    autocorrect: false,
                    textInputAction: TextInputAction.search,
                    onChanged: _onChanged,
                    decoration: InputDecoration(
                      hintText: kt('suche.platzhalter'),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
              ],
            ),
            const Divider(height: 1, color: AppColors.hairline),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(AppSpacing.x4),
                children: _query.isEmpty
                    ? _ohneEingabe(theme)
                    : _ergebnisse(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ohne Eingabe -------------------------------------------------------

  List<Widget> _ohneEingabe(ThemeData theme) {
    final zustand = ref.watch(standortZustandProvider);
    final zuletzt = ref.watch(karteBezugProvider).zuletzt;
    final umkreis = ref.watch(umkreisProvider);
    final standortText = switch (zustand) {
      StandortZustand.abgelehnt => kt('suche.standortFreigeben'),
      StandortZustand.dauerhaftAbgelehnt => kt('suche.einstellungen'),
      _ => kt('suche.meinStandort'),
    };
    return [
      _Zeile(
        icon: PhosphorIcons.crosshair,
        text: standortText,
        onTap: _meinStandort,
      ),
      if (zuletzt.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.x4),
        _Ueberschrift(kt('suche.zuletzt')),
        for (final p in zuletzt)
          _Zeile(
            icon: PhosphorIcons.clockCounterClockwise,
            text: p.label,
            onTap: () => _waehleOrt(p),
          ),
      ],
      const SizedBox(height: AppSpacing.x4),
      _Ueberschrift(kt('suche.anfahrtHoechstens')),
      UmkreisAuswahl(
        wert: umkreis,
        onChanged: (u) => ref.read(umkreisProvider.notifier).set(u),
      ),
    ];
  }

  // --- Ergebnisse ---------------------------------------------------------

  List<Widget> _ergebnisse(ThemeData theme) {
    final index = ref.watch(placeIndexProvider).asData?.value;
    final orte = index?.search(_query, limit: 5) ?? const <UserPlace>[];
    final eintraege = sucheEintraege(
      ref.watch(eintraegeProvider) ?? const <Eintrag>[],
      _query,
    );
    if (orte.isEmpty && eintraege.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x4),
          child: Text(
            kt('suche.leer', {'q': _query}),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
        ),
      ];
    }
    return [
      if (orte.isNotEmpty) ...[
        _Ueberschrift(kt('suche.gruppeOrte')),
        for (final p in orte)
          _Zeile(
            icon: PhosphorIcons.mapPin,
            text: p.label,
            onTap: () => _waehleOrt(p),
          ),
        const SizedBox(height: AppSpacing.x4),
      ],
      if (eintraege.isNotEmpty) ...[
        _Ueberschrift(kt('suche.gruppeEintraege')),
        for (final e in eintraege)
          _Zeile(
            icon: PhosphorIcons.path,
            text: e.name,
            untertitel: e.typLabel,
            onTap: () => _waehleEintrag(e),
          ),
      ],
    ];
  }
}

class _Ueberschrift extends StatelessWidget {
  const _Ueberschrift(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.x2),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(color: AppColors.inkMuted),
    ),
  );
}

class _Zeile extends StatelessWidget {
  const _Zeile({
    required this.icon,
    required this.text,
    required this.onTap,
    this.untertitel,
  });

  final PhosphorIconData icon;
  final String text;
  final String? untertitel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Row(
          children: [
            PhosphorIcon(icon, size: 20),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(text, style: theme.textTheme.bodyLarge),
                  if (untertitel != null)
                    Text(
                      untertitel!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 15 Min, 30 Min, 1 Std, Egal. Einmal gebaut für Ortssuche und Filter-Sheet.
class UmkreisAuswahl extends StatelessWidget {
  const UmkreisAuswahl({
    super.key,
    required this.wert,
    required this.onChanged,
  });

  final Umkreis wert;
  final ValueChanged<Umkreis> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.x2,
      runSpacing: AppSpacing.x2,
      children: [
        for (final u in Umkreis.values)
          ChoiceChip(
            label: Text(u.kurz),
            selected: u == wert,
            onSelected: (_) => onChanged(u),
          ),
      ],
    );
  }
}
