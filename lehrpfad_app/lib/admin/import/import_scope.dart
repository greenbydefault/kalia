import 'package:flutter/material.dart';

import '../core/field_spec.dart';
import 'import_models.dart';

/// Brücke zwischen Review-Seite und Editor: der Editor registriert, wie ein Wert
/// in ein Feld geschrieben wird; die Review-Seite stößt Blöcke zum Neuladen an.
class ImportEditorController extends ChangeNotifier {
  /// Vom Editor gesetzt: schreibt [value] ins Feld [key] (Autosave + Feld neu aufbauen).
  void Function(String key, dynamic value)? applyValue;

  /// Vom Editor gesetzt: aktueller Zeilenstand.
  DbRow Function()? currentRow;

  /// Vom Editor gesetzt: schreibt sofort alle offenen Änderungen.
  Future<void> Function()? flush;

  /// Wird nach jedem erfolgreichen Autosave gerufen (löst die Neuprüfung aus).
  VoidCallback? onSaved;

  final _keys = <String, GlobalKey>{};

  /// Schlüssel je Feld/Block, damit „nächste Meldung“ dorthin scrollen kann.
  GlobalKey keyFor(String k) => _keys.putIfAbsent(k, GlobalKey.new);

  BuildContext? contextFor(String k) => _keys[k]?.currentContext;

  int _blockRev = 0;
  int get blockRev => _blockRev;

  /// Relations-/Child-Blöcke neu laden (nach Arten- oder Stationsänderung).
  void refreshBlocks() {
    _blockRev++;
    notifyListeners();
  }
}

/// Aktionen, die Meldungen im Editor auslösen können.
abstract class ImportReviewActions {
  Future<void> applyFix(ReportEntry e);
  Future<void> overrideEntry(ReportEntry e);
  Future<void> ack(ReportEntry e);
  Future<void> ask(ReportEntry e);
  Future<void> resolveSpecies(ReportEntry e);
  Future<void> resolveDuplicate(ReportEntry e);
  Future<void> addStation();
}

class ImportScopeData {
  const ImportScopeData({
    required this.job,
    required this.messages,
    required this.states,
    required this.controller,
    required this.actions,
  });

  final ImportJob job;
  final ImportMessages messages;
  final FieldStates states;
  final ImportEditorController controller;
  final ImportReviewActions actions;
}

class ImportScope extends InheritedWidget {
  const ImportScope({super.key, required this.data, required super.child});

  final ImportScopeData data;

  static ImportScopeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ImportScope>()?.data;

  @override
  bool updateShouldNotify(ImportScope old) =>
      old.data.job != data.job ||
      old.data.states != data.states ||
      old.data.messages != data.messages;
}

/// Editor-Schlüssel des Blocks mit diesem Titel (nur Trails).
String? importBlockKey(String title) => switch (title) {
  'Stationen' => 'stationen',
  'Arten' => 'arten',
  'Bilder' => 'bilder',
  'Lebensräume' => 'lebensraeume',
  _ => null,
};
