import 'package:lehrpfad_app/features/species/data/local_funde_store.dart';
import 'package:lehrpfad_app/features/species/domain/fund.dart';

/// Funde im Speicher, statt SharedPreferences.
class MemoryFundeStore implements FundeStore {
  MemoryFundeStore([Map<String, Fund>? start]) : funde = {...?start};

  Map<String, Fund> funde;

  Set<String> get ids => funde.keys.toSet();

  @override
  Future<Map<String, Fund>> read() async => {...funde};

  @override
  Future<void> write(Map<String, Fund> next) async {
    funde = {...next};
  }
}
