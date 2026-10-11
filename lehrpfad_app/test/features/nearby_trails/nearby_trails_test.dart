import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/app/theme/app_theme.dart';
import 'package:lehrpfad_app/features/auth/presentation/account_prompt_sheet.dart';
import 'package:lehrpfad_app/features/nearby_trails/data/nearby_trails_provider.dart';
import 'package:lehrpfad_app/features/nearby_trails/domain/anfahrt.dart';
import 'package:lehrpfad_app/features/onboarding/data/onboarding_prefs_provider.dart';
import 'package:lehrpfad_app/features/player/data/mini_player_provider.dart';
import 'package:lehrpfad_app/features/trail/data/seed_trail_repository.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';
import 'package:lehrpfad_app/features/trail_progress/data/trail_progress_providers.dart';
import 'package:lehrpfad_app/features/trail_progress/data/trail_list_providers.dart';
import 'package:lehrpfad_app/features/trail_progress/presentation/quick_merken.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wartet (echte Zeit), bis [done] stimmt.
Future<void> until(bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(done(), isTrue, reason: 'Provider nicht geladen');
}

Future<void> loaded(ProviderContainer c) => until(
  () =>
      c.read(trailBookmarksProvider).hasValue &&
      c.read(trailListsProvider).hasValue &&
      c.read(onboardingPrefsProvider).hasValue,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Trail> trails;

  setUpAll(() async {
    trails = await SeedTrailRepository().getTrails();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Anfahrt', () {
    test('rundet und nennt ca.', () {
      expect(anfahrtMinuten(1000), 1);
      expect(anfahrtMinuten(10000), 13);
      expect(anfahrtMinuten(30000), 40);
      expect(anfahrtLabel(10000), 'ca. 13 Min mit dem Auto');
      expect(anfahrtLabel(120000), 'ca. 2 Std 35 Min mit dem Auto');
      expect(anfahrtLabel(100000 * 1.0), contains('Std'));
    });

    test('nie unter 1 Minute', () => expect(anfahrtMinuten(0), 1));
  });

  group('selectNearbyTrails', () {
    const anchor = LatLng(53.0, 13.0);

    List<NearbyTrailEntry> select({
      int? maxKm,
      bool stroller = false,
      bool lengthOn = true,
      bool strollerOn = true,
    }) => selectNearbyTrails(
      trails,
      maxKm: maxKm,
      stroller: stroller,
      lengthOn: lengthOn,
      strollerOn: strollerOn,
      anchor: anchor,
    );

    test('höchstens $nearbyTrailCount Wege, nie leer', () {
      final r = select(maxKm: 0, stroller: true);
      expect(r, hasLength(nearbyTrailCount));
    });

    test('passende Wege vor unpassenden, danach nach Entfernung', () {
      final r = select(maxKm: 3);
      final firstMiss = r.indexWhere((e) => !e.matches);
      if (firstMiss >= 0) {
        expect(r.skip(firstMiss).every((e) => !e.matches), isTrue);
      }
      for (final group in [
        r.where((e) => e.matches),
        r.where((e) => !e.matches),
      ]) {
        final d = group.map((e) => e.distanceM!).toList();
        expect(d, orderedEquals([...d]..sort()));
      }
    });

    test('Länge-Filter: Treffer sind Fläche oder innerhalb des Limits', () {
      for (final e in select(maxKm: 3).where((e) => e.matches)) {
        expect(e.trail.isFlaeche || e.trail.laengeKm <= 3, isTrue);
      }
    });

    test('Kinderwagen: Treffer sind kinderwagentauglich', () {
      final r = select(stroller: true, lengthOn: false);
      for (final e in r.where((e) => e.matches)) {
        expect(isStrollerFriendly(e.trail), isTrue);
      }
    });

    test('Filter aus: alles passt', () {
      final r = select(lengthOn: false, strollerOn: false, stroller: true);
      expect(r.every((e) => e.matches), isTrue);
    });

    test('ohne Anker keine Distanz', () {
      final r = selectNearbyTrails(
        trails,
        maxKm: null,
        stroller: false,
        lengthOn: true,
        strollerOn: true,
        anchor: null,
      );
      expect(r.every((e) => e.distanceM == null), isTrue);
    });
  });

  group('Mini-Player', () {
    test('play, pausieren, fortsetzen, stoppen', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(miniPlayerProvider.notifier);
      final t = trails.first;

      expect(c.read(miniPlayerProvider), isNull);
      n.play(t);
      expect(c.read(miniPlayerProvider)!.trail.id, t.id);
      expect(n.isPlaying(t.id), isTrue);

      n.play(t); // gleicher Trail = toggle
      expect(c.read(miniPlayerProvider)!.playing, isFalse);
      n.toggle();
      expect(c.read(miniPlayerProvider)!.playing, isTrue);

      n.play(trails[1]);
      expect(c.read(miniPlayerProvider)!.trail.id, trails[1].id);

      n.stop();
      expect(c.read(miniPlayerProvider), isNull);
    });
  });

  group('Merken ohne Konto', () {
    Future<void> pump(
      WidgetTester tester,
      ProviderContainer container,
      Trail trail,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () => quickToggleMerken(context, ref, trail),
                  child: const Text('merken'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Toast nur beim ersten Merken', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.runAsync(() => loaded(container));
      await pump(tester, container, trails.first);

      await tester.tap(find.text('merken'));
      await tester.pumpAndSettle();
      expect(find.text(savedWithoutAccountToast), findsOneWidget);
      expect(
        container.read(trailBookmarksProvider).value,
        contains(trails.first.id),
      );

      // wieder entfernen und neu merken: kein zweiter Toast
      ScaffoldMessenger.of(
        tester.element(find.text('merken')),
      ).clearSnackBars();
      await tester.pumpAndSettle();
      await tester.tap(find.text('merken'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('merken'));
      await tester.pumpAndSettle();
      expect(find.text(savedWithoutAccountToast), findsNothing);
      expect(
        container.read(onboardingPrefsValueProvider).saveToastSeen,
        isTrue,
      );
    });

    test('Zähler: null beim Laden, danach Anzahl', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.listen(savedTrailCountProvider, (_, _) {});
      expect(c.read(savedTrailCountProvider), isNull);
      await loaded(c);
      expect(c.read(savedTrailCountProvider), 0);
      await c
          .read(trailBookmarksProvider.notifier)
          .setBookmarked(trails.first.id, true);
      expect(c.read(savedTrailCountProvider), 1);
    });
  });

  group('requireAccount', () {
    testWidgets('ohne Server: Hinweis statt Konto', (tester) async {
      bool? result;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async => result = await requireAccount(
                    context,
                    reason: AccountReason.rate,
                  ),
                  child: const Text('los'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('los'));
      await tester.pump();
      await tester.pump();
      expect(result, isFalse);
      expect(find.textContaining('Serververbindung'), findsOneWidget);
    });
  });
}
