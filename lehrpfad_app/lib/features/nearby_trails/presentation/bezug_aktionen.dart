import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../location/location_consent_sheet.dart';
import '../../location/location_gate.dart';
import '../../location/location_permission_controller.dart';
import '../../location/user_position_provider.dart';
import '../../onboarding/data/onboarding_prefs_provider.dart';
import '../../onboarding/data/place_search.dart';
import '../../onboarding/domain/user_place.dart';
import '../../trail_progress/tracking/location_service.dart';
import '../data/bezug_provider.dart';
import '../domain/bezugspunkt.dart';
import '../domain/karte_copy.dart';

/// Aktionen rund um Bezugspunkt und Standort (Tipps der Nutzer, nie
/// automatisch).
class BezugAktionen {
  BezugAktionen(this._ref);

  final WidgetRef _ref;

  /// Ort aus der Ortssuche wird Bezugspunkt (Quelle „suche“).
  Future<void> waehleOrt(UserPlace place) async {
    await _ref.read(karteBezugProvider.notifier).merkeOrt(place);
    await _ref.read(onboardingPrefsProvider.notifier).setPlace(place);
    _ref.read(locateTargetProvider.notifier).goTo(place.position);
  }

  /// Startpunkt entfernen: Ort, Standort, Position und Kartenmitte weg, die
  /// Karte zeigt wieder alle Wege.
  Future<void> entferneStartpunkt() async {
    await _ref.read(onboardingPrefsProvider.notifier).clearStartpoint();
    await _ref.read(karteBezugProvider.notifier).loescheKarte();
    _ref.read(locateTargetProvider.notifier).goTo(null);
  }

  /// Karte auf den Standort, Bezugspunkt wird GPS. Die Systemabfrage kommt
  /// nur hier, also nach einem Tipp. Dauerhaft abgelehnt: Dialog.
  Future<void> zentriereAufStandort(BuildContext context) async {
    final status = await _ref
        .read(locationPermissionProvider.notifier)
        .refresh();
    if (status == OsLocationStatus.deniedForever) {
      if (context.mounted) await zeigeEinstellungenDialog(context, _ref);
      return;
    }
    if (!context.mounted) return;
    try {
      final ok = await LocationGate.ensureMap(context, _ref);
      if (!ok) return;
      _ref.read(karteBezugProvider.notifier).verwerfeKarte();
      final fix = await _ref
          .read(userPositionProvider.notifier)
          .refresh(force: true);
      if (fix != null) {
        _ref.read(locateTargetProvider.notifier).goTo(fix.position);
      }
    } on LocationException catch (e) {
      if (!context.mounted) return;
      if (e.kind == LocationFailure.deniedForever) {
        await zeigeEinstellungenDialog(context, _ref);
      } else {
        showLocationError(context, e);
      }
    }
  }

  /// „In diesem Bereich suchen“: Kartenmitte wird Bezugspunkt, Ortsname per
  /// Reverse-Geocoding gegen die gebündelten Orte.
  Future<void> sucheImBereich(LatLng mitte) async {
    PlaceIndex? index;
    try {
      index = await _ref.read(placeIndexProvider.future);
    } catch (_) {}
    await _ref
        .read(karteBezugProvider.notifier)
        .setzeKarte(
          Bezugspunkt(
            quelle: BezugQuelle.karte,
            coords: mitte,
            ortName: index?.nearest(mitte)?.name,
          ),
        );
  }
}

/// Dialog für dauerhaft abgelehnten Standort (`standort.dialog.*`).
Future<void> zeigeEinstellungenDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(kt('standort.dialog.text')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(kt('allg.schliessen')),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            ref.read(locationPermissionProvider.notifier).openSystemSettings();
          },
          child: Text(kt('standort.dialog.button')),
        ),
      ],
    ),
  );
}
