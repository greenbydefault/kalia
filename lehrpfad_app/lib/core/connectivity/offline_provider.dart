import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `true`, wenn das Gerät keine Netzverbindung meldet. Fehlt die Plattform
/// (Tests), gilt das Gerät als online.
final offlineProvider = NotifierProvider<OfflineNotifier, bool>(
  OfflineNotifier.new,
);

class OfflineNotifier extends Notifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  bool build() {
    ref.onDispose(() => _sub?.cancel());
    _init();
    return false;
  }

  static bool _offline(List<ConnectivityResult> r) =>
      r.isEmpty || r.every((e) => e == ConnectivityResult.none);

  Future<void> _init() async {
    try {
      final connectivity = Connectivity();
      state = _offline(await connectivity.checkConnectivity());
      _sub = connectivity.onConnectivityChanged.listen((r) {
        state = _offline(r);
      });
    } catch (_) {
      // Keine Plattform-Implementierung: online annehmen.
    }
  }
}
