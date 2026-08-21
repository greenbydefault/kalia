import 'completion_source.dart';

class TrailCompletion {
  const TrailCompletion({
    required this.trailId,
    required this.completedAt,
    required this.source,
  });

  final String trailId;
  final DateTime completedAt;
  final CompletionSource source;

  Map<String, dynamic> toJson() => {
    'trailId': trailId,
    'completedAt': completedAt.toIso8601String(),
    'source': source.wire,
  };

  factory TrailCompletion.fromJson(Map<String, dynamic> json) =>
      TrailCompletion(
        trailId: json['trailId'] as String,
        completedAt: DateTime.parse(json['completedAt'] as String),
        source: CompletionSource.fromWire(json['source'] as String?),
      );
}
