import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/config/build_stamp.dart';
import '../../../core/motion/reduced_motion.dart';
import '../../../shared/widgets/bottom_content_card.dart';
import '../../../shared/widgets/empty_filter_notice.dart';
import '../../../shared/widgets/placeholder_block.dart';
import '../../location/home_filter.dart';
import '../../location/map_radius.dart';
import '../../location/user_position_provider.dart';
import '../../onboarding/data/onboarding_prefs_provider.dart';
import '../../trail/domain/catalog_filter.dart';
import '../data/nearby_trails_provider.dart';
import 'nearby_trail_card.dart';
import 'place_pill.dart';

/// Ziel-Schlüssel für den Coach-Mark (Hören-Button der ersten Karte).
final coachTargetKeyProvider = Provider<GlobalKey>(
  (ref) => GlobalKey(debugLabel: 'coachHoeren'),
);

/// Karten-Einstieg läuft nur beim ersten Zeigen pro App-Start.
final nearbyIntroPlayedProvider =
    NotifierProvider<NearbyIntroPlayedNotifier, bool>(
      NearbyIntroPlayedNotifier.new,
    );

class NearbyIntroPlayedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markPlayed() => state = true;
}

/// „Nächste Wege“: ziehbares Panel über der Karte.
class NearbyTrailsPanel extends ConsumerStatefulWidget {
  const NearbyTrailsPanel({
    super.key,
    required this.onHeightChanged,
    this.bottomInset = 0,
  });

  /// Aktuelle Panelhöhe in Pixeln (für FAB-Versatz).
  final ValueChanged<double> onHeightChanged;

  /// Platz für den Mini-Player unter der Liste.
  final double bottomInset;

  static const minSize = 0.17;
  static const initialSize = 0.55;
  static const maxSize = 0.92;

  static const headline = 'Nächste Wege';

  @override
  ConsumerState<NearbyTrailsPanel> createState() => _NearbyTrailsPanelState();
}

class _NearbyTrailsPanelState extends ConsumerState<NearbyTrailsPanel> {
  late final bool _animateIntro = !ref.read(nearbyIntroPlayedProvider);
  double _lastReported = -1;

  @override
  void initState() {
    super.initState();
    // `_animateIntro` ist beim ersten Build fixiert; danach gilt der
    // Einstieg als gespielt und kommt nicht bei jedem Wiederzeigen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(nearbyIntroPlayedProvider.notifier).markPlayed();
    });
  }

  void _report(double px) {
    if ((px - _lastReported).abs() < 0.5) return;
    _lastReported = px;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onHeightChanged(px);
    });
  }

  @override
  void dispose() {
    final report = widget.onHeightChanged;
    WidgetsBinding.instance.addPostFrameCallback((_) => report(0));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        _report(NearbyTrailsPanel.initialSize * h);
        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (n) {
            _report(n.extent * h);
            return false;
          },
          child: DraggableScrollableSheet(
            initialChildSize: NearbyTrailsPanel.initialSize,
            minChildSize: NearbyTrailsPanel.minSize,
            maxChildSize: NearbyTrailsPanel.maxSize,
            snap: true,
            snapSizes: const [
              NearbyTrailsPanel.minSize,
              NearbyTrailsPanel.initialSize,
              NearbyTrailsPanel.maxSize,
            ],
            builder: (context, scrollController) {
              return DecoratedBox(
                decoration: BottomContentCard.decoration(theme),
                child: ClipRRect(
                  borderRadius: BottomContentCard.topRadius,
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.x5,
                      0,
                      AppSpacing.x5,
                      AppSpacing.x5 + widget.bottomInset,
                    ),
                    children: [
                      const BottomContentCardHandle(),
                      const PlacePill(),
                      const SizedBox(height: AppSpacing.x3),
                      Text(
                        NearbyTrailsPanel.headline,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.x3),
                      const _FilterChips(),
                      const SizedBox(height: AppSpacing.x4),
                      ..._cards(),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _cards() {
    final anchorState = ref.watch(nearbyAnchorStateProvider);
    if (anchorState == NearbyAnchorState.unavailable) {
      return const [_LocateFailed()];
    }
    final entries = ref.watch(nearbyTrailEntriesProvider);
    if (anchorState == NearbyAnchorState.locating || entries == null) {
      return [
        for (var i = 0; i < 3; i++) const _NearbySkeleton(),
        if (anchorState == NearbyAnchorState.locating)
          Text(
            'Standort wird gesucht…',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
          ),
      ];
    }
    if (entries.isEmpty) {
      final radiusAll = ref.watch(effectiveMapRadiusProvider).isAll;
      return [
        EmptyFilterNotice(
          actionLabel: radiusAll ? null : 'Umkreis vergrößern',
          onAction: radiusAll
              ? null
              : () => ref.read(mapRadiusProvider.notifier).enlarge(),
        ),
      ];
    }
    logNearbyVisible();
    final targetKey = ref.watch(coachTargetKeyProvider);
    return [
      for (var i = 0; i < entries.length; i++)
        _intro(
          i,
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.x3),
            child: NearbyTrailCard(
              key: ValueKey(entries[i].trail.id),
              entry: entries[i],
              hoerenKey: i == 0 ? targetKey : null,
            ),
          ),
        ),
    ];
  }

  Widget _intro(int index, Widget child) {
    if (!_animateIntro) return child;
    return child
        .animate(delay: context.motion(OnboardingMotion.cardStagger * index))
        .fadeIn(
          duration: context.motion(OnboardingMotion.cardEnter),
          curve: Curves.easeOutCubic,
        )
        .moveY(
          begin: 50,
          end: 0,
          duration: context.motion(OnboardingMotion.cardEnter),
          curve: Curves.easeOutCubic,
        );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(onboardingPrefsValueProvider);
    final filter = ref.watch(homeFilterProvider);
    final notifier = ref.read(homeFilterProvider.notifier);
    final km = prefs.maxLaengeKm;

    final chips = <Widget>[
      if (km != null)
        FilterPill(
          label: 'Weg bis $km km lang',
          selected: filter.lengthOn,
          onTap: notifier.toggleLength,
        ),
      if (prefs.stroller)
        FilterPill(
          label: 'Kinderwagen',
          selected: filter.strollerOn,
          onTap: notifier.toggleStroller,
        ),
      if (km == null && !prefs.stroller)
        FilterPill(
          label: 'Weg bis $defaultShortKm km lang',
          selected: filter.lengthOn,
          onTap: notifier.toggleLength,
        ),
    ];
    return Wrap(
      spacing: AppSpacing.x2,
      runSpacing: AppSpacing.x2,
      children: chips,
    );
  }
}

/// Filter-Chip mit 44 pt Touch-Ziel.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
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
                  Text(
                    label,
                    style:
                        (theme.chipTheme.labelStyle ??
                                theme.textTheme.labelLarge)
                            ?.copyWith(
                              color: selected ? AppColors.paper : AppColors.ink,
                            ),
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

class _NearbySkeleton extends StatelessWidget {
  const _NearbySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.x3),
      child: PlaceholderBlock(
        height: NearbyTrailCard.height,
        radius: AppSpacing.x5,
        color: AppColors.n100,
      ),
    );
  }
}

class _LocateFailed extends StatelessWidget {
  const _LocateFailed();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Standort nicht gefunden', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.x2),
        Text(
          'Gebt stattdessen Ort oder Postleitzahl ein.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () => openPlaceScreen(context),
          child: const Text('Ort eingeben'),
        ),
      ],
    );
  }
}
