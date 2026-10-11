import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/motion/reduced_motion.dart';
import '../../../../shared/widgets/hint_box.dart';
import '../../../../shared/widgets/selectable_chip_tile.dart';
import '../../data/onboarding_prefs_provider.dart';
import '../../domain/age_group.dart';
import '../widgets/step_header.dart';
import '../widgets/stroller_switch.dart';

/// Screen 2: Mit wem seid ihr unterwegs? Mehrfachauswahl, alles optional.
class GroupScreen extends ConsumerStatefulWidget {
  const GroupScreen({super.key, required this.onBack, required this.onNext});

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  ConsumerState<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends ConsumerState<GroupScreen> {
  late Set<AgeGroup> _groups;
  late bool _stroller;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(onboardingPrefsValueProvider);
    _groups = {...prefs.ageGroups};
    _stroller = prefs.stroller;
  }

  void _toggle(AgeGroup g) {
    setState(() {
      if (!_groups.remove(g)) {
        _groups.add(g);
        if (g == AgeGroup.under3) _stroller = true;
      }
    });
  }

  Future<void> _next({required bool save}) async {
    if (save) {
      await ref
          .read(onboardingPrefsProvider.notifier)
          .setGroups(_groups, stroller: _stroller);
    }
    widget.onNext();
  }

  Widget _chip(AgeGroup g, int index) {
    return Expanded(
      child:
          SelectableChipTile(
                title: g.title,
                subtitle: g.subtitle,
                selected: _groups.contains(g),
                onTap: () => _toggle(g),
              )
              .animate(
                delay: context.motion(OnboardingMotion.chipStagger * index),
              )
              .fadeIn(duration: context.motion(OnboardingMotion.chipPop))
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: context.motion(OnboardingMotion.chipPop),
                curve: Curves.easeOutBack,
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gap = AppSpacing.x3;
    const groups = AgeGroup.values;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingStepHeader(step: 1, onBack: widget.onBack),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x5,
                AppSpacing.x5,
                AppSpacing.x5,
                AppSpacing.x4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Mit wem seid ihr unterwegs?',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'Damit wir passende Wege zuerst zeigen. '
                    'Mehrere Antworten gehen.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _chip(groups[0], 0),
                        const SizedBox(width: gap),
                        _chip(groups[1], 1),
                      ],
                    ),
                  ),
                  const SizedBox(height: gap),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _chip(groups[2], 2),
                        const SizedBox(width: gap),
                        _chip(groups[3], 3),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  StrollerSwitch(
                    value: _stroller,
                    onChanged: (v) => setState(() => _stroller = v),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  GroupHintBox(groups: _groups, stroller: _stroller),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x5,
              AppSpacing.x2,
              AppSpacing.x5,
              AppSpacing.x4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => _next(save: true),
                  child: const Text('Weiter'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => _next(save: false),
                  child: const Text('Überspringen'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Live-Hinweis unter den Chips. Zahl zählt animiert hoch.
class GroupHintBox extends StatelessWidget {
  const GroupHintBox({super.key, required this.groups, required this.stroller});

  final Set<AgeGroup> groups;
  final bool stroller;

  static const emptyText =
      'Wählt aus, wer mitkommt. Ihr könnt das jederzeit ändern.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final km = AgeGroup.minKm(groups);
    final style = theme.textTheme.bodyMedium;

    final Widget child;
    if (km == null) {
      child = Text(emptyText, key: const ValueKey('empty'), style: style);
    } else {
      child = TweenAnimationBuilder<double>(
        key: const ValueKey('km'),
        tween: Tween(begin: 0, end: km.toDouble()),
        duration: context.motion(OnboardingMotion.countUp),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => Text(
          'Wir zeigen euch zuerst Wege bis ca. ${v.round()} km'
          '${stroller ? ', die mit Kinderwagen gehen' : ''}.',
          style: style,
        ),
      );
    }

    return HintBox(
      child: AnimatedSize(
        duration: context.motion(const Duration(milliseconds: 250)),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topLeft,
        child: AnimatedSwitcher(
          duration: context.motion(const Duration(milliseconds: 200)),
          child: Align(
            key: child.key,
            alignment: Alignment.centerLeft,
            child: child,
          ),
        ),
      ),
    );
  }
}
