import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/nearby.dart';
import 'nearby_zeiten_repository.dart';

/// Offline-Fahrzeiten aus dem gebündelten Asset.
class SeedNearbyZeitenRepository implements NearbyZeitenRepository {
  static const assetPath = 'assets/seed/nearby_zeiten.json';

  @override
  Future<NearbyZeiten> getZeiten() async {
    final raw = await rootBundle.loadString(assetPath);
    return zeitenFromSeedJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
