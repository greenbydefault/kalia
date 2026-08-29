import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_engine.dart';

/// App-weite Sync-Engine. Keep-alive (kein autoDispose); wird von den
/// Repository-Providern und dem Sync-Lifecycle (`app/sync_lifecycle.dart`)
/// genutzt.
final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine();
});
