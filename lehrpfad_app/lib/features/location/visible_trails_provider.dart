import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../trail/data/providers.dart';
import '../trail/domain/trail.dart';
import '../trail/presentation/map/map_typ_filter.dart';
import 'map_radius.dart';
import 'user_position_provider.dart';

/// Typ × Umkreis. `null` solange die Trails noch laden.
final visibleTrailsProvider = Provider<List<Trail>?>((ref) {
  final trails = ref.watch(trailsProvider).asData?.value;
  if (trails == null) return null;
  final typ = ref.watch(mapTypFilterProvider);
  final byTyp = filterTrailsByTyp(trails, typ) ?? const [];
  final radius = ref.watch(effectiveMapRadiusProvider);
  final pos = ref.watch(userPositionProvider).fix?.position;
  return filterTrailsByRadius(byTyp, radius: radius, user: pos);
});
