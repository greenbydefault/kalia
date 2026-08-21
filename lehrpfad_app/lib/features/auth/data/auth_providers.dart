import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Aktuell eingeloggter User, `null` wenn ausgeloggt.
/// Folgt dem Supabase-Auth-Stream; das erste Event (`initialSession`)
/// liefert die persistierte Session direkt nach dem App-Start.
/// Darf nur gelesen werden, wenn Supabase initialisiert ist
/// (siehe `SupabaseConfig.isConfigured`).
final authStateProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange
      .map((event) => event.session?.user);
});

/// Aktionen rund ums Konto. Werfen bei Fehlern eine `AuthException`,
/// die die UI in deutsche Meldungen übersetzt.
final authControllerProvider = NotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends Notifier<void> {
  @override
  void build() {}

  GoTrueClient get _auth => Supabase.instance.client.auth;

  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _auth.signUp(
      email: email,
      password: password,
      data: displayName == null || displayName.isEmpty
          ? null
          : {'display_name': displayName},
    );
  }

  Future<void> signOut() {
    return _auth.signOut();
  }
}
