import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/offline/offline.dart';
import 'package:lehrpfad_app/features/species/data/supabase_species_repository.dart';
import 'package:lehrpfad_app/features/species/domain/species.dart';
import 'package:lehrpfad_app/features/species/presentation/species_glyph.dart';
import 'package:lehrpfad_app/features/species/presentation/species_illustration.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

const _svg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10">'
    '<rect width="10" height="10" fill="#554233"/></svg>';

Species _igel({String? illustrationPath}) => Species(
  id: 'igel',
  nameDe: 'Igel',
  nameLat: 'Erinaceus europaeus',
  kategorie: 'fauna',
  kurztext: 'Nachtjäger.',
  illustrationPath: illustrationPath,
);

class _MemoryStore implements FileStore {
  _MemoryStore(this.files);
  final Map<String, String> files;

  @override
  String? pathIfExists(String key) => files[key];

  @override
  Future<String> write(String key, List<int> bytes) async => key;

  @override
  Future<void> delete(String key) async {}

  @override
  Future<int> usedBytes() async => 0;
}

Widget _host(Species s, {FileStore? store, bool silhouette = false}) {
  return ProviderScope(
    overrides: [
      assetResolverProvider.overrideWithValue(
        AssetResolver(
          files: store ?? const NullFileStore(),
          storageBaseUrl: 'https://x.supabase.co',
        ),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: SpeciesGlyph(
            species: s,
            seen: true,
            silhouette: silhouette,
            showCheck: false,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('Species', () {
    test('illustrationPath: JSON-Roundtrip, leer wird null', () {
      final s = Species.fromJson({
        'id': 'igel',
        'nameDe': 'Igel',
        'kategorie': 'fauna',
        'illustrationPath': 'storage:catalog-media/species/igel/illu-a.svg',
      });
      expect(s.hasIllustration, isTrue);
      expect(Species.fromJson(s.toJson()).illustrationPath, s.illustrationPath);

      final leer = Species.fromJson({
        'id': 'igel',
        'nameDe': 'Igel',
        'kategorie': 'fauna',
        'illustrationPath': '',
      });
      expect(leer.illustrationPath, isNull);
      expect(leer.hasIllustration, isFalse);
      expect(leer.toJson().containsKey('illustrationPath'), isFalse);
    });

    test('Repository mappt illustration_path', () {
      final json = SupabaseSpeciesRepository.rowToJson({
        'id': 'igel',
        'name_de': 'Igel',
        'kategorie': 'fauna',
        'illustration_path': 'storage:catalog-media/species/igel/illu-a.svg',
      });
      expect(
        Species.fromJson(json).illustrationPath,
        'storage:catalog-media/species/igel/illu-a.svg',
      );
      expect(SupabaseSpeciesRepository.columns, contains('illustration_path'));
    });
  });

  group('AssetResolver.illustration', () {
    final resolver = AssetResolver(
      files: _MemoryStore({
        const IllustrationRef('storage:catalog-media/a.svg').fileKey():
            '/tmp/a.svg',
      }),
      storageBaseUrl: 'https://x.supabase.co',
    );

    test('lokale Datei vor URL', () {
      final r = resolver.illustration(
        const IllustrationRef('storage:catalog-media/a.svg'),
      );
      expect(r, isA<IllustrationFile>());
    });

    test('storage: wird zur öffentlichen URL', () {
      final r = resolver.illustration(
        const IllustrationRef('storage:catalog-media/b.svg'),
      );
      expect(
        (r as IllustrationUrl).url,
        'https://x.supabase.co/storage/v1/object/public/catalog-media/b.svg',
      );
    });

    test('Asset und leerer Pfad', () {
      expect(
        resolver.illustration(const IllustrationRef('assets/x.svg')),
        isA<IllustrationAsset>(),
      );
      expect(resolver.illustration(const IllustrationRef('')), isNull);
    });
  });

  group('SpeciesIllustration', () {
    testWidgets('ohne Illustration: nur das Icon', (tester) async {
      await tester.pumpWidget(_host(_igel()));
      expect(find.byType(PhosphorIcon), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);
    });

    testWidgets('mit lokaler Datei: SVG statt Icon', (tester) async {
      final dir = await tester.runAsync(
        () async => Directory.systemTemp.createTemp('illu'),
      );
      final file = File('${dir!.path}/a.svg')..writeAsStringSync(_svg);
      const path = 'storage:catalog-media/species/igel/illu-a.svg';
      final store = _MemoryStore({
        const IllustrationRef(path).fileKey(): file.path,
      });

      await tester.pumpWidget(
        _host(_igel(illustrationPath: path), store: store),
      );
      await tester.pump();
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('Igel'), findsOneWidget);
    });

    testWidgets('Silhouette färbt ein', (tester) async {
      final dir = await tester.runAsync(
        () async => Directory.systemTemp.createTemp('illu'),
      );
      final file = File('${dir!.path}/a.svg')..writeAsStringSync(_svg);
      const path = 'storage:catalog-media/species/igel/illu-a.svg';
      final store = _MemoryStore({
        const IllustrationRef(path).fileKey(): file.path,
      });

      await tester.pumpWidget(
        _host(_igel(illustrationPath: path), store: store, silhouette: true),
      );
      await tester.pump();
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.colorFilter, isNotNull);
    });
  });
}
