import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/species/data/hybrid_sightings_repository.dart';
import 'package:lehrpfad_app/features/species/data/species_providers.dart';
import 'package:lehrpfad_app/features/species/presentation/gesehen_toggle.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/memory_funde_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('GesehenToggle toggles label and persists via provider', (
    tester,
  ) async {
    final store = MemoryFundeStore();
    final repo = HybridSightingsRepository(local: store);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sightingsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              final seen =
                  ref.watch(sightingsProvider).asData?.value.contains('biber') ??
                  false;
              return Scaffold(
                body: GesehenToggle(
                  seen: seen,
                  onChanged: (v) {
                    final funde = ref.read(fundeProvider.notifier);
                    v ? funde.entdecke('biber') : funde.entferne('biber');
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Hab gesehen'), findsOneWidget);

    await tester.tap(find.text('Hab gesehen'));
    await tester.pumpAndSettle();

    expect(find.text('Gesehen'), findsOneWidget);
    expect(store.ids, {'biber'});
    expect(store.funde['biber']!.entdecktAm, isNotNull);
  });
}
