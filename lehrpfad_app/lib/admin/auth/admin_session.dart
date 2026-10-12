import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wo steht die Session auf dem Weg zum Editieren?
enum AdminGate {
  loading,
  signedOut,
  notAdmin,
  needsMfaEnroll,
  needsMfaChallenge,
  ok,
}

/// Hört auf den Auth-Stream und berechnet daraus das Gate. Schreiben im
/// Katalog braucht Admin-Rolle **und** AAL2 (siehe `is_catalog_editor()`),
/// deshalb endet der Weg erst nach TOTP in [AdminGate.ok].
/// Dient dem Router als `refreshListenable`.
class AdminSession extends ChangeNotifier {
  AdminSession(this._client) {
    _sub = _client.auth.onAuthStateChange.listen((_) => refresh());
    refresh();
  }

  final SupabaseClient _client;
  late final StreamSubscription<AuthState> _sub;
  int _generation = 0;

  AdminGate gate = AdminGate.loading;

  String? get email => _client.auth.currentUser?.email;

  Future<void> refresh() async {
    final gen = ++_generation;
    final next = await _compute();
    if (gen != _generation || next == gate) return;
    gate = next;
    notifyListeners();
  }

  Future<AdminGate> _compute() async {
    final user = _client.auth.currentUser;
    if (user == null) return AdminGate.signedOut;
    try {
      final row = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      if (row?['role'] != 'admin') return AdminGate.notAdmin;
    } catch (_) {
      return AdminGate.notAdmin;
    }
    final aal = _client.auth.mfa.getAuthenticatorAssuranceLevel();
    if (aal.currentLevel == AuthenticatorAssuranceLevels.aal2) {
      return AdminGate.ok;
    }
    final verified = (user.factors ?? const <Factor>[]).any(
      (f) => f.status == FactorStatus.verified,
    );
    return verified || aal.nextLevel == AuthenticatorAssuranceLevels.aal2
        ? AdminGate.needsMfaChallenge
        : AdminGate.needsMfaEnroll;
  }

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
