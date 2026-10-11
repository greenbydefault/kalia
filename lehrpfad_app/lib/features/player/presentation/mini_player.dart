import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/motion/reduced_motion.dart';
import '../data/mini_player_provider.dart';
import 'equalizer_bars.dart';

/// Mini-Player über der Tab-Bar. Gleitet mit `easeOutBack` ein und aus.
class MiniPlayerHost extends ConsumerStatefulWidget {
  const MiniPlayerHost({super.key});

  /// Höhe inkl. Abstand, damit andere Overlays ausweichen können.
  static const double height = 68;

  @override
  ConsumerState<MiniPlayerHost> createState() => _MiniPlayerHostState();
}

class _MiniPlayerHostState extends ConsumerState<MiniPlayerHost> {
  MiniPlayerState? _last;

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(miniPlayerProvider);
    if (current != null) _last = current;
    final shown = _last;
    if (shown == null) return const SizedBox.shrink();
    final visible = current != null;

    return Positioned(
      left: AppSpacing.x3,
      right: AppSpacing.x3,
      bottom: AppSpacing.x2,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 1.8),
          duration: context.motion(const Duration(milliseconds: 450)),
          curve: visible ? Curves.easeOutBack : Curves.easeInCubic,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: context.motion(const Duration(milliseconds: 250)),
            child: _MiniPlayerCard(state: shown),
          ),
        ),
      ),
    );
  }
}

class _MiniPlayerCard extends ConsumerWidget {
  const _MiniPlayerCard({required this.state});

  final MiniPlayerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(miniPlayerProvider.notifier);
    return Material(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(AppSpacing.x4),
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      shadowColor: AppColors.scrim54,
      child: SizedBox(
        height: MiniPlayerHost.height - AppSpacing.x2,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.x4),
                  EqualizerBars(playing: state.playing, color: AppColors.paper),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.stationTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppColors.paper,
                          ),
                        ),
                        Text(
                          state.trail.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onImage70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: state.playing ? 'Pause' : 'Abspielen',
                    onPressed: notifier.toggle,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: PhosphorIcon(
                      state.playing ? PhosphorIcons.pause : PhosphorIcons.play,
                      color: AppColors.paper,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Schließen',
                    onPressed: notifier.stop,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: const PhosphorIcon(
                      PhosphorIcons.x,
                      size: 20,
                      color: AppColors.onImage70,
                    ),
                  ),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: state.progress,
              minHeight: 3,
              backgroundColor: AppColors.n700,
              color: AppColors.paper,
            ),
          ],
        ),
      ),
    );
  }
}
