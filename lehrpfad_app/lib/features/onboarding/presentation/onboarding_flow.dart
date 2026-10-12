import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/motion/reduced_motion.dart';
import '../../location/location_permission_controller.dart';
import '../../nearby/data/nearby_providers.dart';
import '../../trail/data/providers.dart';
import '../../trail_progress/tracking/location_service.dart';
import '../data/onboarding_providers.dart';
import '../data/place_search.dart';
import 'screens/group_screen.dart';
import 'screens/location_screen.dart';
import 'screens/place_screen.dart';
import 'screens/welcome_screen.dart';

enum OnboardingStep { welcome, group, location, place }

/// Vollbild-Flow beim ersten Start: Willkommen → Gruppe → Standort (→ Ort).
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  var _step = OnboardingStep.welcome;
  var _dir = 1.0;

  /// Ort-Screen direkt (Berechtigung früher dauerhaft abgelehnt).
  var _skippedLocation = false;
  var _showSettingsHint = false;

  @override
  void initState() {
    super.initState();
    // Katalog und Ortsindex laden, während Willkommen und Gruppe laufen,
    // damit die Nähe-Liste nach der Ortseingabe nicht erst dann startet.
    ref.read(trailsProvider);
    ref.read(nearbyCatalogProvider);
    ref.read(nearbyZeitenProvider);
    ref.read(placeIndexProvider);
  }

  void _go(OnboardingStep step, {required bool forward}) {
    setState(() {
      _dir = forward ? 1 : -1;
      _step = step;
    });
  }

  void _back() {
    switch (_step) {
      case OnboardingStep.welcome:
        return;
      case OnboardingStep.group:
        _go(OnboardingStep.welcome, forward: false);
      case OnboardingStep.location:
        _go(OnboardingStep.group, forward: false);
      case OnboardingStep.place:
        _go(
          _skippedLocation ? OnboardingStep.group : OnboardingStep.location,
          forward: false,
        );
    }
  }

  Future<void> _toLocation() async {
    OsLocationStatus status;
    try {
      status = await ref.read(locationPermissionProvider.notifier).refresh();
    } catch (_) {
      status = OsLocationStatus.unknown;
    }
    if (!mounted) return;
    if (status == OsLocationStatus.deniedForever) {
      _skippedLocation = true;
      _showSettingsHint = true;
      _go(OnboardingStep.place, forward: true);
      return;
    }
    _skippedLocation = false;
    _showSettingsHint = false;
    _go(OnboardingStep.location, forward: true);
  }

  void _toPlace() {
    _skippedLocation = false;
    _showSettingsHint = false;
    _go(OnboardingStep.place, forward: true);
  }

  Future<void> _finish() =>
      ref.read(onboardingCompletedProvider.notifier).complete();

  Widget _child() {
    return switch (_step) {
      OnboardingStep.welcome => WelcomeScreen(
        onStart: () => _go(OnboardingStep.group, forward: true),
        onLoggedIn: () => _go(OnboardingStep.group, forward: true),
      ),
      OnboardingStep.group => GroupScreen(onBack: _back, onNext: _toLocation),
      OnboardingStep.location => LocationScreen(
        onBack: _back,
        onGranted: _finish,
        onNeedPlace: _toPlace,
      ),
      OnboardingStep.place => PlaceScreen(
        onBack: _back,
        onDone: _finish,
        showSettingsHint: _showSettingsHint,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == OnboardingStep.welcome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: ClipRect(
          child: AnimatedSwitcher(
            duration: context.motion(OnboardingMotion.screen),
            switchInCurve: OnboardingMotion.screenCurve,
            switchOutCurve: OnboardingMotion.screenCurve,
            layoutBuilder: (current, previous) =>
                Stack(fit: StackFit.expand, children: [...previous, ?current]),
            transitionBuilder: (child, animation) {
              final incoming = child.key == ValueKey(_step);
              final begin = Offset(incoming ? _dir : -_dir, 0);
              return SlideTransition(
                position: Tween(
                  begin: begin,
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
            child: KeyedSubtree(key: ValueKey(_step), child: _child()),
          ),
        ),
      ),
    );
  }
}
