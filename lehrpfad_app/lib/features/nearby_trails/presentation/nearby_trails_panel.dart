import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/connectivity/offline_provider.dart';
import '../../../shared/catalogs/icon_catalog.dart';
import '../../../shared/widgets/bottom_content_card.dart';
import '../../../shared/widgets/placeholder_block.dart';
import '../../location/user_position_provider.dart';
import '../../trail/data/providers.dart';
import '../../trail/domain/gebiet.dart';
import '../../trail_progress/presentation/open_trail_on_map.dart';
import '../data/bezug_provider.dart';
import '../data/karte_state.dart';
import '../domain/bezugspunkt.dart';
import '../domain/karte_copy.dart';
import '../domain/karte_logik.dart';
import 'bezug_aktionen.dart';
import 'eintrag_karte.dart';
import 'filter_sheet.dart';
import 'ortssuche_page.dart';

/// Karte-Tab: ziehbares Sheet „In eurer Nähe“ über der Karte.
///
/// Drei Höhen (eingeklappt, halb, ganz), Kopf mit Titel, Bezugszeile und
/// Chip-Reihe bleibt oben stehen, darunter Abschnittszeile und Karten.
class NearbyTrailsPanel extends ConsumerStatefulWidget {
  const NearbyTrailsPanel({
    super.key,
    required this.onHeightChanged,
    this.bottomInset = 0,
  });

  /// Aktuelle Sheet-Höhe in Pixeln (für den Standort-Button).
  final ValueChanged<double> onHeightChanged;

  /// Platz für den Mini-Player unter der Liste.
  final double bottomInset;

  static const halbSize = 0.55;
  static const ganzSize = 0.92;

  /// Fester Kopf: Griff, Titel, Bezugszeile, Chips.
  static const kopfHoehe = 160.0;

  /// Karten pro Seite beim Nachladen.
  static const seite = 20;

  @override
  ConsumerState<NearbyTrailsPanel> createState() => _NearbyTrailsPanelState();
}

class _NearbyTrailsPanelState extends ConsumerState<NearbyTrailsPanel> {
  final _sheet = DraggableScrollableController();
  ScrollController? _scroll;
  bool _scrollInit = false;
  Timer? _settle;
  bool _programmatisch = false;
  double _lastReported = -1;
  double _minSize = 0.25;
  int _gezeigt = NearbyTrailsPanel.seite;

  @override
  void initState() {
    super.initState();
    ref.listenManual(sheetHoeheProvider, (prev, next) => _animiereZu(next));
    ref.listenManual(karteRetapProvider, (_, _) {
      _nachOben();
      if (ref.read(sheetHoeheProvider) == SheetHoehe.ganz) {
        ref.read(sheetHoeheProvider.notifier).set(SheetHoehe.halb);
      }
    });
    ref.listenManual(listeNachObenProvider, (_, _) => _nachOben());
    ref.listenManual(standortZustandProvider, (prev, next) {
      if (next == StandortZustand.erteiltTimeout &&
          prev != StandortZustand.erteiltTimeout &&
          ref.read(aktuellerBezugProvider) != null) {
        _zeigeStandortFehler();
      }
    });
    // Neue Menge (Gebiet, Filter, Sortierung, Bezugspunkt): wieder 20.
    for (final p in [gebietProvider, karteFilterProvider, sortierungProvider]) {
      ref.listenManual(p, (_, _) => _gezeigt = NearbyTrailsPanel.seite);
    }
  }

  @override
  void dispose() {
    _settle?.cancel();
    final report = widget.onHeightChanged;
    WidgetsBinding.instance.addPostFrameCallback((_) => report(0));
    _sheet.dispose();
    super.dispose();
  }

  double _groesse(SheetHoehe h) => switch (h) {
    SheetHoehe.eingeklappt => _minSize,
    SheetHoehe.halb => NearbyTrailsPanel.halbSize,
    SheetHoehe.ganz => NearbyTrailsPanel.ganzSize,
  };

  void _animiereZu(SheetHoehe h) {
    if (!_sheet.isAttached) return;
    final ziel = _groesse(h);
    if ((_sheet.size - ziel).abs() < 0.01) return;
    _programmatisch = true;
    _sheet
        .animateTo(
          ziel,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() => _programmatisch = false);
  }

