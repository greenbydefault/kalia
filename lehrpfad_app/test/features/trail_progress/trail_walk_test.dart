import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/trail_progress/domain/trail_walk.dart';
import 'package:lehrpfad_app/features/trail_progress/domain/walk_status.dart';

void main() {
  final walk = TrailWalk(
    id: 'w1',
    trailId: 't1',
    status: WalkStatus.active,
    startedAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1, 1),
    lastLat: 53.1,
    lastLon: 13.2,
  );

  test('copyWith(lastLat: null) behält den Wert — Sentinel nötig', () {
    final next = walk.copyWith(lastLat: null, lastLon: null);
    expect(next.lastLat, 53.1);
    expect(next.lastLon, 13.2);
  });

  test('clearLastPosition nullt Coords', () {
    final next = walk.copyWith(
      status: WalkStatus.completed,
      clearLastPosition: true,
    );
    expect(next.lastLat, isNull);
    expect(next.lastLon, isNull);
    expect(next.status, WalkStatus.completed);
  });
}
