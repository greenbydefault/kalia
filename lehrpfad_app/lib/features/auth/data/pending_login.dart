import 'package:shared_preferences/shared_preferences.dart';

/// E-Mail, an die zuletzt ein Code ging. Überlebt den App-Neustart
/// beim Wechsel in die Mail-App; nach Ablauf des Codes wertlos.
class PendingLogin {
  const PendingLogin({required this.email, required this.sentAt});

  final String email;
  final DateTime sentAt;

  static const codeLifetime = Duration(minutes: 60);
  static const _emailKey = 'auth.pending.email';
  static const _sentAtKey = 'auth.pending.sentAt';

  bool get isValid => DateTime.now().difference(sentAt) < codeLifetime;

  static Future<PendingLogin?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);
    final sentAtMs = prefs.getInt(_sentAtKey);
    if (email == null || sentAtMs == null) return null;
    final pending = PendingLogin(
      email: email,
      sentAt: DateTime.fromMillisecondsSinceEpoch(sentAtMs),
    );
    if (!pending.isValid) {
      await clear();
      return null;
    }
    return pending;
  }

  static Future<void> save(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
    await prefs.setInt(_sentAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_sentAtKey);
  }
}
