import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/catalogs/icon_catalog.dart';
import '../../data/providers.dart';
import '../../domain/trail.dart';
import 'map_typ_filter.dart';

/// Schwebende Chip-Leiste: Alle + vorhandene Trail-Typen (Single-Select).
class MapTypFilterBar extends ConsumerWidget {
  const MapTypFilterBar({super.key, required this.trails});

  final List<Trail> trails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typs = typsIn(trails);
    if (typs.length < 2) return const SizedBox.shrink();

    final selected = ref.watch(mapTypFilterProvider);
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
        itemCount: typs.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.x2),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Center(
              child: MapFilterChip(
                label: 'Alle',
                selected: selected == null,
                scheme: scheme,
                onSelected: (_) =>
                    ref.read(mapTypFilterProvider.notifier).clear(),
              ),
            );
          }
          final typ = typs[index - 1];
          final eintrag = typEintrag(typ);
          return Center(
            child: MapFilterChip(
              label: eintrag.label,
              avatar: eintrag.buildIcon(size: 16),
              selected: selected == typ,
              scheme: scheme,
              onSelected: (isSelected) {
                final notifier = ref.read(mapTypFilterProvider.notifier);
                if (isSelected) {
                  notifier.select(typ);
                } else {
                  notifier.clear();
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class MapFilterChip extends StatelessWidget {
  const MapFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.scheme,
    required this.onSelected,
    this.avatar,
  });

  final String label;
  final Widget? avatar;
  final bool selected;
  final ColorScheme scheme;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: avatar,
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      elevation: 2,
      pressElevation: 4,
      shadowColor: AppColors.scrim38,
      backgroundColor: scheme.surface,
      selectedColor: scheme.secondaryContainer,
      side: BorderSide(color: scheme.outlineVariant),
    );
  }
}
