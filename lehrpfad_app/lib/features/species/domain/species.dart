import '../../../shared/catalogs/icon_catalog.dart';
import 'species_beziehung.dart';
import 'species_content.dart';
import 'species_masse.dart';

/// Eine Art bzw. ein Gerät im Katalog (Flora / Fauna / Geräte).
class Species {
  final String id;
  final String nameDe;
  final String nameLat;
  final String kategorie; // 'flora' | 'fauna' | 'geraete'
  final String kurztext;
  final SpeciesContent content;
  final List<String> aliases;
  final String? imagePath;
  final String imageCredit;
  final String? audioPath;

  /// Key in [geraeteKatalog]; nur relevant bei [isGeraet].
  final String? iconKey;

  // Profil (nur Flora/Fauna; Geräte: Defaults/leer)
  final String gruppe; // Key in [speciesGruppeKatalog]
  final String seltenheit; // Key in [seltenheitKatalog]
  final int gefahr; // 0 = nicht gesetzt, 1–5
  final List<String> nahrung;
  final Map<String, String> taxonomie; // reich/stamm/klasse/ordnung/familie
  final List<SpeciesMasse> masse;
  final List<String> merkmalIds;
  final List<SpeciesBeziehung> beziehungen;

  const Species({
    required this.id,
    required this.nameDe,
    required this.nameLat,
    required this.kategorie,
    required this.kurztext,
    this.content = SpeciesContent.empty,
    this.aliases = const [],
    this.imagePath,
    this.imageCredit = '',
    this.audioPath,
    this.iconKey,
    this.gruppe = '',
    this.seltenheit = '',
    this.gefahr = 0,
    this.nahrung = const [],
    this.taxonomie = const {},
    this.masse = const [],
    this.merkmalIds = const [],
    this.beziehungen = const [],
  });

  bool get isFlora => kategorie == 'flora';
  bool get isFauna => kategorie == 'fauna';
  bool get isGeraet => kategorie == 'geraete';

  /// Profil nur für Flora/Fauna.
  bool get hasProfil => !isGeraet && gruppe.isNotEmpty;

  /// Kategorie-Label (Flora / Fauna / Geräte) aus dem Icon-Katalog.
  String get kategorieLabel => speciesKategorieEintrag(kategorie).label;

  /// Anzeige-Icon: Geräte über [iconKey], sonst Kategorie-Icon.
  KatalogEintrag get displayIconEintrag {
    if (isGeraet) return geraeteEintrag(iconKey);
    return speciesKategorieEintrag(kategorie);
  }

  /// Hook aus [content], sonst [kurztext] (alte Caches / Seed ohne content).
  String get displayHook {
    final hook = content.hook.trim();
    if (hook.isNotEmpty) return hook;
    return kurztext;
  }

  factory Species.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    Map<String, dynamic>? contentMap;
    if (rawContent is Map<String, dynamic>) {
      contentMap = rawContent;
    } else if (rawContent is Map) {
      contentMap = Map<String, dynamic>.from(rawContent);
    }
    final rawIcon = json['iconKey'] as String?;

    final rawTax = json['taxonomie'];
    Map<String, String> taxonomie = const {};
    if (rawTax is Map) {
      taxonomie = rawTax.map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
      );
    }

    return Species(
      id: json['id'] as String,
      nameDe: json['nameDe'] as String,
      nameLat: json['nameLat'] as String? ?? '',
      kategorie: json['kategorie'] as String,
      kurztext: json['kurztext'] as String? ?? '',
      content: SpeciesContent.fromJson(contentMap),
      aliases: (json['aliases'] as List? ?? const []).cast<String>(),
      imagePath: json['imagePath'] as String?,
      imageCredit: json['imageCredit'] as String? ?? '',
      audioPath: json['audioPath'] as String?,
      iconKey: (rawIcon == null || rawIcon.isEmpty) ? null : rawIcon,
      gruppe: json['gruppe'] as String? ?? '',
      seltenheit: json['seltenheit'] as String? ?? '',
      gefahr: json['gefahr'] as int? ?? 0,
      nahrung: (json['nahrung'] as List? ?? const []).cast<String>(),
      taxonomie: taxonomie,
      masse: (json['masse'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => SpeciesMasse.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      merkmalIds: (json['merkmale'] as List? ?? const []).cast<String>(),
      beziehungen: (json['beziehungen'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => SpeciesBeziehung.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameDe': nameDe,
    'nameLat': nameLat,
    'kategorie': kategorie,
    'kurztext': kurztext,
    'content': content.toJson(),
    'aliases': aliases,
    'imagePath': imagePath,
    'imageCredit': imageCredit,
    'audioPath': audioPath,
    if (iconKey != null) 'iconKey': iconKey,
    'gruppe': gruppe,
    'seltenheit': seltenheit,
    'gefahr': gefahr,
    'nahrung': nahrung,
    'taxonomie': taxonomie,
    'masse': masse.map((m) => m.toJson()).toList(),
    'merkmale': merkmalIds,
    'beziehungen': beziehungen.map((b) => b.toJson()).toList(),
  };
}
