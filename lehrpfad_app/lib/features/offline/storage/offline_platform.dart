// Conditional Import wie `catalog_cache_platform.dart`: Web ohne dart:io/sqlite.
export 'offline_platform_stub.dart'
    if (dart.library.io) 'offline_platform_io.dart';
