// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $NetworkCacheTableTable extends NetworkCacheTable
    with TableInfo<$NetworkCacheTableTable, NetworkCacheTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NetworkCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseBodyMeta = const VerificationMeta(
    'responseBody',
  );
  @override
  late final GeneratedColumn<String> responseBody = GeneratedColumn<String>(
    'response_body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [cacheKey, responseBody, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'network_cache_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<NetworkCacheTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('response_body')) {
      context.handle(
        _responseBodyMeta,
        responseBody.isAcceptableOrUnknown(
          data['response_body']!,
          _responseBodyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_responseBodyMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  NetworkCacheTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NetworkCacheTableData(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      responseBody: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_body'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $NetworkCacheTableTable createAlias(String alias) {
    return $NetworkCacheTableTable(attachedDatabase, alias);
  }
}

class NetworkCacheTableData extends DataClass
    implements Insertable<NetworkCacheTableData> {
  final String cacheKey;
  final String responseBody;
  final DateTime cachedAt;
  const NetworkCacheTableData({
    required this.cacheKey,
    required this.responseBody,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['response_body'] = Variable<String>(responseBody);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  NetworkCacheTableCompanion toCompanion(bool nullToAbsent) {
    return NetworkCacheTableCompanion(
      cacheKey: Value(cacheKey),
      responseBody: Value(responseBody),
      cachedAt: Value(cachedAt),
    );
  }

  factory NetworkCacheTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NetworkCacheTableData(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      responseBody: serializer.fromJson<String>(json['responseBody']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'responseBody': serializer.toJson<String>(responseBody),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  NetworkCacheTableData copyWith({
    String? cacheKey,
    String? responseBody,
    DateTime? cachedAt,
  }) => NetworkCacheTableData(
    cacheKey: cacheKey ?? this.cacheKey,
    responseBody: responseBody ?? this.responseBody,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  NetworkCacheTableData copyWithCompanion(NetworkCacheTableCompanion data) {
    return NetworkCacheTableData(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      responseBody: data.responseBody.present
          ? data.responseBody.value
          : this.responseBody,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NetworkCacheTableData(')
          ..write('cacheKey: $cacheKey, ')
          ..write('responseBody: $responseBody, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, responseBody, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NetworkCacheTableData &&
          other.cacheKey == this.cacheKey &&
          other.responseBody == this.responseBody &&
          other.cachedAt == this.cachedAt);
}

class NetworkCacheTableCompanion
    extends UpdateCompanion<NetworkCacheTableData> {
  final Value<String> cacheKey;
  final Value<String> responseBody;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const NetworkCacheTableCompanion({
    this.cacheKey = const Value.absent(),
    this.responseBody = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NetworkCacheTableCompanion.insert({
    required String cacheKey,
    required String responseBody,
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       responseBody = Value(responseBody);
  static Insertable<NetworkCacheTableData> custom({
    Expression<String>? cacheKey,
    Expression<String>? responseBody,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (responseBody != null) 'response_body': responseBody,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NetworkCacheTableCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? responseBody,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return NetworkCacheTableCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      responseBody: responseBody ?? this.responseBody,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (responseBody.present) {
      map['response_body'] = Variable<String>(responseBody.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NetworkCacheTableCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('responseBody: $responseBody, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NetworkCacheTableTable networkCacheTable =
      $NetworkCacheTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [networkCacheTable];
}

typedef $$NetworkCacheTableTableCreateCompanionBuilder =
    NetworkCacheTableCompanion Function({
      required String cacheKey,
      required String responseBody,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$NetworkCacheTableTableUpdateCompanionBuilder =
    NetworkCacheTableCompanion Function({
      Value<String> cacheKey,
      Value<String> responseBody,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$NetworkCacheTableTableFilterComposer
    extends Composer<_$AppDatabase, $NetworkCacheTableTable> {
  $$NetworkCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responseBody => $composableBuilder(
    column: $table.responseBody,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NetworkCacheTableTableOrderingComposer
    extends Composer<_$AppDatabase, $NetworkCacheTableTable> {
  $$NetworkCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responseBody => $composableBuilder(
    column: $table.responseBody,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NetworkCacheTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $NetworkCacheTableTable> {
  $$NetworkCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get responseBody => $composableBuilder(
    column: $table.responseBody,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$NetworkCacheTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NetworkCacheTableTable,
          NetworkCacheTableData,
          $$NetworkCacheTableTableFilterComposer,
          $$NetworkCacheTableTableOrderingComposer,
          $$NetworkCacheTableTableAnnotationComposer,
          $$NetworkCacheTableTableCreateCompanionBuilder,
          $$NetworkCacheTableTableUpdateCompanionBuilder,
          (
            NetworkCacheTableData,
            BaseReferences<
              _$AppDatabase,
              $NetworkCacheTableTable,
              NetworkCacheTableData
            >,
          ),
          NetworkCacheTableData,
          PrefetchHooks Function()
        > {
  $$NetworkCacheTableTableTableManager(
    _$AppDatabase db,
    $NetworkCacheTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NetworkCacheTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NetworkCacheTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NetworkCacheTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> responseBody = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NetworkCacheTableCompanion(
                cacheKey: cacheKey,
                responseBody: responseBody,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String responseBody,
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NetworkCacheTableCompanion.insert(
                cacheKey: cacheKey,
                responseBody: responseBody,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NetworkCacheTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NetworkCacheTableTable,
      NetworkCacheTableData,
      $$NetworkCacheTableTableFilterComposer,
      $$NetworkCacheTableTableOrderingComposer,
      $$NetworkCacheTableTableAnnotationComposer,
      $$NetworkCacheTableTableCreateCompanionBuilder,
      $$NetworkCacheTableTableUpdateCompanionBuilder,
      (
        NetworkCacheTableData,
        BaseReferences<
          _$AppDatabase,
          $NetworkCacheTableTable,
          NetworkCacheTableData
        >,
      ),
      NetworkCacheTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NetworkCacheTableTableTableManager get networkCacheTable =>
      $$NetworkCacheTableTableTableManager(_db, _db.networkCacheTable);
}
