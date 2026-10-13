import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/app/theme/app_theme.dart';
import 'package:lehrpfad_app/features/onboarding/data/onboarding_prefs_provider.dart';
import 'package:lehrpfad_app/features/onboarding/data/onboarding_prefs_store.dart';
import 'package:lehrpfad_app/features/onboarding/data/place_search.dart';
import 'package:lehrpfad_app/features/onboarding/domain/age_group.dart';
import 'package:lehrpfad_app/features/onboarding/domain/user_place.dart';
import 'package:lehrpfad_app/features/onboarding/presentation/onboarding_flow.dart';
import 'package:lehrpfad_app/features/onboarding/presentation/screens/group_screen.dart';
import 'package:lehrpfad_app/features/trail_progress/tracking/location_service.dart';
import 'package:lehrpfad_app/shared/widgets/bottom_content_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_location_service.dart';

final _index = PlaceIndex(const [
  UserPlace(name: 'Leipzig', plz: '04109', lat: 51.342, lon: 12.375),
  UserPlace(name: 'Leipzig', plz: '04103', lat: 51.34, lon: 12.38),
  UserPlace(name: 'Leipzig-Marienbrunn', plz: '04277', lat: 51.31, lon: 12.38),
  UserPlace(name: 'Köln', plz: '50667', lat: 50.94, lon: 6.96),
]);

Widget _flowApp(FakeLocationService location) {
  return ProviderScope(
    overrides: [
      locationServiceProvider.overrideWithValue(location),
      placeIndexProvider.overrideWith((ref) async => _index),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: const _Gate()),
  );
}

/// Browser hat erlaubt, `ensurePermission` wirft trotzdem (Positionsfehler als
/// „dauerhaft verweigert“ gemeldet); der Status selbst ist erlaubt.
class _GrantedButFailingLocation extends FakeLocationService {
  @override
  Future<bool> ensurePermission({bool requestAlways = false}) async {
    status0 = OsLocationStatus.whileInUse;
    throw LocationException(
      LocationFailure.deniedForever,
      LocationException.deniedForeverMessage,
    );
  }
}

/// Wie AppShell: Flow solange `onboardingDone` fehlt, sonst „Home“.
class _Gate extends ConsumerWidget {
  const _Gate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(onboardingCompletedProvider);
    if (!done.hasValue) return const SizedBox();
    return done.value! ? const Text('HOME') : const OnboardingFlow();
  }
}

