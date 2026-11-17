import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/catalogs/icon_catalog.dart';
import '../../data/sammlung_providers.dart';
import '../../domain/species.dart';
import '../species_detail_sheet.dart';
import '../species_glyph.dart';

/// Überschrift eines Bereichs mit Anzahl im aktuellen Filter.
class SammlungBereichTitel extends StatelessWidget {
  const SammlungBereichTitel({super.key, required this.titel, this.anzahl});

  final String titel;
  final int? anzahl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.section,
        AppSpacing.page,
        AppSpacing.afterHeading,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            titel,
            style: theme.textTheme.titleSmall?.copyWith(color: AppColors.ink),
          ),
          if (anzahl != null) ...[
            const SizedBox(width: AppSpacing.x2),
            Text(
              '$anzahl',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Satz statt Kacheln, wenn ein Bereich leer ist.
class SammlungLeerSatz extends StatelessWidget {
  const SammlungLeerSatz(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
      ),
    );
  }
}

/// 3er-Grid. [offen] zeigt Silhouetten, sonst farbige Funde.
class SammlungGrid extends StatelessWidget {
  const SammlungGrid({super.key, required this.arten, required this.offen});

  final List<Species> arten;
  final bool offen;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.x2,
      ),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => SammlungKachel(species: arten[i], offen: offen),
          childCount: arten.length,
        ),
      ),
    );
  }
}

/// Eine Kachel: Fund (farbig, Seltenheit) oder offen (Silhouette).
class SammlungKachel extends ConsumerWidget {
  const SammlungKachel({super.key, required this.species, required this.offen});

  final Species species;
  final bool offen;

  /// Häufige Arten bekommen keine Markierung, sonst wäre sie überall.
  static bool zeigtSeltenheit(Species s) =>
      s.seltenheit.isNotEmpty && s.seltenheit != 'haeufig';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frisch = ref.watch(
      sammlungFrischProvider.select((id) => id == species.id),
    );
    return Material(
      color: AppColors.n100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: frisch
            ? const BorderSide(color: AppColors.ink, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        key: ValueKey('sammlung-kachel-${species.id}'),
        borderRadius: BorderRadius.circular(10),
        onTap: () => SpeciesDetailSheet.show(context, species),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Center(
                child: SpeciesGlyph(
                  species: species,
                  seen: !offen,
                  showCheck: false,
                  silhouette: offen,
                  iconSize: 32,
                ),
              ),
            ),
            if (!offen && zeigtSeltenheit(species))
              Positioned(
                top: 6,
                right: 6,
                child: Tooltip(
                  message: seltenheitEintrag(species.seltenheit).label,
                  child: PhosphorIcon(
                    seltenheitEintrag(species.seltenheit).icon,
                    size: 14,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
