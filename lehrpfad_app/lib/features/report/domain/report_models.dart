import 'report_enums.dart';

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

T? _enumOrNull<T extends Enum>(List<T> values, Object? name) {
  if (name == null) return null;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}

/// Lokaler Entwurf (Spec 2.1) plus Cache-Felder für „Meine Meldungen“.
class ReportDraft {
  const ReportDraft({
    required this.id,
    required this.kind,
    required this.mode,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.targetTrailId,
    this.targetTrailName,
    this.intent,
    this.title,
    this.area,
    this.isLoop,
    this.stroller = 'unknown',
    this.note,
    this.trimStartM = 0,
    this.trimEndM = 0,
    this.serverId,
    this.failureCode,
    this.dupDismissed = false,
    this.justFinished = false,
    this.lowAccuracyStart = false,
    this.attempts = 0,
    this.openedAt,
    this.serverStatus,
    this.decisionReason,
    this.decisionNote,
    this.serverQuestion,
    this.decidedAt,
    this.lastSeenStatus,
    this.photosMissing = 0,
    this.photosExpected = 0,
    this.serverCheckedAt,
  });

  /// UUID v4, zugleich `client_submission_id`.
  final String id;
  final ReportKind kind;
  final RecordingMode mode;
  final DraftStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Bei `revision` und `quick`.
  final String? targetTrailId;
  final String? targetTrailName;

  /// Nur bei `quick`.
  final QuickIntent? intent;

  /// Pflicht bei `newTrail`.
  final String? title;
  final String? area;
  final bool? isLoop;

  /// yes | no | unknown
  final String stroller;
  final String? note;
  final double trimStartM;
  final double trimEndM;

  /// Nach dem Einreichen.
  final String? serverId;

  /// Fehlercode bei `failed`: limit_open, limit_daily, invalid_payload,
  /// too_large oder network.
  final String? failureCode;

  /// „Nein, anderer Pfad“ in R4 für diesen Entwurf.
  final bool dupDismissed;

  /// Direkt nach „Beenden und prüfen“: „Weiter aufnehmen“ ist noch möglich.
  final bool justFinished;
  final bool lowAccuracyStart;

  /// Messversuche der Schnellmeldung (Trotzdem senden nach 3).
  final int attempts;

  /// Zuletzt geöffnet (für „Entwurf vom …“ nach 30 Tagen).
  final DateTime? openedAt;

  // Cache des Server-Stands für R7.
  final SubmissionStatus? serverStatus;
  final DecisionReason? decisionReason;
  final String? decisionNote;
  final String? serverQuestion;
  final DateTime? decidedAt;

  /// Zuletzt gesehener Status (Punkt für Statuswechsel).
  final String? lastSeenStatus;
  final int photosMissing;
  final int photosExpected;
  final DateTime? serverCheckedAt;

  bool get isQuick => kind == ReportKind.quick;
  bool get isSubmitted => serverId != null;

  /// Gehört in die Gruppe „Entwürfe“ in R7.
  bool get isLocalDraft =>
      status == DraftStatus.recording ||
      status == DraftStatus.paused ||
      status == DraftStatus.review ||
      status == DraftStatus.awaitingAccount;

