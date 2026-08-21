import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/app/theme/app_theme.dart';
import 'package:lehrpfad_app/features/onboarding/data/local_guest_profile_store.dart';
import 'package:lehrpfad_app/features/onboarding/data/onboarding_providers.dart';
import 'package:lehrpfad_app/features/onboarding/presentation/onboarding_overlay.dart';
import 'package:lehrpfad_app/features/trail/data/providers.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';
import 'package:lehrpfad_app/shared/widgets/bottom_content_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('splash then welcome card', (tester) async {
    await tester.pumpWidget(_overlayApp());
    await tester.pump();
    expect(find.text('Ohne Konto weiter'), findsNothing);

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Ohne Konto weiter'), findsOneWidget);
    expect(find.text('Konto erstellen'), findsOneWidget);
  });

  testWidgets('guest path completes and trims children', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_overlayApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.text('Ohne Konto weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Wer seid ihr?'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Dein Name'), 'Anna');
    await tester.enterText(
      find.widgetWithText(TextField, 'Name des Kindes'),
      '  ',
    );
    await tester.tap(find.text('Kind hinzufügen'));
    await tester.pump();
    expect(find.widgetWithText(TextField, 'Name des Kindes'), findsNWidgets(2));

    final childFields = find.widgetWithText(TextField, 'Name des Kindes');
    await tester.enterText(childFields.at(1), '  Eli  ');

    await tester.ensureVisible(find.text('Weiter'));
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Nicht jetzt'), findsOneWidget);

    await tester.tap(find.text('Nicht jetzt'));
    await tester.pumpAndSettle();

    final store = LocalGuestProfileStore();
    expect(await store.isCompleted(), isTrue);
    final profile = await store.readProfile();
    expect(profile.displayName, 'Anna');
    expect(profile.childNames, ['Eli']);
  });

  testWidgets('gate: empty prefs → onboarding active', (tester) async {
    await tester.pumpWidget(_gateApp());
    await tester.pump();
    await tester.pump();
    expect(find.text('active'), findsOneWidget);
  });

  testWidgets('gate: completed prefs → onboarding done', (tester) async {
    SharedPreferences.setMockInitialValues({
      LocalGuestProfileStore.completedKey: true,
    });
    await tester.pumpWidget(_gateApp());
    await tester.pump();
    await tester.pump();
    expect(find.text('done'), findsOneWidget);
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
    expect(find.text('tall'), findsOneWidget);
  });
}

Widget _overlayApp() {
  return ProviderScope(
    overrides: [trailsProvider.overrideWith((ref) async => <Trail>[])],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(body: OnboardingOverlay()),
    ),
  );
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
