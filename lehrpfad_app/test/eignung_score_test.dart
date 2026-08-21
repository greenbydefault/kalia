import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/features/trail/domain/amenity.dart';
import 'package:lehrpfad_app/features/trail/domain/eignung_score.dart';
import 'package:lehrpfad_app/features/trail/domain/station.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';

void main() {
  Trail trail({
    List<String> tags = const [],
    List<Station> stationen = const [],
    List<Amenity> amenities = const [],
  }) {
    return Trail(
      id: 't',
      name: 'Test',
      typ: 'moor',
      kurzbeschreibung: 'k',
      beschreibung: 'b',
      laengeKm: 1,
      dauerMin: 30,
      rundkurs: false,
      markierung: 'm',
      betreiber: 'b',
      region: 'r',
      anreise: 'a',
      startName: 's',
      arten: const [],
      tags: tags,
      route: const [LatLng(52, 13), LatLng(52.01, 13.01)],
      stationen: stationen,
      amenities: amenities,
    );
  }

  Station station({
    required int n,
    bool barrierefrei = false,
    List<String> erlebnisse = const [],
  }) {
    return Station(
      osmId: n,
      position: LatLng(52 + n * 0.001, 13),
      km: n.toDouble(),
      reihenfolge: n,
      titel: 'S$n',
      thema: 't',
      kurztext: 'k',
      erlebnisse: erlebnisse,
      barrierefrei: barrierefrei,
    );
  }

  Amenity amenity(String kat, {int osmId = 1}) {
    return Amenity(
      osmId: osmId,
      position: const LatLng(52, 13),
      kategorie: kat,
    );
  }

  test('leerer Trail → beide Level 1, keine matchedSignals', () {
    final scores = scoreEignungen(trail());
    expect(scores.kinder.level, 1);
    expect(scores.barriere.level, 1);
    expect(scores.kinder.matchedSignals, isEmpty);
    expect(scores.barriere.matchedSignals, isEmpty);
    expect(scores.kinder.label, 'Gar nicht');
  });

  test('nur rollstuhltauglich → Barriere Level 2', () {
    final scores = scoreEignungen(trail(tags: ['rollstuhltauglich']));
    expect(scores.barriere.level, 2);
    expect(scores.barriere.matchedSignals, ['rollstuhltauglich']);
    expect(scores.barriere.label, 'Wenig');
    expect(scores.kinder.level, 1);
  });

  test('nur schwaches Signal (WC) → Level 1', () {
    final scores = scoreEignungen(
      trail(amenities: [amenity('wc')]),
    );
    expect(scores.kinder.level, 1);
    expect(scores.barriere.level, 1);
    expect(scores.kinder.matchedSignals, contains('wc'));
    expect(scores.barriere.matchedSignals, contains('wc'));
  });

  test('Punkte > 5 → Level clamp 5', () {
    final scores = scoreEignungen(
      trail(
        tags: [
          'kinderfreundlich',
          'kinderwagentauglich',
          'spielplatz',
          'barfusspfad',
          'picknick',
        ],
        amenities: [amenity('wc'), amenity('picnic', osmId: 2)],
        stationen: [
          station(n: 1, erlebnisse: ['quiz']),
        ],
      ),
    );
    // 2+2+1+1+1+1+1 = 9 → clamp 5
    expect(scores.kinder.level, 5);
    expect(scores.kinder.label, 'Sehr');
  });

  test('Station-Anteil ≥50% allein → Barriere Level 2', () {
    final scores = scoreEignungen(
      trail(
        stationen: [
          station(n: 1, barrierefrei: true),
          station(n: 2, barrierefrei: true),
          station(n: 3, barrierefrei: false),
        ],
      ),
    );
    expect(scores.barriere.level, 2);
    expect(
      scores.barriere.matchedSignals,
      contains('stationen-barrierefrei-mehrheit'),
    );
  });

  test('Station-Anteil <50% mit ≥1 → Barriere Level 1', () {
    final scores = scoreEignungen(
      trail(
        stationen: [
          station(n: 1, barrierefrei: true),
          station(n: 2, barrierefrei: false),
          station(n: 3, barrierefrei: false),
        ],
      ),
    );
    expect(scores.barriere.level, 1);
    expect(
      scores.barriere.matchedSignals,
      contains('stationen-barrierefrei-teilweise'),
    );
  });

  test('displayTags filtert Summary-Tags', () {
    final t = trail(
      tags: ['kinderfreundlich', 'rollstuhltauglich', 'einkehr', 'picknick'],
    );
    expect(t.displayTags, containsAll(['einkehr', 'picknick']));
    expect(t.displayTags, isNot(contains('kinderfreundlich')));
    expect(t.displayTags, isNot(contains('rollstuhltauglich')));
  });

  test('autoTag spielplatz aus Amenity playground', () {
    final t = trail(amenities: [amenity('playground')]);
    expect(t.autoTags, contains('spielplatz'));
    expect(scoreEignungen(t).kinder.matchedSignals, contains('spielplatz'));
  });

  test('eignungLevelLabel clamp und Mapping', () {
    expect(eignungLevelLabel(1), 'Gar nicht');
    expect(eignungLevelLabel(3), 'Mittel');
    expect(eignungLevelLabel(5), 'Sehr');
    expect(eignungLevelLabel(0), 'Gar nicht');
    expect(eignungLevelLabel(9), 'Sehr');
  });
}
