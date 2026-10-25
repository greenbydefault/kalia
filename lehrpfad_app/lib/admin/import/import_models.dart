import 'dart:convert';

/// Schweregrad einer Prüfmeldung (Worker: `import_worker/rules.py`).
enum Severity {
  hart,
  uebersteuerbar,
  warnung;

  static Severity parse(String? v) => switch (v) {
    'hart' => hart,
    'uebersteuerbar' => uebersteuerbar,
    _ => warnung,
  };
}

/// Eine Meldung aus `import_jobs.report`.
class ReportEntry {
  const ReportEntry({
    required this.code,
    required this.severity,
    required this.feld,
    this.abschnitt,
    this.params = const {},
    this.wert,
    this.vorschlag,
    this.status = 'offen',
    this.overrideReason,
  });

  final String code;
  final Severity severity;
  final String feld;
  final int? abschnitt;
  final Map<String, dynamic> params;
  final dynamic wert;
  final dynamic vorschlag;
  final String status;
  final String? overrideReason;

  factory ReportEntry.fromJson(Map<String, dynamic> j) {
    final ov = j['override'];
    return ReportEntry(
      code: j['code'] as String? ?? '',
      severity: Severity.parse(j['severity'] as String?),
      feld: j['feld'] as String? ?? '',
      abschnitt: (j['abschnitt'] as num?)?.toInt(),
      params: Map<String, dynamic>.from((j['params'] as Map?) ?? const {}),
      wert: j['wert'],
      vorschlag: j['vorschlag'],
      status: j['status'] as String? ?? 'offen',
      overrideReason: ov is Map ? ov['reason'] as String? : null,
    );
  }

  bool get isOpen => status == 'offen';
  bool get isOverridden => (overrideReason ?? '').isNotEmpty;

  /// Zählt für „Anlegen“ (wie `import_open_blockers` in der DB).
  bool get blocks =>
      isOpen &&
      (severity == Severity.hart ||
          (severity == Severity.uebersteuerbar && !isOverridden));

  /// `stationen[3]` → `stationen`, `bilder[1]` → `bilder`, `abschnitt2` → `abschnitt`.
  String get baseFeld {
    final i = feld.indexOf('[');
    final b = i < 0 ? feld : feld.substring(0, i);
    return RegExp(r'^abschnitt\d+$').hasMatch(b) ? 'abschnitt' : b;
  }

  /// Schlüssel im Editor, an dem die Meldung angezeigt wird.
  String get anzeigeKey => switch (baseFeld) {
    'start_lat' || 'start_lon' => 'start_lat',
    'area' => 'route',
    final f => f,
  };

  /// Nummer aus `stationen[3]` / `bilder[2]`.
  int? get index {
    final m = RegExp(r'\[(\d+)\]').firstMatch(feld);
    return m == null ? null : int.tryParse(m.group(1)!);
  }
}

List<ReportEntry> parseReport(dynamic raw) {
  if (raw is String) raw = jsonDecode(raw);
  if (raw is! List) return const [];
  return [
    for (final e in raw)
      if (e is Map) ReportEntry.fromJson(Map<String, dynamic>.from(e)),
  ];
}

class Blockers {
  const Blockers(this.hart, this.uebersteuerbar);
  final int hart;
  final int uebersteuerbar;
  bool get any => hart + uebersteuerbar > 0;
  int get total => hart + uebersteuerbar;
}

Blockers blockersOf(List<ReportEntry> report) {
  var h = 0, u = 0;
  for (final e in report) {
    if (!e.blocks) continue;
    if (e.severity == Severity.hart) {
      h++;
    } else {
      u++;
    }
  }
  return Blockers(h, u);
}

int warningCount(List<ReportEntry> r) =>
    r.where((e) => e.isOpen && e.severity == Severity.warnung).length;

enum ImportStatus {
  wartet,
  laeuft,
  bereit,
  wartetAufKlaerung,
  vorschlag,
  angelegt,
  verworfen,
  fehlgeschlagen;

  static ImportStatus parse(String? v) => switch (v) {
    'laeuft' => laeuft,
    'bereit' => bereit,
    'wartet_auf_klaerung' => wartetAufKlaerung,
    'vorschlag' => vorschlag,
    'angelegt' => angelegt,
    'verworfen' => verworfen,
    'fehlgeschlagen' => fehlgeschlagen,
    _ => wartet,
  };

