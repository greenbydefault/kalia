import 'trail.dart';

/// Art der abgeleiteten Trail-Eignung.
enum EignungArt { kinderfreundlich, barrierefreundlich }

/// Abgeleiteter Eignungs-Score eines Trails.
///
/// Invariant: [level] ∈ 1..5. Nicht persistiert — immer aus Trail-Daten
/// berechnet (siehe [scoreEignungen]).
class EignungScore {
  final EignungArt art;
  final int level;
  final List<String> matchedSignals;

  const EignungScore({
    required this.art,
    required this.level,
    required this.matchedSignals,
  });

  /// Kurzlabel zum Level: Gar nicht / Wenig / Mittel / Gut / Sehr.
  String get label => eignungLevelLabel(level);

  String get artLabel => switch (art) {
    EignungArt.kinderfreundlich => 'Kinderfreundlich',
    EignungArt.barrierefreundlich => 'Barrierefreundlich',
  };
}

/// Level-Labels für die Signal-Balken (Index = level − 1).
const eignungLevelLabels = <String>[
  'Gar nicht',
  'Wenig',
  'Mittel',
  'Gut',
  'Sehr',
];

String eignungLevelLabel(int level) {
  final i = level.clamp(1, 5) - 1;
  return eignungLevelLabels[i];
}

/// Ein gewichtetes Signal im Eignungs-Katalog.
///
/// Neues Signal = ein Eintrag in [_eignungSignale]. Gewichte: 1 (schwach)
/// oder 2 (stark). Level = Summe der Treffer-Gewichte, geclampt auf 1..5.
class _EignungSignal {
  final String id;
  final EignungArt art;
  final int weight;
  final bool Function(_EignungContext ctx) matches;

  const _EignungSignal({
    required this.id,
    required this.art,
    required this.weight,
    required this.matches,
  });
}

/// Vorberechnete Lookups für eine Trail-Bewertung (einmal pro Aufruf).
class _EignungContext {
  final Set<String> tags;
  final Set<String> amenityKats;
  final Set<String> erlebnisse;
  /// Anteil barrierefreier Stationen, 0 wenn keine Stationen.
  final double barrierefreiRatio;

  const _EignungContext({
    required this.tags,
    required this.amenityKats,
    required this.erlebnisse,
    required this.barrierefreiRatio,
  });

  bool hasTag(String key) => tags.contains(key);
  bool hasAmenity(String kat) => amenityKats.contains(kat);
  bool hasErlebnis(String key) => erlebnisse.contains(key);

  bool get hasWc => hasAmenity('wc') || hasTag('wc-am-weg');
  bool get hasParking => hasAmenity('parking') || hasTag('parkplatz-nahe');
}

const _interaktivErlebnisse = {'quiz', 'memory', 'mitmach-modell'};

