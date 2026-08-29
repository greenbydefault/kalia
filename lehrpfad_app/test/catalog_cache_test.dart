import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/core/cache/catalog_cache.dart';
import 'package:lehrpfad_app/features/species/data/cached_species_repository.dart';
import 'package:lehrpfad_app/features/species/data/species_repository.dart';
import 'package:lehrpfad_app/features/species/domain/merkmal.dart';
import 'package:lehrpfad_app/features/species/domain/species.dart';
import 'package:lehrpfad_app/features/trail/data/cached_trail_repository.dart';
import 'package:lehrpfad_app/features/trail/data/trail_repository.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';

Trail _trail(String id) => Trail(
  id: id,
  name: id,
  typ: 'wald',
  kurzbeschreibung: 'k',
  beschreibung: 'b',
  laengeKm: 1,
  dauerMin: 10,
  rundkurs: true,
  markierung: '-',
  betreiber: '-',
  region: '-',
  anreise: '-',
  startName: '-',
  arten: const [],
  stationen: const [],
  amenities: const [],
);

class _ThrowingTrails implements TrailRepository {
  @override
  Future<List<Trail>> getTrails({near, radiusKm}) async =>
      throw StateError('offline');
}

class _SeedTrails implements TrailRepository {
  @override
  Future<List<Trail>> getTrails({near, radiusKm}) async => [_trail('seed')];
}

class _ThrowingSpecies implements SpeciesRepository {
  @override
  Future<List<Species>> getCatalog() async => throw StateError('offline');

  @override
  Future<List<Merkmal>> getMerkmale() async => throw StateError('offline');
}

class _SeedSpecies implements SpeciesRepository {
  @override
  Future<List<Species>> getCatalog() async => [
    const Species(
      id: 'seed-art',
      nameDe: 'Seed',
      nameLat: '',
      kategorie: 'fauna',
      kurztext: 'k',
    ),
  ];

  @override
  Future<List<Merkmal>> getMerkmale() async => [
    const Merkmal(id: 'seed-m', nameDe: 'Seed'),
  ];
}

void main() {
  test('Remote wirft, valider Cache trifft', () async {
    final cache = MemoryCatalogCache();
    await cache.write(
      CachedTrailRepository.cacheKey,
      '[{"id":"cached","name":"Cached","typ":"wald","kurzbeschreibung":"k",'
      '"beschreibung":"b","laengeKm":1,"dauerMin":10,"rundkurs":true,'
      '"markierung":"-","betreiber":"-","region":"-","anreise":"-",'
      '"startName":"-","arten":[],"stationen":[],"amenities":[]}]',
    );
    final repo = CachedTrailRepository(
      _ThrowingTrails(),
      fallback: _SeedTrails(),
      cache: cache,
    );
    final trails = await repo.getTrails();
    expect(trails.single.id, 'cached');
  });

  test('Remote wirft, Müll im Cache → Seed', () async {
    final cache = MemoryCatalogCache();
    await cache.write(CachedTrailRepository.cacheKey, '{kein json');
    final repo = CachedTrailRepository(
      _ThrowingTrails(),
      fallback: _SeedTrails(),
      cache: cache,
    );
    final trails = await repo.getTrails();
    expect(trails.single.id, 'seed');
  });

  test('Species-Cache: Müll → Seed', () async {
    final cache = MemoryCatalogCache();
    await cache.write(CachedSpeciesRepository.catalogKey, '[]');
    await cache.write(CachedSpeciesRepository.merkmaleKey, 'null');
    final repo = CachedSpeciesRepository(
      _ThrowingSpecies(),
      fallback: _SeedSpecies(),
      cache: cache,
    );
    expect((await repo.getCatalog()), isEmpty);
    expect((await repo.getMerkmale()).single.id, 'seed-m');
  });
}
