import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  static ApiService get instance => _instance;

  static const String baseUrl = 'http://localhost:8000/api/v1';
  
  ApiService._internal();

  /// Get request
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final finalUri = queryParameters != null && queryParameters.isNotEmpty
          ? uri.replace(queryParameters: queryParameters)
          : uri;

      final response = await http.get(
        finalUri,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Post request
  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: body is String ? body : json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        throw Exception('Failed to post data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Put request
  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: body is String ? body : json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        throw Exception('Failed to update data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Delete request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.statusCode == 200 ? json.decode(response.body) : null;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        throw Exception('Failed to delete: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Register FCM token
  Future<bool> registerFCMToken(String token) async {
    try {
      await post(
        '/users/fcm-token/',
        body: {'token': token},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Log notification event
  Future<bool> logNotification({
    required String notificationId,
    required String type,
    required String status,
    required String timestamp,
  }) async {
    try {
      await post(
        '/notifications/log/',
        body: {
          'notification_id': notificationId,
          'type': type,
          'status': status,
          'timestamp': timestamp,
        },
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
