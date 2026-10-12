import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'collection_spec.dart';
import 'field_spec.dart';

/// Eingeloggter Supabase-Client des Admins.
final adminClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Generisches Zeilen-CRUD auf Row-Maps. Domain-Modelle der App bleiben
/// unangetastet; der Editor arbeitet direkt auf den Spalten.
class AdminRepository {
  AdminRepository(this._client);

  final SupabaseClient _client;

  PostgrestFilterBuilder<PostgrestList> _base(
    CollectionSpec spec,
    String cols,
  ) {
    var q = _client.from(spec.table).select(cols);
    final fc = spec.filterColumn;
    if (fc != null) q = q.eq(fc, spec.filterValue!);
    return q;
  }

  Future<List<DbRow>> list(CollectionSpec spec) async {
    final cols = {spec.idColumn, ...spec.listColumns.split(',')}.join(',');
    final rows = await _base(spec, cols).order(spec.titleColumn);
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<DbRow?> get(CollectionSpec spec, String id) async {
    final row = await _client
        .from(spec.table)
        .select()
        .eq(spec.idColumn, id)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<int> count(CollectionSpec spec) async {
    var q = _client.from(spec.table).count();
    final fc = spec.filterColumn;
    if (fc != null) q = q.eq(fc, spec.filterValue!);
    return q;
  }

  Future<void> update(
    CollectionSpec spec,
    String id,
    Map<String, dynamic> patch,
  ) async {
    await _client.from(spec.table).update(patch).eq(spec.idColumn, id);
  }

  Future<DbRow> insert(CollectionSpec spec, DbRow row) async {
    final res = await _client.from(spec.table).insert(row).select().single();
    return Map<String, dynamic>.from(res);
  }

  Future<void> delete(CollectionSpec spec, String id) async {
    for (final d in spec.manualCascade) {
      await _client.from(d.table).delete().eq(d.column, id);
    }
    await _client.from(spec.table).delete().eq(spec.idColumn, id);
  }

  /// Anzahl abhängiger Zeilen je [DependentSpec] für den Löschdialog.
  Future<Map<String, int>> dependentCounts(
    CollectionSpec spec,
    String id,
  ) async {
    final out = <String, int>{};
    for (final d in spec.dependents) {
      final n = await _client.from(d.table).count().eq(d.column, id);
      if (n > 0) out[d.label] = n;
    }
    return out;
  }

  /// Ob [id] in der Tabelle schon vergeben ist.
  Future<bool> exists(CollectionSpec spec, String id) async {
    final row = await _client
        .from(spec.table)
        .select(spec.idColumn)
        .eq(spec.idColumn, id)
        .maybeSingle();
    return row != null;
  }
}

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(adminClientProvider)),
);

/// Listenzeilen einer Collection. Nach Speichern/Anlegen/Löschen
/// invalidieren; alte Daten bleiben beim Reload sichtbar.
final collectionRowsProvider =
    FutureProvider.family<List<DbRow>, CollectionSpec>((ref, spec) {
      return ref.watch(adminRepositoryProvider).list(spec);
    });

/// Zeile im Editor.
final collectionRowProvider =
    FutureProvider.family<DbRow?, ({CollectionSpec spec, String id})>((
      ref,
      key,
    ) {
      return ref.watch(adminRepositoryProvider).get(key.spec, key.id);
    });

final collectionCountProvider = FutureProvider.family<int, CollectionSpec>((
  ref,
  spec,
) {
  return ref.watch(adminRepositoryProvider).count(spec);
});

/// `Kranich der Ostsee` → `kranich-der-ostsee`.
String slugify(String input) {
  const map = {'ä': 'ae', 'ö': 'oe', 'ü': 'ue', 'ß': 'ss'};
  var s = input.toLowerCase().trim();
  map.forEach((k, v) => s = s.replaceAll(k, v));
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  s = s.replaceAll(RegExp(r'^-+|-+$'), '');
  return s;
}
