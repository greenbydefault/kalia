import 'walk_status.dart';

class TrailWalk {
  const TrailWalk({
    required this.id,
    required this.trailId,
    required this.status,
    required this.startedAt,
    required this.updatedAt,
    this.completedAt,
    this.progressM = 0,
    this.progressRatio = 0,
    this.lastLat,
    this.lastLon,
    this.visitedStationIds = const [],
  });

  final String id;
  final String trailId;
  final WalkStatus status;
  final DateTime startedAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final double progressM;
  final double progressRatio;
  final double? lastLat;
  final double? lastLon;
  final List<String> visitedStationIds;

  bool get isActive => status == WalkStatus.active;

  TrailWalk copyWith({
    WalkStatus? status,
    DateTime? updatedAt,
    DateTime? completedAt,
    double? progressM,
    double? progressRatio,
    double? lastLat,
    double? lastLon,
    List<String>? visitedStationIds,
    bool clearLastPosition = false,
  }) {
    return TrailWalk(
      id: id,
      trailId: trailId,
      status: status ?? this.status,
      startedAt: startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      progressM: progressM ?? this.progressM,
      progressRatio: progressRatio ?? this.progressRatio,
      lastLat: clearLastPosition ? null : (lastLat ?? this.lastLat),
      lastLon: clearLastPosition ? null : (lastLon ?? this.lastLon),
      visitedStationIds: visitedStationIds ?? this.visitedStationIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'trailId': trailId,
    'status': status.wire,
    'startedAt': startedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'progressM': progressM,
    'progressRatio': progressRatio,
    'lastLat': lastLat,
    'lastLon': lastLon,
    'visitedStationIds': visitedStationIds,
  };

  factory TrailWalk.fromJson(Map<String, dynamic> json) => TrailWalk(
    id: json['id'] as String,
    trailId: json['trailId'] as String,
    status: WalkStatus.fromWire(json['status'] as String?),
    startedAt: DateTime.parse(json['startedAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    completedAt: json['completedAt'] == null
        ? null
        : DateTime.parse(json['completedAt'] as String),
    progressM: (json['progressM'] as num?)?.toDouble() ?? 0,
    progressRatio: (json['progressRatio'] as num?)?.toDouble() ?? 0,
    lastLat: (json['lastLat'] as num?)?.toDouble(),
    lastLon: (json['lastLon'] as num?)?.toDouble(),
    visitedStationIds: ((json['visitedStationIds'] as List?) ?? const [])
        .cast<String>(),
  );
}
