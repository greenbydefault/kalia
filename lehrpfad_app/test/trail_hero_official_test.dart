import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/community/domain/trail_image.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';
import 'package:lehrpfad_app/features/trail/domain/trail_bild.dart';
import 'package:lehrpfad_app/features/trail/presentation/map/trail_hero.dart';

TrailImage _img(
  String id, {
  required TrailImageSource source,
  int sort = 0,
  String credit = 'Autor',
  String license = '',
  TrailImageStatus status = TrailImageStatus.approved,
  int? stationId,
}) {
  return TrailImage(
    id: id,
    trailId: 't',
    stationId: stationId,
    uploaderId: null,
    source: source,
    status: status,
    credit: credit,
    width: null,
    height: null,
    mimeType: null,
    thumbBytes: null,
    smallBytes: null,
    mediumBytes: null,
    createdAt: DateTime.utc(2026, 1, 1),
    isMine: false,
    thumbUrl: 'https://x/$id/thumb.avif',
    smallUrl: 'https://x/$id/small.avif',
    mediumUrl: 'https://x/$id/medium.avif',
    license: license,
    sort: sort,
  );
}

Trail _trail({List<TrailBild> bilder = const []}) => Trail(
  id: 't',
  name: 'T',
  typ: 'lehrpfad',
  kurzbeschreibung: 'k',
  beschreibung: 'b',
  laengeKm: 1,
  dauerMin: 10,
  rundkurs: true,
  markierung: 'm',
  betreiber: 'b',
  region: 'r',
  anreise: 'a',
  startName: 's',
  arten: const [],
  stationen: const [],
  amenities: const [],
  bilder: bilder,
);

const _bild = TrailBild(
  file: 'a.jpg',
  caption: '',
  credit: 'Seed',
  license: 'cc0',
  licenseUrl: '',
  sourceUrl: '',
);

void main() {
  test('Offizielle DB-Bilder ersetzen gebündelte, nach sort', () {
    final slides = TrailHero.slidesFor(_trail(bilder: [_bild]), [
      _img('b', source: TrailImageSource.official, sort: 2),
      _img('a', source: TrailImageSource.official, sort: 1),
      _img('u', source: TrailImageSource.user),
    ]);
    expect(slides.map((s) => s.seed == null).toList(), [true, true, true]);
    expect(slides.map((s) => s.community!.id).toList(), ['a', 'b', 'u']);
  });

  test('Ohne offizielle Bilder bleiben die gebündelten', () {
    final slides = TrailHero.slidesFor(_trail(bilder: [_bild]), [
      _img('u', source: TrailImageSource.user),
    ]);
    expect(slides.first.seed, isNotNull);
    expect(slides.last.community!.id, 'u');
  });

  test('Pending und Stationsbilder fallen heraus', () {
    final slides = TrailHero.slidesFor(_trail(), [
      _img(
        'p',
        source: TrailImageSource.official,
        status: TrailImageStatus.pending,
      ),
      _img('s', source: TrailImageSource.official, stationId: 3),
    ]);
    expect(slides.single.seed!.isPlaceholder, isTrue);
  });

  test('Offizielles Bild zeigt Lizenz, Nutzerfoto nicht', () {
    final official = HeroSlide.community(
      _img('o', source: TrailImageSource.official, license: 'cc-by-sa-4.0'),
    );
    final user = HeroSlide.community(_img('u', source: TrailImageSource.user));
    expect(official.showsLicense, isTrue);
    expect(official.badgeText, 'Autor · CC BY-SA');
    expect(user.showsLicense, isFalse);
    expect(user.badgeText, '© Autor');
  });
}
