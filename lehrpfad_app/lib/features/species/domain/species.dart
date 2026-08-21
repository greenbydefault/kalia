import '../../../shared/catalogs/icon_catalog.dart';
import 'species_content.dart';

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
  });

  bool get isFlora => kategorie == 'flora';
  bool get isFauna => kategorie == 'fauna';
  bool get isGeraet => kategorie == 'geraete';

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
  };
}
