/// Scanbarer Outdoor-Steckbrief plus Einsprech-Skript (`hoertext`).
///
/// `hoertext` ist Studio-Vorlage, nicht UI. Stimme: docs/audio/GRUND.md
/// Spec: tools/SPECIES_CONTENT.md
class SpeciesContent {
  final String hook;
  final List<String> erkennung;
  final String lebensraum;
  final List<String> funFacts;
  final String hinweis;
  final String hoertext;

  /// `voll` (Hörtext) oder `kurz` (Scan-Felder, noch kein Hörtext).
  final String tiefe;

  const SpeciesContent({
    this.hook = '',
    this.erkennung = const [],
    this.lebensraum = '',
    this.funFacts = const [],
    this.hinweis = '',
    this.hoertext = '',
    this.tiefe = 'voll',
  });

  static const empty = SpeciesContent();

  bool get isEmpty =>
      hook.isEmpty &&
      erkennung.isEmpty &&
      lebensraum.isEmpty &&
      funFacts.isEmpty &&
      hinweis.isEmpty &&
      hoertext.isEmpty;

  factory SpeciesContent.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return empty;
    return SpeciesContent(
      hook: json['hook'] as String? ?? '',
      erkennung: (json['erkennung'] as List? ?? const []).cast<String>(),
      lebensraum: json['lebensraum'] as String? ?? '',
      funFacts: (json['funFacts'] as List? ?? const []).cast<String>(),
      hinweis: json['hinweis'] as String? ?? '',
      hoertext: json['hoertext'] as String? ?? '',
      tiefe: json['tiefe'] as String? ?? 'voll',
    );
  }

  Map<String, dynamic> toJson() => {
    'hook': hook,
    'erkennung': erkennung,
    'lebensraum': lebensraum,
    'funFacts': funFacts,
    'hinweis': hinweis,
    'hoertext': hoertext,
    if (tiefe == 'kurz') 'tiefe': tiefe,
  };
}
