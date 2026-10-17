import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../trail/domain/gebiet.dart';
import '../../trail/domain/haversine.dart';
import 'eintrag.dart';
import 'karte_copy.dart';

// ---------------------------------------------------------------------------
// Anfahrt
// ---------------------------------------------------------------------------

/// Anfahrt mit dem Auto in Minuten, aus der Luftlinie geschätzt
/// (Umwegfaktor 1,3, Schnitt 45 km/h, mindestens 2 Min).
///
/// Gerechnet bis zum Startpunkt (Parkplatz), nie bis zur Mitte des Gebiets.
/// Später durch echtes Routing ersetzbar, die Anzeige bleibt gleich.
int schaetzeAnfahrtMin(LatLng bezug, LatLng start) {
  final km = haversineMeters(bezug, start) / 1000;
  return math.max(2, (km * 1.3 / 45 * 60).round());
}

// ---------------------------------------------------------------------------
// Formatierer (Dezimalkomma, Anfahrt immer mit „ca.“)
// ---------------------------------------------------------------------------

String _stunden(int halbeStunden) {
  final ganz = halbeStunden ~/ 2;
  return halbeStunden.isEven ? '$ganz Std' : '$ganz,5 Std';
}

/// Erst runden, dann Einheit wählen. Unter 10: ganze Minuten. 10 bis 59:
/// auf 5 Min. Ab 60: auf halbe Stunden.
String formatAnfahrt(int min) {
  if (min < 10) return 'ca. $min Min';
  if (min < 60) {
    final gerundet = (min / 5).round() * 5;
    if (gerundet < 60) return 'ca. $gerundet Min';
    return 'ca. 1 Std';
  }
  return 'ca. ${_stunden((min / 30).round())}';
}

/// Unter 60: auf 5 Min aufrunden. Ab 60: auf halbe Stunden aufrunden
/// (lieber zu lang als zu kurz).
String formatDauer(int min) {
  if (min < 60) {
    final auf = (min / 5).ceil() * 5;
    if (auf < 60) return '$auf Min';
    return '1 Std';
  }
  return _stunden((min / 30).ceil());
}

/// Unter 1000: auf 50 m runden. Ab 1000: eine Nachkommastelle, „,0“ entfällt.
String formatLaenge(int m) {
  if (m < 1000) {
    final gerundet = (m / 50).round() * 50;
    if (gerundet < 1000) return '$gerundet m';
    return '1 km';
  }
  final zehntel = (m / 100).round();
  final ganz = zehntel ~/ 10;
  final rest = zehntel % 10;
  return rest == 0 ? '$ganz km' : '$ganz,$rest km';
}

const monatKuerzel = [
  'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
];

/// Ganzjährig → „Ganzjährig“. Heute in der Saison → Spanne. Sonst Beginn.
String formatSaison(Saison s, DateTime heute) {
  if (s.ganzjaehrig) return kt('saison.ganzjaehrig');
  if (s.enthaelt(heute.month)) {
    return '${monatKuerzel[s.vonMonat! - 1]}–${monatKuerzel[s.bisMonat! - 1]}';
  }
  return kt('saison.ab', {'monat': monatKuerzel[s.vonMonat! - 1]});
}

String formatEintritt(Eintritt e) => e.frei ? kt('eintritt.frei') : e.text!;

/// Fünf Balken, [n] davon gefüllt. `null` oder außerhalb 1..5: keine Balken.
List<bool>? formatKinder(int? n) {
  if (n == null) return null;
  final voll = n.clamp(0, 5);
  return [for (var i = 0; i < 5; i++) i < voll];
}

String kinderSemantik(int n) => kt('a11y.kinder', {'n': n});

// ---------------------------------------------------------------------------
// Umkreis
// ---------------------------------------------------------------------------

enum Umkreis {
  min15(15),
  min30(30),
  min60(60),
  egal(null);

  const Umkreis(this.minuten);

  /// `null` bei [egal].
  final int? minuten;

  String get key => minuten == null ? 'egal' : '$minuten';

  /// „bis 30 Min Anfahrt“.
  String get text => kt('umkreis.$key');

