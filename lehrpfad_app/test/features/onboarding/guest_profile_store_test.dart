import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/onboarding/data/local_guest_profile_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('trimChildren drops blanks and trims', () {
    expect(LocalGuestProfileStore.trimChildren(['  Anna  ', '', '  ', 'Leo']), [
      'Anna',
      'Leo',
    ]);
  });

  test('complete persists flag, name and trimmed children', () async {
    final store = LocalGuestProfileStore();
    await store.complete(
      displayName: '  Mira  ',
      childNames: ['  Eli  ', '', 'Noa'],
    );

    expect(await store.isCompleted(), isTrue);
    final profile = await store.readProfile();
    expect(profile.displayName, 'Mira');
    expect(profile.childNames, ['Eli', 'Noa']);
  });
}
