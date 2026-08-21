/// Scanbarer Outdoor-Steckbrief + Vorlese-Skript einer Art.
///
/// Spec: tools/SPECIES_CONTENT.md
class SpeciesContent {
  final String hook;
  final List<String> erkennung;
  final String lebensraum;
  final List<String> funFacts;
  final String hinweis;
  final String hoertext;

  const SpeciesContent({
    this.hook = '',
    this.erkennung = const [],
    this.lebensraum = '',
    this.funFacts = const [],
    this.hinweis = '',
    this.hoertext = '',
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
    );
  }

  Map<String, dynamic> toJson() => {
    'hook': hook,
    'erkennung': erkennung,
    'lebensraum': lebensraum,
    'funFacts': funFacts,
    'hinweis': hinweis,
    'hoertext': hoertext,
  };
}
