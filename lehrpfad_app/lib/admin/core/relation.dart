import 'package:supabase_flutter/supabase_flutter.dart';

import 'field_spec.dart';

/// Eine Verknüpfung zu einem anderen Datensatz (Chip im Multi-Reference-Feld).
class RelationLink {
  const RelationLink({
    required this.otherId,
    required this.title,
    this.subtitle,
    this.extras = const {},
    this.other = const {},
  });

  final String otherId;
  final String title;
  final String? subtitle;

  /// Spalten der Join-Zeile (`nachweis`, `rolle` …).
  final Map<String, dynamic> extras;

  /// Roh-Zeile des verknüpften Datensatzes (für Routing, z. B. `kategorie`).
  final Map<String, dynamic> other;
}

/// Lese-/Schreibzugriff einer Beziehung aus Sicht eines Datensatzes.
/// Gleiche Oberfläche für Join-Tabellen, Array-Spalten und Katalog-Keys,
/// damit ein Widget alle Richtungen darstellt.
abstract class RelationBackend {
  /// Verknüpfte Datensätze von [ownId].
  Future<List<RelationLink>> load(String ownId);

  /// Kandidaten zum Hinzufügen, gefiltert nach [query].
  Future<List<RelationLink>> search(String query);

  Future<void> add(String ownId, String otherId);

  Future<void> remove(String ownId, String otherId);

  Future<void> updateExtras(
    String ownId,
    String otherId,
    Map<String, dynamic> patch,
  ) async {}

  /// `false` → nur Anzeige (z. B. aus OSRM berechnete Fahrzeiten).
  bool get editable => true;
}

enum OrderScope { own, other }

/// Join-Tabelle `(own_col, other_col, extras…)`.
class JoinTableBackend extends RelationBackend {
  JoinTableBackend(
    this.client, {
    required this.table,
    required this.ownCol,
    required this.otherCol,
    this.otherTable,
    this.otherTitleCol = 'name',
    this.otherSubtitleCol,
    this.otherExtraCols = const [],
    this.otherFilter,
    this.extraCols = const [],
    this.orderCol,
    this.orderScope = OrderScope.own,
    this.staticOptions,
    this.editable = true,
    this.defaults = const {},
    this.sortByExtra,
  });

  final SupabaseClient client;
  final String table;
  final String ownCol;
  final String otherCol;

  /// Tabelle des verknüpften Datensatzes; `null` bei [staticOptions].
  final String? otherTable;
  final String otherTitleCol;
  final String? otherSubtitleCol;
  final List<String> otherExtraCols;
  final (String, String)? otherFilter;
  final List<String> extraCols;

  /// Sortierspalte der Join-Zeilen (`sortierung`). Beim Hinzufügen ans Ende.
  final String? orderCol;
  final OrderScope orderScope;

  /// Key → Label, wenn die andere Seite ein Katalog-Key ist.
  final Map<String, String>? staticOptions;
  @override
  final bool editable;

  /// Feste Werte für neue Join-Zeilen.
  final Map<String, dynamic> defaults;

  /// Numerische Extra-Spalte als Sortierung der Chips (`sek`).
  final String? sortByExtra;

  String get _embedCols {
    final cols = <String>{
      'id',
      otherTitleCol,
      ?otherSubtitleCol,
      ...otherExtraCols,
    };
    return cols.join(',');
  }

  RelationLink _link(Map<String, dynamic> row, Map<String, DbRow> others) {
    final extras = {for (final c in extraCols) c: row[c]};
    final key = row[otherCol] as String;
    final opts = staticOptions;
    if (opts != null) {
      return RelationLink(
        otherId: key,
        title: opts[key] ?? key,
        extras: extras,
      );
    }
    final other = others[key] ?? const <String, dynamic>{};
    final title = other[otherTitleCol] as String?;
    return RelationLink(
      otherId: key,
      title: title != null && title.trim().isNotEmpty ? title : key,
      subtitle: otherSubtitleCol == null
          ? null
          : other[otherSubtitleCol] as String?,
      extras: extras,
      other: other,
    );
  }

