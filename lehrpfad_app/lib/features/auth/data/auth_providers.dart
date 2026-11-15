import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_client_provider.dart';

/// Aktuell eingeloggter User, `null` wenn ausgeloggt.
/// Folgt dem Supabase-Auth-Stream; das erste Event (`initialSession`)
/// liefert die persistierte Session direkt nach dem App-Start.
/// Darf nur gelesen werden, wenn Supabase initialisiert ist
/// (siehe `SupabaseConfig.isConfigured`).
final authStateProvider = StreamProvider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const Stream.empty();
  return client.auth.onAuthStateChange.map((event) => event.session?.user);
});

/// Aktionen rund ums Konto. Passwortlos: E-Mail bekommt einen Code,
/// gleich für neue und bestehende Konten. Werfen bei Fehlern eine
/// `AuthException`, die die UI in deutsche Meldungen übersetzt.
final authControllerProvider = NotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends Notifier<void> {
  @override
  void build() {}

  GoTrueClient get _auth {
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      throw StateError('Auth ohne Supabase-Client.');
    }
    return client.auth;
  }

  /// Schickt den Code. Legt das Konto an, falls es noch keins gibt.
  Future<void> sendCode(String email) {
    return _auth.signInWithOtp(email: email, shouldCreateUser: true);
  }

  Future<void> verifyCode({required String email, required String code}) {
    return _auth.verifyOTP(type: OtpType.email, email: email, token: code);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }
}

/// Name gilt als nicht gesetzt, solange er leer ist oder dem
/// E-Mail-Präfix entspricht (Default aus `handle_new_user`).
bool isDisplayNameUnset(String displayName, String? email) {
  final name = displayName.trim();
  if (name.isEmpty) return true;
  if (email == null) return false;
  return name == email.split('@').first;
}
