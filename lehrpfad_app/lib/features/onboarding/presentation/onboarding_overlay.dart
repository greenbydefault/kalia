import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/widgets/bottom_content_card.dart';
import '../../../shared/widgets/sheet_motion.dart';
import '../../auth/data/auth_providers.dart';
import '../../location/location_permission_controller.dart';
import '../../location/user_position_provider.dart';
import '../../trail_progress/tracking/location_service.dart';
import '../../trail/data/providers.dart';
import '../data/onboarding_providers.dart';
import 'steps/auth_step.dart';
import 'steps/family_step.dart';
import 'steps/location_step.dart';
import 'steps/welcome_step.dart';

enum OnboardingStep { welcome, auth, family, location }

class OnboardingOverlay extends ConsumerStatefulWidget {
  const OnboardingOverlay({super.key});

  @override
  ConsumerState<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends ConsumerState<OnboardingOverlay> {
  static const _minSplash = Duration(milliseconds: 700);

  var _showCard = false;
  var _step = OnboardingStep.welcome;
  var _authAsRegister = true;
  var _viaAuth = false;

  final _nameController = TextEditingController();
  final _childControllers = <TextEditingController>[TextEditingController()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _childControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _boot() async {
    final started = DateTime.now();
    try {
      await ref.read(trailsProvider.future);
    } catch (_) {}
    final wait = _minSplash - DateTime.now().difference(started);
    if (wait > Duration.zero) await Future<void>.delayed(wait);
    if (mounted) setState(() => _showCard = true);
  }

  void _go(OnboardingStep step) => setState(() => _step = step);

  void _openAuth({required bool register}) {
    if (SupabaseConfig.isConfigured) {
      final auth = ref.read(authStateProvider);
      if (auth.hasValue && auth.value != null) {
        _go(OnboardingStep.family);
        return;
      }
    }
    setState(() {
      _authAsRegister = register;
      _viaAuth = true;
      _step = OnboardingStep.auth;
    });
  }

  void _back() {
    switch (_step) {
      case OnboardingStep.welcome:
        return;
      case OnboardingStep.auth:
        _go(OnboardingStep.welcome);
      case OnboardingStep.family:
        _go(_viaAuth ? OnboardingStep.auth : OnboardingStep.welcome);
      case OnboardingStep.location:
        _go(OnboardingStep.family);
    }
  }

  Future<void> _allowLocation() async {
    try {
      await ref.read(locationPermissionProvider.notifier).requestWhenInUse();
      if (ref.read(locationPermissionProvider).isGranted) {
        await ref.read(mapLocationEnabledProvider.notifier).setEnabled(true);
        await ref.read(userPositionProvider.notifier).refresh(force: true);
      }
    } catch (_) {}
    await _finish();
  }

  Future<void> _finish() async {
    await ref
        .read(onboardingCompletedProvider.notifier)
        .complete(
          displayName: _nameController.text,
          childNames: [for (final c in _childControllers) c.text],
        );
  }

  int get _dotIndex => switch (_step) {
    OnboardingStep.welcome || OnboardingStep.auth => 0,
    OnboardingStep.family => 1,
    OnboardingStep.location => 2,
  };

  bool get _needsKeyboard =>
      _step == OnboardingStep.auth || _step == OnboardingStep.family;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.scrim38)),
          IgnorePointer(
            ignoring: _showCard,
            child: Center(
              child: AnimatedOpacity(
                opacity: _showCard ? 0 : 1,
                duration: SheetMotion.fade,
                curve: SheetMotion.fadeCurve,
                child: const _SplashMark(),
              ),
            ),
          ),
          if (_showCard)
            BottomContentCard(
              padForKeyboard: _needsKeyboard,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StepDots(index: _dotIndex),
                  const SizedBox(height: AppSpacing.x3),
                  AnimatedSwitcher(
                    duration: SheetMotion.fade,
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: _stepChild(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _stepChild() {
    return switch (_step) {
      OnboardingStep.welcome => WelcomeStep(
        onContinueWithoutAccount: () {
          _viaAuth = false;
          _go(OnboardingStep.family);
        },
        onCreateAccount: () => _openAuth(register: true),
        onSignIn: () => _openAuth(register: false),
      ),
      OnboardingStep.auth => AuthStep(
        initialDisplayName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        startInRegisterMode: _authAsRegister,
        onSuccess: () => _go(OnboardingStep.family),
        onContinueWithoutAccount: () {
          _viaAuth = false;
          _go(OnboardingStep.family);
        },
      ),
      OnboardingStep.family => FamilyStep(
        nameController: _nameController,
        childControllers: _childControllers,
        onAddChild: () =>
            setState(() => _childControllers.add(TextEditingController())),
        onRemoveChild: (i) => setState(() {
          _childControllers.removeAt(i).dispose();
          if (_childControllers.isEmpty) {
            _childControllers.add(TextEditingController());
          }
        }),
        onContinue: () => _go(OnboardingStep.location),
      ),
      OnboardingStep.location => LocationStep(
        onAllow: _allowLocation,
        onSkip: _finish,
      ),
    };
  }
}

class _SplashMark extends StatelessWidget {
  const _SplashMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: const BoxDecoration(
        color: AppColors.paper,
        shape: BoxShape.circle,
      ),
      child: const PhosphorIcon(
        PhosphorIcons.mapTrifold,
        size: 40,
        color: AppColors.ink,
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == index ? AppColors.ink : AppColors.n300,
            ),
          ),
      ],
    );
  }
}
