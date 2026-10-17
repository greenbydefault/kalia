import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../domain/report_models.dart';
import 'draft_store.dart';

/// Native: pro Entwurf ein Ordner `reports/{draftId}/` im Dokumentenordner
/// der App.
///
/// - `draft.json`: Entwurf, Marker und Foto-Verweise (klein, wird komplett
///   geschrieben, atomar über temporäre Datei)
/// - `fixes.jsonl`: Track-Fixes, nur angehängt
/// - `photos/{id}.jpg`: komprimierte Fotos ohne EXIF
class FileReportDraftStore implements ReportDraftStore {
  FileReportDraftStore({this._root});

  Directory? _root;
  final _locks = <String, Future<void>>{};

  Future<Directory> _base() async {
    final r = _root;
    if (r != null) return r;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/reports');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return _root = dir;
  }

  Future<Directory> _dir(String id, {bool create = true}) async {
    final dir = Directory('${(await _base()).path}/$id');
    if (create && !dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// Serialisiert Schreibzugriffe je Entwurf.
  Future<T> _serial<T>(String id, Future<T> Function() job) {
    final prev = _locks[id] ?? Future<void>.value();
    final next = prev.then((_) => job());
    _locks[id] = next.then((_) {}, onError: (_) {});
    return next;
  }

  // draft.json = { draft: {...}, points: [...], photos: [...] }
  Future<Map<String, Object?>> _readDoc(String id) async {
    final f = File('${(await _dir(id, create: false)).path}/draft.json');
    if (!f.existsSync()) return {};
    try {
      return Map<String, Object?>.from(
        jsonDecode(await f.readAsString()) as Map,
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeDoc(String id, Map<String, Object?> doc) async {
    final dir = await _dir(id);
    final tmp = File('${dir.path}/draft.json.tmp');
    await tmp.writeAsString(jsonEncode(doc), flush: true);
    await tmp.rename('${dir.path}/draft.json');
  }

  Future<void> _mutate(
    String id,
    void Function(Map<String, Object?> doc) change,
  ) => _serial(id, () async {
    final doc = await _readDoc(id);
    change(doc);
    await _writeDoc(id, doc);
  });

  @override
  Future<List<ReportDraft>> listDrafts() async {
    final base = await _base();
    final out = <ReportDraft>[];
    for (final e in base.listSync()) {
      if (e is! Directory) continue;
      final id = e.path.split(Platform.pathSeparator).last;
      final d = await load(id);
      if (d != null) out.add(d);
    }
    return out;
  }

  @override
  Future<ReportDraft?> load(String id) async {
    final doc = await _readDoc(id);
    final d = doc['draft'];
    if (d is! Map) return null;
    try {
      return ReportDraft.fromJson(Map<String, Object?>.from(d));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveDraft(ReportDraft draft) =>
      _mutate(draft.id, (doc) => doc['draft'] = draft.toJson());

  List<T> _list<T>(
    Map<String, Object?> doc,
    String key,
    T Function(Map<String, Object?>) from,
  ) {
    final raw = doc[key];
    if (raw is! List) return <T>[];
    return [
      for (final e in raw)
        if (e is Map) from(Map<String, Object?>.from(e)),
    ];
  }

  @override
  Future<List<DraftPoint>> points(String draftId) async {
    final list = _list(await _readDoc(draftId), 'points', DraftPoint.fromJson)
      ..sort((a, b) => a.seq.compareTo(b.seq));
    return list;
  }

  @override
  Future<void> savePoint(DraftPoint point) => _mutate(point.draftId, (doc) {
    final list = _list(doc, 'points', DraftPoint.fromJson)
      ..removeWhere((p) => p.id == point.id)
      ..add(point);
    doc['points'] = [for (final p in list) p.toJson()];
  });

  @override
  Future<void> deletePoint(String draftId, String pointId) =>
      _mutate(draftId, (doc) {
        final list = _list(doc, 'points', DraftPoint.fromJson)
          ..removeWhere((p) => p.id == pointId);
        doc['points'] = [for (final p in list) p.toJson()];
      });

  @override
  Future<List<DraftPhoto>> photos(String draftId) async =>
      _list(await _readDoc(draftId), 'photos', DraftPhoto.fromJson);

  @override
  Future<void> savePhoto(DraftPhoto photo) => _mutate(photo.draftId, (doc) {
    final list = _list(doc, 'photos', DraftPhoto.fromJson)
      ..removeWhere((p) => p.id == photo.id)
      ..add(photo);
    doc['photos'] = [for (final p in list) p.toJson()];
  });

  @override
  Future<void> deletePhoto(String draftId, String photoId) async {
    String? path;
    await _mutate(draftId, (doc) {
      final list = _list(doc, 'photos', DraftPhoto.fromJson);
      for (final p in list) {
        if (p.id == photoId) path = p.localPath;
      }
      list.removeWhere((p) => p.id == photoId);
      doc['photos'] = [for (final p in list) p.toJson()];
    });
    final f = path == null ? null : File(path!);
    if (f != null && f.existsSync()) await f.delete();
  }

  @override
  Future<String> writePhotoBytes(
    String draftId,
    String photoId,
    Uint8List bytes,
  ) async {
    final dir = Directory('${(await _dir(draftId)).path}/photos');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final f = File('${dir.path}/$photoId.jpg');
    await f.writeAsBytes(bytes, flush: true);
    return f.path;
  }

  @override
  Future<Uint8List?> readPhotoBytes(String localPath) async {
    final f = File(localPath);
    if (!f.existsSync()) return null;
    return f.readAsBytes();
  }

  @override
  Future<void> appendFixes(String draftId, List<TrackFix> fixes) async {
    if (fixes.isEmpty) return;
    await _serial(draftId, () async {
      final f = File('${(await _dir(draftId)).path}/fixes.jsonl');
      final sb = StringBuffer();
      for (final x in fixes) {
        sb.writeln(jsonEncode(x.toJson()));
      }
      await f.writeAsString(sb.toString(), mode: FileMode.append, flush: true);
    });
  }

  @override
  Future<List<TrackFix>> fixes(String draftId) async {
    final f = File('${(await _dir(draftId, create: false)).path}/fixes.jsonl');
    if (!f.existsSync()) return [];
    final out = <TrackFix>[];
    for (final line in await f.readAsLines()) {
      if (line.trim().isEmpty) continue;
      try {
        out.add(
          TrackFix.fromJson(
            draftId,
            Map<String, Object?>.from(jsonDecode(line) as Map),
          ),
        );
      } catch (_) {
        // Abgebrochene letzte Zeile (App beendet): überspringen.
      }
    }
    return out;
  }

  @override
  Future<void> deleteDraft(String draftId) => _serial(draftId, () async {
    final dir = await _dir(draftId, create: false);
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  @override
  Future<void> clearHeavy(String draftId) => _serial(draftId, () async {
    final dir = await _dir(draftId, create: false);
    final fixes = File('${dir.path}/fixes.jsonl');
    if (fixes.existsSync()) await fixes.delete();
    final photos = Directory('${dir.path}/photos');
    if (photos.existsSync()) await photos.delete(recursive: true);
    final doc = await _readDoc(draftId);
    doc.remove('photos');
    if (doc.containsKey('draft')) await _writeDoc(draftId, doc);
  });
}
