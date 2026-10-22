import 'file_store.dart';
import 'offline_database.dart';

/// Web: bleibt beim bisherigen Verhalten (CatalogCache + Seed).
const offlineStorageSupported = false;

OfflineDatabase openOfflineDatabase() =>
    throw UnsupportedError('Offline-Datenbank nur nativ');

Future<FileStore> openFileStore() async => const NullFileStore();
