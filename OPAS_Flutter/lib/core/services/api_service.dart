import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.113.93.34:8000/api';

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
      ).timeout(const Duration(seconds: 15));

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
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData.toString());
      }
    } catch (e) {
      throw Exception('Failed to register: $e');
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
          .timeout(const Duration(seconds: 15));

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
      throw Exception('Failed to login: $e');
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
      ).timeout(const Duration(seconds: 15));

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
  }) async {
    try {
      var token = accessToken;

      final response = await http.post(
        Uri.parse('$baseUrl/users/seller-application/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'farm_name': farmName,
          'farm_location': farmLocation,
          'store_name': storeName,
          'store_description': storeDescription,
        }),
      ).timeout(const Duration(seconds: 15));

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
              body: jsonEncode({
                'farm_name': farmName,
                'farm_location': farmLocation,
                'store_name': storeName,
                'store_description': storeDescription,
              }),
            ).timeout(const Duration(seconds: 15));

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
}