/// Wie pumpAndSettle, aber ohne an Endlosschleifen (Pin-Pulsringe) zu hängen.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> bigScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  group('PlaceIndex', () {
    test('Name: exakter Treffer zuerst, ein Treffer pro Ortsname', () {
      final hits = _index.search('leipzig');
      expect(hits.map((p) => p.name), ['Leipzig', 'Leipzig-Marienbrunn']);
      expect(hits.first.plz, '04103');
    });

    test('PLZ-Anfang und Umlaut-Faltung', () {
      expect(_index.search('041').map((p) => p.plz), ['04109', '04103']);
      expect(_index.search('koeln').single.name, 'Köln');
      expect(_index.search(''), isEmpty);
    });

    test('max. 4 Vorschläge', () {
      final many = PlaceIndex([
        for (var i = 0; i < 10; i++)
          UserPlace(name: 'Ort$i', plz: '0000$i', lat: 0, lon: 0),
      ]);
      expect(many.search('ort').length, 4);
    });
  });

  group('AgeGroup.minKm', () {
    test('Minimum über gewählte Gruppen', () {
      expect(AgeGroup.minKm({}), isNull);
      expect(AgeGroup.minKm({AgeGroup.tenPlus}), 10);
      expect(AgeGroup.minKm({AgeGroup.sixToNine, AgeGroup.threeToFive}), 3);
      expect(AgeGroup.minKm(AgeGroup.values), 3);
    });
  });

  testWidgets('Willkommen zeigt Copy, kein Zurück', (tester) async {
    await bigScreen(tester);
    await tester.pumpWidget(_flowApp(FakeLocationService()));
    await settle(tester);

    expect(find.text('Kleine Wege. Große Entdeckungen.'), findsOneWidget);
    expect(find.textContaining('Ohne Anmeldung'), findsOneWidget);
    expect(find.text('Los geht’s'), findsOneWidget);
    expect(find.byTooltip('Zurück'), findsNothing);
  });

  testWidgets('Erster Start bis Home in 3 Taps (Ort eingeben)', (tester) async {
    await bigScreen(tester);
    await tester.pumpWidget(_flowApp(FakeLocationService()));
    await settle(tester);

    await tester.tap(find.text('Los geht’s'));
    await settle(tester);
    expect(find.text('Mit wem seid ihr unterwegs?'), findsOneWidget);
    expect(find.text('Schritt 1 von 2'), findsOneWidget);

    await tester.tap(find.text('Überspringen'));
    await settle(tester);
    expect(find.text('Pfade in eurer Nähe'), findsOneWidget);
    expect(find.text('Schritt 2 von 2'), findsOneWidget);

    await tester.tap(find.text('Ort selbst eingeben'));
    await settle(tester);
    expect(find.text('Von wo startet ihr meistens?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Leipzig');
    await settle(tester);
    await tester.tap(find.text('04103'));
    await settle(tester);
    await tester.tap(find.text('Pfade anzeigen'));
    await settle(tester);

    expect(find.text('HOME'), findsOneWidget);
    final prefs = await tester.runAsync(
      () => ProviderContainer().read(onboardingPrefsStoreProvider).read(),
    );
    expect(prefs!.completed, isTrue);
    expect(prefs.place?.name, 'Leipzig');
    expect(prefs.place?.plz, '04103');
  });

  testWidgets('Standort erlaubt → Home, useLocation gesetzt', (tester) async {
    await bigScreen(tester);
    final fake = FakeLocationService();
    await tester.pumpWidget(_flowApp(fake));
    await settle(tester);

    await tester.tap(find.text('Los geht’s'));
    await settle(tester);
    await tester.tap(find.text('Überspringen'));
    await settle(tester);
    await tester.tap(find.text('Standort freigeben'));
    await settle(tester);

    expect(fake.requests, greaterThanOrEqualTo(1));
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('Freigabe trotz Positionsfehler (Web) → Home, kein Ort-Screen', (
    tester,
  ) async {
    await bigScreen(tester);
    final fake = _GrantedButFailingLocation();
    await tester.pumpWidget(_flowApp(fake));
    await settle(tester);

    await tester.tap(find.text('Los geht’s'));
    await settle(tester);
    await tester.tap(find.text('Überspringen'));
    await settle(tester);
    await tester.tap(find.text('Standort freigeben'));
    await settle(tester);

    expect(find.text('Von wo startet ihr meistens?'), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('Standort abgelehnt → Ort-Screen + Toast, nie leer', (
    tester,
  ) async {
    await bigScreen(tester);
    final fake = FakeLocationService(afterRequest: OsLocationStatus.denied);
    await tester.pumpWidget(_flowApp(fake));
    await settle(tester);

    await tester.tap(find.text('Los geht’s'));
    await settle(tester);
    await tester.tap(find.text('Überspringen'));
    await settle(tester);
    await tester.tap(find.text('Standort freigeben'));
    await settle(tester);

    expect(find.text('Von wo startet ihr meistens?'), findsOneWidget);
    expect(
      find.text('Kein Problem, gebt euren Ort einfach ein'),
      findsOneWidget,
    );
  });

  testWidgets('Dauerhaft abgelehnt → direkt Ort-Screen, Zurück zur Gruppe', (
    tester,
  ) async {
    await bigScreen(tester);
    final fake = FakeLocationService(status0: OsLocationStatus.deniedForever);
    await tester.pumpWidget(_flowApp(fake));
    await settle(tester);

    await tester.tap(find.text('Los geht’s'));
    await settle(tester);
    await tester.tap(find.text('Überspringen'));
    await settle(tester);

    expect(find.text('Von wo startet ihr meistens?'), findsOneWidget);
    expect(find.text('Einstellungen öffnen'), findsOneWidget);

    await tester.tap(find.byTooltip('Zurück'));
    await settle(tester);
    expect(find.text('Mit wem seid ihr unterwegs?'), findsOneWidget);
  });

  testWidgets('Zurück-Navigation auf jedem Screen außer Willkommen', (
    tester,
  ) async {
    await bigScreen(tester);
    await tester.pumpWidget(_flowApp(FakeLocationService()));
    await settle(tester);

    await tester.tap(find.text('Los geht’s'));
    await settle(tester);
    await tester.tap(find.text('Überspringen'));
    await settle(tester);
    await tester.tap(find.byTooltip('Zurück'));
    await settle(tester);
    expect(find.text('Mit wem seid ihr unterwegs?'), findsOneWidget);
    await tester.tap(find.byTooltip('Zurück'));
    await settle(tester);
    expect(find.text('Kleine Wege. Große Entdeckungen.'), findsOneWidget);
  });

  group('Gruppen-Screen', () {
    testWidgets('Hinweis leer, dann Minimum und Kinderwagen', (tester) async {
      await bigScreen(tester);
      await tester.pumpWidget(_flowApp(FakeLocationService()));
      await settle(tester);
      await tester.tap(find.text('Los geht’s'));
      await settle(tester);

      expect(find.text(GroupHintBox.emptyText), findsOneWidget);

      await tester.tap(find.text('10 und älter'));
      await settle(tester);
      expect(
        find.text('Wir zeigen euch zuerst Wege bis ca. 10 km.'),
        findsOneWidget,
      );

      // „Unter 3“ schaltet Kinderwagen automatisch an, Minimum 4 vs. 10 = 4.
      await tester.tap(find.text('Unter 3'));
      await settle(tester);
      expect(
        find.text(
          'Wir zeigen euch zuerst Wege bis ca. 4 km, die mit Kinderwagen gehen.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Weiter speichert Gruppen und Kinderwagen', (tester) async {
      await bigScreen(tester);
      await tester.pumpWidget(_flowApp(FakeLocationService()));
      await settle(tester);
      await tester.tap(find.text('Los geht’s'));
      await settle(tester);
      await tester.tap(find.text('3 bis 5'));
      await tester.pump();
      await tester.tap(find.text('Weiter'));
      await settle(tester);

      final prefs = await tester.runAsync(
        () => ProviderContainer().read(onboardingPrefsStoreProvider).read(),
      );
      expect(prefs!.ageGroups, {AgeGroup.threeToFive});
      expect(prefs.stroller, isFalse);
      expect(prefs.maxLaengeKm, 3);
    });

    testWidgets('Reduzierte Bewegung: keine Endlosschleife', (tester) async {
      await bigScreen(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(_flowApp(FakeLocationService()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Los geht’s'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Überspringen'));
      // Pin-Pulsringe sind aus, pumpAndSettle terminiert.
      await tester.pumpAndSettle();
      expect(find.text('Pfade in eurer Nähe'), findsOneWidget);
    });
  });

  group('Gate', () {
    testWidgets('leere Prefs → Onboarding aktiv', (tester) async {
      await tester.pumpWidget(_gateApp());
      await tester.pump();
      await tester.pump();
      expect(find.text('active'), findsOneWidget);
    });

    testWidgets('zweiter Start → direkt fertig', (tester) async {
      SharedPreferences.setMockInitialValues({
        OnboardingPrefsStore.completedKey: true,
      });
      await tester.pumpWidget(_gateApp());
      await tester.pump();
      await tester.pump();
      expect(find.text('done'), findsOneWidget);
    });
  });

  testWidgets('BottomContentCard caps height', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BottomContentCard(
            child: SizedBox(height: 4000, child: Text('tall')),
          ),
        ),
      ),
    );
    await tester.pump();

    final card = find.descendant(
      of: find.byType(BottomContentCard),
      matching: find.byType(DecoratedBox),
    );
    expect(
      tester.getSize(card.first).height,
      lessThanOrEqualTo(800 * 0.85 + 1),
    );
  });
}

Widget _gateApp() {
  return ProviderScope(
    child: MaterialApp(
      home: Consumer(
        builder: (context, ref, _) {
          final active = ref.watch(onboardingActiveProvider);
          return Text(active ? 'active' : 'done');
        },
      ),
    ),
  );
}
