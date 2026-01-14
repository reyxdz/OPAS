import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:opas_flutter/core/config/backend_config.dart';

class ApiService {
  // Use configuration from backend_config.dart
  static final List<String> _possibleBaseUrls = BackendConfig.possibleBackendUrls;

  static String? _cachedBaseUrl; // Cache the working URL

  /// Get the base URL, trying to find a working connection
  static String get baseUrl {
    // If we already found a working URL, use it
    if (_cachedBaseUrl != null) {
      return _cachedBaseUrl!;
    }

    // For web, always use localhost
    if (kIsWeb) {
      _cachedBaseUrl = 'http://localhost:${BackendConfig.port}${BackendConfig.apiPath}';
      return _cachedBaseUrl!;
    }

    // For mobile, start with trying localhost first, then other options
    // This will be validated on first API call
    _cachedBaseUrl = _possibleBaseUrls[0]; // Start with localhost
    return _cachedBaseUrl!;
  }

  /// Try to find a working backend URL by testing each possible URL in parallel
  static Future<String> findWorkingUrl() async {
    debugPrint('🔍 Starting parallel URL discovery...');
    
    // Create concurrent requests to all URLs with aggressive timeout
    final futures = _possibleBaseUrls.asMap().entries.map((entry) async {
      final index = entry.key;
      final url = entry.value;
      
      try {
        // Test with a simple GET to the base API URL
        // This checks connectivity without requiring valid credentials
        debugPrint('Testing [$index] $url...');
        
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: BackendConfig.singleRequestTimeout));

        // If we get ANY response (200, 404, 405, etc), the server is reachable
        // 404 is actually good - it means Django is responding
        debugPrint('  ✅ Got response ${response.statusCode} from $url');
        return {'url': url, 'priority': 10 - index, 'statusCode': response.statusCode};
      } catch (e) {
        // Connection errors are expected during discovery
        debugPrint('  ❌ [$index] Connection failed: ${e.toString().split('\n').first}');
        return null;
      }
    });

    // Wait for all requests with a reasonable timeout
    try {
      final results = await Future.wait(futures, eagerError: false)
          .timeout(const Duration(seconds: BackendConfig.totalDiscoveryTimeout));
      
      // Filter null results and sort by priority
      final validResults = results
          .where((r) => r != null)
          .cast<Map<String, dynamic>>()
          .toList()
          ..sort((a, b) => (b['priority'] as int).compareTo(a['priority'] as int));

      if (validResults.isNotEmpty) {
        final workingUrl = validResults.first['url'] as String;
        final statusCode = validResults.first['statusCode'] as int;
        _cachedBaseUrl = workingUrl;
        debugPrint('🎯 Using backend URL: $workingUrl (status: $statusCode)');
        return workingUrl;
      }
    } catch (e) {
      debugPrint('⚠️ Timeout during parallel URL discovery: $e');
    }

    // If nothing works, throw an error with instructions
    throw Exception(
      'Could not connect to backend. Tried: ${_possibleBaseUrls.join(", ")}. '
      'Make sure Django is running with: ${BackendConfig.djangoRunCommand} '
      'and update machineIp in lib/core/config/backend_config.dart if needed.'
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
      ).timeout(const Duration(seconds: BackendConfig.apiCallTimeout));

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
      ).timeout(const Duration(seconds: BackendConfig.apiCallTimeout));

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
          final workingUrl = await findWorkingUrl();
          
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
      debugPrint('🔐 Login Request:');
      debugPrint('  URL: $baseUrl/auth/login/');
      debugPrint('  Phone: $phoneNumber');
      debugPrint('  Password: ${password.replaceAll(RegExp(r'.'), '*')}');
      
      final requestBody = {'phone_number': phoneNumber, 'password': password};
      debugPrint('  Body: $requestBody');
      
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: BackendConfig.apiCallTimeout));

      debugPrint('🔐 Login Response Status: ${response.statusCode}');
      debugPrint('🔐 Login Response Body (first 500 chars): ${response.body.substring(0, (response.body.length < 500) ? response.body.length : 500)}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('🔐 Login successful, user role: ${responseData['role']}');
        return responseData;
      } else {
        // try to decode error body, otherwise use raw body
        try {
          final errorData = jsonDecode(response.body);
          debugPrint('🔐 Login error response: $errorData');
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
          final workingUrl = await findWorkingUrl();
          
          // Retry with working URL
          final retryResponse = await http
              .post(
                Uri.parse('$workingUrl/auth/login/'),
                headers: {'Content-Type': 'application/json'},
                body:
                    jsonEncode({'phone_number': phoneNumber, 'password': password}),
              )
              .timeout(const Duration(seconds: BackendConfig.apiCallTimeout));

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
