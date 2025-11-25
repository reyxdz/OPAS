import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/error_handler.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/retry_service.dart';
import '../../../core/services/api_service.dart';

/// Enhanced Seller Service with Error Handling & Caching
/// Wraps the base SellerService with comprehensive error handling,
/// retry logic with exponential backoff, and offline caching
class EnhancedSellerService {
  static String get baseUrl => ApiService.baseUrl;
  static const int maxRetries = 3;
  static const int initialDelayMs = 1000;

  static late final ConnectivityService _connectivityService;
  static late final OfflineListStorage _offlineStorage;

  /// Initialize services
  static Future<void> initialize() async {
    _connectivityService = ConnectivityService();
    _offlineStorage = OfflineListStorage();
    await ConnectivityService.initialize();
    await OfflineListStorage.initialize();
  }

  /// Get access token
  static Future<String> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access') ?? '';
    if (token.isEmpty) {
      throw UnauthorizedException(
        message: 'Session expired',
        details: 'Please log in again to continue.',
      );
    }
    return token;
  }

  /// Handle HTTP response status codes
  static void _handleResponseStatus(http.Response response, String endpoint) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return; // Success
    }

    // Handle error responses
    final exception = ErrorHandler.handleError(
      response.statusCode,
      response.body,
      endpoint: endpoint,
    );

    // Handle 401 by refreshing token and rethrowing
    if (exception is UnauthorizedException) {
      throw exception;
    }

    throw exception;
  }

  /// Parse JSON response with error handling
  static dynamic parseJsonResponse(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (e) {
      throw BadRequestException(
        message: 'Invalid server response',
        details: 'Failed to parse server response: $e',
      );
    }
  }

  /// Validate field-level errors from response
  static Map<String, String> extractFieldErrors(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final errors = <String, String>{};

      if (json.containsKey('errors') && json['errors'] is Map) {
        final fieldErrors = json['errors'] as Map<String, dynamic>;
        fieldErrors.forEach((field, value) {
          if (value is List && value.isNotEmpty) {
            errors[field] = value[0].toString();
          } else if (value is String) {
            errors[field] = value;
          }
        });
      }

      return errors;
    } catch (e) {
      return {};
    }
  }

  /// Clear all caches
  static Future<void> clearAllCaches() async {
    await _connectivityService.clearAllCache();
    await _offlineStorage.clearAllLists();
  }

  /// Clear specific endpoint cache
  static Future<void> clearCache(String endpoint) async {
    await _connectivityService.clearCache(endpoint);
  }

  /// Check cache validity
  static Duration? getCacheExpiry(String endpoint) {
    return _connectivityService.getCacheExpiry(endpoint);
  }

  /// Cache a list for offline access
  static Future<void> cacheList(String key, List<dynamic> data) async {
    await _offlineStorage.cacheList(key, data);
  }

  /// Get cached list
  static List<dynamic>? getCachedList(String key) {
    return _offlineStorage.getCachedList(key);
  }

  /// Make multipart request for file uploads
  static Future<http.Response> makeMultipartRequest(
    String method,
    String endpoint,
    Map<String, dynamic> fields, {
    List<http.MultipartFile>? files,
    bool useRetry = true,
  }) async {
    try {
      final token = await _getAccessToken();
      final url = Uri.parse('$baseUrl$endpoint');

      http.MultipartRequest request = http.MultipartRequest(method, url)
        ..headers['Authorization'] = 'Bearer $token';

      // Add fields
      fields.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Add files
      if (files != null) {
        request.files.addAll(files);
      }

      http.StreamedResponse streamResponse;

      if (useRetry) {
        streamResponse = await RetryService.retryWithBackoff(
          () => request.send().timeout(const Duration(seconds: 60)),
          maxRetries: maxRetries,
          shouldRetry: (e) => e is TimeoutException || e is NetworkException,
        );
      } else {
        streamResponse = await request.send().timeout(const Duration(seconds: 60));
      }

      final response = await http.Response.fromStream(streamResponse);
      _handleResponseStatus(response, endpoint);
      return response;
    } on APIException {
      rethrow;
    } catch (e) {
      throw ErrorHandler.handleNetworkError(e);
    }
  }

  /// Log error for debugging
  static void logError(APIException error, {String? context}) {
    if (context != null) {
      // Log context information
    }
    if (error.details != null) {
      // Log error details
    }
  }
}
