/// Herkunft eines Bildes: offiziell bereitgestellt oder User-Upload.
enum TrailImageSource {
  official,
  user;

  static TrailImageSource parse(String value) =>
      value == 'official' ? TrailImageSource.official : TrailImageSource.user;
}

/// Moderationsstatus. User-Uploads starten als pending und werden von
/// Admins freigeschaltet; oeffentlich sichtbar ist nur approved.
enum TrailImageStatus {
  pending,
  approved,
  rejected;

  static TrailImageStatus parse(String value) => switch (value) {
    'approved' => TrailImageStatus.approved,
    'rejected' => TrailImageStatus.rejected,
    _ => TrailImageStatus.pending,
  };
}

/// Welche AVIF-Variante aus dem Storage geladen wird.
/// Dateikonvention: {trailId}/{imageId}/{variant}.avif
enum TrailImageVariant {
  thumb('thumb'),
  small('small'),
  medium('medium');

  const TrailImageVariant(this.fileName);
  final String fileName;
}

/// Ein Bild, das entweder zum ganzen Trail (stationId == null) oder zu
/// einer einzelnen Station gehoert.
class TrailImage {
  final String id;
  final String trailId;
  final int? stationId;
  final String? uploaderId;
  final TrailImageSource source;
  final TrailImageStatus status;
  final String credit;
  final int? width;
  final int? height;
  final DateTime createdAt;
  final bool isMine;

  /// Oeffentliche URLs der drei AVIF-Varianten (vom Repository befuellt).
  final String thumbUrl;
  final String smallUrl;
  final String mediumUrl;

  const TrailImage({
    required this.id,
    required this.trailId,
    required this.stationId,
    required this.uploaderId,
    required this.source,
    required this.status,
    required this.credit,
    required this.width,
    required this.height,
    required this.createdAt,
    required this.isMine,
    required this.thumbUrl,
    required this.smallUrl,
    required this.mediumUrl,
  });

  bool get isApproved => status == TrailImageStatus.approved;
}
