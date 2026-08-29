import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Hydriert `json['bilder']` aus dem lokalen credits.json.
///
/// Reihenfolge: vorhandenes Array bleibt; sonst `bilderAsset`; sonst
/// `assets/images/trails/{id}/credits.json`. Damit haben Seed *und*
/// Supabase dieselben Hero-Fotos.
Future<void> attachHeroBilder(Map<String, dynamic> json) async {
  final existing = json['bilder'];
  if (existing is List && existing.isNotEmpty) return;

  final asset = json['bilderAsset'] as String?;
  final id = json['id'] as String?;
  final explicit = (asset != null && asset.isNotEmpty) ? asset : null;
  final fallback = (id != null && id.isNotEmpty)
      ? 'assets/images/trails/$id/credits.json'
      : null;
  final paths = <String>[
    if (explicit != null) explicit,
    if (fallback != null && fallback != explicit) fallback,
  ];
  for (final path in paths) {
    try {
      json['bilder'] = jsonDecode(await rootBundle.loadString(path));
      return;
    } catch (e) {
      if (path == explicit) {
        debugPrint('Hero-Credits "$path" übersprungen ($e)');
      }
    }
  }
}
