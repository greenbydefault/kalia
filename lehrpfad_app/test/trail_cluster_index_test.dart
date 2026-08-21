import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';
import 'package:lehrpfad_app/features/trail/presentation/map/trail_cluster_index.dart';

void main() {
  Trail trail({required String id, required LatLng start}) {
    return Trail(
      id: id,
      name: id,
      typ: 'wald',
      kurzbeschreibung: 'k',
      beschreibung: 'b',
      laengeKm: 1,
      dauerMin: 30,
      rundkurs: false,
      markierung: 'm',
      betreiber: 'b',
      region: 'r',
      anreise: 'a',
      startName: 's',
      arten: const [],
      route: [start, LatLng(start.latitude + 0.01, start.longitude + 0.01)],
      stationen: const [],
      amenities: const [],
    );
  }

  final nearA = trail(id: 'near-a', start: const LatLng(52.52, 13.40));
  final nearB = trail(id: 'near-b', start: const LatLng(52.53, 13.42));
  final far = trail(id: 'far', start: const LatLng(48.14, 11.58));

  test('zwei enge Punkte clustern bei Zoom 5, Count exakt', () {
    final index = TrailClusterIndex([nearA, nearB, far]);
    final nodes = index.nodesAt(5);

    final clusters = nodes.whereType<TrailMapCluster>().toList();
    final points = nodes.whereType<TrailMapPoint>().toList();

    expect(clusters, hasLength(1));
    expect(clusters.single.count, 2);
    expect(points, hasLength(1));
    expect(points.single.trail.id, 'far');
  });

  test('dieselben Punkte splitten bei Zoom 14', () {
    final index = TrailClusterIndex([nearA, nearB]);
    final nodes = index.nodesAt(14);

    expect(nodes.whereType<TrailMapCluster>(), isEmpty);
    expect(
      nodes.whereType<TrailMapPoint>().map((n) => n.trail.id).toSet(),
      {'near-a', 'near-b'},
    );
  });

  test('expansionZoom liegt über dem Cluster-Zoom', () {
    final index = TrailClusterIndex([nearA, nearB]);
    final cluster = index.nodesAt(5).whereType<TrailMapCluster>().single;

    expect(cluster.expansionZoom, greaterThan(5));
    expect(index.expansionZoom(cluster.id), cluster.expansionZoom);
  });

  test('nicht übergebene Trails fehlen im Index', () {
    final index = TrailClusterIndex([nearA, nearB]);
    final ids = {
      for (final node in index.nodesAt(14))
        if (node is TrailMapPoint) node.trail.id,
    };

    expect(ids, {'near-a', 'near-b'});
    expect(ids.contains('far'), isFalse);
  });

  test('leere Liste und Trails ohne Start', () {
    final empty = TrailClusterIndex(const []);
    expect(empty.nodesAt(5), isEmpty);

    final noStart = Trail(
      id: 'broken',
      name: 'broken',
      typ: 'wald',
      kurzbeschreibung: 'k',
      beschreibung: 'b',
      laengeKm: 0,
      dauerMin: 0,
      rundkurs: false,
      markierung: 'm',
      betreiber: 'b',
      region: 'r',
      anreise: 'a',
      startName: 's',
      arten: const [],
      route: const [],
      stationen: const [],
      amenities: const [],
    );
    expect(TrailClusterIndex([noStart]).nodesAt(5), isEmpty);
  });
}