/// Deklarativer Signal-Katalog. Erweiterung = neuer Eintrag + Test.
final List<_EignungSignal> _eignungSignale = [
  // ── Kinderfreundlich ─────────────────────────────────────────────
  _EignungSignal(
    id: 'kinderfreundlich',
    art: EignungArt.kinderfreundlich,
    weight: 2,
    matches: (ctx) => ctx.hasTag('kinderfreundlich'),
  ),
  _EignungSignal(
    id: 'kinderwagentauglich',
    art: EignungArt.kinderfreundlich,
    weight: 2,
    matches: (ctx) => ctx.hasTag('kinderwagentauglich'),
  ),
  _EignungSignal(
    id: 'spielplatz',
    art: EignungArt.kinderfreundlich,
    weight: 1,
    matches: (ctx) => ctx.hasTag('spielplatz') || ctx.hasAmenity('playground'),
  ),
  _EignungSignal(
    id: 'barfusspfad',
    art: EignungArt.kinderfreundlich,
    weight: 1,
    matches: (ctx) =>
        ctx.hasTag('barfusspfad') || ctx.hasErlebnis('barfusspfad'),
  ),
  _EignungSignal(
    id: 'interaktiv',
    art: EignungArt.kinderfreundlich,
    weight: 1,
    matches: (ctx) =>
        ctx.erlebnisse.any(_interaktivErlebnisse.contains),
  ),
  _EignungSignal(
    id: 'picknick',
    art: EignungArt.kinderfreundlich,
    weight: 1,
    matches: (ctx) => ctx.hasTag('picknick') || ctx.hasAmenity('picnic'),
  ),
  _EignungSignal(
    id: 'wc',
    art: EignungArt.kinderfreundlich,
    weight: 1,
    matches: (ctx) => ctx.hasWc,
  ),

  // ── Barrierefreundlich ───────────────────────────────────────────
  _EignungSignal(
    id: 'rollstuhltauglich',
    art: EignungArt.barrierefreundlich,
    weight: 2,
    matches: (ctx) => ctx.hasTag('rollstuhltauglich'),
  ),
  _EignungSignal(
    id: 'kinderwagentauglich-proxy',
    art: EignungArt.barrierefreundlich,
    weight: 1,
    matches: (ctx) => ctx.hasTag('kinderwagentauglich'),
  ),
  _EignungSignal(
    id: 'stationen-barrierefrei-teilweise',
    art: EignungArt.barrierefreundlich,
    weight: 1,
    matches: (ctx) =>
        ctx.barrierefreiRatio > 0 && ctx.barrierefreiRatio < 0.5,
  ),
  _EignungSignal(
    id: 'stationen-barrierefrei-mehrheit',
    art: EignungArt.barrierefreundlich,
    weight: 2,
    matches: (ctx) => ctx.barrierefreiRatio >= 0.5,
  ),
  _EignungSignal(
    id: 'wc',
    art: EignungArt.barrierefreundlich,
    weight: 1,
    matches: (ctx) => ctx.hasWc,
  ),
  _EignungSignal(
    id: 'parkplatz',
    art: EignungArt.barrierefreundlich,
    weight: 1,
    matches: (ctx) => ctx.hasParking,
  ),
];

/// Abgeleitete Eignung 1–5 für Kinder- und Barrierefreundlichkeit.
///
/// Nicht persistiert — immer aus Tags, Amenities und Stations-`barrierefrei`
/// berechnet. Level = Summe der Signal-Gewichte, geclampt auf 1..5
/// (0 Punkte → Level 1 „Gar nicht“).
({EignungScore kinder, EignungScore barriere}) scoreEignungen(Trail trail) {
  final ctx = _buildContext(trail);
  return (
    kinder: _scoreArt(EignungArt.kinderfreundlich, ctx),
    barriere: _scoreArt(EignungArt.barrierefreundlich, ctx),
  );
}

_EignungContext _buildContext(Trail trail) {
  final tags = {...trail.tags, ...trail.autoTags};
  final amenityKats = {for (final a in trail.amenities) a.kategorie};
  final erlebnisse = {
    for (final s in trail.stationen)
      for (final e in s.erlebnisse) e,
  };
  final n = trail.stationen.length;
  final barrierefreiRatio = n == 0
      ? 0.0
      : trail.stationen.where((s) => s.barrierefrei).length / n;

  return _EignungContext(
    tags: tags,
    amenityKats: amenityKats,
    erlebnisse: erlebnisse,
    barrierefreiRatio: barrierefreiRatio,
  );
}

EignungScore _scoreArt(EignungArt art, _EignungContext ctx) {
  final matched = <String>[];
  var points = 0;
  for (final signal in _eignungSignale) {
    if (signal.art != art) continue;
    if (!signal.matches(ctx)) continue;
    matched.add(signal.id);
    points += signal.weight;
  }
  return EignungScore(
    art: art,
    level: points.clamp(1, 5),
    matchedSignals: matched,
  );
}
