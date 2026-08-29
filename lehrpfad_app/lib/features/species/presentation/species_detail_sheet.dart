import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/show_app_modal_sheet.dart';
import '../data/species_providers.dart';
import '../domain/species.dart';
import 'gesehen_toggle.dart';
import 'species_content_view.dart';
import 'species_profil_view.dart';

/// Modal-Detail zu einer Art / einem Gerät (Steckbrief + Gesehen-Toggle).
class SpeciesDetailSheet extends ConsumerWidget {
  const SpeciesDetailSheet({super.key, required this.species});

  final Species species;

  static Future<void> show(BuildContext context, Species species) {
    return showAppModalSheet<void>(
      context: context,
      builder: (_) => SpeciesDetailSheet(species: species),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final seen =
        ref.watch(sightingsProvider).asData?.value.contains(species.id) ??
        false;
    final icon = species.displayIconEintrag.icon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            PhosphorIcon(icon, size: 32, color: AppColors.ink),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(species.nameDe, style: theme.textTheme.headlineSmall),
                  if (species.nameLat.isNotEmpty)
                    Text(
                      species.nameLat,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          species.kategorieLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 12),
        GesehenToggle(
          seen: seen,
          onChanged: (v) =>
              ref.read(sightingsProvider.notifier).setSeen(species.id, v),
        ),
        const SizedBox(height: 16),
        SpeciesContentView(species: species),
        const SizedBox(height: 8),
        SpeciesProfilView(species: species),
      ],
    );
  }
}
