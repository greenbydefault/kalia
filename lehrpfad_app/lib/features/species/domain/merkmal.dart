import '../../../shared/catalogs/icon_catalog.dart';

/// Geteiltes Merkmal (Badge) aus assets/seed/merkmale.json / Tabelle `merkmale`.
class Merkmal {
  final String id;
  final String nameDe;
  final String beschreibung;
  final String iconKey;
  final String gruppe; // 'aussehen' | 'verhalten' | 'rolle' | 'lebensraum'
  final int sortierung;

  const Merkmal({
    required this.id,
    required this.nameDe,
    this.beschreibung = '',
    this.iconKey = '',
    this.gruppe = '',
    this.sortierung = 0,
  });

  KatalogEintrag get iconEintrag => merkmalEintrag(iconKey);

  factory Merkmal.fromJson(Map<String, dynamic> json) {
    return Merkmal(
      id: json['id'] as String,
      nameDe: json['nameDe'] as String,
      beschreibung: json['beschreibung'] as String? ?? '',
      iconKey: json['iconKey'] as String? ?? '',
      gruppe: json['gruppe'] as String? ?? '',
      sortierung: json['sortierung'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameDe': nameDe,
    'beschreibung': beschreibung,
    'iconKey': iconKey,
    'gruppe': gruppe,
    'sortierung': sortierung,
  };
}