  ReportDraft copyWith({
    ReportKind? kind,
    RecordingMode? mode,
    DraftStatus? status,
    DateTime? updatedAt,
    String? targetTrailId,
    String? targetTrailName,
    QuickIntent? intent,
    String? title,
    String? area,
    bool? isLoop,
    String? stroller,
    String? note,
    double? trimStartM,
    double? trimEndM,
    String? serverId,
    String? failureCode,
    bool clearFailure = false,
    bool? dupDismissed,
    bool? justFinished,
    bool? lowAccuracyStart,
    int? attempts,
    DateTime? openedAt,
    SubmissionStatus? serverStatus,
    DecisionReason? decisionReason,
    String? decisionNote,
    String? serverQuestion,
    DateTime? decidedAt,
    String? lastSeenStatus,
    int? photosMissing,
    int? photosExpected,
    DateTime? serverCheckedAt,
  }) {
    return ReportDraft(
      id: id,
      kind: kind ?? this.kind,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      targetTrailId: targetTrailId ?? this.targetTrailId,
      targetTrailName: targetTrailName ?? this.targetTrailName,
      intent: intent ?? this.intent,
      title: title ?? this.title,
      area: area ?? this.area,
      isLoop: isLoop ?? this.isLoop,
      stroller: stroller ?? this.stroller,
      note: note ?? this.note,
      trimStartM: trimStartM ?? this.trimStartM,
      trimEndM: trimEndM ?? this.trimEndM,
      serverId: serverId ?? this.serverId,
      failureCode: clearFailure ? null : (failureCode ?? this.failureCode),
      dupDismissed: dupDismissed ?? this.dupDismissed,
      justFinished: justFinished ?? this.justFinished,
      lowAccuracyStart: lowAccuracyStart ?? this.lowAccuracyStart,
      attempts: attempts ?? this.attempts,
      openedAt: openedAt ?? this.openedAt,
      serverStatus: serverStatus ?? this.serverStatus,
      decisionReason: decisionReason ?? this.decisionReason,
      decisionNote: decisionNote ?? this.decisionNote,
      serverQuestion: serverQuestion ?? this.serverQuestion,
      decidedAt: decidedAt ?? this.decidedAt,
      lastSeenStatus: lastSeenStatus ?? this.lastSeenStatus,
      photosMissing: photosMissing ?? this.photosMissing,
      photosExpected: photosExpected ?? this.photosExpected,
      serverCheckedAt: serverCheckedAt ?? this.serverCheckedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'mode': mode.name,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'targetTrailId': targetTrailId,
    'targetTrailName': targetTrailName,
    'intent': intent?.name,
    'title': title,
    'area': area,
    'isLoop': isLoop,
    'stroller': stroller,
    'note': note,
    'trimStartM': trimStartM,
    'trimEndM': trimEndM,
    'serverId': serverId,
    'failureCode': failureCode,
    'dupDismissed': dupDismissed,
    'justFinished': justFinished,
    'lowAccuracyStart': lowAccuracyStart,
    'attempts': attempts,
    'openedAt': openedAt?.toIso8601String(),
    'serverStatus': serverStatus?.name,
    'decisionReason': decisionReason?.name,
    'decisionNote': decisionNote,
    'serverQuestion': serverQuestion,
    'decidedAt': decidedAt?.toIso8601String(),
    'lastSeenStatus': lastSeenStatus,
    'photosMissing': photosMissing,
    'photosExpected': photosExpected,
    'serverCheckedAt': serverCheckedAt?.toIso8601String(),
  };

  static DateTime? _dt(Object? v) => v is String ? DateTime.tryParse(v) : null;

  factory ReportDraft.fromJson(Map<String, Object?> j) {
    return ReportDraft(
      id: j['id']! as String,
      kind: _enum(ReportKind.values, j['kind'], ReportKind.newTrail),
      mode: _enum(
        RecordingMode.values,
        j['mode'],
        RecordingMode.trackAndPoints,
      ),
      status: _enum(DraftStatus.values, j['status'], DraftStatus.review),
      createdAt: _dt(j['createdAt']) ?? DateTime.now(),
      updatedAt: _dt(j['updatedAt']) ?? DateTime.now(),
      targetTrailId: j['targetTrailId'] as String?,
      targetTrailName: j['targetTrailName'] as String?,
      intent: _enumOrNull(QuickIntent.values, j['intent']),
      title: j['title'] as String?,
      area: j['area'] as String?,
      isLoop: j['isLoop'] as bool?,
      stroller: (j['stroller'] as String?) ?? 'unknown',
      note: j['note'] as String?,
      trimStartM: (j['trimStartM'] as num?)?.toDouble() ?? 0,
      trimEndM: (j['trimEndM'] as num?)?.toDouble() ?? 0,
      serverId: j['serverId'] as String?,
      failureCode: j['failureCode'] as String?,
      dupDismissed: (j['dupDismissed'] as bool?) ?? false,
      justFinished: (j['justFinished'] as bool?) ?? false,
      lowAccuracyStart: (j['lowAccuracyStart'] as bool?) ?? false,
      attempts: (j['attempts'] as num?)?.toInt() ?? 0,
      openedAt: _dt(j['openedAt']),
      serverStatus: _enumOrNull(SubmissionStatus.values, j['serverStatus']),
      decisionReason: _enumOrNull(DecisionReason.values, j['decisionReason']),
      decisionNote: j['decisionNote'] as String?,
      serverQuestion: j['serverQuestion'] as String?,
      decidedAt: _dt(j['decidedAt']),
      lastSeenStatus: j['lastSeenStatus'] as String?,
      photosMissing: (j['photosMissing'] as num?)?.toInt() ?? 0,
      photosExpected: (j['photosExpected'] as num?)?.toInt() ?? 0,
      serverCheckedAt: _dt(j['serverCheckedAt']),
    );
  }
}

/// Ein vom Nutzer gesetzter Punkt (Spec 2.1).
class DraftPoint {
  const DraftPoint({
    required this.id,
    required this.draftId,
    required this.type,
    required this.seq,
    required this.lat,
    required this.lng,
    required this.accuracyM,
    required this.fixCount,
    required this.lowAccuracy,
    required this.recordedOn,
    this.number,
    this.title,
    this.hintKind,
    this.targetPointId,
    this.note,
    this.oldLat,
    this.oldLng,
    this.numberManual = false,
  });

