import 'package:drift_flutter/drift_flutter.dart';

import '../offline_config.dart';
import 'file_store.dart';
import 'file_store_io.dart';
import 'offline_database.dart';

/// Native: drift-DB + Dateispeicher.
const offlineStorageSupported = true;

OfflineDatabase openOfflineDatabase() =>
    OfflineDatabase(driftDatabase(name: OfflineConfig.dbName));

Future<FileStore> openFileStore() => IoFileStore.open();
