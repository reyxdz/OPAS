import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // Possible backend URLs for different emulators
  // Web (Edge/Chrome): localhost
  // Mobile (Android Phone): Try common local network patterns
  static const List<String> _possibleBaseUrls = [
    'http://localhost:8000/api',      // Web/localhost
    'http://127.0.0.1:8000/api',      // Fallback localhost
    'http://10.0.2.2:8000/api',       // Android emulator special IP
    'http://10.104.199.34:8000/api',  // Current machine IP (Update this when network changes)
    'http://10.207.234.34:8000/api',  // Alternative machine IP
    'http://192.168.1.1:8000/api',    // Common router IP
    'http://192.168.1.100:8000/api',  // Common local network
    'http://172.16.0.1:8000/api',     // Docker/VM network
  ];

  static String? _cachedBaseUrl; // Cache the working URL

  /// Get the base URL, trying to find a working connection
  static String get baseUrl {
    // If we already found a working URL, use it
    if (_cachedBaseUrl != null) {
      return _cachedBaseUrl!;
    }

    // For web, always use localhost
    if (kIsWeb) {
      _cachedBaseUrl = 'http://localhost:8000/api';
      return _cachedBaseUrl!;
    }

    // For mobile, start with network IP since localhost won't work
    // This will be validated on first API call
    _cachedBaseUrl = _possibleBaseUrls[3]; // Start with current known network IP (10.104.199.34)
    return _cachedBaseUrl!;
  }

  /// Try to find a working backend URL by testing each possible URL
  static Future<String> _findWorkingUrl() async {
    for (final url in _possibleBaseUrls) {
      try {
        final testUrl = '$url/auth/login/';
        final response = await http
            .post(
              Uri.parse(testUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'phone_number': 'test', 'password': 'test'}),
            )
            .timeout(const Duration(seconds: 5));

        // If we get ANY response (even 400/401), the server is reachable
        if (response.statusCode != 0) {
          _cachedBaseUrl = url;
          debugPrint('✅ Found working backend URL: $url');
          return url;
        }
      } catch (e) {
        debugPrint('❌ Failed to connect to $url: $e');
        continue;
      }
    }

    // If nothing works, throw an error
    throw Exception(
      'Could not connect to backend. Tried: ${_possibleBaseUrls.join(", ")}. '
      'Make sure Django is running with: python manage.py runserver 0.0.0.0:8000'
    );
  }

  /// Reset the cached URL (useful when switching emulators)
  static void resetCachedUrl() {
    _cachedBaseUrl = null;
    debugPrint('🔄 Cleared cached backend URL');
  }

  static Future<void> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh') ?? '';

      if (refreshToken.isEmpty) {
        throw Exception('No refresh token available');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await prefs.setString('access', data['access'] ?? '');
      } else {
        throw Exception('Failed to refresh token: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to refresh token: $e');
    }
  }

  static Future<Map<String, dynamic>> registerUser(
      Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData.toString());
      }
    } catch (e) {
      // Check if this is a connection error (socket exception, etc)
      final errorStr = e.toString();
      if (errorStr.contains('Connection refused') || 
          errorStr.contains('SocketException') ||
          errorStr.contains('Network is unreachable') ||
          errorStr.contains('ClientException')) {
        
        debugPrint('⚠️ Connection to $baseUrl failed, trying to find working backend...');
        try {
          final workingUrl = await _findWorkingUrl();
          
          // Retry with working URL
          final retryResponse = await http.post(
            Uri.parse('$workingUrl/auth/signup/'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(userData),
          ).timeout(const Duration(seconds: 30));

          if (retryResponse.statusCode == 201) {
            debugPrint('✅ Registration successful with $workingUrl');
            return jsonDecode(retryResponse.body);
          } else {
            final errorData = jsonDecode(retryResponse.body);
            throw Exception(errorData.toString());
          }
        } catch (retryError) {
          throw Exception('Failed to register: $retryError');
        }
      } else {
        throw Exception('Failed to register: $e');
      }
    }
  }

  static Future<Map<String, dynamic>> loginUser(
      String phoneNumber, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login/'),
            headers: {'Content-Type': 'application/json'},
            body:
                jsonEncode({'phone_number': phoneNumber, 'password': password}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        // try to decode error body, otherwise use raw body
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData.toString());
        } catch (_) {
          throw Exception(
              'Login failed: ${response.statusCode} ${response.body}');
        }
      }
    } catch (e) {
      // Check if this is a connection error (socket exception, timeout, etc)
      final errorStr = e.toString();
      debugPrint('❌ Login error: $errorStr');
      
      if (errorStr.contains('Connection refused') || 
          errorStr.contains('SocketException') ||
          errorStr.contains('TimeoutException') ||
          errorStr.contains('Network is unreachable') ||
          errorStr.contains('ClientException')) {
        
        debugPrint('⚠️ Connection to $baseUrl ($baseUrl) failed, trying to find working backend...');
        try {
          final workingUrl = await _findWorkingUrl();
          
          // Retry with working URL
          final retryResponse = await http
              .post(
                Uri.parse('$workingUrl/auth/login/'),
                headers: {'Content-Type': 'application/json'},
                body:
                    jsonEncode({'phone_number': phoneNumber, 'password': password}),
              )
              .timeout(const Duration(seconds: 30));

          if (retryResponse.statusCode == 200) {
            debugPrint('✅ Login successful with $workingUrl');
            return jsonDecode(retryResponse.body) as Map<String, dynamic>;
          } else {
            try {
              final errorData = jsonDecode(retryResponse.body);
              throw Exception(errorData.toString());
            } catch (_) {
              throw Exception(
                  'Login failed: ${retryResponse.statusCode} ${retryResponse.body}');
            }
          }
        } catch (retryError) {
          throw Exception('Failed to login: $retryError');
        }
      } else {
        throw Exception('Failed to login: $e');
      }
    }
  }

  static Future<Map<String, dynamic>> upgradeToSeller({
    required String accessToken,
    required String storeName,
    required String storeDescription,
  }) async {
    try {
      var token = accessToken;
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/upgrade-to-seller/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'store_name': storeName,
          'store_description': storeDescription,
        }),
      ).timeout(const Duration(seconds: 30));

      // If token expired, try to refresh and retry
      if (response.statusCode == 401) {
        final errorBody = jsonDecode(response.body);
        if (errorBody is Map && 
            errorBody['code'] == 'token_not_valid' && 
            errorBody['messages'] != null) {
          
          try {
            await _refreshToken();
            final prefs = await SharedPreferences.getInstance();
            token = prefs.getString('access') ?? '';
            
            // Retry with refreshed token
            final retryResponse = await http.post(
              Uri.parse('$baseUrl/users/upgrade-to-seller/'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'store_name': storeName,
                'store_description': storeDescription,
              }),
            ).timeout(const Duration(seconds: 15));

            if (retryResponse.statusCode == 200) {
              return jsonDecode(retryResponse.body) as Map<String, dynamic>;
            } else {
              throw Exception('Failed after token refresh: ${retryResponse.statusCode} ${retryResponse.body}');
            }
          } catch (e) {
            throw Exception('Token refresh failed: $e');
          }
        }
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData.toString());
        } catch (_) {
          throw Exception('Upgrade failed: ${response.statusCode} ${response.body}');
        }
      }
    } catch (e) {
      throw Exception('Failed to upgrade to seller: $e');
    }
  }

  static Future<Map<String, dynamic>> submitSellerApplication({
    required String accessToken,
    required String farmName,
    required String farmLocation,
    required String storeName,
    required String storeDescription,
    String? farmMunicipality,
    String? farmBarangay,
  }) async {
    try {
      var token = accessToken;
      
      final requestBody = {
        'farm_name': farmName,
        'farm_location': farmLocation,
        'store_name': storeName,
        'store_description': storeDescription,
      };
      
      // Add farm municipality and barangay if provided
      if (farmMunicipality != null && farmMunicipality.isNotEmpty) {
        requestBody['farm_municipality'] = farmMunicipality;
      }
      if (farmBarangay != null && farmBarangay.isNotEmpty) {
        requestBody['farm_barangay'] = farmBarangay;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/users/seller-application/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      // If token expired, try to refresh and retry
      if (response.statusCode == 401) {
        final errorBody = jsonDecode(response.body);
        if (errorBody is Map && 
            errorBody['code'] == 'token_not_valid' && 
            errorBody['messages'] != null) {

          try {
            await _refreshToken();
            final prefs = await SharedPreferences.getInstance();
            token = prefs.getString('access') ?? '';
            
            // Retry with refreshed token
            final retryResponse = await http.post(
              Uri.parse('$baseUrl/users/seller-application/'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(requestBody),
            ).timeout(const Duration(seconds: 30));

            if (retryResponse.statusCode == 201 || retryResponse.statusCode == 200) {
              return jsonDecode(retryResponse.body) as Map<String, dynamic>;
            } else {
              throw Exception('Failed after token refresh: ${retryResponse.statusCode} ${retryResponse.body}');
            }
          } catch (e) {
            throw Exception('Token refresh failed: $e');
          }
        }
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData.toString());
        } catch (_) {
          throw Exception('Application failed: ${response.statusCode} ${response.body}');
        }
      }
    } catch (e) {
      throw Exception('Failed to submit seller application: $e');
    }
  }

  static Future<Map<String, dynamic>?> getUserStatus({
    required String accessToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
