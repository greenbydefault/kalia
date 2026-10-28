import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/config/build_stamp.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/motion/reduced_motion.dart';
import '../../../../shared/widgets/lowpoly_placeholder_scene.dart';
import '../../../location/location_permission_controller.dart';
import '../../../location/user_position_provider.dart';
import '../../../trail_progress/tracking/location_service.dart';
import '../../data/onboarding_prefs_provider.dart';
import '../widgets/step_header.dart';
import 'place_screen.dart' show PlaceHint;

/// Screen 3: Standort. Echter System-Dialog („Beim Verwenden der App“).
class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({
    super.key,
    required this.onBack,
    required this.onGranted,
    required this.onNeedPlace,
    required this.onBlocked,
  });

  final VoidCallback onBack;
  final VoidCallback onGranted;

  /// „Ort selbst eingeben“: niemand hat die Freigabe versucht.
  final VoidCallback onNeedPlace;

  /// „Standort freigeben“ ohne Erfolg, mit Hinweis für den Ort-Screen.
  final ValueChanged<PlaceHint> onBlocked;

  static const deniedToast = 'Kein Problem, gebt euren Ort einfach ein';

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  var _busy = false;

  Future<OsLocationStatus> _status(LocationPermissionController ctrl) async {
    try {
      return await ctrl.refresh();
    } catch (_) {
      return OsLocationStatus.unknown;
    }
  }

  Future<void> _allow() async {
    if (_busy) return;
    setState(() => _busy = true);
    var granted = false;
    var asked = false;
    // Nach dem Dialog ohne Freigabe fehlt sie in den Einstellungen.
    var hint = kIsWeb ? PlaceHint.none : PlaceHint.appSettings;
    try {
      final ctrl = ref.read(locationPermissionProvider.notifier);
      // Web: Prompt direkt im Tap auslösen, ohne vorherige Status-Abfrage.
      var status = kIsWeb ? OsLocationStatus.unknown : await _status(ctrl);
      // Ohne Dialog gescheitert (Dienst aus, dauerhaft gesperrt): der Hinweis
      // auf die Einstellungen genügt, ein „abgelehnt“-Toast wäre falsch.
      asked =
          status.isGranted ||
          (status != OsLocationStatus.deniedForever &&
              status != OsLocationStatus.servicesDisabled);
      if (!status.isGranted && asked) {
        try {
          status = await ctrl.requestWhenInUse();
        } catch (_) {
          // Der Browser meldet einen fehlgeschlagenen Fix (Timeout, kein
          // Signal) als „dauerhaft verweigert“. Der echte Stand entscheidet.
          status = await _status(ctrl);
        }
      }
      granted = status.isGranted;
      hint = kIsWeb ? PlaceHint.none : PlaceHint.forStatus(status);
    } catch (_) {
      granted = false;
    }
    if (!mounted) return;
    setState(() => _busy = false);

    if (granted) {
      await ref.read(onboardingPrefsProvider.notifier).useDevicePosition();
      final locate = ref.read(locateTargetProvider.notifier);
      unawaited(
        ref
            .read(userPositionProvider.notifier)
            .refresh(force: true)
            .then((fix) => locate.goTo(fix?.position)),
      );
      markNearbyRequested();
      if (mounted) widget.onGranted();
      return;
    }
    if (asked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(LocationScreen.deniedToast),
        ),
      );
    }
    widget.onBlocked(hint);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingStepHeader(step: 2, onBack: widget.onBack),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.x5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: (height * 0.34).clamp(180.0, 320.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.x6),
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: LowpolyPlaceholderScene(
                              animate: false,
                              showSun: false,
                              showPath: false,
                            ),
                          ),
                          const Align(
                            alignment: Alignment(0, 0.45),
                            child: MapPinIllustration(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  Text(
                    'Pfade in eurer Nähe',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'Mit eurem Standort zeigen wir, was um euch herum liegt '
                    'und wie lange ihr mit dem Auto oder der Bahn hinfahrt.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
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
                  onPressed: _busy ? null : _allow,
                  child: const Text('Standort freigeben'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: _busy ? null : widget.onNeedPlace,
                  child: const Text('Ort selbst eingeben'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pin fällt ein (bounceOut), Schatten wächst mit, Pulsringe am Fuß.
class MapPinIllustration extends StatelessWidget {
  const MapPinIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    final fall = context.motion(OnboardingMotion.pinFall);

    Widget ring(Duration delay) {
      return Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.n600, width: 2),
            ),
          )
          .animate(delay: delay, onPlay: (c) => c.repeat())
          .scale(
            begin: const Offset(0.2, 0.2),
            end: const Offset(1.3, 1.3),
            duration: OnboardingMotion.pulse,
            curve: Curves.easeOut,
          )
          .fadeOut(duration: OnboardingMotion.pulse, curve: Curves.easeIn);
    }

    final shadow =
        Container(
          width: 44,
          height: 12,
          decoration: const BoxDecoration(
            color: AppColors.scrim38,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.elliptical(44, 12)),
          ),
        ).animate().scale(
          begin: Offset.zero,
          end: const Offset(1, 1),
          duration: fall,
          curve: Curves.easeOut,
        );

    final pin =
        const PhosphorIcon(
          PhosphorIconsFill.mapPin,
          size: 64,
          color: AppColors.ink,
        ).animate().moveY(
          begin: -170,
          end: 0,
          duration: fall,
          curve: Curves.bounceOut,
        );

    return SizedBox(
      width: 120,
      height: 140,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          if (!reduce) ...[
            Positioned(
              bottom: -42,
              child: ring(const Duration(milliseconds: 1000)),
            ),
            Positioned(
              bottom: -42,
              child: ring(const Duration(milliseconds: 1900)),
            ),
          ],
          Positioned(bottom: 0, child: shadow),
          Positioned(bottom: 6, child: pin),
        ],
      ),
    );
  }
}
