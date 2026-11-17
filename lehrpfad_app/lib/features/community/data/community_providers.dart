import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_client_provider.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/trail_comment.dart';
import '../domain/trail_image.dart';
import '../domain/trail_rating.dart';
import '../domain/user_profile.dart';
import 'comments_repository.dart';
import 'image_upload_service.dart';
import 'images_repository.dart';
import 'profiles_repository.dart';
import 'ratings_repository.dart';
import 'supabase_comments_repository.dart';
import 'supabase_images_repository.dart';
import 'supabase_profiles_repository.dart';
import 'supabase_ratings_repository.dart';

/// Community-Repositories gibt es nur mit Supabase-Anbindung; im
/// Seed-Modus sind sie null und die UI blendet die Bereiche aus.
final imagesRepositoryProvider = Provider<ImagesRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseImagesRepository(client);
});

final ratingsRepositoryProvider = Provider<RatingsRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseRatingsRepository(client);
});

final commentsRepositoryProvider = Provider<CommentsRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseCommentsRepository(client);
});

final imageUploadServiceProvider = Provider<ImageUploader?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return ImageUploadService(client);
});

final profilesRepositoryProvider = Provider<ProfilesRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseProfilesRepository(client);
});

/// Profil des eingeloggten Users (Anzeigename, Rolle), null wenn
/// ausgeloggt oder Seed-Modus.
final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final repo = ref.watch(profilesRepositoryProvider);
  if (repo == null) return null;
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return repo.getProfile(user.id);
});

final isAdminProvider = Provider<bool>(
  (ref) => ref.watch(currentProfileProvider).value?.isAdmin ?? false,
);

/// Sichtbare Bilder eines Trails. Re-fetch bei Login/Logout, weil dann
/// eigene pending-Bilder bzw. Admin-Sichtbarkeit wechseln.
final trailImagesProvider = FutureProvider.family<List<TrailImage>, String>((
  ref,
  trailId,
) {
  ref.watch(authStateProvider);
  final repo = ref.watch(imagesRepositoryProvider);
  if (repo == null) return Future.value(const <TrailImage>[]);
  return repo.getImages(trailId);
});

/// Eigene Uploads in jedem Status, neueste zuerst. Leer ausgeloggt.
final myImagesProvider = FutureProvider<List<TrailImage>>((ref) {
  final user = ref.watch(authStateProvider).value;
  final repo = ref.watch(imagesRepositoryProvider);
  if (repo == null || user == null) return Future.value(const <TrailImage>[]);
  return repo.getMyImages();
});

/// Eigene Kommentare ueber alle Trails, neueste zuerst. Leer ausgeloggt.
final myCommentsProvider = FutureProvider<List<TrailComment>>((ref) {
  final user = ref.watch(authStateProvider).value;
  final repo = ref.watch(commentsRepositoryProvider);
  if (repo == null || user == null) {
    return Future.value(const <TrailComment>[]);
  }
  return repo.getMyComments();
});

/// Zaehler fuer den Konto-Kopf.
class ContributionStats {
  final int photos;
  final int pending;
  final int approved;
  final int rejected;
  final int comments;

  const ContributionStats({
    this.photos = 0,
    this.pending = 0,
    this.approved = 0,
    this.rejected = 0,
    this.comments = 0,
  });

  static const empty = ContributionStats();

  bool get isEmpty => photos == 0 && comments == 0;
}

final myContributionStatsProvider = Provider<ContributionStats>((ref) {
  final images = ref.watch(myImagesProvider).value ?? const <TrailImage>[];
  final comments = ref.watch(myCommentsProvider).value ?? const [];
  int count(TrailImageStatus s) => images.where((i) => i.status == s).length;
  return ContributionStats(
    photos: images.length,
    pending: count(TrailImageStatus.pending),
    approved: count(TrailImageStatus.approved),
    rejected: count(TrailImageStatus.rejected),
    comments: comments.length,
  );
});

/// Offene Moderationsqueue (nur Admins). Wartet aufs Profil, damit nach
/// Admin-Login nicht kurz eine leere Liste kommt.
final pendingImagesProvider = FutureProvider<List<TrailImage>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null || !profile.isAdmin) return const <TrailImage>[];
  final repo = ref.watch(imagesRepositoryProvider);
  if (repo == null) return const <TrailImage>[];
  return repo.getPendingImages();
});

final trailRatingProvider = FutureProvider.family<TrailRating, String>((
  ref,
  trailId,
) {
  ref.watch(authStateProvider);
  final repo = ref.watch(ratingsRepositoryProvider);
  if (repo == null) return Future.value(TrailRating.empty);
  return repo.getRating(trailId);
});

final trailCommentsProvider = FutureProvider.family<List<TrailComment>, String>(
  (ref, trailId) {
    ref.watch(authStateProvider);
    final repo = ref.watch(commentsRepositoryProvider);
    if (repo == null) return Future.value(const <TrailComment>[]);
    return repo.getComments(trailId);
  },
);