  @override
  Future<List<RelationLink>> load(String ownId) async {
    final cols = {otherCol, ...extraCols, ?orderCol}.join(',');
    final q = client.from(table).select(cols).eq(ownCol, ownId);
    final oc = orderCol;
    final rows = oc != null && orderScope == OrderScope.own
        ? await q.order(oc, ascending: true)
        : await q;
    var others = <String, DbRow>{};
    if (staticOptions == null && rows.isNotEmpty) {
      // Zwei Schritte statt Embed: manche Join-Tabellen (trail_pois) haben
      // keinen FK auf die andere Seite, bei species_beziehungen sind es zwei.
      final ids = rows.map((r) => r[otherCol] as String).toSet().toList();
      final found = await client
          .from(otherTable!)
          .select(_embedCols)
          .inFilter('id', ids);
      others = {for (final r in found) r['id'] as String: r};
    }
    final links = rows.map<RelationLink>((r) => _link(r, others)).toList();
    final se = sortByExtra;
    if (se != null) {
      links.sort(
        (a, b) => ((a.extras[se] as num?) ?? 0).compareTo(
          (b.extras[se] as num?) ?? 0,
        ),
      );
    } else if (oc == null || orderScope == OrderScope.other) {
      links.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    }
    return links;
  }

  @override
  Future<List<RelationLink>> search(String query) async {
    final q = query.trim().toLowerCase();
    final opts = staticOptions;
    if (opts != null) {
      return [
        for (final e in opts.entries)
          if (q.isEmpty ||
              e.value.toLowerCase().contains(q) ||
              e.key.contains(q))
            RelationLink(otherId: e.key, title: e.value),
      ];
    }
    var b = client.from(otherTable!).select(_embedCols);
    final f = otherFilter;
    if (f != null) b = b.eq(f.$1, f.$2);
    if (q.isNotEmpty) {
      final safe = q.replaceAll(RegExp(r'[,()*%]'), ' ');
      b = b.or('$otherTitleCol.ilike.*$safe*,id.ilike.*$safe*');
    }
    final rows = await b.order(otherTitleCol, ascending: true).limit(40);
    return rows
        .map<RelationLink>(
          (r) => RelationLink(
            otherId: r['id'] as String,
            title: (r[otherTitleCol] as String?) ?? r['id'] as String,
            subtitle: otherSubtitleCol == null
                ? null
                : r[otherSubtitleCol] as String?,
            other: r,
          ),
        )
        .toList();
  }

  Future<int> _nextOrder(String ownId, String otherId) async {
    final oc = orderCol!;
    final scopeCol = orderScope == OrderScope.own ? ownCol : otherCol;
    final scopeVal = orderScope == OrderScope.own ? ownId : otherId;
    final rows = await client
        .from(table)
        .select(oc)
        .eq(scopeCol, scopeVal)
        .order(oc, ascending: false)
        .limit(1);
    if (rows.isEmpty) return 1;
    return ((rows.first[oc] as num?) ?? 0).toInt() + 1;
  }

  @override
  Future<void> add(String ownId, String otherId) async {
    final row = <String, dynamic>{
      ownCol: ownId,
      otherCol: otherId,
      ...defaults,
    };
    if (orderCol != null) row[orderCol!] = await _nextOrder(ownId, otherId);
    await client.from(table).upsert(row, onConflict: '$ownCol,$otherCol');
  }

  @override
  Future<void> remove(String ownId, String otherId) async {
    await client.from(table).delete().eq(ownCol, ownId).eq(otherCol, otherId);
  }

  @override
  Future<void> updateExtras(
    String ownId,
    String otherId,
    Map<String, dynamic> patch,
  ) async {
    await client
        .from(table)
        .update(patch)
        .eq(ownCol, ownId)
        .eq(otherCol, otherId);
  }
}

/// Eigener Datensatz trägt die Verknüpfung in einer text[]-Spalte
/// (`trails.lebensraeume` → Lebensräume). Sicht: Trail → Lebensräume.
class ArrayForwardBackend extends RelationBackend {
  ArrayForwardBackend(
    this.client, {
    required this.ownTable,
    required this.arrayCol,
    required this.otherTable,
    required this.otherTitleCol,
    this.otherSubtitleCol,
    this.maxItems,
  });

  final SupabaseClient client;
  final String ownTable;
  final String arrayCol;
  final String otherTable;
  final String otherTitleCol;
  final String? otherSubtitleCol;
  final int? maxItems;

  Future<List<String>> _ids(String ownId) async {
    final row = await client
        .from(ownTable)
        .select(arrayCol)
        .eq('id', ownId)
        .maybeSingle();
    final v = row?[arrayCol];
    return v is List ? v.map((e) => e.toString()).toList() : <String>[];
  }

