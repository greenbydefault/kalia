import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/show_app_modal_sheet.dart';
import '../../onboarding/presentation/screens/place_screen.dart';
import '../data/bezug_provider.dart';
import 'bezug_aktionen.dart';

/// Startpunkt ändern (Konto): Standort, Ort oder Postleitzahl, entfernen.
/// Alle Wege laufen über [BezugAktionen], wie in der Karte.
Future<void> showStartpunktSheet(BuildContext context, WidgetRef ref) {
  final hasBezug = ref.read(aktuellerBezugProvider) != null;
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
              await BezugAktionen(ref).zentriereAufStandort(context);
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
          if (hasBezug)
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () async {
                Navigator.of(sheetContext).pop();
                await BezugAktionen(ref).entferneStartpunkt();
              },
              child: const Text('Startpunkt entfernen'),
            ),
        ],
      );
    },
  );
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
