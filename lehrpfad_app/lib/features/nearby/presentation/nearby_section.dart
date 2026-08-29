import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/catalogs/icon_catalog.dart';
import '../data/nearby_providers.dart';
import '../domain/nearby.dart';
import 'oeffnungs_badge.dart';

/// Gruppierte Liste der Orte im Umkreis (Accordion-Inhalt).
class NearbySection extends ConsumerWidget {
  const NearbySection({super.key, required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(nearbyPlacesProvider(trailId));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (e, _) => Text(
        'Orte konnten nicht geladen werden.',
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
      ),
      data: (treffer) {
        if (treffer.isEmpty) {
          return Text(
            'Keine Orte im Umkreis hinterlegt.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.inkMuted,
            ),
          );
        }
        final grouped = groupNearbyByKategorie(treffer);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in grouped.entries) ...[
              _KategorieHeader(kategorie: entry.key, count: entry.value.length),
              const SizedBox(height: AppSpacing.x2),
              for (final t in entry.value) _OrtTile(treffer: t),
              const SizedBox(height: AppSpacing.x3),
            ],
          ],
        );
      },
    );
  }
}

class _KategorieHeader extends StatelessWidget {
  const _KategorieHeader({required this.kategorie, required this.count});

  final String kategorie;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kat = poiKategorieEintrag(kategorie);
    return Row(
      children: [
        kat.buildIcon(size: 18, color: AppColors.ink),
        const SizedBox(width: 6),
        Text(
          kat.label,
          style: theme.textTheme.titleSmall?.copyWith(color: AppColors.ink),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

class _OrtTile extends StatelessWidget {
  const _OrtTile({required this.treffer});

  final NearbyTreffer treffer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final place = treffer.place;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(place.name, style: theme.textTheme.bodyMedium),
              ),
              Text(
                formatDistanzKm(treffer.distanzKm),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
          if (place.kurztext.isNotEmpty)
            Text(
              place.kurztext,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          if (place.oeffnungszeiten != null &&
              place.oeffnungszeiten!.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: Text(
                    place.oeffnungszeiten!,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                OeffnungsBadge(openingHours: place.openingHours),
              ],
            )
          else
            OeffnungsBadge(openingHours: place.openingHours),
          Row(
            children: [
              if (place.website != null && place.website!.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _open(place.website!),
                  icon: const PhosphorIcon(PhosphorIcons.globe, size: 16),
                  label: const Text('Website'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if (place.telefon != null && place.telefon!.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _call(place.telefon!),
                  icon: const PhosphorIcon(PhosphorIcons.phone, size: 16),
                  label: const Text('Anrufen'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _open(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> _call(String telefon) async {
  final digits = telefon.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.isEmpty) return;
  await launchUrl(Uri(scheme: 'tel', path: digits));
}
