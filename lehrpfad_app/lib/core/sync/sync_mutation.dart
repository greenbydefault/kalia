import 'package:uuid/uuid.dart';

/// Eine ausstehende Remote-Mutation. Serialisierbar, damit die Queue
/// App-Neustarts überlebt.
///
/// [key] identifiziert zusammen mit [entity] das betroffene Objekt und
/// dient dem Coalescing: pro (entity, key) hält die Queue nur die
/// neueste Mutation.
class SyncMutation {
  const SyncMutation({
    required this.id,
    required this.entity,
    required this.key,
    required this.op,
    required this.payload,
    required this.at,
  });

  factory SyncMutation.create({
    required String entity,
    required String key,
    required SyncOp op,
    Map<String, dynamic> payload = const {},
  }) {
    return SyncMutation(
      id: const Uuid().v4(),
      entity: entity,
      key: key,
      op: op.name,
      payload: payload,
      at: DateTime.now().toUtc(),
    );
  }

  factory SyncMutation.fromJson(Map<String, dynamic> json) {
    return SyncMutation(
      id: json['id'] as String,
      entity: json['entity'] as String,
      key: json['key'] as String,
      op: json['op'] as String,
      payload: (json['payload'] as Map).cast<String, dynamic>(),
      at: DateTime.parse(json['at'] as String),
    );
  }

  final String id;
  final String entity;
  final String key;

  /// [SyncOp.name]; als String gehalten, damit die Queue keine
  /// Enum-Kenntnis fremder Entities braucht.
  final String op;
  final Map<String, dynamic> payload;
  final DateTime at;

  Map<String, dynamic> toJson() => {
    'id': id,
    'entity': entity,
    'key': key,
    'op': op,
    'payload': payload,
    'at': at.toIso8601String(),
  };
}

enum SyncOp { upsert, delete }
