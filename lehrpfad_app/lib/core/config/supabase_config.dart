/// Supabase-Zugangsdaten, per `--dart-define` beim Build gesetzt:
/// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...`
/// Ohne Defines läuft die App gegen den lokalen Seed (Offline-Entwicklung,
/// Tests), es wird keine Verbindung aufgebaut.
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
