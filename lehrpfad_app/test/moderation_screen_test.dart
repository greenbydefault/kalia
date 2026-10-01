import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/community/data/community_providers.dart';
import 'package:lehrpfad_app/features/community/domain/photo_geo_check.dart';
import 'package:lehrpfad_app/features/community/domain/trail_image.dart';
import 'package:lehrpfad_app/features/community/presentation/fullscreen_image_viewer.dart';
import 'package:lehrpfad_app/features/community/presentation/moderation_screen.dart';
import 'package:lehrpfad_app/features/trail/data/providers.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';

TrailImage _image({PhotoGeoCheck? geoCheck}) {
  return TrailImage(
    id: 'img-1',
    trailId: 'heide-erlebnisweg',
    stationId: null,
    uploaderId: null,
    source: TrailImageSource.user,
    status: TrailImageStatus.pending,
    credit: 'Test',
    width: 3024,
    height: 4032,
    mimeType: 'image/avif',
    thumbBytes: 5869,
    smallBytes: 36016,
    mediumBytes: 182054,
    createdAt: DateTime.utc(2026, 8, 29),
    isMine: false,
    thumbUrl: 'https://example.invalid/thumb.avif',
    smallUrl: 'https://example.invalid/small.avif',
    mediumUrl: 'https://example.invalid/medium.avif',
    geoCheck: geoCheck,
  );
}

Trail _trail() {
  return const Trail(
    id: 'heide-erlebnisweg',
    name: 'Heide-Erlebnisweg',
    typ: 'lehrpfad',
    kurzbeschreibung: 'kurz',
    beschreibung: 'lang',
    laengeKm: 1,
    dauerMin: 60,
    rundkurs: true,
    markierung: 'm',
    betreiber: 'b',
    region: 'r',
    anreise: 'a',
    startName: 's',
    arten: [],
    stationen: [],
    amenities: [],
  );
}

void main() {
  test('formatLabel mappt MIME auf Kurzname', () {
    expect(_image().formatLabel, 'AVIF');
    expect(
      TrailImage(
        id: 'x',
        trailId: 't',
        stationId: null,
        uploaderId: null,
        source: TrailImageSource.user,
        status: TrailImageStatus.pending,
        credit: '',
        width: null,
        height: null,
        mimeType: 'image/jpeg',
        thumbBytes: null,
        smallBytes: null,
        mediumBytes: null,
        createdAt: DateTime.utc(2026, 1, 1),
        isMine: false,
        thumbUrl: '',
        smallUrl: '',
        mediumUrl: '',
      ).formatLabel,
      'JPEG',
    );
  });

  testWidgets('Tabelle zeigt Format, Pixel und Dateigroessen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingImagesProvider.overrideWith((ref) async => [_image()]),
          trailsProvider.overrideWith((ref) async => [_trail()]),
        ],
        child: const MaterialApp(home: ModerationScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('AVIF'), findsOneWidget);
    expect(find.text('3024 × 4032'), findsOneWidget);
    expect(find.text('5.7 KB · 35 KB · 178 KB'), findsOneWidget);
    expect(find.text('Heide-Erlebnisweg'), findsOneWidget);
  });

  testWidgets('Klick aufs Thumb oeffnet den Vollbild-Viewer', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingImagesProvider.overrideWith((ref) async => [_image()]),
          trailsProvider.overrideWith((ref) async => [_trail()]),
        ],
        child: const MaterialApp(home: ModerationScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byType(Tooltip).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(FullscreenImageViewer), findsOneWidget);
  });

  testWidgets('Ort-Spalte zeigt die Ampel, Altbestand einen Strich', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    TrailImage withCheck(String id, PhotoGeoCheck? c) {
      final base = _image(geoCheck: c);
      return TrailImage(
        id: id,
        trailId: base.trailId,
        stationId: null,
        uploaderId: null,
        source: base.source,
        status: base.status,
        credit: base.credit,
        width: base.width,
        height: base.height,
        mimeType: base.mimeType,
        thumbBytes: base.thumbBytes,
        smallBytes: base.smallBytes,
        mediumBytes: base.mediumBytes,
        createdAt: base.createdAt,
        isMine: false,
        thumbUrl: base.thumbUrl,
        smallUrl: base.smallUrl,
        mediumUrl: base.mediumUrl,
        geoCheck: c,
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingImagesProvider.overrideWith(
            (ref) async => [
              withCheck('a', PhotoGeoCheck.match),
              withCheck('b', PhotoGeoCheck.near),
              withCheck('c', PhotoGeoCheck.far),
              withCheck('d', PhotoGeoCheck.none),
              withCheck('e', null),
            ],
          ),
          trailsProvider.overrideWith((ref) async => [_trail()]),
        ],
        child: const MaterialApp(home: ModerationScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Ort'), findsOneWidget);
    expect(find.text('Passt zum Trail'), findsOneWidget);
    expect(find.text('Grob in der Nähe'), findsOneWidget);
    expect(find.text('Weit entfernt'), findsOneWidget);
    expect(find.text('Kein GPS'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });
}
