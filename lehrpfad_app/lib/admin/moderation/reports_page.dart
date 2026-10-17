import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../core/config/map_config.dart';
import '../core/admin_repository.dart';

/// Offene Beiträge: eingereicht, in Prüfung, Rückfrage.
const _openStatuses = ['submitted', 'in_review', 'needs_info'];

const _reasonLabels = {
  'duplicate': 'Dublette',
  'within_gps_noise': 'Im GPS-Rauschen',
  'not_family_suitable': 'Nicht familiengeeignet',
  'not_public': 'Nicht öffentlich',
  'insufficient_data': 'Zu wenig Daten',
  'wrong_location': 'Falscher Ort',
  'other': 'Sonstiges',
};

const _statusLabels = {
  'submitted': 'Eingereicht',
  'in_review': 'In Prüfung',
  'needs_info': 'Rückfrage',
  'approved': 'Übernommen',
  'partially_approved': 'Teilweise',
  'rejected': 'Abgelehnt',
  'withdrawn': 'Zurückgezogen',
};

const _kindLabels = {
  'new_trail': 'Neuer Pfad',
  'revision': 'Neuaufnahme',
  'quick': 'Schnellmeldung',
};

/// Anzahl offener Beiträge für die Sidebar.
final openSubmissionCountProvider = FutureProvider<int>((ref) async {
  final rows = await ref
      .watch(adminClientProvider)
      .from('submissions')
      .select('id')
      .inFilter('status', _openStatuses);
  return rows.length;
});

/// Filter der Queue: `open` oder `all`, dazu die Art.
typedef ReportFilter = ({bool onlyOpen, String? kind});

final adminSubmissionsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, ReportFilter>((
      ref,
      f,
    ) async {
      var q = ref
          .watch(adminClientProvider)
          .from('submissions')
          .select(
            'id, kind, status, title, area, target_trail_id, intent, '
            'submitted_at, presence_ok, possible_duplicate_trail_id, '
            'consensus_group_id, track_length_m, photos_expected',
          );
      if (f.onlyOpen) q = q.inFilter('status', _openStatuses);
      if (f.kind != null) q = q.eq('kind', f.kind!);
      final rows = await q
          .order('submitted_at', ascending: f.onlyOpen)
          .limit(200);
      return rows.cast<Map<String, dynamic>>();
    });

final adminSubmissionDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
      final client = ref.watch(adminClientProvider);
      final res = await client.rpc<dynamic>(
        'admin_submission_detail',
        params: {'p_submission_id': id},
      );
      final detail = Map<String, dynamic>.from(res as Map);
      // Fotos: private Bucket, signierte URLs.
      final photos = <Map<String, dynamic>>[];
      for (final p in (detail['photos'] as List).cast<Map<String, dynamic>>()) {
        String? url;
        try {
          url = await client.storage
              .from('submission-photos')
              .createSignedUrl(p['storage_path'] as String, 3600);
        } catch (_) {}
        photos.add({...p, 'url': url});
      }
      detail['photos'] = photos;
      return detail;
    });

