import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/merkmal.dart';
import '../domain/species.dart';
import 'species_repository.dart';

/// Offline-Katalog aus dem gebuendelten Asset.
class SeedSpeciesRepository implements SpeciesRepository {
  static const assetPath = 'assets/seed/species.json';
  static const merkmalePath = 'assets/seed/merkmale.json';

  @override
  Future<List<Species>> getCatalog() async {
    final raw = await rootBundle.loadString(assetPath);
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Species.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Merkmal>> getMerkmale() async {
    final raw = await rootBundle.loadString(merkmalePath);
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Merkmal.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