  /// „30 Min“, für Filter und Ortssuche.
  String get kurz => kt('umkreis.kurz.$key');

  /// Nächstgrößerer Umkreis bis 1 Std, `null` ab 1 Std.
  Umkreis? get groesser => switch (this) {
    Umkreis.min15 => Umkreis.min30,
    Umkreis.min30 => Umkreis.min60,
    _ => null,
  };

  static Umkreis fromKey(String? key) {
    for (final u in values) {
      if (u.key == key) return u;
    }
    return standard;
  }

  static const standard = Umkreis.min30;
}

// ---------------------------------------------------------------------------
// Filter
// ---------------------------------------------------------------------------

enum DauerBereich { bis1Std, von1bis2Std, ueber2Std }

enum LaengeBereich { bis3km, bis5km, ueber5km }

bool _inDauer(DauerBereich b, int min) => switch (b) {
  DauerBereich.bis1Std => min <= 60,
  DauerBereich.von1bis2Std => min > 60 && min <= 120,
  DauerBereich.ueber2Std => min > 120,
};

bool _inLaenge(LaengeBereich b, int m) => switch (b) {
  LaengeBereich.bis3km => m <= 3000,
  LaengeBereich.bis5km => m <= 5000,
  LaengeBereich.ueber5km => m > 5000,
};

/// Alle Filter außer Umkreis und Gebiet (Filter-Sheet).
class KarteFilter {
  const KarteFilter({
    this.arten = const {EintragArt.weg, EintragArt.ort},
    this.dauer,
    this.laenge,
    this.merkmale = const {},
  });

  /// Mindestens eine Art.
  final Set<EintragArt> arten;
  final DauerBereich? dauer;
  final LaengeBereich? laenge;
  final Set<Merkmal> merkmale;

  static const standard = KarteFilter();

  bool get istStandard => anzahlAktiv == 0;

  /// Was vom Standard abweicht: „Was“, „Dauer“, „Länge“ je 1, dazu jedes
  /// gewählte Merkmal. Der Umkreis zählt nicht mit.
  int get anzahlAktiv =>
      (arten.length == 2 ? 0 : 1) +
      (dauer == null ? 0 : 1) +
      (laenge == null ? 0 : 1) +
      merkmale.length;

  KarteFilter copyWith({
    Set<EintragArt>? arten,
    DauerBereich? dauer,
    bool dauerLeeren = false,
    LaengeBereich? laenge,
    bool laengeLeeren = false,
    Set<Merkmal>? merkmale,
  }) => KarteFilter(
    arten: arten ?? this.arten,
    dauer: dauerLeeren ? null : (dauer ?? this.dauer),
    laenge: laengeLeeren ? null : (laenge ?? this.laenge),
    merkmale: merkmale ?? this.merkmale,
  );

