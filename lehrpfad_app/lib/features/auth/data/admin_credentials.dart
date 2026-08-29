import 'package:flutter/foundation.dart';

/// Debug-Admin. Prefill nur in [kDebugMode], nicht im Release-Bundle.
abstract final class AdminCredentials {
  static const emailAddress = 'admin@lehrpfad.app';

  static String get email => kDebugMode ? emailAddress : '';

  static String get password => kDebugMode ? 'LehrpfadAdmin2026!' : '';
}
