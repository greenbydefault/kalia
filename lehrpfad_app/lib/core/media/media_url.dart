import '../config/supabase_config.dart';

/// Pfade für Katalog-Medien (`species.image_path` / `audio_path`).
///
/// Drei Formen, alle in derselben Spalte:
/// - `http(s)://…`         externe URL, wird unverändert geladen
/// - `storage:<bucket>/<pfad>`  Supabase Storage (public), vom Admin-CMS
/// - sonst                 gebündeltes Asset (`assets/…`)
abstract final class MediaUrl {
  static const storagePrefix = 'storage:';

  static bool isNetwork(String path) =>
      path.startsWith('http://') ||
      path.startsWith('https://') ||
      path.startsWith(storagePrefix);

  /// Netzwerk-URL für [path], `null` bei gebündeltem Asset.
  static String? resolve(String path, {String? supabaseUrl}) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (!path.startsWith(storagePrefix)) return null;
    final base = (supabaseUrl ?? SupabaseConfig.url).replaceAll(
      RegExp(r'/+$'),
      '',
    );
    if (base.isEmpty) return null;
    final rest = path.substring(storagePrefix.length);
    return '$base/storage/v1/object/public/$rest';
  }

  /// `storage:<bucket>/<objekt>` aus Bucket und Objektpfad.
  static String storagePath(String bucket, String object) =>
      '$storagePrefix$bucket/$object';

  /// Zerlegt `storage:<bucket>/<objekt>`; `null` für alles andere.
  static ({String bucket, String object})? parseStorage(String path) {
    if (!path.startsWith(storagePrefix)) return null;
    final rest = path.substring(storagePrefix.length);
    final i = rest.indexOf('/');
    if (i <= 0) return null;
    return (bucket: rest.substring(0, i), object: rest.substring(i + 1));
  }
}
