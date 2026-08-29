import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';
import 'package:lehrpfad_app/features/trail/presentation/map/camera_target.dart';
import 'package:lehrpfad_app/features/trail/presentation/map/trail_peek_card.dart';

void main() {
  const start = LatLng(52.52, 13.40);
  const end = LatLng(53.10, 14.20);

  Trail linie() => Trail(
    id: 'linie',
    name: 'linie',
    typ: 'wald',
    kurzbeschreibung: 'k',
    beschreibung: 'b',
    laengeKm: 80,
    dauerMin: 240,
    rundkurs: false,
    markierung: 'm',
    betreiber: 'b',
    region: 'r',
    anreise: 'a',
    startName: 's',
    arten: const [],
    route: const [start, LatLng(52.70, 13.60), end],
    stationen: const [],
    amenities: const [],
  );

  Trail flaeche() => Trail(
    id: 'flaeche',
    name: 'flaeche',
    typ: 'waldspielplatz',
    form: 'flaeche',
    kurzbeschreibung: 'k',
    beschreibung: 'b',
    laengeKm: 0,
    dauerMin: 0,
    rundkurs: false,
    markierung: 'm',
    betreiber: 'b',
    region: 'r',
    anreise: 'a',
    startName: 's',
    arten: const [],
    area: const [
      LatLng(52.50, 13.38),
      LatLng(52.51, 13.42),
      LatLng(52.48, 13.41),
    ],
    stationen: const [],
    amenities: const [],
  );

  test('lange Linie: Bounds enthalten das Route-Ende, nicht nur den Start', () {
    final target = CameraTarget.fromTrail(
      linie(),
      padding: CameraTarget.catalogPadding,
    )!;

    expect(target.bounds.contains(end), isTrue);
    expect(target.bounds.contains(start), isTrue);
  });

  test('Fläche: Bounds kommen aus area, nicht aus route', () {
    final trail = flaeche();
    final target = CameraTarget.fromTrail(
      trail,
      padding: CameraTarget.catalogPadding,
    )!;

    for (final p in trail.area) {
      expect(target.bounds.contains(p), isTrue);
    }
  });

  test('Peek vergrößert das Bottom-Padding um die Card-Höhe', () {
    expect(CameraTarget.peekPadding.bottom, TrailPeekCard.height + 24);
    expect(
      CameraTarget.peekPadding.bottom,
      greaterThan(CameraTarget.catalogPadding.bottom),
    );
    expect(CameraTarget.paddingFor(peek: true), CameraTarget.peekPadding);
    expect(CameraTarget.paddingFor(peek: false), CameraTarget.catalogPadding);
  });

  test('leere Punkte → null', () {
    expect(
      CameraTarget.fromPoints(const [], padding: CameraTarget.catalogPadding),
      isNull,
    );
  });
}
