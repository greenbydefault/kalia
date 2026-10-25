import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../core/config/map_config.dart';
import '../../features/community/domain/trail_image.dart';
import '../../shared/widgets/kalia_image.dart';
import '../core/field_spec.dart';
import 'import_models.dart';

List<LatLng> _points(dynamic raw) {
  if (raw is! List) return const [];
  final out = <LatLng>[];
  for (final p in raw) {
    if (p is List && p.length >= 2 && p[0] is num && p[1] is num) {
      out.add(LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()));
    }
  }
  return out;
}

/// Linke Seite im Review: Dossier-Rohtext, offizielle Bilder, Karte.
class SourcePanel extends StatelessWidget {
  const SourcePanel({
    super.key,
    required this.job,
    required this.trail,
    required this.images,
    required this.stations,
    required this.onSetStart,
  });

  final ImportJob job;
  final DbRow? trail;
  final List<DbRow> images;
  final List<DbRow> stations;
  final void Function(LatLng) onSetStart;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Dossier'),
              Tab(text: 'Bilder'),
              Tab(text: 'Karte'),
            ],
          ),
          const Divider(height: 1, color: AppColors.n200),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                DossierView(roh: job.parsed?['roh']),
                _ImagesView(images: images, trailId: job.trailId),
                _MapView(
                  trail: trail,
                  stations: stations,
                  onSetStart: onSetStart,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DossierView extends StatelessWidget {
  const DossierView({super.key, required this.roh});

  final dynamic roh;

  static const _titles = {
    '1': 'Steckbrief',
    '2': 'Lage und Zugang',
    '3': 'Texte',
    '4': 'Natur und Arten',
    '5': 'Stationen',
    '6': 'Besuch',
    '7': 'Bilder',
    '8': 'Quellen',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (roh is! Map) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Kein Dossier-Rohtext gespeichert.'),
        ),
      );
    }
    final m = Map<String, dynamic>.from(roh as Map);
    final abschnitte = Map<String, dynamic>.from(
      (m['abschnitte'] as Map?) ?? {},
    );
    final felder = Map<String, dynamic>.from((m['felder'] as Map?) ?? {});
    final nrs = {
      ...abschnitte.keys,
      for (final f in felder.values) '${(f as Map)['abschnitt']}',
    }..remove('null');
    final sorted = nrs.toList()
      ..sort(
        (a, b) => (int.tryParse(a) ?? 99).compareTo(int.tryParse(b) ?? 99),
      );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final nr in sorted) ...[
          _SectionHead(
            title: '$nr · ${_titles[nr] ?? 'Abschnitt'}',
            status: (abschnitte[nr] as Map?)?['status'] as String?,
          ),
          for (final e in felder.entries)
            if ('${(e.value as Map)['abschnitt']}' == nr &&
                '${(e.value as Map)['roh'] ?? ''}'.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(e.value as Map)['label'] ?? e.key.replaceFirst('trails.', '')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    SelectableText('${(e.value as Map)['roh']}'),
                  ],
                ),
              ),
          for (final q
              in ((abschnitte[nr] as Map?)?['quellen'] as List? ?? const []))
            if (q is Map)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: SelectableText(
                  'Quelle: ${q['angabe'] ?? ''} ${q['url'] ?? ''}'.trim(),
                  style: theme.textTheme.bodySmall,
                ),
              ),
          const SizedBox(height: 12),
        ],
        for (final t in const [
          ('arten', 'Arten'),
          ('stationen', 'Stationen'),
          ('bilder', 'Bilder'),
          ('pois', 'Orte'),
          ('ausstattung', 'Ausstattung'),
          ('steckbrief', 'Steckbrief-Zeilen'),
        ])
          if ((m[t.$1] as List?)?.isNotEmpty ?? false)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('${t.$2} (${(m[t.$1] as List).length})'),
              children: [
                for (final row in (m[t.$1] as List))
                  if (row is Map)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SelectableText(
                          [
                            for (final v in row.values)
                              if ('${v ?? ''}'.trim().isNotEmpty) '$v',
                          ].join(' · '),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
              ],
            ),
      ],
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.title, this.status});

  final String title;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final fertig = status == 'fertig';
    final text = status == null ? 'ohne Status' : status!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          Icon(
            fertig ? Icons.check_circle_outline : Icons.pending_outlined,
            size: 14,
            color: fertig ? AppColors.statusOk : AppColors.statusWarn,
          ),
          const SizedBox(width: 4),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ImagesView extends StatelessWidget {
  const _ImagesView({required this.images, required this.trailId});

  final List<DbRow> images;
  final String? trailId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (images.isEmpty || trailId == null) {
      return const Center(child: Text('Keine offiziellen Bilder.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final r in images)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: KaliaImage(
                      trailId: trailId,
                      imageId: r['id'] as String,
                      slot: TrailImageVariant.medium,
                      thumbhash: r['thumbhash'] as String? ?? '',
                      dominantColor: r['dominant_color'] as String? ?? '',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${r['caption'] ?? ''}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  [
                    if ('${r['credit'] ?? ''}'.isNotEmpty) '${r['credit']}',
                    if ('${r['license'] ?? ''}'.isNotEmpty)
                      '${r['license']}'
                    else
                      'Lizenz fehlt',
                    'Status ${r['status']}',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MapView extends StatefulWidget {
  const _MapView({
    required this.trail,
    required this.stations,
    required this.onSetStart,
  });

  final DbRow? trail;
  final List<DbRow> stations;
  final void Function(LatLng) onSetStart;

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  var _setStart = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.trail;
    if (t == null) return const Center(child: CircularProgressIndicator());
    final route = _points(t['route']);
    final area = _points(t['area']);
    final line = area.isNotEmpty ? area : route;
    final sLat = (t['start_lat'] as num?)?.toDouble();
    final sLon = (t['start_lon'] as num?)?.toDouble();
    final start = sLat != null && sLon != null ? LatLng(sLat, sLon) : null;
    final stationPts = [
      for (final s in widget.stations)
        if (s['lat'] is num && s['lon'] is num)
          (
            n: s['reihenfolge'],
            p: LatLng(
              (s['lat'] as num).toDouble(),
              (s['lon'] as num).toDouble(),
            ),
          ),
    ];
    final all = [...line, ?start, for (final s in stationPts) s.p];
    if (all.isEmpty) {
      return const Center(child: Text('Keine Geometrie im Entwurf.'));
    }
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCameraFit: all.length > 1
                ? CameraFit.coordinates(
                    coordinates: all,
                    padding: const EdgeInsets.all(32),
                  )
                : null,
            initialCenter: all.first,
            initialZoom: 15,
            onTap: _setStart ? (_, p) => widget.onSetStart(p) : null,
          ),
          children: [
            MapConfig.buildOsmTileLayer(),
            if (area.isNotEmpty)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: area,
                    color: AppColors.statusInfo.withValues(alpha: 0.2),
                    borderColor: AppColors.statusInfo,
                    borderStrokeWidth: 3,
                  ),
                ],
              )
            else if (route.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: route,
                    strokeWidth: 4,
                    color: AppColors.statusInfo,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final s in stationPts)
                  Marker(
                    point: s.p,
                    width: 26,
                    height: 26,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${s.n}',
                          style: const TextStyle(
                            color: AppColors.n50,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (start != null)
                  Marker(
                    point: start,
                    width: 32,
                    height: 32,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.flag,
                      color: AppColors.statusError,
                      size: 30,
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          left: 12,
          top: 12,
          child: FilterChip(
            selected: _setStart,
            label: Text(
              _setStart ? 'Tippen setzt den Start' : 'Start verschieben',
            ),
            avatar: const Icon(Icons.flag_outlined, size: 16),
            onSelected: (v) => setState(() => _setStart = v),
          ),
        ),
      ],
    );
  }
}
