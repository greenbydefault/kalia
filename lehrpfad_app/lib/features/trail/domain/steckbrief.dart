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
    groesseHa: _double(json['groesseHa']),
    alterJahre: _int(json['alterJahre']),
    tiefeM: _double(json['tiefeM']),
    lebenselixier: json['lebenselixier'] as String?,
    werdegang: json['werdegang'] as String?,
  );

  // Importe liefern Zahlen teils als String ("12,5"); beides wird gelesen.
  static double? _double(Object? v) => v is num
      ? v.toDouble()
      : v is String
      ? double.tryParse(v.replaceAll(',', '.').trim())
      : null;

  static int? _int(Object? v) => v is num
      ? v.toInt()
      : v is String
      ? int.tryParse(v.trim()) ??
            double.tryParse(v.replaceAll(',', '.').trim())?.toInt()
      : null;

  Map<String, dynamic> toJson() => {
    'groesseHa': groesseHa,
    'alterJahre': alterJahre,
    'tiefeM': tiefeM,
    'lebenselixier': lebenselixier,
    'werdegang': werdegang,
  };
}
