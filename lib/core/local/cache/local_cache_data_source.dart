import 'package:drift/drift.dart';
import 'package:yiraclinics/core/local/database/app_database.dart';

abstract class LocalCacheDataSource {
  Future<String?> getCachedResponse(String cacheKey, {Duration maxCacheAge});
  Future<void> saveResponse(String cacheKey, String rawJson);
  Future<void> clearCache(String cacheKey);
  Future<void> clearAllCache();
}

class LocalCacheDataSourceImpl implements LocalCacheDataSource {
  final AppDatabase _db;
  LocalCacheDataSourceImpl(this._db);

  @override
  Future<String?> getCachedResponse(
      String cacheKey, {
        Duration maxCacheAge = const Duration(hours: 24),
      }) async {
    final record = await (_db.select(_db.networkCacheTable)
      ..where((tbl) => tbl.cacheKey.equals(cacheKey)))
        .getSingleOrNull();

    if (record == null) return null;

    final difference = DateTime.now().difference(record.cachedAt);
    if (difference > maxCacheAge) {
      await clearCache(cacheKey);
      return null;
    }

    return record.responseBody;
  }

  @override
  Future<void> saveResponse(String cacheKey, String rawJson) async {
    await _db.into(_db.networkCacheTable).insertOnConflictUpdate(
      NetworkCacheTableCompanion(
        cacheKey: Value(cacheKey),
        responseBody: Value(rawJson),
        cachedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> clearCache(String cacheKey) async {
    await (_db.delete(_db.networkCacheTable)
      ..where((tbl) => tbl.cacheKey.equals(cacheKey)))
        .go();
  }

  @override
  Future<void> clearAllCache() async {
    await _db.delete(_db.networkCacheTable).go();
  }
}