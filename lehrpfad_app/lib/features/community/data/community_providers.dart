import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/trail_comment.dart';
import '../domain/trail_image.dart';
import '../domain/trail_rating.dart';
import '../domain/user_profile.dart';
import 'comments_repository.dart';
import 'image_upload_service.dart';
import 'images_repository.dart';
import 'ratings_repository.dart';
import 'supabase_comments_repository.dart';
import 'supabase_images_repository.dart';
import 'supabase_ratings_repository.dart';

/// Community-Repositories gibt es nur mit Supabase-Anbindung; im
/// Seed-Modus sind sie null und die UI blendet die Bereiche aus.
final imagesRepositoryProvider = Provider<ImagesRepository?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  return SupabaseImagesRepository(Supabase.instance.client);
});

final ratingsRepositoryProvider = Provider<RatingsRepository?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  return SupabaseRatingsRepository(Supabase.instance.client);
});

final commentsRepositoryProvider = Provider<CommentsRepository?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  return SupabaseCommentsRepository(Supabase.instance.client);
});

final imageUploadServiceProvider = Provider<ImageUploadService?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  return ImageUploadService(Supabase.instance.client);
});

/// Profil des eingeloggten Users (Anzeigename, Rolle), null wenn
/// ausgeloggt oder Seed-Modus.
final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  if (!SupabaseConfig.isConfigured) return null;
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  final row = await Supabase.instance.client
      .from('profiles')
      .select('id, display_name, role')
      .eq('id', user.id)
      .maybeSingle();
  if (row == null) return null;
  return UserProfile(
    id: row['id'] as String,
    displayName: row['display_name'] as String? ?? '',
    role: row['role'] as String? ?? 'user',
  );
});

final isAdminProvider = Provider<bool>(
  (ref) => ref.watch(currentProfileProvider).value?.isAdmin ?? false,
);

/// Sichtbare Bilder eines Trails. Re-fetch bei Login/Logout, weil dann
/// eigene pending-Bilder bzw. Admin-Sichtbarkeit wechseln.
final trailImagesProvider =
    FutureProvider.family<List<TrailImage>, String>((ref, trailId) {
  ref.watch(authStateProvider);
  final repo = ref.watch(imagesRepositoryProvider);
  if (repo == null) return Future.value(const <TrailImage>[]);
  return repo.getImages(trailId);
});

/// Offene Moderationsqueue (nur Admins).
final pendingImagesProvider = FutureProvider<List<TrailImage>>((ref) {
  if (!ref.watch(isAdminProvider)) return Future.value(const <TrailImage>[]);
  final repo = ref.watch(imagesRepositoryProvider);
  if (repo == null) return Future.value(const <TrailImage>[]);
  return repo.getPendingImages();
});

final trailRatingProvider =
    FutureProvider.family<TrailRating, String>((ref, trailId) {
  ref.watch(authStateProvider);
  final repo = ref.watch(ratingsRepositoryProvider);
  if (repo == null) return Future.value(TrailRating.empty);
  return repo.getRating(trailId);
});

final trailCommentsProvider =
    FutureProvider.family<List<TrailComment>, String>((ref, trailId) {
  ref.watch(authStateProvider);
  final repo = ref.watch(commentsRepositoryProvider);
  if (repo == null) return Future.value(const <TrailComment>[]);
  return repo.getComments(trailId);
});
