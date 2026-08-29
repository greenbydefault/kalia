import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/core/sync/sync_engine.dart';
import 'package:lehrpfad_app/core/sync/sync_mutation.dart';
import 'package:lehrpfad_app/core/sync/sync_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

SyncMutation mut(
  String entity,
  String key, {
  SyncOp op = SyncOp.upsert,
  Map<String, dynamic> payload = const {},
}) => SyncMutation.create(entity: entity, key: key, op: op, payload: payload);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SyncQueue', () {
    test('enqueue/peek/remove halten FIFO', () async {
      final q = SyncQueue();
      await q.enqueue(mut('a', '1'));
      await q.enqueue(mut('a', '2'));
      expect((await q.peek())?.key, '1');
      final all = await q.readAll();
      await q.remove(all.first.id);
      expect((await q.peek())?.key, '2');
    });

    test('coalescing: gleiche (entity, key) ersetzt, Position wandert ans Ende', () async {
      final q = SyncQueue();
      await q.enqueue(mut('walk', 'w1', payload: {'progress': 0.1}));
      await q.enqueue(mut('walk', 'w2'));
      await q.enqueue(mut('walk', 'w1', payload: {'progress': 0.9}));
      final all = await q.readAll();
      expect(all.length, 2);
      expect(all[0].key, 'w2');
      expect(all[1].key, 'w1');
      expect(all[1].payload['progress'], 0.9);
    });

    test('cap verwirft älteste Einträge', () async {
      final q = SyncQueue();
      for (var i = 0; i < SyncQueue.maxEntries + 10; i++) {
        await q.enqueue(mut('e', 'k$i'));
      }
      final all = await q.readAll();
      expect(all.length, SyncQueue.maxEntries);
      expect(all.first.key, 'k10');
    });

    test('überlebt "Neustart" (neue Instanz, gleiche Prefs)', () async {
      final q1 = SyncQueue();
      await q1.enqueue(mut('sighting', 'biber'));
      final q2 = SyncQueue();
      expect((await q2.readAll()).single.key, 'biber');
    });
  });

  group('SyncEngine', () {
    test('enqueue ohne Executor ist No-Op (Seed-Modus)', () async {
      final engine = SyncEngine();
      await engine.enqueue(mut('x', '1'));
      expect(await engine.pendingCount, 0);
    });

    test('enqueue bei Erfolg landet nicht in Queue', () async {
      final engine = SyncEngine();
      final ran = <String>[];
      engine.registerExecutor('e', (m) async => ran.add(m.key));
      await engine.enqueue(mut('e', '1'));
      expect(ran, ['1']);
      expect(await engine.pendingCount, 0);
    });

    test('enqueue bei Fehler queued; flush liefert später aus', () async {
      final engine = SyncEngine();
      var fail = true;
      final ran = <String>[];
      engine.registerExecutor('e', (m) async {
        if (fail) throw StateError('offline');
        ran.add(m.key);
      });
      await engine.enqueue(mut('e', '1'));
      expect(await engine.pendingCount, 1);
      expect(ran, isEmpty);

      fail = false;
      await engine.flush();
      expect(ran, ['1']);
      expect(await engine.pendingCount, 0);
    });

    test('flush hält FIFO und bricht bei Fehler ab', () async {
      final engine = SyncEngine();
      final ran = <String>[];
      var offline = true;
      engine.registerExecutor('e', (m) async {
        if (offline) throw StateError('offline');
        if (m.key == '2') throw StateError('boom');
        ran.add(m.key);
      });
      // Alle drei landen in der Queue (offline).
      await engine.enqueue(mut('e', '1'));
      await engine.enqueue(mut('e', '2'));
      await engine.enqueue(mut('e', '3'));
      expect(await engine.pendingCount, 3);

      offline = false;
      await engine.flush();
      expect(ran, ['1']); // '2' wirft → Abbruch, '3' bleibt hinter '2'
      expect(await engine.pendingCount, 2);
    });

    test('flush ist single-flight', () async {
      final engine = SyncEngine();
      var running = 0;
      var maxConcurrent = 0;
      engine.registerExecutor('e', (m) async {
        running++;
        maxConcurrent = running > maxConcurrent ? running : maxConcurrent;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        running--;
      });
      await engine.enqueue(mut('e', '1'));
      // Executor wirft nicht, also ist die Queue leer; wir testen
      // single-flight über parallele flush-Aufrufe mit gefüllter Queue:
      final q = SyncQueue();
      await q.enqueue(mut('e', 'a'));
      await q.enqueue(mut('e', 'b'));
      final engine2 = SyncEngine(queue: q);
      engine2.registerExecutor('e', (m) async {
        running++;
        maxConcurrent = running > maxConcurrent ? running : maxConcurrent;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        running--;
      });
      await Future.wait([engine2.flush(), engine2.flush(), engine2.flush()]);
      expect(maxConcurrent, 1);
      expect(await q.readAll(), isEmpty);
    });

    test('erfolgreicher enqueue liefert alte Queue-Einträge nach', () async {
      final q = SyncQueue();
      await q.enqueue(mut('e', 'alt'));
      final engine = SyncEngine(queue: q);
      final ran = <String>[];
      engine.registerExecutor('e', (m) async => ran.add(m.key));
      await engine.enqueue(mut('e', 'neu'));
      // 'neu' lief sofort, flush dahinter räumt 'alt' auf.
      await Future<void>.delayed(Duration.zero);
      expect(ran, containsAll(['neu', 'alt']));
      expect(await engine.pendingCount, 0);
    });

    test('mergeAllOnLogin ruft alle Handler, Fehler blockieren nicht', () async {
      final engine = SyncEngine();
      final calls = <String>[];
      engine.registerMergeHandler('a', () async {
        calls.add('a');
        throw StateError('offline');
      });
      engine.registerMergeHandler('b', () async => calls.add('b'));
      await engine.mergeAllOnLogin();
      expect(calls, ['a', 'b']);
    });

    test('coalescing über Engine: 20 Walk-Updates → 1 Queue-Eintrag', () async {
      final engine = SyncEngine();
      engine.registerExecutor('walk', (m) async => throw StateError('off'));
      for (var i = 0; i < 20; i++) {
        await engine.enqueue(
          mut('walk', 'w1', payload: {'progress': i / 20}),
        );
      }
      expect(await engine.pendingCount, 1);
      final all = await SyncQueue().readAll();
      expect(all.single.payload['progress'], 0.95);
    });
  });
}