  /// Nach dem Loslassen: nächstgelegene Höhe in den Provider schreiben.
  void _erkenneSnap() {
    if (!mounted || !_sheet.isAttached) return;
    var best = SheetHoehe.halb;
    var abstand = double.infinity;
    for (final h in SheetHoehe.values) {
      final d = (_sheet.size - _groesse(h)).abs();
      if (d < abstand) {
        abstand = d;
        best = h;
      }
    }
    if (best != ref.read(sheetHoeheProvider)) {
      ref.read(sheetHoeheProvider.notifier).set(best);
    }
  }

  void _nachOben() {
    _gezeigt = NearbyTrailsPanel.seite;
    final c = _scroll;
    if (c != null && c.hasClients) {
      c.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _report(double px) {
    if ((px - _lastReported).abs() < 0.5) return;
    _lastReported = px;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onHeightChanged(px);
    });
  }

  void _zeigeStandortFehler() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(kt('fehler.standort')),
          action: SnackBarAction(
            label: kt('allg.erneut'),
            onPressed: () =>
                ref.read(userPositionProvider.notifier).refresh(force: true),
          ),
        ),
      );
  }

  void _anScrollHaengen(ScrollController c) {
    if (identical(_scroll, c)) return;
    _scroll = c;
    if (_scrollInit) return;
    _scrollInit = true;
    c.addListener(() {
      if (c.hasClients) {
        ref.read(karteScrollProvider.notifier).set(c.offset);
      }
      if (c.hasClients &&
          c.position.extentAfter < 400 &&
          _gezeigt < (ref.read(karteAnzeigeProvider)?.n ?? 0)) {
        setState(() => _gezeigt += NearbyTrailsPanel.seite);
      }
    });
    final gespeichert = ref.read(karteScrollProvider);
    if (gespeichert > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (c.hasClients) {
          c.jumpTo(gespeichert.clamp(0.0, c.position.maxScrollExtent));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hoehe = ref.watch(sheetHoeheProvider);
    final ganz = hoehe == SheetHoehe.ganz;
    final keinStart = ref.watch(aktuellerBezugProvider) == null;

    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        _minSize = ((NearbyTrailsPanel.kopfHoehe + AppSpacing.x2) / h).clamp(
          0.15,
          0.4,
        );
        final aktuell = _groesse(hoehe);
        _report(aktuell * h);
        return Stack(
          children: [
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (n) {
                _report(n.extent * h);
                _settle?.cancel();
                if (!_programmatisch) {
                  _settle = Timer(
                    const Duration(milliseconds: 150),
                    _erkenneSnap,
                  );
                }
                return false;
              },
              child: DraggableScrollableSheet(
                controller: _sheet,
                initialChildSize: aktuell,
                minChildSize: _minSize,
                maxChildSize: NearbyTrailsPanel.ganzSize,
                snap: true,
                snapSizes: [
                  _minSize,
                  NearbyTrailsPanel.halbSize,
                  NearbyTrailsPanel.ganzSize,
                ],
                builder: (context, scrollController) {
                  _anScrollHaengen(scrollController);
                  return DecoratedBox(
                    decoration: BottomContentCard.decoration(theme),
                    child: ClipRRect(
                      borderRadius: BottomContentCard.topRadius,
                      child: CustomScrollView(
                        controller: scrollController,
                        slivers: [
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _KopfDelegate(
                              child: _Kopf(keinStart: keinStart),
                            ),
                          ),
                          ..._inhalt(theme),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height:
                                  AppSpacing.x5 +
                                  widget.bottomInset +
                                  (ganz ? 60 : 0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (ganz)
              Positioned(
                left: 0,
                right: 0,
                bottom: AppSpacing.x4 + widget.bottomInset,
                child: Center(
                  child: Theme(
                    data: theme.copyWith(
                      floatingActionButtonTheme: theme.floatingActionButtonTheme
                          .copyWith(
                            extendedSizeConstraints:
                                const BoxConstraints.tightFor(height: 44),
                            extendedPadding: const EdgeInsetsDirectional.only(
                              start: 14,
                              end: 16,
                            ),
                            extendedIconLabelSpacing: 6,
                          ),
                    ),
                    child: FloatingActionButton.extended(
                      heroTag: null,
                      onPressed: () => ref
                          .read(sheetHoeheProvider.notifier)
                          .set(SheetHoehe.halb),
                      icon: const PhosphorIcon(
                        PhosphorIcons.mapTrifold,
                        size: 18,
                      ),
                      label: Text(kt('karte.kartenButton')),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Inhalt je Zustand
  // -------------------------------------------------------------------------

  List<Widget> _inhalt(ThemeData theme) {
    const rand = EdgeInsets.symmetric(horizontal: AppSpacing.x5);
    Widget block(Widget w) => SliverPadding(
      padding: rand,
      sliver: SliverToBoxAdapter(child: w),
    );

    final trailsAsync = ref.watch(trailsProvider);
    final offline = ref.watch(offlineProvider);
    final bezug = ref.watch(aktuellerBezugProvider);
    final zustand = ref.watch(standortZustandProvider);
    final anzeige = ref.watch(karteAnzeigeProvider);

    final out = <Widget>[];
    if (offline) {
      out.add(
        block(
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.x2),
            child: Row(
              children: [
                const PhosphorIcon(
                  PhosphorIcons.wifiSlash,
                  size: 16,
                  color: AppColors.inkMuted,
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Text(
                    kt('offline.hinweis'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // E8: Laden fehlgeschlagen.
    if (trailsAsync.hasError && anzeige == null) {
      out.add(
        block(
          _Meldung(
            text: kt('fehler.laden'),
            primaer: kt('allg.erneut'),
            onPrimaer: () => ref.invalidate(trailsProvider),
          ),
        ),
      );
      return out;
    }

    // E1 und E2: Skeletons.
    final ermittelt =
        bezug == null && zustand == StandortZustand.erteiltErmittelt;
    if (anzeige == null || ermittelt) {
      out.add(
        SliverPadding(
          padding: rand,
          sliver: SliverList.list(
            children: [
              const SizedBox(height: AppSpacing.x3),
              for (var i = 0; i < 3; i++) const _Skeleton(),
            ],
          ),
        ),
      );
      return out;
    }

    // E3: kein Startpunkt, dazu alle Einträge nach Name.
    if (bezug == null) {
      out.add(
        block(
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.x3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(kt('leer.keinStart'), style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.x4),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => openOrtssuche(context),
                  child: Text(kt('leer.keinStart.ort')),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () =>
                      BezugAktionen(ref).zentriereAufStandort(context),
                  child: Text(kt('leer.keinStart.standort')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // E5, E6, E7.
    final leer = anzeige.leer;
    if (leer != null) {
      out.add(block(_LeerZustand(fall: leer)));
      return out;
    }

    // Abschnittszeile.
    final alleModus = bezug == null || anzeige.modus == ListenModus.alle;
    final filter = ref.watch(karteFilterProvider);
    out.add(
      block(
        SizedBox(
          height: 52,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  alleModus
                      ? listenAnzahlText(anzeige.n, filter)
                      : kt('liste.vorschlaege'),
                  style: theme.textTheme.titleSmall,
                ),
              ),
              if (bezug != null && !alleModus)
                TextButton(
                  onPressed: () => zeigeAlle(ref),
                  child: Text(kt('liste.alleAnzeigen', {'n': anzeige.n})),
                ),
              if (bezug != null && alleModus) const _SortierMenue(),
            ],
          ),
        ),
      ),
    );

    // Karten.
    final byId = ref.watch(trailsByIdProvider);
    final coachKey = ref.watch(coachTargetKeyProvider);
    final liste = alleModus
        ? anzeige.sichtbar.take(_gezeigt).toList()
        : anzeige.sichtbar;
    var coachVergeben = false;
    out.add(
      SliverPadding(
        padding: rand,
        sliver: SliverList.builder(
          itemCount: liste.length,
          itemBuilder: (context, i) {
            final t = liste[i];
            final trail = byId[t.eintrag.id];
            if (trail == null) return const SizedBox.shrink();
            GlobalKey? key;
            if (!coachVergeben && t.eintrag.audio != null) {
              coachVergeben = true;
              key = coachKey;
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.x3),
              child: EintragKarte(
                key: ValueKey(t.eintrag.id),
                treffer: t,
                trail: trail,
                hoerenKey: key,
              ),
            );
          },
        ),
      ),
    );
    return out;
  }
}

class _KopfDelegate extends SliverPersistentHeaderDelegate {
  _KopfDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => NearbyTrailsPanel.kopfHoehe;

  @override
  double get maxExtent => NearbyTrailsPanel.kopfHoehe;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(covariant _KopfDelegate oldDelegate) => true;
}

/// Griff, Titel, Bezugszeile, Chip-Reihe.
class _Kopf extends ConsumerWidget {
  const _Kopf({required this.keinStart});

  final bool keinStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hoehe = ref.watch(sheetHoeheProvider);
    final a11y = switch (hoehe) {
      SheetHoehe.eingeklappt => kt('a11y.listeEingeklappt'),
      SheetHoehe.halb => kt('a11y.listeHalb'),
      SheetHoehe.ganz => kt('a11y.listeAusgeklappt'),
    };
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: a11y,
            button: true,
            onTap: () => ref
                .read(sheetHoeheProvider.notifier)
                .set(
                  hoehe == SheetHoehe.ganz ? SheetHoehe.halb : SheetHoehe.ganz,
                ),
            child: const BottomContentCardHandle(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
            child: SizedBox(
              height: 36,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  keinStart ? kt('karte.titel.keinStart') : kt('karte.titel'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
            ),
          ),
          const _Bezugszeile(),
          const SizedBox(height: AppSpacing.x1),
          const _ChipReihe(),
          const SizedBox(height: AppSpacing.x2),
        ],
      ),
    );
  }
}

/// „Rund um {ort}, bis 30 Min Anfahrt“. Tipp öffnet die Ortssuche.
class _Bezugszeile extends ConsumerWidget {
  const _Bezugszeile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bezug = ref.watch(aktuellerBezugProvider);
    final umkreis = ref.watch(umkreisProvider);
    final ermittelt =
        ref.watch(standortZustandProvider) == StandortZustand.erteiltErmittelt;
    final text = bezugszeileText(
      bezug: bezug,
      umkreis: umkreis,
      ermittelt: ermittelt,
    );
    final icon = bezug?.quelle == BezugQuelle.gps
        ? PhosphorIcons.navigationArrow
        : PhosphorIcons.mapPin;
    return Semantics(
      button: true,
      label: text,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => openOrtssuche(context),
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
            child: Row(
              children: [
                PhosphorIcon(icon, size: 18),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const PhosphorIcon(PhosphorIcons.caretRight, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Filter | Alle und sieben Gebiete, horizontal scrollbar. Das gewählte
/// Gebiet wird ins Bild gescrollt, erneutes Tippen wählt „Alle“.
class _ChipReihe extends ConsumerStatefulWidget {
  const _ChipReihe();

  @override
  ConsumerState<_ChipReihe> createState() => _ChipReiheState();
}

class _ChipReiheState extends ConsumerState<_ChipReihe> {
  final _keys = {for (final g in Gebiet.values) g: GlobalKey()};
  final _alleKey = GlobalKey();

  void _insBild(Gebiet? g) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = (g == null ? _alleKey : _keys[g])?.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gebiet = ref.watch(gebietProvider);
    final aktiv = ref.watch(karteFilterProvider).anzahlAktiv;
    ref.listen(gebietProvider, (_, next) => _insBild(next));

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
        children: [
          KarteChip(
            label: aktiv > 0
                ? kt('chip.filterAnzahl', {'n': aktiv})
                : kt('chip.filter'),
            icon: PhosphorIcons.slidersHorizontal,
            selected: aktiv > 0,
            onTap: () => openFilterSheet(context),
          ),
          const SizedBox(width: AppSpacing.x2),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
            color: AppColors.hairline,
          ),
          const SizedBox(width: AppSpacing.x2),
          KarteChip(
            key: _alleKey,
            label: kt('chip.alle'),
            selected: gebiet == null,
            onTap: () => ref.read(gebietProvider.notifier).set(null),
          ),
          for (final g in Gebiet.values) ...[
            const SizedBox(width: AppSpacing.x2),
            KarteChip(
              key: _keys[g],
              label: kt('gebiet.${g.key}'),
              icon: gebietIcons[g],
              selected: gebiet == g,
              onTap: () => ref.read(gebietProvider.notifier).toggle(g),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chip mit 44 pt Touch-Ziel.
class KarteChip extends StatelessWidget {
  const KarteChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final farbe = selected ? AppColors.paper : AppColors.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.ink : AppColors.n100,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.ink : AppColors.hairline,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    PhosphorIcon(icon!, size: 16, color: farbe),
                    const SizedBox(width: AppSpacing.x2),
                  ],
                  Text(
                    label,
                    style:
                        (theme.chipTheme.labelStyle ??
                                theme.textTheme.labelLarge)
                            ?.copyWith(color: farbe),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SortierMenue extends ConsumerWidget {
  const _SortierMenue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aktuell = ref.watch(sortierungProvider);
    return PopupMenuButton<Sortierung>(
      initialValue: aktuell,
      onSelected: ref.read(sortierungProvider.notifier).set,
      itemBuilder: (_) => [
        for (final s in Sortierung.values)
          PopupMenuItem(value: s, child: Text(s.text)),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(aktuell.text, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(width: AppSpacing.x1),
            const PhosphorIcon(PhosphorIcons.caretDown, size: 14),
          ],
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.x3),
      child: PlaceholderBlock(
        height: 180,
        radius: AppSpacing.x5,
        color: AppColors.n100,
      ),
    );
  }
}

/// Text mit einem primären und optional sekundären Schritt.
class _Meldung extends StatelessWidget {
  const _Meldung({
    required this.text,
    this.primaer,
    this.onPrimaer,
    this.sekundaer,
    this.onSekundaer,
  });

  final String text;
  final String? primaer;
  final VoidCallback? onPrimaer;
  final String? sekundaer;
  final VoidCallback? onSekundaer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
          if (primaer != null) ...[
            const SizedBox(height: AppSpacing.x4),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: onPrimaer,
              child: Text(primaer!),
            ),
          ],
          if (sekundaer != null)
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: onSekundaer,
              child: Text(sekundaer!),
            ),
        ],
      ),
    );
  }
}

/// E5, E6, E7.
class _LeerZustand extends ConsumerWidget {
  const _LeerZustand({required this.fall});

  final LeerFall fall;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final umkreis = ref.watch(umkreisProvider);
    switch (fall.art) {
      case LeerArt.umkreis:
        final n = fall.naechster!;
        final erweitern = fall.erweitern!;
        return _Meldung(
          text: kt('leer.umkreis', {
            'umkreis': umkreis.kurz,
            'name': n.eintrag.name,
            'anfahrt': formatAnfahrt(n.anfahrtMin ?? 0),
          }),
          primaer: kt('leer.umkreis.erweitern', {'umkreis': erweitern.kurz}),
          onPrimaer: () => ref.read(umkreisProvider.notifier).set(erweitern),
          sekundaer: kt('leer.umkreis.ansehen', {'name': n.eintrag.name}),
          onSekundaer: () {
            final trail = ref.read(trailsByIdProvider)[n.eintrag.id];
            if (trail != null)
              openTrailOnMap(context, ref, trail, detail: true);
          },
        );
      case LeerArt.filter:
        return _Meldung(
          text: kt('leer.filter'),
          primaer: kt('leer.filter.zuruecksetzen'),
          onPrimaer: () {
            ref.read(gebietProvider.notifier).set(null);
            ref
                .read(karteFilterProvider.notifier)
                .uebernehmen(KarteFilter.standard);
          },
          sekundaer: kt('leer.filter.aendern'),
          onSekundaer: () => openFilterSheet(context),
        );
      case LeerArt.region:
        return _Meldung(
          text: kt('leer.region'),
          primaer: kt('leer.region.naechster'),
          onPrimaer: () => ref.read(umkreisProvider.notifier).set(Umkreis.egal),
        );
    }
  }
}
