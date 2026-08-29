import '../../../shared/catalogs/icon_catalog.dart';

/// Ein Maß-Eintrag (Species `masse[]`): Key aus [masseKatalog] + Anzeigewert.
class SpeciesMasse {
  final String key;
  final String wert;

  const SpeciesMasse({required this.key, required this.wert});

  KatalogEintrag get eintrag => masseEintrag(key);

  factory SpeciesMasse.fromJson(Map<String, dynamic> json) {
    return SpeciesMasse(
      key: json['key'] as String,
      wert: json['wert'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'key': key, 'wert': wert};
}