/// Moderation der Nutzer-Meldungen („Pfad melden“): Queue links, Detail
/// rechts mit Karte, Markern und Entscheidung.
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key, this.itemId});

  final String? itemId;

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  bool _onlyOpen = true;
  String? _kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = (onlyOpen: _onlyOpen, kind: _kind);
    final list = ref.watch(adminSubmissionsProvider(filter));

    final queue = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
          child: Text('Meldungen', style: theme.textTheme.headlineSmall),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilterChip(
                label: const Text('Offen'),
                selected: _onlyOpen,
                onSelected: (v) => setState(() => _onlyOpen = v),
              ),
              for (final e in _kindLabels.entries)
                FilterChip(
                  label: Text(e.value),
                  selected: _kind == e.key,
                  onSelected: (v) => setState(() => _kind = v ? e.key : null),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.n200),
        Expanded(
          child: list.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Fehler: $e')),
            data: (rows) => rows.isEmpty
                ? const Center(child: Text('Keine Meldungen.'))
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.n200),
                    itemBuilder: (_, i) {
                      final r = rows[i];
                      final id = r['id'] as String;
                      return ListTile(
                        selected: id == widget.itemId,
                        title: Text(_title(r), maxLines: 1),
                        subtitle: Text(
                          '${_kindLabels[r['kind']] ?? r['kind']} · '
                          '${_statusLabels[r['status']] ?? r['status']} · '
                          '${_date(r['submitted_at'])}',
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            if (r['presence_ok'] == false)
                              const Tooltip(
                                message: 'Nicht vor Ort',
                                child: Icon(Icons.location_off, size: 18),
                              ),
                            if (r['possible_duplicate_trail_id'] != null)
                              const Tooltip(
                                message: 'Mögliche Dublette',
                                child: Icon(Icons.copy, size: 18),
                              ),
                            if (r['consensus_group_id'] != null)
                              const Tooltip(
                                message: 'Mehrere Meldungen am selben Punkt',
                                child: Icon(Icons.groups_outlined, size: 18),
                              ),
                          ],
                        ),
                        onTap: () => context.go('/meldungen/$id'),
                      );
                    },
                  ),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        final detail = widget.itemId == null
            ? const Center(child: Text('Meldung wählen.'))
            : SubmissionDetail(
                key: ValueKey(widget.itemId),
                id: widget.itemId!,
                onDecided: () {
                  ref.invalidate(adminSubmissionsProvider(filter));
                  ref.invalidate(openSubmissionCountProvider);
                },
              );
        if (c.maxWidth >= 1000) {
          return Row(
            children: [
              SizedBox(width: 380, child: queue),
              const VerticalDivider(width: 1, color: AppColors.n200),
              Expanded(child: detail),
            ],
          );
        }
        return widget.itemId == null ? queue : detail;
      },
    );
  }

  static String _title(Map<String, dynamic> r) {
    final t = (r['title'] as String?)?.trim();
    if (t != null && t.isNotEmpty) return t;
    return switch (r['intent']) {
      'move_point' => 'Station verschoben',
      'add_point' => 'Station ergänzt',
      'hint' => 'Hinweis',
      'other' => 'Sonstiges',
      _ => (r['target_trail_id'] as String?) ?? 'Beitrag',
    };
  }

  static String _date(Object? iso) {
    final d = DateTime.tryParse('$iso')?.toLocal();
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
}

/// Detail einer Meldung mit Entscheidung.
class SubmissionDetail extends ConsumerStatefulWidget {
  const SubmissionDetail({
    super.key,
    required this.id,
    required this.onDecided,
  });

  final String id;
  final VoidCallback onDecided;

  @override
  ConsumerState<SubmissionDetail> createState() => _SubmissionDetailState();
}

class _SubmissionDetailState extends ConsumerState<SubmissionDetail> {
  final _map = MapController();
  final _note = TextEditingController();
  final _question = TextEditingController();
  final Map<String, bool> _accept = {};
  String? _reason;
  bool _consensusMean = false;
  bool _busy = false;
  bool _opened = false;

  @override
  void dispose() {
    _map.dispose();
    _note.dispose();
    _question.dispose();
    super.dispose();
  }

  Future<void> _open(Map<String, dynamic> detail) async {
    if (_opened) return;
    _opened = true;
    final status = (detail['submission'] as Map)['status'];
    if (status != 'submitted') return;
    try {
      await ref
          .read(adminClientProvider)
          .rpc<dynamic>(
            'open_submission',
            params: {'p_submission_id': widget.id},
          );
      widget.onDecided();
    } catch (_) {}
  }

