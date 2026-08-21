/// Fakten-Steckbrief einer Station (alle Angaben optional).
class Steckbrief {
  final double? groesseHa;
  final int? alterJahre;
  final double? tiefeM;
  final String? lebenselixier;
  final String? werdegang;

  const Steckbrief({
    this.groesseHa,
    this.alterJahre,
    this.tiefeM,
    this.lebenselixier,
    this.werdegang,
  });

  factory Steckbrief.fromJson(Map<String, dynamic> json) => Steckbrief(
    groesseHa: (json['groesseHa'] as num?)?.toDouble(),
    alterJahre: json['alterJahre'] as int?,
    tiefeM: (json['tiefeM'] as num?)?.toDouble(),
    lebenselixier: json['lebenselixier'] as String?,
    werdegang: json['werdegang'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'groesseHa': groesseHa,
    'alterJahre': alterJahre,
    'tiefeM': tiefeM,
    'lebenselixier': lebenselixier,
    'werdegang': werdegang,
  };
}
