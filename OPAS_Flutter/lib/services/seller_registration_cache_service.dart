import 'dart:convert';
import 'dart:io' show Platform;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Import sqflite_common_ffi for desktop platforms
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Cache service for seller registration data with offline-first support
/// CORE PRINCIPLE: Resource Management - Efficient caching reduces API calls
/// CORE PRINCIPLE: Network Volatility - Stores data locally for offline access
class SellerRegistrationCacheService {
  static const String _dbName = 'opas_seller_registration_cache.db';
  static const String _registrationTable = 'registrations';
  static const String _admRegistrationsTable = 'admin_registrations';
  static const String _filtersTable = 'admin_filters';
  static const int _defaultTtlMinutes = 30; // Cache TTL in minutes
  static const int _maxCacheSize = 1000; // Max items to cache

  static final SellerRegistrationCacheService _instance =
      SellerRegistrationCacheService._internal();

  Database? _database;
  bool _isInitialized = false;
  static bool _factoryInitialized = false;

  SellerRegistrationCacheService._internal();

  factory SellerRegistrationCacheService() {
    return _instance;
  }

  /// Initialize database connection
  /// CORE PRINCIPLE: Resource Management - Lazy initialization
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize database factory for desktop platforms (Windows, Linux, macOS)
    if (!_factoryInitialized && _isDesktopPlatform()) {
      try {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        _factoryInitialized = true;
        print('✅ SQLite FFI initialized for desktop platform');
      } catch (e) {
        print('⚠️ SQLite FFI initialization warning: $e');
        _factoryInitialized = true; // Mark as attempted to avoid retry loop
      }
    }

    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: _createTables,
      );

      _isInitialized = true;
      print('✅ Database initialized successfully');
    } catch (e) {
      print('❌ Database initialization error: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Check if running on desktop platform
  static bool _isDesktopPlatform() {
    try {
      return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    } catch (e) {
      return false;
    }
  }

  /// Create all necessary tables
  Future<void> _createTables(Database db, int version) async {
    // Registrations cache table for buyer-side
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_registrationTable (
        id TEXT PRIMARY KEY,
        key TEXT UNIQUE,
        data TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        ttl_minutes INTEGER NOT NULL DEFAULT $_defaultTtlMinutes
      )
    ''');

    // Admin registrations cache table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_admRegistrationsTable (
        id TEXT PRIMARY KEY,
        filter_key TEXT,
        page INTEGER,
        data TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        ttl_minutes INTEGER NOT NULL DEFAULT $_defaultTtlMinutes,
        UNIQUE(filter_key, page)
      )
    ''');

    // Filter cache table for admin
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_filtersTable (
        id TEXT PRIMARY KEY,
        key TEXT UNIQUE,
        data TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Create indexes for performance
    // CORE PRINCIPLE: Database - Indexing for fast queries
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_registration_timestamp ON $_registrationTable(timestamp)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_admin_filter_key ON $_admRegistrationsTable(filter_key)');
  }

  /// Cache buyer's registration data
  /// CORE PRINCIPLE: Offline-First - Store locally for offline access
  Future<void> cacheBuyerRegistration(
      String registrationId, Map<String, dynamic> data) async {
    await initialize();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final key = 'buyer_registration_$registrationId';

    await _database!.insert(
      _registrationTable,
      {
        'id': registrationId,
        'key': key,
        'data': jsonEncode(data),
        'timestamp': timestamp,
        'ttl_minutes': _defaultTtlMinutes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Cleanup old cache if size exceeds limit
    // CORE PRINCIPLE: Memory Management - Prevent unbounded growth
    await _pruneIfNeeded(_registrationTable);
  }

  /// Get cached buyer registration
  /// CORE PRINCIPLE: Caching - Return cached data if valid
  Future<Map<String, dynamic>?> getBuyerRegistration(
      String registrationId) async {
    await initialize();
    final key = 'buyer_registration_$registrationId';

    final result = await _database!.query(
      _registrationTable,
      where: 'key = ?',
      whereArgs: [key],
    );

    if (result.isEmpty) return null;

    final row = result.first;
    if (_isCacheExpired(row)) {
      await clearBuyerRegistration(registrationId);
      return null;
    }

    return jsonDecode(row['data'] as String);
  }

  /// Clear buyer registration cache
  Future<void> clearBuyerRegistration(String registrationId) async {
    await initialize();
    final key = 'buyer_registration_$registrationId';

    await _database!.delete(
      _registrationTable,
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  /// Cache admin registrations list with pagination support
  /// CORE PRINCIPLE: Resource Management - Cache paginated results
  Future<void> cacheAdminRegistrationsList(
      String filterKey, int page, List<Map<String, dynamic>> data) async {
    await initialize();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cacheId = '${filterKey}_page_$page';

    await _database!.insert(
      _admRegistrationsTable,
      {
        'id': cacheId,
        'filter_key': filterKey,
        'page': page,
        'data': jsonEncode(data),
        'timestamp': timestamp,
        'ttl_minutes': _defaultTtlMinutes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _pruneIfNeeded(_admRegistrationsTable);
  }

  /// Get cached admin registrations for specific filter and page
  Future<List<Map<String, dynamic>>?> getAdminRegistrationsList(
      String filterKey, int page) async {
    await initialize();

    final result = await _database!.query(
      _admRegistrationsTable,
      where: 'filter_key = ? AND page = ?',
      whereArgs: [filterKey, page],
    );

    if (result.isEmpty) return null;

    final row = result.first;
    if (_isCacheExpired(row)) {
      await _database!.delete(
        _admRegistrationsTable,
        where: 'filter_key = ? AND page = ?',
        whereArgs: [filterKey, page],
      );
      return null;
    }

    final dataList = jsonDecode(row['data'] as String) as List;
    return dataList.cast<Map<String, dynamic>>();
  }

  /// Clear admin registrations for a specific filter (all pages)
  /// CORE PRINCIPLE: Cache Invalidation - Clear when filters change
  Future<void> clearAdminRegistrationsByFilter(String filterKey) async {
    await initialize();

    await _database!.delete(
      _admRegistrationsTable,
      where: 'filter_key = ?',
      whereArgs: [filterKey],
    );
  }

  /// Clear all admin registrations cache
  Future<void> clearAllAdminRegistrations() async {
    try {
      await initialize();
      if (_database != null) {
        final count = await _database!.delete(_admRegistrationsTable);
        print('✅ Cleared admin registrations cache: $count items deleted');
      }
    } catch (e) {
      // Log the error but don't crash - database caching is non-critical
      print('⚠️ Warning: Could not clear admin registrations cache: $e');
      // Don't rethrow - this is a non-critical operation
    }
  }

  /// Cache filter state
  /// CORE PRINCIPLE: State Preservation - Restore filter state
  Future<void> cacheFilterState(String key, Map<String, dynamic> filters) async {
    await initialize();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await _database!.insert(
      _filtersTable,
      {
        'id': key,
        'key': key,
        'data': jsonEncode(filters),
        'timestamp': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get cached filter state
  Future<Map<String, dynamic>?> getFilterState(String key) async {
    await initialize();

    final result = await _database!.query(
      _filtersTable,
      where: 'key = ?',
      whereArgs: [key],
    );

    if (result.isEmpty) return null;

    return jsonDecode(result.first['data'] as String);
  }

  /// Check if cache entry is expired
  bool _isCacheExpired(Map<String, dynamic> row) {
    final timestamp = row['timestamp'] as int;
    final ttlMinutes = (row['ttl_minutes'] as int?) ?? _defaultTtlMinutes;
    final expirationTime =
        DateTime.fromMillisecondsSinceEpoch(timestamp)
            .add(Duration(minutes: ttlMinutes));

    return DateTime.now().isAfter(expirationTime);
  }

  /// Prune cache if size exceeds limit
  /// CORE PRINCIPLE: Memory Management - Keep cache bounded
  Future<void> _pruneIfNeeded(String tableName) async {
    final count = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM $tableName'));

    if ((count ?? 0) > _maxCacheSize) {
      // Delete oldest entries
      await _database!.execute('''
        DELETE FROM $tableName 
        WHERE id IN (
          SELECT id FROM $tableName 
          ORDER BY timestamp ASC 
          LIMIT ${(count ?? 0) - _maxCacheSize}
        )
      ''');
    }
  }

  /// Clear all expired cache entries
  /// CORE PRINCIPLE: Resource Management - Cleanup expired data
  Future<void> clearExpiredCache() async {
    await initialize();

    final now = DateTime.now().millisecondsSinceEpoch;

    // Clear expired registrations
    await _database!.delete(
      _registrationTable,
      where:
          '(timestamp + (ttl_minutes * 60 * 1000)) < ?',
      whereArgs: [now],
    );

    // Clear expired admin registrations
    await _database!.delete(
      _admRegistrationsTable,
      where:
          '(timestamp + (ttl_minutes * 60 * 1000)) < ?',
      whereArgs: [now],
    );
  }

  /// Clear all cache data
  Future<void> clearAllCache() async {
    await initialize();

    await _database!.delete(_registrationTable);
    await _database!.delete(_admRegistrationsTable);
    await _database!.delete(_filtersTable);
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _isInitialized = false;
    }
  }

  /// Get cache statistics (for debugging)
  /// CORE PRINCIPLE: Developer Experience - Debug info
  Future<Map<String, dynamic>> getCacheStats() async {
    await initialize();

    final regCount = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM $_registrationTable'));
    final adminCount = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM $_admRegistrationsTable'));
    final filterCount = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM $_filtersTable'));

    return {
      'registrations': regCount ?? 0,
      'admin_registrations': adminCount ?? 0,
      'filters': filterCount ?? 0,
      'total': (regCount ?? 0) + (adminCount ?? 0) + (filterCount ?? 0),
    };
  }
}