  final String id;
  final String draftId;
  final PointType type;

  /// Nummer wurde vom Nutzer gesetzt und rückt nicht automatisch nach.
  final bool numberManual;

  /// Reihenfolge der Erfassung.
  final int seq;

  /// Stationsnummer, vom Nutzer änderbar.
  final int? number;
  final String? title;
  final HintKind? hintKind;
  final double lat;
  final double lng;
  final double accuracyM;
  final int fixCount;
  final bool lowAccuracy;

  /// Bei `movePoint`: der bestehende Punkt (`station:<id>` usw.).
  final String? targetPointId;
  final String? note;

  /// Nur das Datum wird hochgeladen.
  final DateTime recordedOn;

  /// Bei `movePoint`: gespeicherte Position (für Anzeige, nicht hochgeladen).
  final double? oldLat;
  final double? oldLng;

  DraftPoint copyWith({
    PointType? type,
    int? number,
    bool clearNumber = false,
    String? title,
    HintKind? hintKind,
    double? lat,
    double? lng,
    double? accuracyM,
    int? fixCount,
    bool? lowAccuracy,
    String? note,
    int? seq,
    bool? numberManual,
  }) {
    return DraftPoint(
      numberManual: numberManual ?? this.numberManual,
      id: id,
      draftId: draftId,
      type: type ?? this.type,
      seq: seq ?? this.seq,
      number: clearNumber ? null : (number ?? this.number),
      title: title ?? this.title,
      hintKind: hintKind ?? this.hintKind,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      accuracyM: accuracyM ?? this.accuracyM,
      fixCount: fixCount ?? this.fixCount,
      lowAccuracy: lowAccuracy ?? this.lowAccuracy,
      targetPointId: targetPointId,
      note: note ?? this.note,
      recordedOn: recordedOn,
      oldLat: oldLat,
      oldLng: oldLng,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'draftId': draftId,
    'type': type.name,
    'seq': seq,
    'number': number,
    'title': title,
    'hintKind': hintKind?.name,
    'lat': lat,
    'lng': lng,
    'accuracyM': accuracyM,
    'fixCount': fixCount,
    'lowAccuracy': lowAccuracy,
    'targetPointId': targetPointId,
    'note': note,
    'recordedOn': recordedOn.toIso8601String(),
    'oldLat': oldLat,
    'oldLng': oldLng,
    'numberManual': numberManual,
  };

  factory DraftPoint.fromJson(Map<String, Object?> j) => DraftPoint(
    id: j['id']! as String,
    draftId: j['draftId']! as String,
    type: _enum(PointType.values, j['type'], PointType.station),
    seq: (j['seq'] as num?)?.toInt() ?? 0,
    number: (j['number'] as num?)?.toInt(),
    title: j['title'] as String?,
    hintKind: _enumOrNull(HintKind.values, j['hintKind']),
    lat: (j['lat']! as num).toDouble(),
    lng: (j['lng']! as num).toDouble(),
    accuracyM: (j['accuracyM'] as num?)?.toDouble() ?? 0,
    fixCount: (j['fixCount'] as num?)?.toInt() ?? 1,
    lowAccuracy: (j['lowAccuracy'] as bool?) ?? false,
    targetPointId: j['targetPointId'] as String?,
    note: j['note'] as String?,
    recordedOn:
        DateTime.tryParse((j['recordedOn'] as String?) ?? '') ?? DateTime.now(),
    oldLat: (j['oldLat'] as num?)?.toDouble(),
    oldLng: (j['oldLng'] as num?)?.toDouble(),
    numberManual: (j['numberManual'] as bool?) ?? false,
  );
}

/// Fix des Tracks. Der Zeitstempel bleibt lokal.
class TrackFix {
  const TrackFix({
    required this.draftId,
    required this.seq,
    required this.segment,
    required this.lat,
    required this.lng,
    required this.accuracyM,
    required this.t,
  });

