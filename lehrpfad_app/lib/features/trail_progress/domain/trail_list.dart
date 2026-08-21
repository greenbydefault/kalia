class TrailListItem {
  const TrailListItem({
    required this.listId,
    required this.trailId,
    required this.addedAt,
  });

  final String listId;
  final String trailId;
  final DateTime addedAt;

  Map<String, dynamic> toJson() => {
    'listId': listId,
    'trailId': trailId,
    'addedAt': addedAt.toIso8601String(),
  };

  factory TrailListItem.fromJson(Map<String, dynamic> json) => TrailListItem(
    listId: json['listId'] as String,
    trailId: json['trailId'] as String,
    addedAt: DateTime.parse(json['addedAt'] as String),
  );
}

/// Benannte Sammlung von Trails. Items separat, analog zur SQL-Junction.
class TrailList {
  const TrailList({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TrailListItem> items;

  int get trailCount => items.length;

  bool containsTrail(String trailId) =>
      items.any((item) => item.trailId == trailId);

  List<String> get trailIds => [for (final item in items) item.trailId];

  TrailList copyWith({
    String? name,
    DateTime? updatedAt,
    List<TrailListItem>? items,
  }) {
    return TrailList(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMetaJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory TrailList.fromMetaJson(Map<String, dynamic> json) => TrailList(
    id: json['id'] as String,
    name: json['name'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
