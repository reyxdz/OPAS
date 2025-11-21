import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

/// Connectivity Service
/// Handles offline detection and local caching of API responses
class ConnectivityService {
  static const String _cachePrefix = 'cache_';
  static const String _cacheTimestampPrefix = 'cache_ts_';
  static const Duration _defaultCacheDuration = Duration(hours: 24);

  late SharedPreferences _prefs;

  ConnectivityService._();

  static final ConnectivityService _instance = ConnectivityService._();

  factory ConnectivityService() {
    return _instance;
  }

  /// Initialize the service
  static Future<void> initialize() async {
    _instance._prefs = await SharedPreferences.getInstance();
  }

  /// Check if a request should use cached data (simulated offline check)
  /// In a real app, use connectivity_plus package
  bool isOffline() {
    // This is a basic implementation. In production, integrate connectivity_plus:
    // final connectivityResult = await (Connectivity().checkConnectivity());
    // return connectivityResult == ConnectivityResult.none;
    return false; // For now, assume always online
  }

  /// Cache API response
  Future<void> cacheResponse(
    String endpoint,
    dynamic responseData, {
    Duration? duration,
  }) async {
    try {
      final key = _cachePrefix + endpoint;
      final timestampKey = _cacheTimestampPrefix + endpoint;
      // ignore: unused_local_variable
      final cacheDuration = duration ?? _defaultCacheDuration;

      // Store response
      if (responseData is String) {
        await _prefs.setString(key, responseData);
      } else {
        await _prefs.setString(key, jsonEncode(responseData));
      }

      // Store timestamp
      await _prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Silently fail - caching is not critical
    }
  }

  /// Retrieve cached response
  dynamic getCachedResponse(String endpoint) {
    try {
      final key = _cachePrefix + endpoint;
      final cached = _prefs.getString(key);
      if (cached == null) return null;

      // Check if cache is still valid
      if (!_isCacheValid(endpoint)) {
        clearCache(endpoint);
        return null;
      }

      // Try to parse as JSON
      try {
        return jsonDecode(cached);
      } catch (e) {
        return cached; // Return as string if not JSON
      }
    } catch (e) {
      return null;
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid(String endpoint) {
    try {
      final timestampKey = _cacheTimestampPrefix + endpoint;
      final timestamp = _prefs.getInt(timestampKey);
      if (timestamp == null) return false;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final expiryTime = cacheTime.add(_defaultCacheDuration);
      return DateTime.now().isBefore(expiryTime);
    } catch (e) {
      return false;
    }
  }

  /// Clear specific cache entry
  Future<void> clearCache(String endpoint) async {
    try {
      final key = _cachePrefix + endpoint;
      final timestampKey = _cacheTimestampPrefix + endpoint;
      await _prefs.remove(key);
      await _prefs.remove(timestampKey);
    } catch (e) {
      // Silently fail
    }
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    try {
      final keys = _prefs.getKeys().toList();
      for (final key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_cacheTimestampPrefix)) {
          await _prefs.remove(key);
        }
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Get cache expiry time
  Duration? getCacheExpiry(String endpoint) {
    try {
      final timestampKey = _cacheTimestampPrefix + endpoint;
      final timestamp = _prefs.getInt(timestampKey);
      if (timestamp == null) return null;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final expiryTime = cacheTime.add(_defaultCacheDuration);
      final remaining = expiryTime.difference(DateTime.now());

      return remaining.isNegative ? Duration.zero : remaining;
    } catch (e) {
      return null;
    }
  }

  /// Wait for network (stub for production use)
  Future<bool> waitForNetwork({Duration timeout = const Duration(seconds: 30)}) async {
    // In production, implement actual network waiting with connectivity_plus
    return Future.delayed(Duration.zero, () => true);
  }
}

/// Offline Storage for list data (with list caching)
class OfflineListStorage {
  static const String _listCachePrefix = 'list_cache_';
  static const String _listTimestampPrefix = 'list_ts_';

  late SharedPreferences _prefs;

  OfflineListStorage._();

  static final OfflineListStorage _instance = OfflineListStorage._();

  factory OfflineListStorage() {
    return _instance;
  }

  /// Initialize the storage
  static Future<void> initialize() async {
    _instance._prefs = await SharedPreferences.getInstance();
  }

  /// Cache list data
  Future<void> cacheList(String key, List<dynamic> data) async {
    try {
      final cacheKey = _listCachePrefix + key;
      final timestampKey = _listTimestampPrefix + key;

      await _prefs.setString(cacheKey, jsonEncode(data));
      await _prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      /// Silently fail
    }
  }

  /// Retrieve cached list
  List<dynamic>? getCachedList(String key) {
    try {
      final cacheKey = _listCachePrefix + key;
      final cached = _prefs.getString(cacheKey);
      if (cached == null) return null;

      return jsonDecode(cached) as List<dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Clear list cache
  Future<void> clearList(String key) async {
    try {
      final cacheKey = _listCachePrefix + key;
      final timestampKey = _listTimestampPrefix + key;
      await _prefs.remove(cacheKey);
      await _prefs.remove(timestampKey);
    } catch (e) {
      // Silently fail
    }
  }

  /// Clear all list cache
  Future<void> clearAllLists() async {
    try {
      final keys = _prefs.getKeys().toList();
      for (final key in keys) {
        if (key.startsWith(_listCachePrefix) || key.startsWith(_listTimestampPrefix)) {
          await _prefs.remove(key);
        }
      }
    } catch (e) {
      // Silently fail
    }
  }
}
