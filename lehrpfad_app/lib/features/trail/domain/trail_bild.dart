/// Redaktionelles Hero-Foto eines Trails (Seed-Asset, nicht User-Upload).
class TrailBild {
  final String file;
  final String caption;
  final String credit;
  final String license;
  final String licenseUrl;
  final String sourceUrl;
  final String? kind;

  const TrailBild({
    required this.file,
    required this.caption,
    required this.credit,
    required this.license,
    required this.licenseUrl,
    required this.sourceUrl,
    this.kind,
  });

  bool get isPlaceholder => kind == 'placeholder';

  bool get hasCreditBadge =>
      credit.trim().isNotEmpty || licenseLabel.trim().isNotEmpty;

  /// Absolute Asset-Pfade (Platzhalter) unverändert; sonst Ordner des Trails.
  String assetPath(String trailId) =>
      file.startsWith('assets/') ? file : 'assets/images/trails/$trailId/$file';

  String get licenseLabel => switch (license) {
    'cc-by-sa-4.0' || 'cc-by-sa-3.0' || 'cc-by-sa-2.0' => 'CC BY-SA',
    'cc-by-4.0' || 'cc-by-3.0' || 'cc-by-2.0' => 'CC BY',
    'cc0' => 'CC0',
    'pd' => 'PD',
    _ => license,
  };

  String get badgeText {
    final author = credit.trim();
    if (author.isEmpty) return licenseLabel;
    return '$author · $licenseLabel';
  }

  factory TrailBild.fromJson(Map<String, dynamic> json) => TrailBild(
    file: json['file'] as String,
    caption: json['caption'] as String? ?? '',
    credit: json['credit'] as String? ?? '',
    license: json['license'] as String? ?? '',
    licenseUrl: json['licenseUrl'] as String? ?? '',
    sourceUrl: json['sourceUrl'] as String? ?? '',
    kind: json['kind'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'file': file,
    'caption': caption,
    'credit': credit,
    'license': license,
    'licenseUrl': licenseUrl,
    'sourceUrl': sourceUrl,
    if (kind != null) 'kind': kind,
  };
}