  /// UND über alle Sektionen. Dauer und Länge filtern nur Wege, Orte bleiben
  /// davon unberührt. Unbekannte oder nicht passende Merkmale fallen raus.
  bool passt(Eintrag e) {
    if (!arten.contains(e.art)) return false;
    if (e.istWeg) {
      if (dauer != null) {
        final d = e.dauerMin;
        if (d == null || !_inDauer(dauer!, d)) return false;
      }
      if (laenge != null) {
        final l = e.laengeM;
        if (l == null || !_inLaenge(laenge!, l)) return false;
      }
    }
    for (final m in merkmale) {
      if (!e.hat(m)) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is KarteFilter &&
      other.dauer == dauer &&
      other.laenge == laenge &&
      other.arten.length == arten.length &&
      other.arten.containsAll(arten) &&
      other.merkmale.length == merkmale.length &&
      other.merkmale.containsAll(merkmale);

  @override
  int get hashCode => Object.hash(
    dauer,
    laenge,
    Object.hashAllUnordered(arten),
    Object.hashAllUnordered(merkmale),
  );
}

// ---------------------------------------------------------------------------
// Menge M, Sortierung, Vorschläge
// ---------------------------------------------------------------------------

class Treffer {
  const Treffer(this.eintrag, this.anfahrtMin);

  final Eintrag eintrag;

  /// Geschätzte Anfahrt, `null` ohne Bezugspunkt.
  final int? anfahrtMin;
}

enum Sortierung {
  anfahrt('sort.anfahrt'),
  dauer('sort.dauer'),
  kinder('sort.kinder');

  const Sortierung(this.copyKey);
  final String copyKey;

  String get text => kt(copyKey);
}

/// Menge M: alle Einträge mit Anfahrt im Umkreis, die Gebiet und Filter
/// erfüllen. Ohne [bezug] gilt kein Umkreis (Zustand E3).
List<Treffer> berechneMenge(
  Iterable<Eintrag> alle, {
  required LatLng? bezug,
  Umkreis umkreis = Umkreis.standard,
  Gebiet? gebiet,
  KarteFilter filter = KarteFilter.standard,
}) {
  final limit = umkreis.minuten;
  final out = <Treffer>[];
  for (final e in alle) {
    if (gebiet != null && e.gebiet != gebiet) continue;
    if (!filter.passt(e)) continue;
    final min = bezug == null ? null : schaetzeAnfahrtMin(bezug, e.startpunkt);
    if (limit != null && min != null && min > limit) continue;
    out.add(Treffer(e, min));
  }
  return out;
}

int _nachAnfahrtDannName(Treffer a, Treffer b) {
  final ma = a.anfahrtMin;
  final mb = b.anfahrtMin;
  if (ma != null && mb != null && ma != mb) return ma.compareTo(mb);
  if (ma == null && mb != null) return 1;
  if (ma != null && mb == null) return -1;
  return a.eintrag.name.toLowerCase().compareTo(b.eintrag.name.toLowerCase());
}

/// Sortiert nach [sortierung]. Bei Gleichstand entscheidet die Anfahrt,
/// dann der Name. Einträge ohne Wert wandern ans Ende (dort nach Anfahrt).
List<Treffer> sortiere(Iterable<Treffer> menge, Sortierung sortierung) {
  final liste = menge.toList();
  switch (sortierung) {
    case Sortierung.anfahrt:
      liste.sort(_nachAnfahrtDannName);
    case Sortierung.dauer:
      liste.sort((a, b) {
        final da = a.eintrag.dauerMin;
        final db = b.eintrag.dauerMin;
        if (da != null && db != null && da != db) return da.compareTo(db);
        if (da == null && db != null) return 1;
        if (da != null && db == null) return -1;
        return _nachAnfahrtDannName(a, b);
      });
    case Sortierung.kinder:
      liste.sort((a, b) {
        final ka = a.eintrag.kinderfreundlich;
        final kb = b.eintrag.kinderfreundlich;
        if (ka != null && kb != null && ka != kb) return kb.compareTo(ka);
        if (ka == null && kb != null) return 1;
        if (ka != null && kb == null) return -1;
        return _nachAnfahrtDannName(a, b);
      });
  }
  return liste;
}

/// Anzahl Karten im Modus „Vorschläge“.
const vorschlagAnzahl = 4;

bool _ausserSaison(Eintrag e, DateTime heute) {
  final s = e.saison;
  return e.istOrt && s != null && !s.enthaelt(heute.month);
}

/// Modus „Vorschläge“: pro Gebiet der Eintrag mit der kürzesten Anfahrt,
/// davon die 4 nächsten. Weniger als 4 Gebiete: mit den nächsten übrigen
/// Einträgen auffüllen. Orte außerhalb ihrer Saison werden übersprungen.
/// Bei höchstens 4 Einträgen in M erscheinen alle.
List<Treffer> vorschlaege(Iterable<Treffer> menge, DateTime heute) {
  final nachAnfahrt = sortiere(menge, Sortierung.anfahrt);
  if (nachAnfahrt.length <= vorschlagAnzahl) return nachAnfahrt;

  final kandidaten = [
    for (final t in nachAnfahrt)
      if (!_ausserSaison(t.eintrag, heute)) t,
  ];
  final proGebiet = <Gebiet, Treffer>{};
  for (final t in kandidaten) {
    proGebiet.putIfAbsent(t.eintrag.gebiet, () => t);
  }
  final gewaehlt = sortiere(
    proGebiet.values,
    Sortierung.anfahrt,
  ).take(vorschlagAnzahl).toList();
  if (gewaehlt.length < vorschlagAnzahl) {
    final ids = {for (final t in gewaehlt) t.eintrag.id};
    for (final t in kandidaten) {
      if (gewaehlt.length >= vorschlagAnzahl) break;
      if (!ids.contains(t.eintrag.id)) gewaehlt.add(t);
    }
  }
  return sortiere(gewaehlt, Sortierung.anfahrt);
}

// ---------------------------------------------------------------------------
// Leerzustände E5, E6, E7
// ---------------------------------------------------------------------------

enum LeerArt {
  /// E5: nichts im Umkreis, aber im nächstgrößeren bis 1 Std.
  umkreis,

  /// E6: nichts wegen Filter oder Gebiet.
  filter,

  /// E7: nichts innerhalb 1 Std, Region noch nicht abgedeckt.
  region,
}

class LeerFall {
  const LeerFall(this.art, {this.erweitern, this.naechster});

  final LeerArt art;

  /// E5: Umkreis, auf den „Auf … erweitern“ setzt.
  final Umkreis? erweitern;

  /// E5: nächster Eintrag mit Anfahrt.
  final Treffer? naechster;
}

/// Prüfreihenfolge bei leerer Liste:
/// 1. Treffer ohne Filter und mit Gebiet „Alle“: E6.
/// 2. Treffer mit dem nächstgrößeren Umkreis bis 1 Std: E5.
/// 3. Sonst E7.
LeerFall bestimmeLeerFall(
  Iterable<Eintrag> alle, {
  required LatLng? bezug,
  required Umkreis umkreis,
  required Gebiet? gebiet,
  required KarteFilter filter,
}) {
  final ohneFilter = berechneMenge(alle, bezug: bezug, umkreis: umkreis);
  if (ohneFilter.isNotEmpty && (gebiet != null || !filter.istStandard)) {
    return const LeerFall(LeerArt.filter);
  }
  var groesser = umkreis.groesser;
  while (groesser != null) {
    final treffer = berechneMenge(alle, bezug: bezug, umkreis: groesser);
    if (treffer.isNotEmpty) {
      return LeerFall(
        LeerArt.umkreis,
        erweitern: groesser,
        naechster: sortiere(treffer, Sortierung.anfahrt).first,
      );
    }
    groesser = groesser.groesser;
  }
  return const LeerFall(LeerArt.region);
}

// ---------------------------------------------------------------------------
// Texte aus Daten
// ---------------------------------------------------------------------------

/// Merkmale der Eintragskarte: nur zutreffende, mit Komma getrennt, in dieser
/// Reihenfolge: Rundkurs, Kinderwagen, Parkplatz, WC, Einkehr, Barrierefrei.
String merkmaleText(Eintrag e) {
  const reihenfolge = [
    Merkmal.rundkurs,
    Merkmal.kinderwagen,
    Merkmal.parkplatz,
    Merkmal.wc,
    Merkmal.einkehr,
    Merkmal.barrierefrei,
  ];
  return [
    for (final m in reihenfolge)
      if (e.hat(m)) kt('merkmal.${m.name}'),
  ].join(', ');
}

/// Abschnittszeile im Modus „Alle“: „{n} Wege und Orte“, bei einer Art
/// „{n} Wege“ bzw. „{n} Orte“, bei einem Treffer „1 Ergebnis“.
String listenAnzahlText(int n, KarteFilter filter) {
  if (n == 1) return kt('liste.anzahl.eins');
  if (filter.arten.length == 1) {
    return filter.arten.first == EintragArt.weg
        ? kt('liste.anzahl.nurWege', {'n': n})
        : kt('liste.anzahl.nurOrte', {'n': n});
  }
  return kt('liste.anzahl', {'n': n});
}

/// Anfahrt der Zelle: „ca. 25 Min“ oder „–“ ohne Bezugspunkt.
String anfahrtZelle(int? min) =>
    min == null ? kt('fakt.leer') : formatAnfahrt(min);
