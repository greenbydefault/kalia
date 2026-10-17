import 'package:latlong2/latlong.dart';

import '../../trail/domain/gebiet.dart';

/// Weg: Pfad mit Strecke. Ort: Punkt ohne Strecke (z. B. Wasserspielplatz).
enum EintragArt { weg, ort }

/// Saison eines Orts. Monate 1 bis 12, darf über den Jahreswechsel gehen.
class Saison {
  const Saison.ganzjaehrig() : vonMonat = null, bisMonat = null;
  const Saison(int this.vonMonat, int this.bisMonat);

  final int? vonMonat;
  final int? bisMonat;

  bool get ganzjaehrig => vonMonat == null || bisMonat == null;

  bool enthaelt(int monat) {
    if (ganzjaehrig) return true;
    final von = vonMonat!;
    final bis = bisMonat!;
    return von <= bis
        ? monat >= von && monat <= bis
        : monat >= von || monat <= bis;
  }
}

/// Eintritt: `text == null` heißt frei.
class Eintritt {
  const Eintritt.frei() : text = null;
  const Eintritt(String this.text);

  final String? text;
  bool get frei => text == null;
}

class EintragAudio {
  const EintragAudio({
    required this.url,
    required this.titel,
    required this.dauerSek,
  });

  final String url;
  final String titel;
  final int dauerSek;
}

/// Merkmale, nach denen die Filter-Sektion „Wichtig für euch“ filtert.
enum Merkmal { rundkurs, kinderwagen, barrierefrei, parkplatz, wc, einkehr }

/// Alles, was in Liste und Karte erscheint: ein Weg oder ein Ort.
///
/// Reine Daten, keine Trail-Abhängigkeit, damit die Logik ohne Katalog
/// testbar bleibt. Gebaut wird sie aus dem Trail in `eintrag_mapper.dart`.
class Eintrag {
  const Eintrag({
    required this.id,
    required this.art,
    required this.gebiet,
    required this.name,
    required this.startpunkt,
    this.typKey = '',
    this.typLabel = '',
    this.ortLabel,
    this.dauerMin,
    this.laengeM,
    this.rundkurs,
    this.kinderfreundlich,
    this.barrierefreundlich,
    this.kinderwagen = false,
    this.parkplatz = false,
    this.wcAmWeg = false,
    this.einkehr = false,
    this.saison,
    this.eintritt,
    this.audio,
  });

  final String id;
  final EintragArt art;
  final Gebiet gebiet;
  final String typKey;
  final String typLabel;
  final String name;
  final String? ortLabel;

  /// Parkplatz, sonst Start oder Eingang.
  final LatLng startpunkt;

  // nur Wege
  final int? dauerMin;
  final int? laengeM;
  final bool? rundkurs;
  final int? kinderfreundlich;
  final int? barrierefreundlich;

  // Wege und Orte
  final bool kinderwagen;
  final bool parkplatz;
  final bool wcAmWeg;
  final bool einkehr;

  // nur Orte (TODO: Daten fehlen im Katalog, bis dahin null)
  final Saison? saison;
  final Eintritt? eintritt;

  final EintragAudio? audio;

  bool get istWeg => art == EintragArt.weg;
  bool get istOrt => art == EintragArt.ort;

  /// „Barrierefrei“ gilt ab 4 von 5 (offene Frage in der Spec, Vorschlag).
  static const barrierefreiSchwelle = 4;

  bool get barrierefrei => (barrierefreundlich ?? 0) >= barrierefreiSchwelle;

  /// Ob das Merkmal zutrifft. `false` auch bei unbekannt oder nicht passend
  /// zum Typ (Rundkurs bei einem Ort).
  bool hat(Merkmal m) => switch (m) {
    Merkmal.rundkurs => rundkurs == true,
    Merkmal.kinderwagen => kinderwagen,
    Merkmal.barrierefrei => barrierefrei,
    Merkmal.parkplatz => parkplatz,
    Merkmal.wc => wcAmWeg,
    Merkmal.einkehr => einkehr,
  };
}
