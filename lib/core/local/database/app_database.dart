import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../constants/constants.dart';

part 'app_database.g.dart';

class NetworkCacheTable extends Table {
  // Houses your unique, custom-constructed endpoint + parameter tracking key
  TextColumn get cacheKey => text()();

  // Contains the raw JSON response payload string
  TextColumn get responseBody => text()();

  // Tracks exactly when this payload was saved for time-based eviction gates
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {cacheKey};
}

@DriftDatabase(tables: [NetworkCacheTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: dbName);
  }
}