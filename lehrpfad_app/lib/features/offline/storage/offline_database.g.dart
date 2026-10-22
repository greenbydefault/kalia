// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_database.dart';

// ignore_for_file: type=lint
class $TrailIndexTable extends TrailIndex
    with TableInfo<$TrailIndexTable, TrailRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrailIndexTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataVersionMeta = const VerificationMeta(
    'dataVersion',
  );
  @override
  late final GeneratedColumn<int> dataVersion = GeneratedColumn<int>(
    'data_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closedMeta = const VerificationMeta('closed');
  @override
  late final GeneratedColumn<bool> closed = GeneratedColumn<bool>(
    'closed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("closed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, dataVersion, closed, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trail_index';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrailRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('data_version')) {
      context.handle(
        _dataVersionMeta,
        dataVersion.isAcceptableOrUnknown(
          data['data_version']!,
          _dataVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dataVersionMeta);
    }
    if (data.containsKey('closed')) {
      context.handle(
        _closedMeta,
        closed.isAcceptableOrUnknown(data['closed']!, _closedMeta),
      );
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrailRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrailRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      dataVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}data_version'],
      )!,
      closed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}closed'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $TrailIndexTable createAlias(String alias) {
    return $TrailIndexTable(attachedDatabase, alias);
  }
}

class TrailRow extends DataClass implements Insertable<TrailRow> {
  final String id;
  final int dataVersion;
  final bool closed;
  final String json;
  const TrailRow({
    required this.id,
    required this.dataVersion,
    required this.closed,
    required this.json,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['data_version'] = Variable<int>(dataVersion);
    map['closed'] = Variable<bool>(closed);
    map['json'] = Variable<String>(json);
    return map;
  }

  TrailIndexCompanion toCompanion(bool nullToAbsent) {
    return TrailIndexCompanion(
      id: Value(id),
      dataVersion: Value(dataVersion),
      closed: Value(closed),
      json: Value(json),
    );
  }

  factory TrailRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrailRow(
      id: serializer.fromJson<String>(json['id']),
      dataVersion: serializer.fromJson<int>(json['dataVersion']),
      closed: serializer.fromJson<bool>(json['closed']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'dataVersion': serializer.toJson<int>(dataVersion),
      'closed': serializer.toJson<bool>(closed),
      'json': serializer.toJson<String>(json),
    };
  }

  TrailRow copyWith({
    String? id,
    int? dataVersion,
    bool? closed,
    String? json,
  }) => TrailRow(
    id: id ?? this.id,
    dataVersion: dataVersion ?? this.dataVersion,
    closed: closed ?? this.closed,
    json: json ?? this.json,
  );
  TrailRow copyWithCompanion(TrailIndexCompanion data) {
    return TrailRow(
      id: data.id.present ? data.id.value : this.id,
      dataVersion: data.dataVersion.present
          ? data.dataVersion.value
          : this.dataVersion,
      closed: data.closed.present ? data.closed.value : this.closed,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrailRow(')
          ..write('id: $id, ')
          ..write('dataVersion: $dataVersion, ')
          ..write('closed: $closed, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dataVersion, closed, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrailRow &&
          other.id == this.id &&
          other.dataVersion == this.dataVersion &&
          other.closed == this.closed &&
          other.json == this.json);
}

class TrailIndexCompanion extends UpdateCompanion<TrailRow> {
  final Value<String> id;
  final Value<int> dataVersion;
  final Value<bool> closed;
  final Value<String> json;
  final Value<int> rowid;
  const TrailIndexCompanion({
    this.id = const Value.absent(),
    this.dataVersion = const Value.absent(),
    this.closed = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrailIndexCompanion.insert({
    required String id,
    required int dataVersion,
    this.closed = const Value.absent(),
    required String json,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       dataVersion = Value(dataVersion),
       json = Value(json);
  static Insertable<TrailRow> custom({
    Expression<String>? id,
    Expression<int>? dataVersion,
    Expression<bool>? closed,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dataVersion != null) 'data_version': dataVersion,
      if (closed != null) 'closed': closed,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrailIndexCompanion copyWith({
    Value<String>? id,
    Value<int>? dataVersion,
    Value<bool>? closed,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return TrailIndexCompanion(
      id: id ?? this.id,
      dataVersion: dataVersion ?? this.dataVersion,
      closed: closed ?? this.closed,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (dataVersion.present) {
      map['data_version'] = Variable<int>(dataVersion.value);
    }
    if (closed.present) {
      map['closed'] = Variable<bool>(closed.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrailIndexCompanion(')
          ..write('id: $id, ')
          ..write('dataVersion: $dataVersion, ')
          ..write('closed: $closed, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SpeciesIndexTable extends SpeciesIndex
    with TableInfo<$SpeciesIndexTable, SpeciesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpeciesIndexTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, version, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'species_index';
  @override
  VerificationContext validateIntegrity(
    Insertable<SpeciesRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SpeciesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SpeciesRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $SpeciesIndexTable createAlias(String alias) {
    return $SpeciesIndexTable(attachedDatabase, alias);
  }
}

class SpeciesRow extends DataClass implements Insertable<SpeciesRow> {
  final String id;
  final int version;
  final String json;
  const SpeciesRow({
    required this.id,
    required this.version,
    required this.json,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['version'] = Variable<int>(version);
    map['json'] = Variable<String>(json);
    return map;
  }

  SpeciesIndexCompanion toCompanion(bool nullToAbsent) {
    return SpeciesIndexCompanion(
      id: Value(id),
      version: Value(version),
      json: Value(json),
    );
  }

  factory SpeciesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SpeciesRow(
      id: serializer.fromJson<String>(json['id']),
      version: serializer.fromJson<int>(json['version']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'version': serializer.toJson<int>(version),
      'json': serializer.toJson<String>(json),
    };
  }

  SpeciesRow copyWith({String? id, int? version, String? json}) => SpeciesRow(
    id: id ?? this.id,
    version: version ?? this.version,
    json: json ?? this.json,
  );
  SpeciesRow copyWithCompanion(SpeciesIndexCompanion data) {
    return SpeciesRow(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SpeciesRow(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, version, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpeciesRow &&
          other.id == this.id &&
          other.version == this.version &&
          other.json == this.json);
}

class SpeciesIndexCompanion extends UpdateCompanion<SpeciesRow> {
  final Value<String> id;
  final Value<int> version;
  final Value<String> json;
  final Value<int> rowid;
  const SpeciesIndexCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SpeciesIndexCompanion.insert({
    required String id,
    this.version = const Value.absent(),
    required String json,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       json = Value(json);
  static Insertable<SpeciesRow> custom({
    Expression<String>? id,
    Expression<int>? version,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SpeciesIndexCompanion copyWith({
    Value<String>? id,
    Value<int>? version,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return SpeciesIndexCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpeciesIndexCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta with TableInfo<$SyncMetaTable, MetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class MetaRow extends DataClass implements Insertable<MetaRow> {
  final String key;
  final String value;
  const MetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(key: Value(key), value: Value(value));
  }

  factory MetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  MetaRow copyWith({String? key, String? value}) =>
      MetaRow(key: key ?? this.key, value: value ?? this.value);
  MetaRow copyWithCompanion(SyncMetaCompanion data) {
    return MetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetaRow && other.key == this.key && other.value == this.value);
}

class SyncMetaCompanion extends UpdateCompanion<MetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$OfflineDatabase extends GeneratedDatabase {
  _$OfflineDatabase(QueryExecutor e) : super(e);
  $OfflineDatabaseManager get managers => $OfflineDatabaseManager(this);
  late final $TrailIndexTable trailIndex = $TrailIndexTable(this);
  late final $SpeciesIndexTable speciesIndex = $SpeciesIndexTable(this);
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    trailIndex,
    speciesIndex,
    syncMeta,
  ];
}

typedef $$TrailIndexTableCreateCompanionBuilder =
    TrailIndexCompanion Function({
      required String id,
      required int dataVersion,
      Value<bool> closed,
      required String json,
      Value<int> rowid,
    });
typedef $$TrailIndexTableUpdateCompanionBuilder =
    TrailIndexCompanion Function({
      Value<String> id,
      Value<int> dataVersion,
      Value<bool> closed,
      Value<String> json,
      Value<int> rowid,
    });

class $$TrailIndexTableFilterComposer
    extends Composer<_$OfflineDatabase, $TrailIndexTable> {
  $$TrailIndexTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dataVersion => $composableBuilder(
    column: $table.dataVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get closed => $composableBuilder(
    column: $table.closed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrailIndexTableOrderingComposer
    extends Composer<_$OfflineDatabase, $TrailIndexTable> {
  $$TrailIndexTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dataVersion => $composableBuilder(
    column: $table.dataVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get closed => $composableBuilder(
    column: $table.closed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrailIndexTableAnnotationComposer
    extends Composer<_$OfflineDatabase, $TrailIndexTable> {
  $$TrailIndexTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dataVersion => $composableBuilder(
    column: $table.dataVersion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get closed =>
      $composableBuilder(column: $table.closed, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$TrailIndexTableTableManager
    extends
        RootTableManager<
          _$OfflineDatabase,
          $TrailIndexTable,
          TrailRow,
          $$TrailIndexTableFilterComposer,
          $$TrailIndexTableOrderingComposer,
          $$TrailIndexTableAnnotationComposer,
          $$TrailIndexTableCreateCompanionBuilder,
          $$TrailIndexTableUpdateCompanionBuilder,
          (
            TrailRow,
            BaseReferences<_$OfflineDatabase, $TrailIndexTable, TrailRow>,
          ),
          TrailRow,
          PrefetchHooks Function()
        > {
  $$TrailIndexTableTableManager(_$OfflineDatabase db, $TrailIndexTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrailIndexTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrailIndexTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrailIndexTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> dataVersion = const Value.absent(),
                Value<bool> closed = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrailIndexCompanion(
                id: id,
                dataVersion: dataVersion,
                closed: closed,
                json: json,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int dataVersion,
                Value<bool> closed = const Value.absent(),
                required String json,
                Value<int> rowid = const Value.absent(),
              }) => TrailIndexCompanion.insert(
                id: id,
                dataVersion: dataVersion,
                closed: closed,
                json: json,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TrailIndexTable, TrailRow>(table),
                  BaseReferences<_$OfflineDatabase, $TrailIndexTable, TrailRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrailIndexTableProcessedTableManager =
    ProcessedTableManager<
      _$OfflineDatabase,
      $TrailIndexTable,
      TrailRow,
      $$TrailIndexTableFilterComposer,
      $$TrailIndexTableOrderingComposer,
      $$TrailIndexTableAnnotationComposer,
      $$TrailIndexTableCreateCompanionBuilder,
      $$TrailIndexTableUpdateCompanionBuilder,
      (TrailRow, BaseReferences<_$OfflineDatabase, $TrailIndexTable, TrailRow>),
      TrailRow,
      PrefetchHooks Function()
    >;
typedef $$SpeciesIndexTableCreateCompanionBuilder =
    SpeciesIndexCompanion Function({
      required String id,
      Value<int> version,
      required String json,
      Value<int> rowid,
    });
typedef $$SpeciesIndexTableUpdateCompanionBuilder =
    SpeciesIndexCompanion Function({
      Value<String> id,
      Value<int> version,
      Value<String> json,
      Value<int> rowid,
    });

class $$SpeciesIndexTableFilterComposer
    extends Composer<_$OfflineDatabase, $SpeciesIndexTable> {
  $$SpeciesIndexTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SpeciesIndexTableOrderingComposer
    extends Composer<_$OfflineDatabase, $SpeciesIndexTable> {
  $$SpeciesIndexTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SpeciesIndexTableAnnotationComposer
    extends Composer<_$OfflineDatabase, $SpeciesIndexTable> {
  $$SpeciesIndexTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$SpeciesIndexTableTableManager
    extends
        RootTableManager<
          _$OfflineDatabase,
          $SpeciesIndexTable,
          SpeciesRow,
          $$SpeciesIndexTableFilterComposer,
          $$SpeciesIndexTableOrderingComposer,
          $$SpeciesIndexTableAnnotationComposer,
          $$SpeciesIndexTableCreateCompanionBuilder,
          $$SpeciesIndexTableUpdateCompanionBuilder,
          (
            SpeciesRow,
            BaseReferences<_$OfflineDatabase, $SpeciesIndexTable, SpeciesRow>,
          ),
          SpeciesRow,
          PrefetchHooks Function()
        > {
  $$SpeciesIndexTableTableManager(
    _$OfflineDatabase db,
    $SpeciesIndexTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpeciesIndexTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpeciesIndexTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpeciesIndexTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SpeciesIndexCompanion(
                id: id,
                version: version,
                json: json,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> version = const Value.absent(),
                required String json,
                Value<int> rowid = const Value.absent(),
              }) => SpeciesIndexCompanion.insert(
                id: id,
                version: version,
                json: json,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SpeciesIndexTable, SpeciesRow>(table),
                  BaseReferences<
                    _$OfflineDatabase,
                    $SpeciesIndexTable,
                    SpeciesRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SpeciesIndexTableProcessedTableManager =
    ProcessedTableManager<
      _$OfflineDatabase,
      $SpeciesIndexTable,
      SpeciesRow,
      $$SpeciesIndexTableFilterComposer,
      $$SpeciesIndexTableOrderingComposer,
      $$SpeciesIndexTableAnnotationComposer,
      $$SpeciesIndexTableCreateCompanionBuilder,
      $$SpeciesIndexTableUpdateCompanionBuilder,
      (
        SpeciesRow,
        BaseReferences<_$OfflineDatabase, $SpeciesIndexTable, SpeciesRow>,
      ),
      SpeciesRow,
      PrefetchHooks Function()
    >;
typedef $$SyncMetaTableCreateCompanionBuilder =
    SyncMetaCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SyncMetaTableUpdateCompanionBuilder =
    SyncMetaCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SyncMetaTableFilterComposer
    extends Composer<_$OfflineDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetaTableOrderingComposer
    extends Composer<_$OfflineDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$OfflineDatabase, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncMetaTableTableManager
    extends
        RootTableManager<
          _$OfflineDatabase,
          $SyncMetaTable,
          MetaRow,
          $$SyncMetaTableFilterComposer,
          $$SyncMetaTableOrderingComposer,
          $$SyncMetaTableAnnotationComposer,
          $$SyncMetaTableCreateCompanionBuilder,
          $$SyncMetaTableUpdateCompanionBuilder,
          (MetaRow, BaseReferences<_$OfflineDatabase, $SyncMetaTable, MetaRow>),
          MetaRow,
          PrefetchHooks Function()
        > {
  $$SyncMetaTableTableManager(_$OfflineDatabase db, $SyncMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncMetaTable, MetaRow>(table),
                  BaseReferences<_$OfflineDatabase, $SyncMetaTable, MetaRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$OfflineDatabase,
      $SyncMetaTable,
      MetaRow,
      $$SyncMetaTableFilterComposer,
      $$SyncMetaTableOrderingComposer,
      $$SyncMetaTableAnnotationComposer,
      $$SyncMetaTableCreateCompanionBuilder,
      $$SyncMetaTableUpdateCompanionBuilder,
      (MetaRow, BaseReferences<_$OfflineDatabase, $SyncMetaTable, MetaRow>),
      MetaRow,
      PrefetchHooks Function()
    >;

class $OfflineDatabaseManager {
  final _$OfflineDatabase _db;
  $OfflineDatabaseManager(this._db);
  $$TrailIndexTableTableManager get trailIndex =>
      $$TrailIndexTableTableManager(_db, _db.trailIndex);
  $$SpeciesIndexTableTableManager get speciesIndex =>
      $$SpeciesIndexTableTableManager(_db, _db.speciesIndex);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
}
