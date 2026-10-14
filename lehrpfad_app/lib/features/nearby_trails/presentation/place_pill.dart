import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/show_app_modal_sheet.dart';
import '../../location/location_consent_sheet.dart';
import '../../location/location_gate.dart';
import '../../location/user_position_provider.dart';
import '../../onboarding/data/onboarding_prefs_provider.dart';
import '../../onboarding/presentation/screens/place_screen.dart';
import '../../trail_progress/tracking/location_service.dart';

/// „Rund um [Ort]“. Tap öffnet die Ortswahl.
class PlacePill extends ConsumerWidget {
  const PlacePill({super.key});

  static String label({required String? placeName, required bool hasAnchor}) {
    if (placeName != null) return 'Rund um $placeName';
    return hasAnchor ? 'Rund um euren Standort' : 'Ort wählen';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final text = label(
      placeName: ref.watch(onboardingPrefsValueProvider).place?.name,
      hasAnchor: ref.watch(mapAnchorProvider) != null,
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.n100,
        shape: const StadiumBorder(side: BorderSide(color: AppColors.hairline)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => showPlaceChangeSheet(context, ref),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PhosphorIcon(PhosphorIcons.mapPin, size: 18),
                  const SizedBox(width: AppSpacing.x2),
                  Flexible(
                    child: Text(
                      text,
                      style:
                          (theme.chipTheme.labelStyle ??
                                  theme.textTheme.labelLarge)
                              ?.copyWith(color: AppColors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x1),
                  const PhosphorIcon(PhosphorIcons.caretDown, size: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showPlaceChangeSheet(BuildContext context, WidgetRef ref) {
  return showAppModalSheet<void>(
    context: context,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Von wo startet ihr?', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.x4),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              await useDeviceLocation(context, ref);
            },
            icon: const PhosphorIcon(PhosphorIcons.crosshair, size: 18),
            label: const Text('Aktuellen Standort verwenden'),
          ),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () {
              Navigator.of(sheetContext).pop();
              openPlaceScreen(context);
            },
            child: const Text('Ort oder Postleitzahl eingeben'),
          ),
        ],
      );
    },
  );
}

Future<void> useDeviceLocation(BuildContext context, WidgetRef ref) async {
  try {
    final ok = await LocationGate.ensureMap(context, ref);
    if (!ok) return;
    final fix = ref.read(userPositionProvider).fix;
    ref.read(locateTargetProvider.notifier).goTo(fix?.position);
  } on LocationException catch (e) {
    if (context.mounted) showLocationError(context, e);
  }
}

Future<void> openPlaceScreen(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (routeContext) => Scaffold(
        body: PlaceScreen(
          standalone: true,
          onBack: () => Navigator.of(routeContext).pop(),
          onDone: () => Navigator.of(routeContext).pop(),
        ),
      ),
    ),
  );
}
