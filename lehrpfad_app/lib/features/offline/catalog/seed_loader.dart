import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/trail_index_entry.dart';
import '../offline_config.dart';
import '../storage/offline_database.dart';

/// Ein Eintrag aus `assets/seed/index.json`.
class SeedTrailRef {
  const SeedTrailRef({
    required this.id,
    required this.dataVersion,
    required this.file,
    this.thumb,
    this.thumbImage,
  });

  final String id;
  final int dataVersion;

  /// Dateiname unter `assets/seed/`.
  final String file;

  /// Asset-Pfad relativ zu `assets/seed/` (`thumbs/<id>.webp` oder `.avif`).
  final String? thumb;

  /// `images.id` des gebündelten Thumbs.
  final String? thumbImage;

  String get assetPath => '${OfflineConfig.seedDir}/$file';

  factory SeedTrailRef.fromJson(Map<String, dynamic> json) => SeedTrailRef(
    id: json['id'] as String,
    dataVersion: (json['dataVersion'] as num?)?.toInt() ?? 1,
    file: json['file'] as String,
    thumb: json['thumb'] as String?,
    thumbImage: json['thumbImage'] as String?,
  );
}

class SeedIndex {
  const SeedIndex(this.trails);

  final List<SeedTrailRef> trails;

  factory SeedIndex.parse(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return SeedIndex([
      for (final t in json['trails'] as List)
        SeedTrailRef.fromJson(t as Map<String, dynamic>),
    ]);
  }

  /// trailId → imageId des gebündelten Thumbs (Resolver-Fallback).
  Map<String, String> get thumbImages => {
    for (final t in trails)
      if (t.thumb != null && t.thumbImage != null) t.id: t.thumbImage!,
  };
}

/// Liest den gebündelten Katalog. Der Seed ist nur Erststart-Inhalt und
/// Fallback: die Liste der Trails steht in `index.json`, nicht im Code.
class SeedLoader {
  SeedLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  Future<SeedIndex> loadIndex() async =>
      SeedIndex.parse(await _bundle.loadString(OfflineConfig.seedIndexAsset));

  /// `null`, wenn die Datei fehlt oder defekt ist: ein kaputter Seed darf die
  /// übrigen Trails nicht blockieren.
  Future<TrailIndexEntry?> loadTrail(SeedTrailRef ref) async {
    try {
      final json =
          jsonDecode(await _bundle.loadString(ref.assetPath))
              as Map<String, dynamic>;
      return TrailIndexEntry(
        id: ref.id,
        dataVersion: ref.dataVersion,
        json: json,
      );
    } catch (e) {
      debugPrint('SeedLoader: "${ref.assetPath}" übersprungen ($e)');
      return null;
    }
  }

  Future<List<TrailIndexEntry>> loadTrails([SeedIndex? index]) async {
    final idx = index ?? await loadIndex();
    final loaded = await Future.wait([
      for (final t in idx.trails) loadTrail(t),
    ]);
    return [for (final e in loaded) ?e];
  }

  Future<List<SpeciesIndexEntry>> loadSpecies([String? raw]) async {
    final text =
        raw ?? await _bundle.loadString(OfflineConfig.seedSpeciesAsset);
    return [
      for (final s in jsonDecode(text) as List)
        SpeciesIndexEntry(
          id: (s as Map<String, dynamic>)['id'] as String,
          version: (s['version'] as num?)?.toInt() ?? 1,
          json: s,
        ),
    ];
  }

  /// Spielt den Seed in die DB, wenn sich das Bundle geändert hat (Erststart
  /// oder App-Update). Überschreibt nur, was lokal fehlt oder älter ist, und
  /// löscht nie etwas (Tombstones kommen aus dem Sync).
  Future<bool> importInto(OfflineDatabase db) async {
    final indexRaw = await _bundle.loadString(OfflineConfig.seedIndexAsset);
    final speciesRaw = await _bundle.loadString(OfflineConfig.seedSpeciesAsset);
    final signature = '${_fnv1a(indexRaw)}-${_fnv1a(speciesRaw)}';
    if (await db.meta(OfflineDatabase.metaSeedSignature) == signature) {
      return false;
    }

    final localTrails = await db.trailVersions();
    final trails = await loadTrails(SeedIndex.parse(indexRaw));
    await db.upsertTrails([
      for (final t in trails)
        if (_isNewer(t.dataVersion, localTrails[t.id])) t,
    ]);

    final localSpecies = await db.speciesVersions();
    final species = await loadSpecies(speciesRaw);
    await db.upsertSpecies([
      for (final s in species)
        if (_isNewer(s.version, localSpecies[s.id])) s,
    ]);

    await db.setMeta(OfflineDatabase.metaSeedSignature, signature);
    return true;
  }

  static bool _isNewer(int seed, int? local) => local == null || seed > local;

  /// Stabiler 32-Bit-Hash (String.hashCode ist nicht über Läufe stabil).
  static int _fnv1a(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0xffffffff;
    }
    return h;
  }
}