  final String draftId;
  final int seq;

  /// Neues Segment nach jeder Pause.
  final int segment;
  final double lat;
  final double lng;
  final double accuracyM;
  final DateTime t;

  Map<String, Object?> toJson() => {
    's': seq,
    'g': segment,
    'a': lat,
    'o': lng,
    'c': accuracyM,
    't': t.millisecondsSinceEpoch,
  };

  factory TrackFix.fromJson(String draftId, Map<String, Object?> j) => TrackFix(
    draftId: draftId,
    seq: (j['s']! as num).toInt(),
    segment: (j['g']! as num).toInt(),
    lat: (j['a']! as num).toDouble(),
    lng: (j['o']! as num).toDouble(),
    accuracyM: (j['c']! as num).toDouble(),
    t: DateTime.fromMillisecondsSinceEpoch((j['t']! as num).toInt()),
  );
}

class DraftPhoto {
  const DraftPhoto({
    required this.id,
    required this.draftId,
    required this.localPath,
    this.pointId,
    this.uploaded = false,
    this.storagePath,
    this.width,
    this.height,
  });

  final String id;
  final String draftId;

  /// `null` = gehört zum ganzen Beitrag.
  final String? pointId;

  /// Komprimiert, ohne EXIF.
  final String localPath;
  final bool uploaded;
  final String? storagePath;
  final int? width;
  final int? height;

  DraftPhoto copyWith({bool? uploaded, String? storagePath}) => DraftPhoto(
    id: id,
    draftId: draftId,
    localPath: localPath,
    pointId: pointId,
    uploaded: uploaded ?? this.uploaded,
    storagePath: storagePath ?? this.storagePath,
    width: width,
    height: height,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'draftId': draftId,
    'pointId': pointId,
    'localPath': localPath,
    'uploaded': uploaded,
    'storagePath': storagePath,
    'width': width,
    'height': height,
  };

  factory DraftPhoto.fromJson(Map<String, Object?> j) => DraftPhoto(
    id: j['id']! as String,
    draftId: j['draftId']! as String,
    pointId: j['pointId'] as String?,
    localPath: (j['localPath'] as String?) ?? '',
    uploaded: (j['uploaded'] as bool?) ?? false,
    storagePath: j['storagePath'] as String?,
    width: (j['width'] as num?)?.toInt(),
    height: (j['height'] as num?)?.toInt(),
  );
}
