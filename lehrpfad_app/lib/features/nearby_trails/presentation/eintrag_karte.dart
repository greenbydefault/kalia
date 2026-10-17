import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/catalogs/icon_catalog.dart';
import '../../community/domain/trail_image.dart';
import '../../trail/domain/trail.dart';
import '../../trail/presentation/map/trail_hero.dart';
import '../../trail_progress/data/trail_progress_providers.dart';
import '../../trail_progress/presentation/open_trail_on_map.dart';
import '../../trail_progress/presentation/quick_merken.dart';
import '../domain/eintrag.dart';
import '../domain/karte_copy.dart';
import '../domain/karte_logik.dart';
import 'hoeren_button.dart';

/// Lesezeichen mit Snackbar und „Rückgängig“ (4 Sekunden). Merken geht ohne
/// Konto, lokal gespeichert.
Future<void> merkeEintrag(
  BuildContext context,
  WidgetRef ref,
  Trail trail,
) async {
  final notifier = ref.read(trailBookmarksProvider.notifier);
  final war =
      ref.read(trailBookmarksProvider).asData?.value.contains(trail.id) ??
      false;
  await notifier.setBookmarked(trail.id, !war);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Text(kt(war ? 'merken.entfernt' : 'merken.gemerkt')),
        action: SnackBarAction(
          label: kt('allg.rueckgaengig'),
          onPressed: () => notifier.setBookmarked(trail.id, war),
        ),
      ),
    );
}

/// Eintragskarte: was, wo, wie weit, wie lang und ob es für Kinder passt.
///
/// Kopf (Bild, Typzeile, Name, Ort, Lesezeichen), Fakten-Raster und
/// Aktionszeile. Das Raster behält immer seine Spalten.
class EintragKarte extends ConsumerWidget {
  const EintragKarte({
    super.key,
    required this.treffer,
    required this.trail,
    this.hoerenKey,
  });

  final Treffer treffer;
  final Trail trail;

  /// Ziel für den Coach-Mark (nur erste Karte mit Audio).
  final GlobalKey? hoerenKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final e = treffer.eintrag;
    final gemerkt = isTrailSaved(ref, trail.id);
    final merkmale = merkmaleText(e);
    final audio = e.audio;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.x5),
        border: Border.all(color: AppColors.n200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openTrailOnMap(context, ref, trail, detail: true),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Kopf(eintrag: e, trail: trail, gemerkt: gemerkt),
                const SizedBox(height: AppSpacing.x3),
                FaktenRaster(treffer: treffer),
                if (audio != null || merkmale.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.x3),
                  Row(
                    children: [
                      if (audio != null)
                        KeyedSubtree(
                          key: hoerenKey,
                          child: HoerenButton(trail: trail, audio: audio),
                        ),
                      if (audio != null && merkmale.isNotEmpty)
                        const SizedBox(width: AppSpacing.x3),
                      if (merkmale.isNotEmpty)
                        Expanded(
                          child: Text(
                            merkmale,
                            textAlign: audio == null
                                ? TextAlign.start
                                : TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Kopf extends ConsumerWidget {
  const _Kopf({
    required this.eintrag,
    required this.trail,
    required this.gemerkt,
  });

  final Eintrag eintrag;
  final Trail trail;
  final bool gemerkt;

  static const _bild = 88.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ort = eintrag.ortLabel;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.x4),
          child: SizedBox(
            width: _bild,
            height: _bild,
            child: trail.hasHeroBilder
                ? TrailHeroImage(
                    trailId: trail.id,
                    slide: HeroSlide.seed(TrailHero.pagesFor(trail).first),
                    fit: BoxFit.cover,
                    variant: TrailImageVariant.thumb,
                    width: _bild,
                    height: _bild,
                  )
                : ColoredBox(
                    color: AppColors.n100,
                    child: Center(
                      child: PhosphorIcon(
                        gebietIcons[eintrag.gebiet]!,
                        size: 32,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PhosphorIcon(gebietIcons[eintrag.gebiet]!, size: 14),
                  const SizedBox(width: AppSpacing.x1),
                  Expanded(
                    child: Text(
                      eintrag.typLabel,
                      style: theme.textTheme.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                eintrag.name,
                style: theme.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (ort != null) ...[
                const SizedBox(height: AppSpacing.x1),
                Text(
                  ort,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        IconButton(
          tooltip: kt(gemerkt ? 'a11y.gemerkt' : 'a11y.merken'),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: EdgeInsets.zero,
          onPressed: () => merkeEintrag(context, ref, trail),
          icon: PhosphorIcon(
            gemerkt
                ? PhosphorIconsFill.bookmarkSimple
                : PhosphorIcons.bookmarkSimple,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

/// Label über Wert, auch in der Einzelansicht. Weg: Anfahrt, Dauer, Länge, Kinder. Ort: Anfahrt, Saison,
/// Eintritt.
class FaktenRaster extends StatelessWidget {
  const FaktenRaster({required this.treffer});

  final Treffer treffer;

  @override
  Widget build(BuildContext context) {
    final e = treffer.eintrag;
    final leer = kt('fakt.leer');
    final heute = DateTime.now();
    final fakten = <_Fakt>[
      _Fakt('fakt.anfahrt', Text(anfahrtZelle(treffer.anfahrtMin))),
      if (e.istWeg) ...[
        _Fakt(
          'fakt.dauer',
          Text(e.dauerMin == null ? leer : formatDauer(e.dauerMin!)),
        ),
        _Fakt(
          'fakt.laenge',
          Text(e.laengeM == null ? leer : formatLaenge(e.laengeM!)),
        ),
        _Fakt('fakt.kinder', KinderBalken(stufe: e.kinderfreundlich)),
      ] else ...[
        _Fakt(
          'fakt.saison',
          Text(e.saison == null ? leer : formatSaison(e.saison!, heute)),
        ),
        _Fakt(
          'fakt.eintritt',
          Text(e.eintritt == null ? leer : formatEintritt(e.eintritt!)),
        ),
      ],
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final f in fakten) Expanded(child: _FaktSpalte(fakt: f))],
    );
  }
}

class _Fakt {
  const _Fakt(this.labelKey, this.wert);

  final String labelKey;
  final Widget wert;
}

class _FaktSpalte extends StatelessWidget {
  const _FaktSpalte({required this.fakt});

  final _Fakt fakt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kt(fakt.labelKey),
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.inkMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        DefaultTextStyle.merge(
          style: theme.textTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: fakt.wert,
        ),
      ],
    );
  }
}

/// Fünf Balken, [stufe] davon gefüllt. Ohne Wert „–“ statt Balken.
class KinderBalken extends StatelessWidget {
  const KinderBalken({super.key, required this.stufe});

  final int? stufe;

  @override
  Widget build(BuildContext context) {
    final balken = formatKinder(stufe);
    if (balken == null) return Text(kt('fakt.leer'));
    return Semantics(
      label: kinderSemantik(stufe!),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < balken.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Container(
              width: 6,
              height: 16,
              decoration: BoxDecoration(
                color: balken[i] ? AppColors.ink : AppColors.n200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
