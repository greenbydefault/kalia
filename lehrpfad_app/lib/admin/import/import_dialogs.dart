import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../core/config/map_config.dart';
import '../core/admin_repository.dart' show slugify;
import '../core/field_spec.dart';
import 'import_repository.dart';

/// Einzeiliger oder mehrzeiliger Text mit Pflichtangabe. `null` = abgebrochen.
Future<String?> askText(
  BuildContext context, {
  required String title,
  String? message,
  String hint = '',
  String confirm = 'OK',
  bool required = true,
  int minLines = 1,
}) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message != null) ...[Text(message), const SizedBox(height: 12)],
              TextField(
                controller: c,
                autofocus: true,
                minLines: minLines,
                maxLines: minLines == 1 ? 1 : 6,
                decoration: InputDecoration(hintText: hint),
                onChanged: (_) => set(() {}),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: !required || c.text.trim().isNotEmpty
                ? () => Navigator.pop(ctx, c.text.trim())
                : null,
            child: Text(confirm),
          ),
        ],
      ),
    ),
  );
}

/// Frage an Recherche oder eine Person.
Future<({String frage, String adressat})?> askQuestion(
  BuildContext context, {
  required String feldLabel,
}) {
  final c = TextEditingController();
  var adressat = 'recherche';
  return showDialog<({String frage, String adressat})>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text('Frage zu „$feldLabel“'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: c,
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Was ist unklar?',
                ),
                onChanged: (_) => set(() {}),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'recherche', label: Text('Recherche')),
                  ButtonSegment(value: 'person', label: Text('Person')),
                ],
                selected: {adressat},
                onSelectionChanged: (s) => set(() => adressat = s.first),
              ),
              const SizedBox(height: 8),
              const Text(
                'Der Pfad wartet dann auf Klärung, bis die Frage erledigt ist.',
                style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: c.text.trim().isEmpty
                ? null
                : () => Navigator.pop(ctx, (
                    frage: c.text.trim(),
                    adressat: adressat,
                  )),
            child: const Text('Fragen'),
          ),
        ],
      ),
    ),
  );
}

enum SpeciesAction { zugeordnet, angelegt, weggelassen }

/// Art zuordnen (Suche), neu anlegen oder weglassen.
Future<SpeciesAction?> speciesDialog(
  BuildContext context, {
  required ImportRepository repo,
  required String trailId,
  required String name,
  required String latGuess,
  DbRow? suggestion,
}) {
  return showDialog<SpeciesAction>(
    context: context,
    builder: (_) => _SpeciesDialog(
      repo: repo,
      trailId: trailId,
      name: name,
      latGuess: latGuess,
      suggestion: suggestion,
    ),
  );
}

class _SpeciesDialog extends StatefulWidget {
  const _SpeciesDialog({
    required this.repo,
    required this.trailId,
    required this.name,
    required this.latGuess,
    this.suggestion,
  });

  final ImportRepository repo;
  final String trailId;
  final String name;
  final String latGuess;
  final DbRow? suggestion;

  @override
  State<_SpeciesDialog> createState() => _SpeciesDialogState();
}

class _SpeciesDialogState extends State<_SpeciesDialog> {
  late final _q = TextEditingController(text: widget.name);
  late final _lat = TextEditingController(text: widget.latGuess);
  var _kategorie = 'fauna';
  List<DbRow> _hits = const [];
  var _busy = false;
  var _creating = false;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    _lat.dispose();
    super.dispose();
  }

  void _onQuery(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _search);
  }

  Future<void> _search() async {
    final r = await widget.repo.searchSpecies(_q.text);
    if (mounted) setState(() => _hits = r);
  }

  Future<void> _done(Future<void> Function() f, SpeciesAction a) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await f();
      if (mounted) Navigator.pop(context, a);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$e';
        });
      }
    }
  }

  Future<void> _link(String speciesId) => _done(() async {
    await widget.repo.attachSpecies(
      widget.trailId,
      speciesId,
      nachweis: (widget.suggestion?['nachweis'] as String?) ?? 'typisch',
    );
    final id = (widget.suggestion?['id'] as num?)?.toInt();
    if (id != null) {
      await widget.repo.setSuggestion(id, 'zugeordnet', speciesId: speciesId);
    }
  }, SpeciesAction.zugeordnet);

  Future<void> _create() => _done(() async {
    final id = slugify(widget.name);
    await widget.repo.createSpecies(
      id: id,
      nameDe: widget.name,
      nameLat: _lat.text.trim(),
      kategorie: _kategorie,
    );
    final sid = (widget.suggestion?['id'] as num?)?.toInt();
    await widget.repo.attachSpecies(
      widget.trailId,
      id,
      nachweis: (widget.suggestion?['nachweis'] as String?) ?? 'typisch',
    );
    if (sid != null) {
      await widget.repo.setSuggestion(sid, 'zugeordnet', speciesId: id);
    }
  }, SpeciesAction.angelegt);

  Future<void> _omit() => _done(() async {
    final id = (widget.suggestion?['id'] as num?)?.toInt();
    if (id != null) await widget.repo.setSuggestion(id, 'verworfen');
  }, SpeciesAction.weggelassen);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('„${widget.name}“ zuordnen'),
      content: SizedBox(
        width: 480,
        child: _creating ? _createForm() : _searchForm(),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        if (!_creating) ...[
          TextButton(
            onPressed: _busy ? null : _omit,
            child: const Text('Weglassen'),
          ),
          OutlinedButton(
            onPressed: _busy ? null : () => setState(() => _creating = true),
            child: const Text('Neu anlegen …'),
          ),
        ] else ...[
          TextButton(
            onPressed: _busy ? null : () => setState(() => _creating = false),
            child: const Text('Zurück'),
          ),
          FilledButton(
            onPressed: _busy ? null : _create,
            child: const Text('Anlegen und zuordnen'),
          ),
        ],
      ],
    );
  }

  Widget _searchForm() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: _q,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Art im Katalog suchen (deutsch oder lateinisch)',
          prefixIcon: Icon(Icons.search, size: 18),
        ),
        onChanged: _onQuery,
      ),
      const SizedBox(height: 8),
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: _hits.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Kein Treffer. Neu anlegen oder weglassen.'),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final h in _hits)
                    ListTile(
                      dense: true,
                      title: Text('${h['name_de']}'),
                      subtitle: Text(
                        '${h['name_lat'] ?? ''} · ${h['kategorie']}',
                      ),
                      onTap: _busy ? null : () => _link(h['id'] as String),
                    ),
                ],
              ),
      ),
      if (_error != null)
        Text(_error!, style: const TextStyle(color: AppColors.error)),
    ],
  );

  Widget _createForm() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Neue Art „${widget.name}“ als Kurzprofil (Inhalt später).'),
      const SizedBox(height: 12),
      TextField(
        controller: _lat,
        decoration: const InputDecoration(
          labelText: 'Lateinischer Name',
          hintText: 'Grus grus',
        ),
      ),
      const SizedBox(height: 12),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'fauna', label: Text('Fauna')),
          ButtonSegment(value: 'flora', label: Text('Flora')),
        ],
        selected: {_kategorie},
        onSelectionChanged: (s) => setState(() => _kategorie = s.first),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_error!, style: const TextStyle(color: AppColors.error)),
        ),
    ],
  );
}

