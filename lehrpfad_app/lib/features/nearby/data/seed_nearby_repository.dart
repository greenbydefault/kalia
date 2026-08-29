import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/nearby_place.dart';
import 'nearby_repository.dart';

/// Offline-Katalog aus dem gebündelten Asset.
class SeedNearbyRepository implements NearbyRepository {
  static const assetPath = 'assets/seed/pois.json';

  @override
  Future<List<NearbyPlace>> getCatalog() async {
    final raw = await rootBundle.loadString(assetPath);
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => NearbyPlace.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
