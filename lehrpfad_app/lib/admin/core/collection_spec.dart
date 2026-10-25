import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'autosave.dart';
import 'field_spec.dart';
import 'relation.dart';

/// Was ein Editor-Block dem Custom-Widget mitgibt.
class EditorContext {
  const EditorContext({
    required this.spec,
    required this.row,
    required this.client,
    required this.hub,
    required this.autosave,
  });

  final CollectionSpec spec;
  final DbRow row;
  final SupabaseClient client;
  final AutosaveHub hub;
  final AutosaveController autosave;

  String get id => row[spec.idColumn] as String;
}

sealed class EditorBlock {
  const EditorBlock(this.title, {this.description});
  final String title;
  final String? description;
}

/// Gruppe von Feldern der Zeile selbst.
class FieldsBlock extends EditorBlock {
  const FieldsBlock(super.title, this.fields, {super.description});
  final List<FieldSpec> fields;
}

/// Multi-Reference-Feld.
class RelationBlock extends EditorBlock {
  const RelationBlock(super.title, this.relation, {super.description});
  final RelationSpec relation;
}

/// Eigenes Widget (Medien, Stationen, Beziehungen, Maße).
class CustomBlock extends EditorBlock {
  const CustomBlock(super.title, this.builder, {super.description});
  final Widget Function(BuildContext context, EditorContext ctx) builder;
}

/// Beziehung in einer Richtung, konfiguriert über ein [RelationBackend].
class RelationSpec {
  const RelationSpec({
    required this.backend,
    required this.routeFor,
    this.extraFields = const [],
    this.extraLabel,
    this.createKinds = const [],
    this.emptyText = 'Noch nichts verknüpft.',
    this.addLabel = 'Hinzufügen',
    this.limitHint,
  });

  final RelationBackend Function(SupabaseClient client) backend;

  /// Ziel-Route für Klick auf einen Chip (`/fauna/kranich`).
  final String Function(RelationLink link) routeFor;

  /// Bearbeitbare Spalten der Join-Zeile (`nachweis`, `rolle` …).
  final List<FieldSpec> extraFields;

  /// Kurzanzeige der Extras am Chip. `null` → Werte der [extraFields].
  final String? Function(RelationLink link)? extraLabel;

  /// Collection-IDs, in denen „Neu anlegen“ angeboten wird (`flora`, `fauna`).
  final List<String> createKinds;
  final String emptyText;
  final String addLabel;
  final String? limitHint;
}

/// Tabelle, die auf diesen Datensatz zeigt. Für den Löschdialog.
class DependentSpec {
  const DependentSpec(this.table, this.column, this.label);
  final String table;
  final String column;
  final String label;
}

class ListFilterSpec {
  const ListFilterSpec(this.column, this.label, this.options);
  final String column;
  final String label;
  final Map<String, String> options;
}

/// Ein Ordner im Katalog (Sidebar-Eintrag) mit Tabelle, Liste und Editor.
class CollectionSpec {
  const CollectionSpec({
    required this.id,
    required this.label,
    required this.singular,
    required this.table,
    required this.icon,
    required this.titleColumn,
    required this.listColumns,
    required this.blocks,
    required this.newRow,
    this.idColumn = 'id',
    this.filterColumn,
    this.filterValue,
    this.subtitle,
    this.listFilters = const [],
    this.gaps,
    this.dependents = const [],
    this.thumbUrl,
    this.canCreate = true,
    this.canDelete = true,
    this.manualCascade = const [],
    this.confirmDeleteByTyping = false,
    this.importPath,
  });

  /// Route-Segment und Provider-Key (`trails`, `flora`).
  final String id;
  final String label;
  final String singular;
  final String table;
  final IconData icon;
  final String idColumn;
  final String titleColumn;

  /// Nur Zeilen mit `filterColumn = filterValue` (Flora/Fauna/Geräte).
  final String? filterColumn;
  final String? filterValue;

  /// PostgREST-Select der Listenspalte (leicht halten).
  final String listColumns;
  final String? Function(DbRow row)? subtitle;
  final List<ListFilterSpec> listFilters;

  /// Fehlende Inhalte einer Zeile (für den Lücken-Punkt). Leer = vollständig.
  final List<String> Function(DbRow row)? gaps;
  final List<DependentSpec> dependents;
  final String? Function(DbRow row)? thumbUrl;
  final List<EditorBlock> blocks;

  /// Neue Zeile aus generierter ID und eingegebenem Titel.
  final DbRow Function(String id, String title) newRow;
  final bool canCreate;
  final bool canDelete;

  /// Zeilen ohne FK-Cascade, die vor dem Löschen mitgeräumt werden.
  final List<DependentSpec> manualCascade;

  /// Löschen erst nach Eintippen der ID (Trails).
  final bool confirmDeleteByTyping;

  /// Route zum Import-Bereich (Button in der Liste), nur Trails.
  final String? importPath;

  String get path => '/$id';
  String itemPath(String itemId) => '/$id/${Uri.encodeComponent(itemId)}';
}
