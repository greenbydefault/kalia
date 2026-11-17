/// Wer den Fund gemacht hat (optionale Angabe im Detail-Sheet).
enum EntdecktVon {
  erwachsene,
  kind,
  gemeinsam;

  static EntdecktVon? parse(String? raw) {
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}

/// Ein Fund in der Sammlung: Art/Gerät plus optional Datum, Pfad, Wer.
///
/// Altbestand (nur ID) hat [entdecktAm] = null.
class Fund {
  const Fund({
    required this.speciesId,
    this.entdecktAm,
    this.trailId,
    this.von,
  });

  final String speciesId;
  final DateTime? entdecktAm;
  final String? trailId;
  final EntdecktVon? von;

  Fund withVon(EntdecktVon? value) => Fund(
    speciesId: speciesId,
    entdecktAm: entdecktAm,
    trailId: trailId,
    von: value,
  );

  Fund withTrail(String? value) => Fund(
    speciesId: speciesId,
    entdecktAm: entdecktAm,
    trailId: value,
    von: von,
  );

  factory Fund.fromJson(String speciesId, Map<String, dynamic> json) {
    final at = json['at'] as String?;
    return Fund(
      speciesId: speciesId,
      entdecktAm: at == null ? null : DateTime.tryParse(at),
      trailId: json['trail'] as String?,
      von: EntdecktVon.parse(json['von'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    'at': entdecktAm?.toUtc().toIso8601String(),
    'trail': trailId,
    'von': von?.name,
  };

  @override
  bool operator ==(Object other) =>
      other is Fund &&
      other.speciesId == speciesId &&
      other.entdecktAm == entdecktAm &&
      other.trailId == trailId &&
      other.von == von;

  @override
  int get hashCode => Object.hash(speciesId, entdecktAm, trailId, von);

  /// Merge zweier Stände derselben Art: frühestes Datum, vorhandene Angaben
  /// gewinnen vor leeren, [preferred] vor [other] bei Konflikt.
  static Fund merge(Fund preferred, Fund other) {
    final a = preferred.entdecktAm;
    final b = other.entdecktAm;
    final DateTime? at = a == null
        ? b
        : (b == null ? a : (a.isBefore(b) ? a : b));
    return Fund(
      speciesId: preferred.speciesId,
      entdecktAm: at,
      trailId: preferred.trailId ?? other.trailId,
      von: preferred.von ?? other.von,
    );
  }
}
