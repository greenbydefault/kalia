import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'catalog_cache.dart';

/// Remote → Cache write; bei Fehler Cache-Decode, sonst Seed.
Future<T> loadCatalog<T>({
  required CatalogCache cache,
  required String key,
  required Future<T> Function() remote,
  required Future<T> Function(String raw) decode,
  required String Function(T value) encode,
  required Future<T> Function() seed,
  bool skipWrite = false,
}) async {
  final sw = Stopwatch()..start();
  try {
    final value = await remote();
    final fetchMs = sw.elapsedMilliseconds;
    if (!skipWrite) {
      // Idle, nicht Microtask: encode würde sonst den ersten Frame blockieren.
      unawaited(
        SchedulerBinding.instance.scheduleTask(
          () => _writeCache(cache, key, encode, value),
          Priority.idle,
        ),
      );
    }
    debugPrint('loadCatalog $key fetch $fetchMs ms');
    return value;
  } catch (_) {
    try {
      final raw = await cache.read(key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = await decode(raw);
        debugPrint('loadCatalog $key cache ${sw.elapsedMilliseconds} ms');
        return decoded;
      }
    } catch (_) {
      // Korrupter Cache → Seed
    }
    debugPrint('loadCatalog $key seed ${sw.elapsedMilliseconds} ms');
    return seed();
  }
}

/// Encode und Schreiben nach dem Rückgabewert, damit die Liste nicht
/// auf die Serialisierung des ganzen Katalogs wartet.
Future<void> _writeCache<T>(
  CatalogCache cache,
  String key,
  String Function(T value) encode,
  T value,
) async {
  try {
    await cache.write(key, encode(value));
  } catch (e) {
    debugPrint('loadCatalog $key cache write failed ($e)');
  }
}