  Future<void> _decide(String status, Map<String, dynamic> detail) async {
    final points = (detail['points'] as List).cast<Map<String, dynamic>>();
    if (status == 'rejected' && _reason == null) {
      _snack('Grundcode wählen.');
      return;
    }
    if (status == 'needs_info' && _question.text.trim().isEmpty) {
      _snack('Frage eintragen.');
      return;
    }
    final decisions = <String, dynamic>{
      'status': status,
      if (status == 'rejected') 'reason_code': _reason,
      if (_note.text.trim().isNotEmpty) 'note': _note.text.trim(),
      if (status == 'needs_info') 'question': _question.text.trim(),
      'consensus_mean': _consensusMean,
      'points': [
        for (final p in points)
          {
            'id': p['id'],
            'accept': status == 'approved'
                ? true
                : status == 'partially_approved'
                ? (_accept[p['id']] ?? true)
                : false,
            'lat': p['lat'],
            'lng': p['lng'],
            'type': p['type'],
            'number': p['number'],
            'title': p['title'],
            'hint_kind': p['hint_kind'],
          },
      ],
    };
    setState(() => _busy = true);
    try {
      await ref
          .read(adminClientProvider)
          .rpc<dynamic>(
            'apply_submission',
            params: {'p_submission_id': widget.id, 'decisions': decisions},
          );
      ref.invalidate(adminSubmissionDetailProvider(widget.id));
      widget.onDecided();
      _snack('Entscheidung gespeichert.');
    } catch (e) {
      _snack('Fehler: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminSubmissionDetailProvider(widget.id));
    final theme = Theme.of(context);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (detail) {
        _open(detail);
        final s = Map<String, dynamic>.from(detail['submission'] as Map);
        final points = (detail['points'] as List).cast<Map<String, dynamic>>();
        final photos = (detail['photos'] as List).cast<Map<String, dynamic>>();
        final events = (detail['events'] as List).cast<Map<String, dynamic>>();
        final open = _openStatuses.contains(s['status']);

        final segments = [
          for (final seg in detail['track'] as List)
            [
              for (final c in seg as List)
                LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
            ],
        ];
        final route = [
          for (final c in detail['trail_route'] as List)
            LatLng((c[0] as num).toDouble(), (c[1] as num).toDouble()),
        ];
        final all = [
          for (final sg in segments) ...sg,
          for (final p in points)
            LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()),
        ];

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Zurück',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/meldungen'),
                ),
                Expanded(
                  child: Text(
                    '${_kindLabels[s['kind']] ?? s['kind']}: '
                    '${s['title'] ?? detail['trail_name'] ?? ''}',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                Chip(
                  label: Text(_statusLabels[s['status']] ?? '${s['status']}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 380,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: all.isEmpty
                        ? MapConfig.defaultCenter
                        : all.first,
                    initialZoom: 15,
                    initialCameraFit: all.length >= 2
                        ? CameraFit.coordinates(
                            coordinates: all,
                            padding: const EdgeInsets.all(40),
                            maxZoom: 18,
                          )
                        : null,
                  ),
                  children: [
                    MapConfig.buildOsmTileLayer(),
                    if (route.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: route,
                            strokeWidth: 4,
                            color: AppColors.n400,
                            pattern: const StrokePattern.dotted(),
                          ),
                        ],
                      ),
                    PolylineLayer(
                      polylines: [
                        for (final sg in segments)
                          if (sg.length >= 2)
                            Polyline(
                              points: sg,
                              strokeWidth: 5,
                              color: AppColors.brand,
                            ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        for (final p in points) ...[
                          if (p['target_lat'] != null)
                            Marker(
                              point: LatLng(
                                (p['target_lat'] as num).toDouble(),
                                (p['target_lng'] as num).toDouble(),
                              ),
                              width: 22,
                              height: 22,
                              child: const Icon(
                                Icons.place_outlined,
                                color: AppColors.n400,
                              ),
                            ),
                          Marker(
                            point: LatLng(
                              (p['lat'] as num).toDouble(),
                              (p['lng'] as num).toDouble(),
                            ),
                            width: 30,
                            height: 30,
                            child: Tooltip(
                              message: '${p['type']} ${p['number'] ?? ''}',
                              child: CircleAvatar(
                                backgroundColor: AppColors.brand,
                                child: Text(
                                  p['number']?.toString() ??
                                      (p['type'] as String)[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.paper,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (s['track_length_m'] != null)
                  Text(
                    'Länge ${((s['track_length_m'] as num) / 1000).toStringAsFixed(2)} km',
                  ),
                Text('Fotos ${photos.length} von ${s['photos_expected']}'),
                if (s['presence_ok'] == false)
                  const Text('Nicht vor Ort gemeldet'),
                if (s['possible_duplicate_trail_id'] != null)
                  Text(
                    'Mögliche Dublette: ${s['possible_duplicate_trail_id']}',
                  ),
                if (s['stroller'] != null)
                  Text('Kinderwagen: ${s['stroller']}'),
                if (s['is_loop'] == true) const Text('Rundweg'),
                if (s['platform'] != null)
                  Text('${s['platform']} ${s['app_version'] ?? ''}'),
              ],
            ),
            if ((s['note'] as String?)?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text('Notiz: ${s['note']}'),
            ],
            const SizedBox(height: 16),
            Text('Punkte', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Übernehmen')),
                  DataColumn(label: Text('Typ')),
                  DataColumn(label: Text('Nr.')),
                  DataColumn(label: Text('Titel')),
                  DataColumn(label: Text('±m')),
                  DataColumn(label: Text('Abweichung')),
                  DataColumn(label: Text('Hinweis')),
                ],
                rows: [
                  for (final p in points)
                    DataRow(
                      cells: [
                        DataCell(
                          Checkbox(
                            value: _accept[p['id']] ?? true,
                            onChanged: open
                                ? (v) => setState(
                                    () => _accept['${p['id']}'] = v ?? true,
                                  )
                                : null,
                          ),
                        ),
                        DataCell(Text('${p['type']}')),
                        DataCell(Text('${p['number'] ?? ''}')),
                        DataCell(Text('${p['title'] ?? ''}')),
                        DataCell(
                          Text(
                            '${((p['accuracy_m'] as num?) ?? 0).round()}'
                            '${p['low_accuracy'] == true ? ' !' : ''}',
                          ),
                        ),
                        DataCell(
                          Text(
                            p['deviation_m'] == null
                                ? ''
                                : '${(p['deviation_m'] as num).round()} m '
                                      '(${p['deviation_class']})',
                          ),
                        ),
                        DataCell(Text('${p['hint_kind'] ?? p['note'] ?? ''}')),
                      ],
                    ),
                ],
              ),
            ),
            if (photos.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Fotos', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final f in photos)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: f['url'] == null
                            ? const SizedBox(width: 140, child: Placeholder())
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  f['url'] as String,
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            ],
            if (events.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Verlauf', style: theme.textTheme.titleMedium),
              for (final e in events)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${e['event']}'),
                  subtitle: Text('${e['created_at']} ${e['payload'] ?? ''}'),
                ),
            ],
            if (open) ...[
              const Divider(height: 40),
              Text('Entscheidung', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              if (s['consensus_group_id'] != null)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mittelwert der Konsens-Gruppe verwenden'),
                  value: _consensusMean,
                  onChanged: (v) => setState(() => _consensusMean = v ?? false),
                ),
              TextField(
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notiz an die Nutzerin (optional)',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _reason,
                decoration: const InputDecoration(
                  labelText: 'Grundcode (nur bei Ablehnung)',
                ),
                items: [
                  for (final e in _reasonLabels.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _reason = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _question,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Rückfrage (nur bei Rückfrage)',
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: _busy ? null : () => _decide('approved', detail),
                    child: const Text('Übernehmen'),
                  ),
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _decide('partially_approved', detail),
                    child: const Text('Teilweise übernehmen'),
                  ),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _decide('needs_info', detail),
                    child: const Text('Rückfrage'),
                  ),
                  OutlinedButton(
                    onPressed: _busy ? null : () => _decide('rejected', detail),
                    child: const Text('Ablehnen'),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
