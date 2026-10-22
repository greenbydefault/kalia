import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_config.dart';
import '../network/connectivity_service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(
    probe: () async {
      // Ohne Backend gibt es nichts zu pingen: Interface-Status genügt.
      if (!SupabaseConfig.isConfigured) return true;
      return ConnectivityService.httpProbe(
        '${SupabaseConfig.url.replaceAll(RegExp(r'/+$'), '')}/auth/v1/health',
        headers: {'apikey': SupabaseConfig.publishableKey},
      );
    },
  );
});

/// `true`, wenn das Netz wirklich nutzbar ist. Optimistisch `true` bis zur
/// ersten Messung; fehlt die Plattform (Tests), bleibt es `true`.
final isOnlineProvider = NotifierProvider<OnlineNotifier, bool>(
  OnlineNotifier.new,
);

class OnlineNotifier extends Notifier<bool> {
  StreamSubscription<bool>? _sub;

  @override
  bool build() {
    ref.onDispose(() => _sub?.cancel());
    _init(ref.read(connectivityServiceProvider));
    return true;
  }

  Future<void> _init(ConnectivityService service) async {
    try {
      final first = await service.check();
      if (!ref.mounted) return;
      state = first;
      _sub = service.onChanged.listen((online) => state = online);
    } catch (_) {
      // Keine Plattform-Implementierung: online annehmen.
    }
  }

  /// Manuell neu prüfen (z. B. nach fehlgeschlagenem Request).
  Future<void> recheck() async {
    state = await ref.read(connectivityServiceProvider).check();
  }
}
