import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/app/theme/app_spacing.dart';

void main() {
  test('Rollen liegen auf dem 4-px-Raster und in der richtigen Ordnung', () {
    const roles = {
      'page': AppSpacing.page,
      'afterHeading': AppSpacing.afterHeading,
      'stack': AppSpacing.stack,
      'section': AppSpacing.section,
      'chip': AppSpacing.chip,
    };

    for (final e in roles.entries) {
      expect(e.value % 4, 0, reason: e.key);
    }
    expect(AppSpacing.afterHeading, lessThan(AppSpacing.stack));
    expect(AppSpacing.stack, lessThan(AppSpacing.section));
  });
}
