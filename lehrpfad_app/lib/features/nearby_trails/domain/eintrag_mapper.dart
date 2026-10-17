import 'package:latlong2/latlong.dart';

import '../../../shared/catalogs/icon_catalog.dart';
import '../../trail/domain/catalog_filter.dart';
import '../../trail/domain/eignung_score.dart';
import '../../trail/domain/haversine.dart';
import '../../trail/domain/trail.dart';
import 'eintrag.dart';

/// Parkplatz am Weg, sonst Start oder Eingang (Fläche: Centroid).
///
/// Es gibt kein eigenes Koordinatenfeld; der Parkplatz ist die dem Start
/// nächste Amenity der Kategorie `parking`.
LatLng? startpunktVon(Trail t) {
  final start = t.startOrNull;
  if (start == null) return null;
  LatLng? best;
  var bestM = double.infinity;
  for (final a in t.amenities) {
    if (a.kategorie != 'parking') continue;
    final d = haversineMeters(start, a.position);
    if (d < bestM) {
      bestM = d;
      best = a.position;
    }
  }
  return best ?? start;
}

/// „Ort, Landkreis“ aus `region` (die ersten zwei Teile).
String? ortLabelVon(String region) {
  final teile = [
    for (final t in region.split(','))
      if (t.trim().isNotEmpty) t.trim(),
  ];
  if (teile.isEmpty) return null;
  return teile.take(2).join(', ');
}

final _erwachsenenPreis = RegExp(r'Erwachsene[^\d]{0,20}(\d+(?:,\d+)?)\s*€');

/// Eintritt aus `eintritt` und `eintrittPreise`. Kostenpflichtig ohne
/// lesbaren Erwachsenenpreis bleibt `null` (Fallback „–“).
Eintritt? eintrittVon(Trail t) {
  if (!t.eintritt) return const Eintritt.frei();
  final preis = t.eintrittPreise;
  if (preis == null) return null;
  final m = _erwachsenenPreis.firstMatch(preis);
  if (m == null) return null;
  return Eintritt('Erw. ${m.group(1)} €');
}

/// Gesprochene Einführung. Echte Datei nur mit `audioPath`; solange es keine
/// Aufnahmen gibt, trägt der Hörtext die Dauer (ca. 150 Wörter pro Minute) und
/// die Wiedergabe läuft simuliert (TODO: Aufnahmen einspielen).
EintragAudio? audioVon(Trail t) {
  final path = t.audioPath;
  final text = t.hoertext;
  if ((path == null || path.isEmpty) && (text == null || text.trim().isEmpty)) {
    return null;
  }
  final woerter = (text ?? '').split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final sek = woerter.isEmpty ? 90 : (woerter.length / 2.5).round();
  return EintragAudio(
    url: path ?? '',
    titel: 'Einführung',
    dauerSek: sek < 10 ? 10 : sek,
  );
}

/// Baut den [Eintrag] aus einem Trail. `null` bei Trails ohne Position.
Eintrag? eintragVon(Trail t) {
  final start = startpunktVon(t);
  if (start == null) return null;
  final weg = !t.isFlaeche;
  final scores = weg ? scoreEignungen(t) : null;
  final tags = t.alleTags;
  final dauer = t.dauerMin > 0 ? t.dauerMin : null;
  final laengeM = (t.laengeKm * 1000).round();
  return Eintrag(
    id: t.id,
    art: weg ? EintragArt.weg : EintragArt.ort,
    gebiet: t.gebiet,
    typKey: t.typ,
    typLabel: typEintrag(t.typ).label,
    name: t.name,
    ortLabel: ortLabelVon(t.region),
    startpunkt: start,
    dauerMin: weg ? dauer : null,
    laengeM: weg && laengeM > 0 ? laengeM : null,
    rundkurs: weg ? t.rundkurs : null,
    kinderfreundlich: scores?.kinder.level,
    barrierefreundlich: scores?.barriere.level,
    kinderwagen: isStrollerFriendly(t),
    parkplatz: tags.contains('parkplatz-nahe'),
    wcAmWeg: tags.contains('wc-am-weg'),
    einkehr: t.amenities.any((a) => a.kategorie == 'gastro'),
    saison: null, // TODO: Saison-Daten fehlen im Katalog.
    eintritt: eintrittVon(t),
    audio: audioVon(t),
  );
}
