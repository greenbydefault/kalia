import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/species.dart';
import 'species_repository.dart';

/// Offline-Katalog aus dem gebuendelten Asset.
class SeedSpeciesRepository implements SpeciesRepository {
  static const assetPath = 'assets/seed/species.json';

  @override
  Future<List<Species>> getCatalog() async {
    final raw = await rootBundle.loadString(assetPath);
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Species.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
