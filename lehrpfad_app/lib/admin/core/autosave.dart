import 'dart:async';

import 'package:flutter/foundation.dart';

import 'field_spec.dart';

enum SaveState { idle, dirty, saving, saved, error }

/// Sammelt Autosave-Zustände aller Controller einer Editor-Seite für die
/// Anzeige „Gespeichert“ im Kopf.
class AutosaveHub extends ChangeNotifier {
  final _states = <Object, SaveState>{};
  String? lastError;

  void report(Object owner, SaveState state, [String? error]) {
    if (state == SaveState.idle) {
      _states.remove(owner);
    } else {
      _states[owner] = state;
    }
    if (error != null) lastError = error;
    notifyListeners();
  }

  void forget(Object owner) {
    if (_states.remove(owner) != null) notifyListeners();
  }

  SaveState get state {
    final values = _states.values;
    if (values.contains(SaveState.error)) return SaveState.error;
    if (values.contains(SaveState.saving)) return SaveState.saving;
    if (values.contains(SaveState.dirty)) return SaveState.dirty;
    if (values.contains(SaveState.saved)) return SaveState.saved;
    return SaveState.idle;
  }
}

/// Debounced Speichern einer Zeile. Felder melden Änderungen über [set],
/// nach [delay] Ruhe geht ein einziger Patch an [save].
class AutosaveController {
  AutosaveController({
    required this.row,
    required this.save,
    this.hub,
    this.delay = const Duration(milliseconds: 700),
  });

  /// Aktueller Stand der Zeile (lokal fortgeschrieben).
  final DbRow row;
  final Future<void> Function(Map<String, dynamic> patch) save;
  final AutosaveHub? hub;
  final Duration delay;

  final _patch = <String, dynamic>{};
  Timer? _timer;
  bool _disposed = false;
  Future<void>? _inFlight;

  void set(FieldSpec field, dynamic value) {
    final j = field.json;
    if (j == null) {
      row[field.key] = value;
      _patch[field.key] = value;
    } else {
      final current = row[j];
      final copy = current is Map
          ? Map<String, dynamic>.from(current)
          : <String, dynamic>{};
      if (value == null || (value is List && value.isEmpty) || value == '') {
        copy.remove(field.key);
      } else {
        copy[field.key] = value;
      }
      row[j] = copy;
      _patch[j] = copy;
    }
    hub?.report(this, SaveState.dirty);
    _timer?.cancel();
    _timer = Timer(delay, flush);
  }

  /// Sofort speichern (Navigation, Dispose).
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    final pending = _inFlight;
    if (pending != null) await pending;
    if (_patch.isEmpty) return;
    final patch = Map<String, dynamic>.from(_patch);
    _patch.clear();
    hub?.report(this, SaveState.saving);
    final run = () async {
      try {
        await save(patch);
        if (!_disposed) hub?.report(this, SaveState.saved);
      } catch (e) {
        // Patch zurücklegen, damit der nächste Versuch ihn mitschickt.
        for (final e2 in patch.entries) {
          _patch.putIfAbsent(e2.key, () => e2.value);
        }
        if (!_disposed) hub?.report(this, SaveState.error, e.toString());
      }
    }();
    _inFlight = run;
    await run;
    if (identical(_inFlight, run)) _inFlight = null;
  }

  bool get hasPending => _patch.isNotEmpty;

  /// Letzter Flush beim Verlassen; Fehler bleiben im Hub sichtbar.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    if (_patch.isNotEmpty) {
      final patch = Map<String, dynamic>.from(_patch);
      _patch.clear();
      unawaited(save(patch).catchError((_) {}));
    }
    hub?.forget(this);
  }
}
