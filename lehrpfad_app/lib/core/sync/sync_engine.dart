import 'dart:async';

import 'sync_mutation.dart';
import 'sync_queue.dart';

/// Führt eine Mutation remote aus. Wirft bei Fehlern (z. B. offline).
typedef SyncExecutor = Future<void> Function(SyncMutation mutation);

/// Holt Remote-Stand und merged ihn in den lokalen Store (und umgekehrt).
typedef SyncMergeHandler = Future<void> Function();

/// Zentrale Stelle für Remote-Sync. Repositories registrieren ihre
/// Executors und Merge-Handler; die Engine garantiert:
///
/// - `enqueue` führt sofort aus; bei Fehler landet die Mutation in der
///   persistenten [SyncQueue] statt still zu verschwinden.
/// - `flush` liefert die Queue FIFO aus (Single-Flight).
/// - `mergeAllOnLogin` orchestriert den Login-Merge aller Entities.
///
/// Voraussetzung an alle Executors: Idempotenz (upsert/delete mit
/// klaren Keys), weil Mutationen nach Neustart erneut laufen können.
class SyncEngine {
  SyncEngine({SyncQueue? queue}) : _queue = queue ?? SyncQueue();

  final SyncQueue _queue;
  final _executors = <String, SyncExecutor>{};
  final _mergeHandlers = <String, SyncMergeHandler>{};
  bool _flushing = false;

  /// Anzahl ausstehender Mutationen (Diagnose/Tests).
  Future<int> get pendingCount async => (await _queue.readAll()).length;

  void registerExecutor(String entity, SyncExecutor executor) {
    _executors[entity] = executor;
  }

  void registerMergeHandler(String entity, SyncMergeHandler handler) {
    _mergeHandlers[entity] = handler;
  }

  /// Führt die Mutation sofort remote aus. Bei Fehler wird sie in die
  /// Queue gelegt und beim nächsten [flush] erneut versucht.
  /// Ohne registrierten Executor (Seed-Modus) ist der Aufruf ein No-Op.
  Future<void> enqueue(SyncMutation mutation) async {
    final executor = _executors[mutation.entity];
    if (executor == null) return;
    try {
      await executor(mutation);
      // Erfolg = Netz da: ältere ausstehende Mutationen nachliefern.
      unawaited(flush());
    } catch (_) {
      await _queue.enqueue(mutation);
    }
  }

  /// Arbeitet die Queue in Reihenfolge ab. Bricht beim ersten Fehler
  /// ab (offline), damit die Reihenfolge erhalten bleibt. Single-Flight:
  /// parallele Aufrufe kehren sofort zurück.
  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      while (true) {
        final next = await _queue.peek();
        if (next == null) return;
        final executor = _executors[next.entity];
        if (executor == null) {
          // Executor (noch) nicht registriert: Eintrag nicht verlieren,
          // aber Endlosschleife vermeiden.
          return;
        }
        try {
          await executor(next);
          await _queue.remove(next.id);
        } catch (_) {
          return;
        }
      }
    } catch (_) {
      // Queue-/Persistenzfehler: flush ist best-effort und wird
      // unawaited aufgerufen — darf nie werfen.
    } finally {
      _flushing = false;
    }
  }

  /// Führt alle registrierten Merge-Handler aus und liefert danach
  /// die Queue aus. Fehler einzelner Handler blockieren die anderen
  /// nicht; der Merge heilt sich beim nächsten Login erneut.
  Future<void> mergeAllOnLogin() async {
    for (final handler in _mergeHandlers.values) {
      try {
        await handler();
      } catch (_) {}
    }
    await flush();
  }
}
