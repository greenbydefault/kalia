import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/show_app_modal_sheet.dart';
import '../data/bezug_provider.dart';
import '../data/karte_state.dart';
import '../domain/eintrag.dart';
import '../domain/karte_copy.dart';
import '../domain/karte_logik.dart';
import 'ortssuche_page.dart';

/// Filter-Sheet über der Shell, die Navigation ist verdeckt. Änderungen
/// gelten erst mit „Ergebnisse anzeigen“. Schließen verwirft sie.
Future<void> openFilterSheet(BuildContext context) {
  return showAppModalSheet<void>(
    context: context,
    builder: (_) => const _FilterSheet(),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late KarteFilter _filter = ref.read(karteFilterProvider);
  late Umkreis _umkreis = ref.read(umkreisProvider);
  bool _minHinweis = false;

  static const _merkmale = <(Merkmal, String)>[
    (Merkmal.kinderwagen, 'filter.merkmal.kinderwagen'),
    (Merkmal.barrierefrei, 'merkmal.barrierefrei'),
    (Merkmal.rundkurs, 'merkmal.rundkurs'),
    (Merkmal.parkplatz, 'merkmal.parkplatz'),
    (Merkmal.wc, 'filter.merkmal.wc'),
    (Merkmal.einkehr, 'merkmal.einkehr'),
  ];

  int _anzahl() {
    final alle = ref.read(eintraegeProvider) ?? const [];
    return berechneMenge(
      alle,
      bezug: ref.read(bezugCoordsProvider),
      umkreis: _umkreis,
      gebiet: ref.read(gebietProvider),
      filter: _filter,
    ).length;
  }

  void _toggleArt(EintragArt art) {
    final arten = {..._filter.arten};
    if (arten.contains(art)) {
      if (arten.length == 1) {
        setState(() => _minHinweis = true);
        return;
      }
      arten.remove(art);
    } else {
      arten.add(art);
    }
    setState(() {
      _minHinweis = false;
      _filter = _filter.copyWith(arten: arten);
    });
  }

  void _toggleMerkmal(Merkmal m) {
    final set = {..._filter.merkmale};
    set.contains(m) ? set.remove(m) : set.add(m);
    setState(() => _filter = _filter.copyWith(merkmale: set));
  }

  void _zuruecksetzen() => setState(() {
    _filter = KarteFilter.standard;
    _umkreis = Umkreis.standard;
    _minHinweis = false;
  });

  Future<void> _anwenden() async {
    final nav = Navigator.of(context);
    await ref.read(umkreisProvider.notifier).set(_umkreis);
    await ref.read(karteFilterProvider.notifier).uebernehmen(_filter);
    ref.read(listeNachObenProvider.notifier).trigger();
    if (mounted) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = _anzahl();
    final keine = n == 0;
    final dirty = !_filter.istStandard || _umkreis != Umkreis.standard;

    Widget gruppe(String titelKey, Widget child) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kt(titelKey), style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.x2),
          child,
        ],
      ),
    );

    Widget wahl<T>(
      Map<T, String> optionen,
      T? aktuell,
      ValueChanged<T?> onChanged,
    ) => Wrap(
      spacing: AppSpacing.x2,
      runSpacing: AppSpacing.x2,
      children: [
        for (final o in optionen.entries)
          ChoiceChip(
            label: Text(kt(o.value)),
            selected: aktuell == o.key,
            // Erneut tippen hebt die Auswahl auf.
            onSelected: (_) => onChanged(aktuell == o.key ? null : o.key),
          ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                kt('filter.titel'),
                style: theme.textTheme.titleLarge,
              ),
            ),
            TextButton(
              onPressed: dirty ? _zuruecksetzen : null,
              child: Text(kt('filter.zuruecksetzen')),
            ),
            IconButton(
              tooltip: kt('allg.schliessen'),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        gruppe(
          'filter.anfahrt',
          UmkreisAuswahl(
            wert: _umkreis,
            onChanged: (u) => setState(() => _umkreis = u),
          ),
        ),
        gruppe(
          'filter.was',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.x2,
                runSpacing: AppSpacing.x2,
                children: [
                  FilterChip(
                    label: Text(kt('filter.wege')),
                    selected: _filter.arten.contains(EintragArt.weg),
                    onSelected: (_) => _toggleArt(EintragArt.weg),
                  ),
                  FilterChip(
                    label: Text(kt('filter.orte')),
                    selected: _filter.arten.contains(EintragArt.ort),
                    onSelected: (_) => _toggleArt(EintragArt.ort),
                  ),
                ],
              ),
              if (_minHinweis)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.x2),
                  child: Text(
                    kt('filter.wasMinEins'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
        gruppe(
          'filter.dauer',
          wahl<DauerBereich>(
            const {
              DauerBereich.bis1Std: 'filter.dauer.bis1',
              DauerBereich.von1bis2Std: 'filter.dauer.1bis2',
              DauerBereich.ueber2Std: 'filter.dauer.ueber2',
            },
            _filter.dauer,
            (d) => setState(
              () => _filter = d == null
                  ? _filter.copyWith(dauerLeeren: true)
                  : _filter.copyWith(dauer: d),
            ),
          ),
        ),
        gruppe(
          'filter.laenge',
          wahl<LaengeBereich>(
            const {
              LaengeBereich.bis3km: 'filter.laenge.bis3',
              LaengeBereich.bis5km: 'filter.laenge.bis5',
              LaengeBereich.ueber5km: 'filter.laenge.ueber5',
            },
            _filter.laenge,
            (l) => setState(
              () => _filter = l == null
                  ? _filter.copyWith(laengeLeeren: true)
                  : _filter.copyWith(laenge: l),
            ),
          ),
        ),
        gruppe(
          'filter.merkmale',
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              for (final (m, key) in _merkmale)
                FilterChip(
                  label: Text(kt(key)),
                  selected: _filter.merkmale.contains(m),
                  onSelected: (_) => _toggleMerkmal(m),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x5),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: keine ? null : _anwenden,
          child: Text(
            keine
                ? kt('filter.keineTreffer')
                : n == 1
                ? kt('filter.anzeigen.eins')
                : kt('filter.anzeigen', {'n': n}),
          ),
        ),
        if (keine)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.x2),
            child: Text(
              kt('filter.hinweisLeer'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ),
      ],
    );
  }
}
