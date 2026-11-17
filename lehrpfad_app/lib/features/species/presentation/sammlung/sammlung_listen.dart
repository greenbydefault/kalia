import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../nearby_trails/domain/karte_logik.dart';
import '../../data/sammlung_providers.dart';
import '../../data/species_providers.dart';
import '../../domain/sammlung_ansicht.dart';
import '../../domain/species.dart';
import '../species_detail_sheet.dart';
import '../species_glyph.dart';
import '../species_illustration.dart';
import 'sammlung_grids.dart';

/// „Zuletzt entdeckt“: horizontale Liste, max. 5 Funde, neueste zuerst.
class SammlungZuletzt extends ConsumerWidget {
  const SammlungZuletzt({super.key, required this.arten});

  final List<Species> arten;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final funde = ref.watch(fundeProvider).asData?.value ?? const {};
    final trails = ref.watch(trailNamenProvider);
    final now = DateTime.now();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SammlungBereichTitel(titel: 'Zuletzt entdeckt'),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            itemCount: arten.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.x2),
            itemBuilder: (context, i) {
              final s = arten[i];
              final fund = funde[s.id];
              final wann = fund?.entdecktAm;
              final pfad = fund?.trailId == null ? null : trails[fund!.trailId];
              return SizedBox(
                width: 112,
                child: Material(
                  color: AppColors.n100,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    key: ValueKey('sammlung-zuletzt-${s.id}'),
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => SpeciesDetailSheet.show(context, s),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.x2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SpeciesGlyph(
                            species: s,
                            seen: true,
                            showCheck: false,
                            iconSize: 28,
                            illustrationSize: 36,
                          ),
                          const SizedBox(height: 4),
                          if (wann != null)
                            Text(
                              relativeZeit(wann, now),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.inkMuted,
                              ),
                            ),
                          if (pfad != null)
                            Text(
                              pfad,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.inkMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// „Noch offen in eurer Nähe“: max. 2 offene Einträge mit kürzester Anfahrt.
class SammlungNaehe extends StatelessWidget {
  const SammlungNaehe({super.key, required this.treffer});

  final List<NaehTreffer> treffer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SammlungBereichTitel(titel: 'Noch offen in eurer Nähe'),
        for (final t in treffer)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              0,
              AppSpacing.page,
              AppSpacing.x2,
            ),
            child: Material(
              color: AppColors.n100,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                key: ValueKey('sammlung-naehe-${t.species.id}'),
                borderRadius: BorderRadius.circular(10),
                onTap: () => SpeciesDetailSheet.show(context, t.species),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.x3),
                  child: Row(
                    children: [
                      SpeciesIllustration(
                        species: t.species,
                        size: 40,
                        iconSize: 28,
                        silhouette: true,
                        iconColor: AppColors.n400,
                      ),
                      const SizedBox(width: AppSpacing.x3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.species.nameDe,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              'Gute Chancen: ${t.chance.trail.name} · '
                              '${formatAnfahrt(t.chance.minuten!)}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PhosphorIcon(
                        PhosphorIcons.caretRight,
                        size: 18,
                        color: AppColors.inkMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
