import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/catalogs/icon_catalog.dart';
import '../../data/sammlung_providers.dart';
import '../../data/species_providers.dart';
import '../../domain/sammlung_ansicht.dart';
import 'sammlung_grids.dart';
import 'sammlung_listen.dart';

/// App-weite Sammlung: Umschalter Flora · Fauna · Geräte, Gruppen-Chips,
/// Funde vor offenen Einträgen. Spec: docs/sammlung/umbau-spec.md
class SammlungScreen extends ConsumerStatefulWidget {
  const SammlungScreen({super.key});

  @override
  ConsumerState<SammlungScreen> createState() => _SammlungScreenState();
}

class _SammlungScreenState extends ConsumerState<SammlungScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _waehleKategorie(String kategorie) {
    ref.read(sammlungKategorieProvider.notifier).waehle(kategorie);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final katalog = ref.watch(speciesCatalogProvider);
    final ansichtAsync = ref.watch(sammlungAnsichtProvider);
    final kategorie = ref.watch(sammlungKategorieProvider);
    final gruppe = ref.watch(sammlungGruppeProvider);

    Widget mitten(Widget child) =>
        Scaffold(body: SafeArea(bottom: false, child: child));

    if (katalog.hasError) {
      return mitten(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x6),
            child: Text(
              'Sammlung konnte nicht geladen werden.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final ansicht = ansichtAsync.asData?.value;
    if (ansicht == null) {
      return mitten(const Center(child: CircularProgressIndicator.adaptive()));
    }
    if (katalog.asData!.value.isEmpty) {
      return mitten(
        Center(
          child: Text(
            'Noch nichts hinterlegt.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
        ),
      );
    }

    final alle = gruppe == null;
    final naehe = alle
        ? ref.watch(sammlungNaeheProvider)
        : const <NaehTreffer>[];
    final katLabel = speciesKategorieEintrag(kategorie).label;

    return mitten(
      CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverToBoxAdapter(child: SammlungKopf(ansicht: ansicht)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterHeader(
              ansicht: ansicht,
              kategorie: kategorie,
              gruppe: gruppe,
              onKategorie: _waehleKategorie,
              onGruppe: (g) =>
                  ref.read(sammlungGruppeProvider.notifier).waehle(g),
              hintergrund: theme.scaffoldBackgroundColor,
            ),
          ),
          if (alle && ansicht.zuletzt.isNotEmpty)
            SliverToBoxAdapter(child: SammlungZuletzt(arten: ansicht.zuletzt)),
          if (naehe.isNotEmpty)
            SliverToBoxAdapter(child: SammlungNaehe(treffer: naehe)),
          if (ansicht.hatFunde) ...[
            SliverToBoxAdapter(
              child: SammlungBereichTitel(
                titel: 'Eure Funde',
                anzahl: ansicht.funde.length,
              ),
            ),
            if (ansicht.funde.isEmpty)
              SliverToBoxAdapter(
                child: SammlungLeerSatz(
                  alle
                      ? 'Aus $katLabel habt ihr noch nichts entdeckt.'
                      : 'Aus dieser Gruppe habt ihr noch nichts entdeckt.',
                ),
              )
            else
              SammlungGrid(arten: ansicht.funde, offen: false),
          ],
          if (ansicht.offen.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: SammlungBereichTitel(
                titel: 'Noch zu entdecken',
                anzahl: ansicht.offen.length,
              ),
            ),
            SammlungGrid(arten: ansicht.offen, offen: true),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.x6)),
        ],
      ),
    );
  }
}

/// Titel plus „{n} Funde · +{m} diese Woche“. Ohne Funde ein Hinweis.
class SammlungKopf extends StatelessWidget {
  const SammlungKopf({super.key, required this.ansicht});

  final SammlungAnsicht ansicht;

  static String zeile(SammlungAnsicht a) {
    if (!a.hatFunde) return 'Noch keine Funde';
    final n = a.fundeGesamt;
    final basis = n == 1 ? '1 Fund' : '$n Funde';
    return a.fundeWoche > 0 ? '$basis · +${a.fundeWoche} diese Woche' : basis;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.x4,
        AppSpacing.page,
        AppSpacing.x2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sammlung', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(
            zeile(ansicht),
            key: const ValueKey('sammlung-kopf-zeile'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
          if (!ansicht.hatFunde) ...[
            const SizedBox(height: AppSpacing.x2),
            Text(
              'Etwas vor Ort gesehen? Antippen und „Hab ich gesehen“ wählen.',
              key: const ValueKey('sammlung-kopf-hinweis'),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterHeader extends SliverPersistentHeaderDelegate {
  _FilterHeader({
    required this.ansicht,
    required this.kategorie,
    required this.gruppe,
    required this.onKategorie,
    required this.onGruppe,
    required this.hintergrund,
  });

  final SammlungAnsicht ansicht;
  final String kategorie;
  final String? gruppe;
  final ValueChanged<String> onKategorie;
  final ValueChanged<String?> onGruppe;
  final Color hintergrund;

  static const _umschalter = 56.0;
  static const _chips = 48.0;

  double get _hoehe => _umschalter + (ansicht.gruppen.isEmpty ? 0 : _chips);

  @override
  double get minExtent => _hoehe;

  @override
  double get maxExtent => _hoehe;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: hintergrund,
      child: Column(
        children: [
          SizedBox(
            height: _umschalter,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.page,
                vertical: AppSpacing.x2,
              ),
              child: KategorieUmschalter(
                ansicht: ansicht,
                kategorie: kategorie,
                onChanged: onKategorie,
              ),
            ),
          ),
          if (ansicht.gruppen.isNotEmpty)
            SizedBox(
              height: _chips,
              child: GruppenChips(
                gruppen: ansicht.gruppen,
                aktiv: gruppe,
                onChanged: onGruppe,
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_FilterHeader old) => true;
}

/// Flora · Fauna · Geräte, je mit der Anzahl Funde der Kategorie.
class KategorieUmschalter extends StatelessWidget {
  const KategorieUmschalter({
    super.key,
    required this.ansicht,
    required this.kategorie,
    required this.onChanged,
  });

  final SammlungAnsicht ansicht;
  final String kategorie;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      segments: [
        for (final k in sammlungKategorien)
          ButtonSegment(
            value: k,
            label: Text(
              '${speciesKategorieEintrag(k).label} ${ansicht.fundeIn(k)}',
              key: ValueKey('sammlung-segment-$k'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      selected: {kategorie},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// „Alle“ plus Gruppen der aktiven Kategorie, Einfachauswahl.
class GruppenChips extends StatelessWidget {
  const GruppenChips({
    super.key,
    required this.gruppen,
    required this.aktiv,
    required this.onChanged,
  });

  final List<String> gruppen;
  final String? aktiv;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.page,
        vertical: AppSpacing.x1,
      ),
      children: [
        _chip('Alle', aktiv == null, () => onChanged(null), 'alle'),
        for (final g in gruppen) ...[
          const SizedBox(width: AppSpacing.chip),
          _chip(gruppeEintrag(g).label, aktiv == g, () => onChanged(g), g),
        ],
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, String key) {
    return Center(
      child: ChoiceChip(
        key: ValueKey('sammlung-chip-$key'),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
