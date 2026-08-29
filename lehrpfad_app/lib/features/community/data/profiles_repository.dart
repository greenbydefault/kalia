import '../domain/user_profile.dart';

/// Profile der Nutzer (Anzeigename, Rolle).
abstract class ProfilesRepository {
  /// Profil zur [userId], null wenn nicht vorhanden.
  Future<UserProfile?> getProfile(String userId);
}
