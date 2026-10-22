import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../offline_config.dart';

/// Echte Erreichbarkeit, nicht nur „Interface an“: WLAN ohne Internet,
/// Captive Portals und Funklöcher melden `connectivity_plus` als online.
///
/// Online = Interface aktiv **und** der Ping kommt innerhalb von
/// [OfflineConfig.pingTimeout] zurück.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity, required this._probe})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final Future<bool> Function() _probe;

  static bool interfaceUp(List<ConnectivityResult> r) =>
      r.isNotEmpty && r.any((e) => e != ConnectivityResult.none);

  Future<bool> check() async {
    if (!interfaceUp(await _connectivity.checkConnectivity())) return false;
    return _probe();
  }

  /// Emittiert bei jedem Wechsel des Interfaces den geprüften Zustand.
  Stream<bool> get onChanged => _connectivity.onConnectivityChanged
      .asyncMap<bool>((r) => interfaceUp(r) ? _probe() : false)
      .distinct();

  /// Ping gegen [url]: jede HTTP-Antwort (auch 401/404) heißt „Server da“.
  static Future<bool> httpProbe(
    String url, {
    Map<String, String> headers = const {},
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    try {
      final res = await c
          .head(Uri.parse(url), headers: headers)
          .timeout(OfflineConfig.pingTimeout);
      return res.statusCode < 500;
    } catch (_) {
      return false;
    } finally {
      if (client == null) c.close();
    }
  }
}
