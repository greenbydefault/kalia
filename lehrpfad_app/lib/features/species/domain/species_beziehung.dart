/// Ökologische Beziehung einer Art (frisst / bestäubt / wohnt_an).
///
/// Entweder Katalog-Art ([toSpeciesId] gesetzt, tippbar) oder Freitext-Karte
/// ([nameDe], z. B. „Mücke“, „Uhu“) ohne eigenen Katalog-Eintrag.
class SpeciesBeziehung {
  final String typ; // 'frisst' | 'bestaeubt' | 'wohnt_an'
  final String? toSpeciesId;
  final String nameDe;
  final String nameLat;
  final String kurztext;

  const SpeciesBeziehung({
    required this.typ,
    this.toSpeciesId,
    this.nameDe = '',
    this.nameLat = '',
    this.kurztext = '',
  });

  bool get isKatalogArt => toSpeciesId != null && toSpeciesId!.isNotEmpty;

  factory SpeciesBeziehung.fromJson(Map<String, dynamic> json) {
    final raw = json['toSpeciesId'] ?? json['speciesId'];
    final toId = raw is String ? raw : null;
    return SpeciesBeziehung(
      typ: json['typ'] as String,
      toSpeciesId: (toId == null || toId.isEmpty) ? null : toId,
      nameDe: json['nameDe'] as String? ?? '',
      nameLat: json['nameLat'] as String? ?? '',
      kurztext: json['kurztext'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'typ': typ,
    if (toSpeciesId != null) 'toSpeciesId': toSpeciesId,
    'nameDe': nameDe,
    'nameLat': nameLat,
    'kurztext': kurztext,
  };
}
