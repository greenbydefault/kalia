import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Liest die alte Support-Dir-JSON einmalig fuer Migration nach Prefs.
Future<Set<String>?> readLegacySightingsFile() async {
  try {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/species_sightings.json');
    if (!file.existsSync()) return null;
    final list = jsonDecode(await file.readAsString()) as List;
    return list.cast<String>().toSet();
  } catch (_) {
    return null;
  }
}