  @override
  Future<List<RelationLink>> load(String ownId) async {
    final ids = await _ids(ownId);
    if (ids.isEmpty) return const [];
    final cols = {'id', otherTitleCol, ?otherSubtitleCol}.join(',');
    final rows = await client.from(otherTable).select(cols).inFilter('id', ids);
    final byId = {for (final r in rows) r['id'] as String: r};
    return [
      for (final id in ids)
        RelationLink(
          otherId: id,
          title: (byId[id]?[otherTitleCol] as String?) ?? id,
          subtitle: otherSubtitleCol == null
              ? null
              : byId[id]?[otherSubtitleCol] as String?,
          other: byId[id] ?? const {},
        ),
    ];
  }

  @override
  Future<List<RelationLink>> search(String query) async {
    final q = query.trim().replaceAll(RegExp(r'[,()*%]'), ' ');
    final cols = {'id', otherTitleCol, ?otherSubtitleCol}.join(',');
    var b = client.from(otherTable).select(cols);
    if (q.isNotEmpty) b = b.or('$otherTitleCol.ilike.*$q*,id.ilike.*$q*');
    final rows = await b.order(otherTitleCol, ascending: true).limit(40);
    return rows
        .map<RelationLink>(
          (r) => RelationLink(
            otherId: r['id'] as String,
            title: r[otherTitleCol] as String? ?? r['id'] as String,
            other: r,
          ),
        )
        .toList();
  }

  @override
  Future<void> add(String ownId, String otherId) async {
    final ids = await _ids(ownId);
    if (ids.contains(otherId)) return;
    if (maxItems != null && ids.length >= maxItems!) {
      throw StateError('Maximal $maxItems Einträge.');
    }
    await client
        .from(ownTable)
        .update({
          arrayCol: [...ids, otherId],
        })
        .eq('id', ownId);
  }

  @override
  Future<void> remove(String ownId, String otherId) async {
    final ids = await _ids(ownId);
    await client
        .from(ownTable)
        .update({arrayCol: ids.where((e) => e != otherId).toList()})
        .eq('id', ownId);
  }
}

/// Gegenrichtung zu [ArrayForwardBackend]: Lebensraum → Trails, die den
/// Key in `trails.lebensraeume` tragen.
class ArrayReverseBackend extends RelationBackend {
  ArrayReverseBackend(
    this.client, {
    required this.otherTable,
    required this.arrayCol,
    required this.otherTitleCol,
    this.otherSubtitleCol,
    this.maxItems,
  });

  final SupabaseClient client;
  final String otherTable;
  final String arrayCol;
  final String otherTitleCol;
  final String? otherSubtitleCol;
  final int? maxItems;

  String get _cols =>
      {'id', otherTitleCol, ?otherSubtitleCol, arrayCol}.join(',');

  @override
  Future<List<RelationLink>> load(String ownId) async {
    final rows = await client
        .from(otherTable)
        .select(_cols)
        .contains(arrayCol, [ownId])
        .order(otherTitleCol, ascending: true);
    return rows.map<RelationLink>(_link).toList();
  }

  RelationLink _link(DbRow r) => RelationLink(
    otherId: r['id'] as String,
    title: r[otherTitleCol] as String? ?? r['id'] as String,
    subtitle: otherSubtitleCol == null ? null : r[otherSubtitleCol] as String?,
    other: r,
  );

  @override
  Future<List<RelationLink>> search(String query) async {
    final q = query.trim().replaceAll(RegExp(r'[,()*%]'), ' ');
    var b = client.from(otherTable).select(_cols);
    if (q.isNotEmpty) b = b.or('$otherTitleCol.ilike.*$q*,id.ilike.*$q*');
    final rows = await b.order(otherTitleCol, ascending: true).limit(40);
    return rows.map<RelationLink>(_link).toList();
  }

  Future<List<String>> _ids(String otherId) async {
    final row = await client
        .from(otherTable)
        .select(arrayCol)
        .eq('id', otherId)
        .maybeSingle();
    final v = row?[arrayCol];
    return v is List ? v.map((e) => e.toString()).toList() : <String>[];
  }

  @override
  Future<void> add(String ownId, String otherId) async {
    final ids = await _ids(otherId);
    if (ids.contains(ownId)) return;
    if (maxItems != null && ids.length >= maxItems!) {
      throw StateError('Der Trail hat schon $maxItems Lebensräume.');
    }
    await client
        .from(otherTable)
        .update({
          arrayCol: [...ids, ownId],
        })
        .eq('id', otherId);
  }

  @override
  Future<void> remove(String ownId, String otherId) async {
    final ids = await _ids(otherId);
    await client
        .from(otherTable)
        .update({arrayCol: ids.where((e) => e != ownId).toList()})
        .eq('id', otherId);
  }
}
