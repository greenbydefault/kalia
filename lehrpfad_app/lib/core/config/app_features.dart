/// Zentrale Feature-Schalter (Compile-Time).
abstract final class AppFeatures {
  /// Tour-Modus (GPS-Walk). v1 aus; lokal testbar per
  /// `--dart-define=FEATURE_TOUR=true`. Zum Aktivieren später
  /// `defaultValue: true` setzen.
  static const tour = bool.fromEnvironment('FEATURE_TOUR');
}