enum DuplicateAction { istNeu, zusammenfuehren, verwerfen }

/// Vergleich neuer Entwurf ↔ vorhandener Pfad.
Future<DuplicateAction?> duplicateDialog(
  BuildContext context, {
  required DbRow neu,
  required DbRow? alt,
  required String altId,
}) {
  Widget col(String title, DbRow? r) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (r == null)
          const Text('Pfad nicht gefunden.')
        else ...[
          _kv('Name', r['name']),
          _kv('Region', r['region']),
          _kv('Ort', r['ort']),
          _kv('Länge', r['laenge_km'] == null ? null : '${r['laenge_km']} km'),
          _kv('Start', '${r['start_lat'] ?? '–'}, ${r['start_lon'] ?? '–'}'),
          _kv('Sichtbar', r['sichtbar'] == true ? 'ja' : 'nein'),
        ],
      ],
    ),
  );
  return showDialog<DuplicateAction>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Gibt es diesen Pfad schon?'),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                col('Neuer Entwurf', neu),
                const SizedBox(width: 16),
                col('Vorhanden: $altId', alt),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Zusammenführen heißt: Entwurf verwerfen und den vorhandenen Pfad öffnen. '
              'Felder daraus übernimmst du von Hand.',
              style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, DuplicateAction.verwerfen),
          child: const Text('Verwerfen'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(ctx, DuplicateAction.zusammenfuehren),
          child: const Text('Zusammenführen'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, DuplicateAction.istNeu),
          child: const Text('Ist neu'),
        ),
      ],
    ),
  );
}

Widget _kv(String k, dynamic v) => Padding(
  padding: const EdgeInsets.only(bottom: 4),
  child: Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: '$k: ',
          style: const TextStyle(color: AppColors.inkMuted),
        ),
        TextSpan(text: (v == null || '$v'.isEmpty) ? '–' : '$v'),
      ],
    ),
  ),
);

/// Station ergänzen: Titel, Text, Position per Tipp auf die Karte.
Future<DbRow?> stationDialog(
  BuildContext context, {
  required List<LatLng> route,
  required LatLng center,
  required int reihenfolge,
}) {
  return showDialog<DbRow>(
    context: context,
    builder: (_) => _StationDialog(
      route: route,
      center: center,
      reihenfolge: reihenfolge,
    ),
  );
}

class _StationDialog extends StatefulWidget {
  const _StationDialog({
    required this.route,
    required this.center,
    required this.reihenfolge,
  });

  final List<LatLng> route;
  final LatLng center;
  final int reihenfolge;

  @override
  State<_StationDialog> createState() => _StationDialogState();
}

class _StationDialogState extends State<_StationDialog> {
  final _titel = TextEditingController();
  final _text = TextEditingController();
  late LatLng _pos = widget.center;

  @override
  void dispose() {
    _titel.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Station ${widget.reihenfolge} hinzufügen'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titel,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Titel'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _text,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Kurztext'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Position: auf die Karte tippen.',
              style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _pos,
                    initialZoom: 15,
                    onTap: (_, p) => setState(() => _pos = p),
                  ),
                  children: [
                    MapConfig.buildOsmTileLayer(),
                    if (widget.route.length > 1)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: widget.route,
                            strokeWidth: 4,
                            color: AppColors.statusInfo,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _pos,
                          width: 32,
                          height: 32,
                          child: const Icon(
                            Icons.place,
                            color: AppColors.statusError,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _titel.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, {
                  'titel': _titel.text.trim(),
                  'kurztext': _text.text.trim(),
                  'lat': _pos.latitude,
                  'lon': _pos.longitude,
                  'reihenfolge': widget.reihenfolge,
                }),
          child: const Text('Hinzufügen'),
        ),
      ],
    );
  }
}
