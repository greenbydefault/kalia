import 'catalog_cache.dart';
import 'catalog_cache_stub.dart'
    if (dart.library.io) 'catalog_cache_io.dart' as impl;

/// Platform-Adapter: File native, Prefs auf Web.
CatalogCache createCatalogCache() => impl.createCatalogCache();
