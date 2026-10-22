import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../offline_config.dart';
import 'file_store.dart';

/// Dateien unter Application Support (nicht Documents: dort sehen Nutzer sie
/// in der Dateien-App). iOS: vom iCloud-Backup ausgenommen (AppDelegate),
/// Android: per `backup_rules.xml` / `data_extraction_rules.xml`.
class IoFileStore implements FileStore {
  IoFileStore._(this._root);

  final Directory _root;

  static const _channel = MethodChannel('kalia/file_store');

  static Future<IoFileStore> open({Directory? root}) async {
    final dir =
        root ??
        Directory(
          '${(await getApplicationSupportDirectory()).path}/${OfflineConfig.fileStoreDir}',
        );
    await dir.create(recursive: true);
    if (root == null && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        await _channel.invokeMethod<void>('excludeFromBackup', dir.path);
      } on MissingPluginException {
        // Test/Simulator ohne Runner-Channel.
      }
    }
    return IoFileStore._(dir);
  }

  File _file(String key) {
    if (key.contains('..') || key.startsWith('/')) {
      throw ArgumentError.value(key, 'key', 'ungültiger Schlüssel');
    }
    return File('${_root.path}/$key');
  }

  @override
  String? pathIfExists(String key) {
    final f = _file(key);
    return f.existsSync() ? f.path : null;
  }

  @override
  Future<String> write(String key, List<int> bytes) async {
    final target = _file(key);
    await target.parent.create(recursive: true);
    final tmp = File('${target.path}.part');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(target.path);
    return target.path;
  }

  @override
  Future<void> delete(String key) async {
    final f = _file(key);
    if (await f.exists()) await f.delete();
  }

  @override
  Future<int> usedBytes() async {
    var total = 0;
    await for (final e in _root.list(recursive: true, followLinks: false)) {
      if (e is File) total += await e.length();
    }
    return total;
  }
}
