import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../data/community_providers.dart';

/// Sterne-Bewertung eines Trails: Durchschnitt + Anzahl, darunter die
/// eigene Bewertung (antippbar, eingeloggt). Tippt man den bereits
/// gewaehlten Stern erneut, wird die Bewertung entfernt.
class RatingSection extends ConsumerWidget {
  final String trailId;

  const RatingSection({super.key, required this.trailId});

  Future<void> _setRating(WidgetRef ref, BuildContext context, int stars) async {
    final repo = ref.read(ratingsRepositoryProvider);
    if (repo == null) return;
    final current = ref.read(trailRatingProvider(trailId)).value?.myStars;
    try {
      if (current == stars) {
        await repo.removeRating(trailId);
      } else {
        await repo.setRating(trailId, stars);
      }
      ref.invalidate(trailRatingProvider(trailId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bewertung fehlgeschlagen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingAsync = ref.watch(trailRatingProvider(trailId));
    final loggedIn = ref.watch(authStateProvider).value != null;
    final theme = Theme.of(context);
    final rating = ratingAsync.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Stars(value: rating?.average ?? 0, size: 22),
            const SizedBox(width: 8),
            Text(
              rating == null || rating.count == 0
                  ? 'Noch keine Bewertungen'
                  : '${rating.average.toStringAsFixed(1)} '
                      '(${rating.count} ${rating.count == 1 ? 'Bewertung' : 'Bewertungen'})',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (loggedIn)
          Row(
            children: [
              Text('Deine Bewertung:', style: theme.textTheme.bodySmall),
              const SizedBox(width: 8),
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => _setRating(ref, context, i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      i <= (rating?.myStars ?? 0)
                          ? Icons.star
                          : Icons.star_border,
                      size: 28,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          )
        else
          Text(
            'Melde dich an, um zu bewerten.',
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }
}

/// Statische Sterne-Anzeige fuer den Durchschnitt (mit halben Sternen).
class _Stars extends StatelessWidget {
  final double value;
  final double size;

  const _Stars({required this.value, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            value >= i
                ? Icons.star
                : value >= i - 0.5
                    ? Icons.star_half
                    : Icons.star_border,
            size: size,
            color: color,
          ),
      ],
    );
  }
}
