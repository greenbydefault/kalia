/// Profil des eingeloggten Users (Anzeigename + Rolle).
class UserProfile {
  final String id;
  final String displayName;
  final String role;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.role,
  });

  bool get isAdmin => role == 'admin';
}
