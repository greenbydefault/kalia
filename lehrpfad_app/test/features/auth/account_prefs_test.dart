import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/app/theme/app_theme.dart';
import 'package:lehrpfad_app/features/auth/presentation/account_prefs_sections.dart';
import 'package:lehrpfad_app/features/location/location_permission_controller.dart';
import 'package:lehrpfad_app/features/location/location_settings_section.dart';
import 'package:lehrpfad_app/features/location/user_position_provider.dart';
import 'package:lehrpfad_app/features/onboarding/data/onboarding_prefs_provider.dart';
import 'package:lehrpfad_app/features/onboarding/data/onboarding_prefs_store.dart';
import 'package:lehrpfad_app/features/onboarding/domain/age_group.dart';
import 'package:lehrpfad_app/features/onboarding/domain/user_place.dart';
import 'package:lehrpfad_app/features/trail_progress/tracking/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_location_service.dart';

const _leipzig = UserPlace(
  name: 'Leipzig',
  plz: '04103',
  lat: 51.34,
  lon: 12.38,
);

ProviderContainer _container() {
  final c = ProviderContainer(
    overrides: [
      locationServiceProvider.overrideWithValue(
        FakeLocationService(status0: OsLocationStatus.whileInUse),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

Future<void> _settleContainer(ProviderContainer c) async {
  await c.read(onboardingPrefsProvider.future);
  c.read(mapLocationEnabledProvider);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Anker-Wechsel', () {
    test('Ort wählen: Standort aus, gespeicherte Position weg', () async {
      SharedPreferences.setMockInitialValues({
        'map_location_enabled': true,
        'last_map_lat': 51.0,
        'last_map_lon': 12.0,
        'last_map_at': 1,
      });
      final c = _container();
      await _settleContainer(c);

      await c.read(onboardingPrefsProvider.notifier).setPlace(_leipzig);

      expect(c.read(mapLocationEnabledProvider), isFalse);
      expect(c.read(mapAnchorProvider), _leipzig.position);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('last_map_lat'), isNull);
      expect(prefs.getBool('map_location_enabled'), isFalse);
    });

    test('Standort wählen: Ort weg, Standort an, auch gespeichert', () async {
      final c = _container();
      await _settleContainer(c);
      await c.read(onboardingPrefsProvider.notifier).setPlace(_leipzig);

      await c.read(onboardingPrefsProvider.notifier).useDevicePosition();

      expect(c.read(onboardingPrefsValueProvider).place, isNull);
      expect(c.read(mapLocationEnabledProvider), isTrue);
      final stored = await OnboardingPrefsStore().read();
      expect(stored.place, isNull);
    });

    test('Position löschen: Standort aus, kein Anker', () async {
      final c = _container();
      await _settleContainer(c);
      await c.read(onboardingPrefsProvider.notifier).useDevicePosition();
      await c.read(userPositionProvider.notifier).refresh(force: true);
      expect(c.read(mapAnchorProvider), isNotNull);

      await c.read(userPositionProvider.notifier).clearStored();

      expect(c.read(mapLocationEnabledProvider), isFalse);
      expect(c.read(mapAnchorProvider), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('last_map_lat'), isNull);
    });
  });

  group('Konto-Sektionen', () {
    Future<ProviderContainer> pump(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final container = _container();
      await tester.runAsync(() => _settleContainer(container));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    GroupPrefsSection(),
                    StartpointSection(),
                    LocationSettingsSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return container;
    }

    testWidgets('Gruppe antippen speichert und „Unter 3“ setzt Kinderwagen', (
      tester,
    ) async {
      final c = await pump(tester);

      await tester.tap(find.widgetWithText(FilterChip, '3 bis 5'));
      await tester.pump();
      var prefs = c.read(onboardingPrefsValueProvider);
      expect(prefs.ageGroups, {AgeGroup.threeToFive});
      expect(prefs.stroller, isFalse);

      await tester.tap(find.widgetWithText(FilterChip, 'Unter 3'));
      await tester.pump();
      prefs = c.read(onboardingPrefsValueProvider);
      expect(prefs.ageGroups, {AgeGroup.under3, AgeGroup.threeToFive});
      expect(prefs.stroller, isTrue);

      final stored = await tester.runAsync(() => OnboardingPrefsStore().read());
      expect(stored!.ageGroups, prefs.ageGroups);
      expect(stored.stroller, isTrue);
    });

    testWidgets('Startpunkt zeigt gewählten Ort', (tester) async {
      final c = await pump(tester);
      expect(find.text('Ort wählen'), findsOneWidget);

      await tester.runAsync(
        () => c.read(onboardingPrefsProvider.notifier).setPlace(_leipzig),
      );
      await tester.pump();

      expect(find.text('Rund um Leipzig (04103)'), findsOneWidget);
    });

    testWidgets('Umkreis-Hinweis nur ohne Ort und Standort', (tester) async {
      final c = await pump(tester);
      const hint = 'Ohne Ort oder Standort zeigt die Karte alle Wege.';
      expect(find.text(hint), findsOneWidget);

      await tester.runAsync(
        () => c.read(onboardingPrefsProvider.notifier).setPlace(_leipzig),
      );
      await tester.pump();

      expect(find.text(hint), findsNothing);
    });
  });
}