  String get label => switch (this) {
    wartet => 'Wartet',
    laeuft => 'Läuft',
    bereit => 'Bereit zur Prüfung',
    wartetAufKlaerung => 'Wartet auf Klärung',
    vorschlag => 'Änderungsvorschlag',
    angelegt => 'Angelegt',
    verworfen => 'Verworfen',
    fehlgeschlagen => 'Fehlgeschlagen',
  };
}

/// Tabs der Import-Übersicht.
enum ImportTab {
  imImport('Im Import'),
  klaerung('Wartet auf Klärung'),
  fehlgeschlagen('Fehlgeschlagen'),
  archiv('Erledigt');

  const ImportTab(this.label);
  final String label;

  bool accepts(ImportStatus s) => switch (this) {
    imImport =>
      s == ImportStatus.wartet ||
          s == ImportStatus.laeuft ||
          s == ImportStatus.bereit ||
          s == ImportStatus.vorschlag,
    klaerung => s == ImportStatus.wartetAufKlaerung,
    fehlgeschlagen => s == ImportStatus.fehlgeschlagen,
    archiv => s == ImportStatus.angelegt || s == ImportStatus.verworfen,
  };
}

class ImportJob {
  const ImportJob({
    required this.id,
    required this.fileName,
    required this.status,
    required this.modus,
    this.batchId,
    this.trailId,
    this.fileHash = '',
    this.attempts = 0,
    this.report = const [],
    this.proposal,
    this.parsed,
    this.error,
    this.errorDetail,
    this.kostenUsd = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? batchId;
  final String? trailId;
  final String fileName;
  final String fileHash;
  final ImportStatus status;
  final String modus;
  final int attempts;
  final List<ReportEntry> report;
  final Map<String, dynamic>? proposal;
  final Map<String, dynamic>? parsed;
  final String? error;
  final String? errorDetail;
  final double kostenUsd;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ImportJob.fromRow(Map<String, dynamic> r) => ImportJob(
    id: r['id'] as String,
    batchId: r['batch_id'] as String?,
    trailId: r['trail_id'] as String?,
    fileName: r['file_name'] as String? ?? '',
    fileHash: r['file_hash'] as String? ?? '',
    status: ImportStatus.parse(r['status'] as String?),
    modus: r['modus'] as String? ?? 'import',
    attempts: (r['attempts'] as num?)?.toInt() ?? 0,
    report: parseReport(r['report']),
    proposal: r['proposal'] is Map
        ? Map<String, dynamic>.from(r['proposal'] as Map)
        : null,
    parsed: r['parsed'] is Map
        ? Map<String, dynamic>.from(r['parsed'] as Map)
        : null,
    error: r['error'] as String?,
    errorDetail: r['error_detail'] as String?,
    kostenUsd: (r['kosten_usd'] as num?)?.toDouble() ?? 0,
    createdAt: DateTime.tryParse('${r['created_at']}'),
    updatedAt: DateTime.tryParse('${r['updated_at']}'),
  );

  /// Worker rechnet gerade (Import oder Neuprüfung nach einer Änderung).
  bool get pruefend =>
      status == ImportStatus.wartet || status == ImportStatus.laeuft;

  Blockers get blockers => blockersOf(report);

  bool get canPublish =>
      (status == ImportStatus.bereit ||
          status == ImportStatus.wartetAufKlaerung) &&
      trailId != null &&
      !blockers.any;

  /// Anzeigename: Slug aus dem Dossier, sonst Dateiname.
  String get title => trailId ?? fileName;
}

// ---------------------------------------------------------------------------
// Feldstatus im Editor
// ---------------------------------------------------------------------------

enum FieldTone {
  // Reihenfolge = Wichtigkeit (niedrigster Index gewinnt).
  error,
  warn,
  info,
  locked,
  ok,
  none;

  /// Wichtigster Ton gewinnt: rot vor gelb vor blau vor grün.
  static FieldTone worst(FieldTone a, FieldTone b) =>
      a.index <= b.index ? a : b;
}

class FieldState {
  const FieldState({
    required this.tone,
    this.entries = const [],
    this.locked = false,
    this.fromKi = false,
    this.autoFixed = false,
  });

  final FieldTone tone;
  final List<ReportEntry> entries;
  final bool locked;
  final bool fromKi;
  final bool autoFixed;

  static const none = FieldState(tone: FieldTone.none);
}

/// Feldstatus aller Felder aus Report, Sperren und `field_meta`.
class FieldStates {
  FieldStates({
    required this.report,
    required this.locked,
    required this.fieldMeta,
    required this.row,
  });

  final List<ReportEntry> report;
  final Set<String> locked;
  final Map<String, dynamic> fieldMeta;
  final Map<String, dynamic> row;

  List<ReportEntry> entriesFor(String key) => [
    for (final e in report)
      if (e.anzeigeKey == key) e,
  ];

  static bool _filled(dynamic v) =>
      v != null && !(v is String && v.trim().isEmpty) && !(v is List && v.isEmpty);

  FieldState of(String key) {
    final entries = entriesFor(key);
    final open = entries.where((e) => e.isOpen).toList();
    var tone = FieldTone.none;
    for (final e in open) {
      final t = switch (e.severity) {
        Severity.hart => FieldTone.error,
        Severity.uebersteuerbar =>
          e.isOverridden ? FieldTone.info : FieldTone.error,
        Severity.warnung => e.code == 'FORM' ? FieldTone.info : FieldTone.warn,
      };
      tone = FieldTone.worst(tone, t);
    }
    final meta = fieldMeta[key];
    final fromKi = meta is Map && meta['quelle'] == 'ki';
    final autoFixed =
        entries.any((e) => e.code == 'FORM' || e.vorschlag != null) &&
        open.every((e) => e.severity == Severity.warnung);
    if (tone == FieldTone.none && fromKi) tone = FieldTone.info;
    final isLocked = locked.contains(key);
    if (tone == FieldTone.none && _filled(row[key])) tone = FieldTone.ok;
    if (tone == FieldTone.ok && isLocked) tone = FieldTone.locked;
    return FieldState(
      tone: tone,
      entries: open,
      locked: isLocked,
      fromKi: fromKi,
      autoFixed: autoFixed,
    );
  }
}

/// Meldungstexte aus `import_worker/messages.json` (gleiche Datei wie der Worker).
class ImportMessages {
  ImportMessages(Map<String, dynamic> json)
    : _codes = Map<String, dynamic>.from(json['codes'] as Map),
      _felder = Map<String, String>.from(json['felder'] as Map),
      hilfe = Map<String, String>.from(json['hilfe'] as Map);

  factory ImportMessages.parse(String source) =>
      ImportMessages(jsonDecode(source) as Map<String, dynamic>);

  final Map<String, dynamic> _codes;
  final Map<String, String> _felder;
  final Map<String, String> hilfe;

  bool has(String code) => _codes.containsKey(code);

  String feldLabel(String feld) {
    final m = RegExp(r'^(\w+)\[(\w+)\]$').firstMatch(feld);
    if (m != null) {
      final basis = m.group(1)!, nr = m.group(2)!;
      if (basis == 'stationen') return 'Station $nr';
      if (basis == 'bilder') return 'Bild $nr';
      return '${_felder[basis] ?? basis} $nr';
    }
    final a = RegExp(r'^abschnitt(\d+)$').firstMatch(feld);
    if (a != null) return 'Abschnitt ${a.group(1)}';
    return _felder[feld] ?? feld;
  }

  String _bereich(Map<String, dynamic> p) {
    final mn = (p['min'] as num?)?.toInt() ?? 0;
    final mx = (p['max'] as num?)?.toInt() ?? 0;
    if (mn > 0 && mx > 0) return '$mn bis $mx';
    if (mx > 0) return 'bis $mx';
    return 'mindestens $mn';
  }

  /// `{titel, was, warum, wie}` mit eingesetzten Parametern (wie `messages.render` im Worker).
  ({String titel, String was, String warum, String wie}) render(
    ReportEntry e,
  ) {
    final m = _codes[e.code] as Map?;
    if (m == null) {
      return (titel: e.code, was: e.code, warum: '', wie: '');
    }
    final p = Map<String, dynamic>.from(e.params);
    p.putIfAbsent('wert', () => e.wert);
    p['feld'] = feldLabel(e.feld);
    final was = p['was'];
    if (was is String && _felder.containsKey(was)) p['was'] = _felder[was];
    p.putIfAbsent('einheit', () => 'Zeichen');
    p['bereich'] = _bereich(p);
    String fill(String t) => t.replaceAllMapped(RegExp(r'\{(\w+)\}'), (mm) {
      final v = p[mm.group(1)];
      return v == null ? '' : '$v';
    });
    return (
      titel: fill(m['titel'] as String),
      was: fill(m['was'] as String),
      warum: fill(m['warum'] as String),
      wie: fill(m['wie'] as String),
    );
  }
}
