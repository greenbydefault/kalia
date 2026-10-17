import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../nearby_trails/data/karte_state.dart';
import '../trail/domain/trail.dart';

/// Menge M als Trails: Umkreis (Anfahrt), Gebiet und Filter. Einzige
/// gefilterte Menge für Karte und Liste. `null` solange die Trails laden.
final visibleTrailsProvider = Provider<List<Trail>?>((ref) {
  final menge = ref.watch(mengeProvider);
  if (menge == null) return null;
  final byId = ref.watch(trailsByIdProvider);
  return [
    for (final t in menge)
      ?byId[t.eintrag.id],
  ];
});
