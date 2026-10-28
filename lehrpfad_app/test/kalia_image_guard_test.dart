import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/community/domain/trail_image.dart';
import 'package:lehrpfad_app/features/trail/domain/trail_bild.dart';
import 'package:lehrpfad_app/shared/images/image_encoder.dart';
import 'package:lehrpfad_app/shared/widgets/kalia_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Hero-Pager verlangt small, nicht medium', () {
    final pager = File(
      'lib/features/trail/presentation/map/trail_hero_pager.dart',
    ).readAsStringSync();
    expect(pager, contains('TrailImageVariant.small'));
    expect(pager.contains('TrailImageVariant.medium'), isFalse);
    final zoom = File(
      'lib/features/trail/presentation/map/trail_hero_fullscreen.dart',
    ).readAsStringSync();
    expect(zoom, contains('TrailImageVariant.medium'));
  });

  test(
    'Avif-Widgets und Image.network bleiben aus den Auslieferungsflächen',
    () {
      const banned = ['CachedNetworkAvifImage', 'AvifImage(', 'Image.network('];
      final roots = [
        Directory('lib/features'),
        File('lib/admin/widgets/trail_hero_gallery.dart'),
        File('lib/admin/moderation/moderation_page.dart'),
        File('lib/admin/import/source_panel.dart'),
      ];
      final hits = <String>[];
      for (final root in roots) {
        final Iterable<File> files = root is Directory
            ? root
                  .listSync(recursive: true)
                  .whereType<File>()
                  .where((f) => f.path.endsWith('.dart'))
            : [root as File];
        for (final file in files) {
          final text = file.readAsStringSync();
          for (final token in banned) {
            if (text.contains(token)) hits.add('${file.path}: $token');
          }
        }
      }
      expect(hits, isEmpty);
    },
  );

  test('Encoder übernimmt die Qualität der Stichprobe', () {
    final quality =
        (jsonDecode(File('tools/webp_quality.json').readAsStringSync())
                as Map<String, dynamic>)['quality']
            as Map<String, dynamic>;
    expect(kWebpQuality[TrailImageVariant.thumb], quality['thumb']);
    expect(kWebpQuality[TrailImageVariant.small], quality['small']);
    expect(kWebpQuality[TrailImageVariant.medium], quality['medium']);
    final probe =
        (jsonDecode(File('tools/webp_quality.json').readAsStringSync())
                as Map<String, dynamic>)['probe']
            as Map<String, dynamic>;
    expect(probe['thumb']['median'] as int, lessThanOrEqualTo(30 * 1024));
    expect(probe['thumb']['p90'] as int, lessThanOrEqualTo(50 * 1024));
    expect(probe['small']['median'] as int, lessThanOrEqualTo(60 * 1024));
    expect(probe['small']['p90'] as int, lessThanOrEqualTo(110 * 1024));
    expect(probe['medium']['p90'] as int, lessThanOrEqualTo(400 * 1024));
    expect(probe['medium']['max'] as int, lessThanOrEqualTo(500 * 1024));
  });

  test('TrailBild trägt ThumbHash und Farbe durchs JSON', () {
    const bild = TrailBild(
      file: 'a.jpg',
      caption: '',
      credit: 'A',
      license: 'cc0',
      licenseUrl: '',
      sourceUrl: '',
      thumbhash: 'abc',
      dominantColor: '#112233',
    );
    final again = TrailBild.fromJson(bild.toJson());
    expect(again.thumbhash, 'abc');
    expect(again.dominantColor, '#112233');
  });

  testWidgets('Fehler zeigt den Farbplatzhalter, kein Broken-Icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: KaliaImage(
              slot: TrailImageVariant.thumb,
              dominantColor: '#336699',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
    expect(find.byType(ColoredBox), findsWidgets);
  });
}
