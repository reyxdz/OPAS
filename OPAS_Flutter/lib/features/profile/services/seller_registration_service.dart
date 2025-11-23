import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/seller_registration_model.dart';

/// Seller Registration Service
/// Handles all API calls for seller registration workflow
/// 
/// CORE PRINCIPLES APPLIED:
/// - Resource Management: Minimal JSON payloads, efficient queries
/// - Input Validation: Server-side validation enforced in serializers
/// - Security: Bearer token authentication on all endpoints
/// - Idempotency: OneToOne constraint prevents duplicate registrations
/// - Rate Limiting: One registration per user enforced by backend
class SellerRegistrationService {
  static const String baseUrl = 'http://10.113.93.34:8000/api';
  static const String registrationEndpoint = '$baseUrl/sellers';

  /// Submit seller registration application
  /// 
  /// Requires:
  /// - farmName: Name of the farm (3+ characters)
  /// - farmLocation: Location of farm
  /// - farmSize: Size of farm
  /// - productsGrown: List of products (fruits, vegetables, livestock, others)
  /// - storeName: Store name (3+ characters)
  /// - storeDescription: Store description (10+ characters)
  /// - businessPermitFile: File for business permit
  /// - governmentIdFile: File for government ID
  /// - acceptedTerms: Must be true
  /// 
  /// Returns: SellerRegistration object if successful
  /// 
  /// Throws: Exception with error message
  static Future<SellerRegistration> submitRegistration({
    required String farmName,
    required String farmLocation,
    required String farmSize,
    required List<String> productsGrown,
    required String storeName,
    required String storeDescription,
    required String accessToken,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = accessToken.isNotEmpty
          ? accessToken
          : prefs.getString('access') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      final payload = {
        'farm_name': farmName.trim(),
        'farm_location': farmLocation.trim(),
        'farm_size': farmSize.trim(),
        'products_grown': productsGrown,
        'store_name': storeName.trim(),
        'store_description': storeDescription.trim(),
      };

      final response = await http.post(
        Uri.parse('$registrationEndpoint/register-application/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return SellerRegistration.fromJson(data);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errors = _extractErrors(errorData);
        throw Exception(errors);
      } else if (response.statusCode == 401) {
        throw Exception('Your session has expired. Please log in again.');
      } else if (response.statusCode == 403) {
        throw Exception('You are not authorized to perform this action.');
      } else {
        throw Exception(
            'Failed to submit registration. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to submit registration: $e');
    }
  }

  /// Get current user's registration status
  /// 
  /// Returns: SellerRegistration with status and documents
  /// Returns null if no registration found
  /// 
  /// Throws: Exception with error message
  static Future<SellerRegistration?> getMyRegistration(
      String accessToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = accessToken.isNotEmpty
          ? accessToken
          : prefs.getString('access') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      final response = await http.get(
        Uri.parse('$registrationEndpoint/my-registration/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData =
            jsonDecode(response.body) as Map<String, dynamic>;
        return SellerRegistration.fromJson(responseData);
      } else if (response.statusCode == 404) {
        return null; // No registration found
      } else if (response.statusCode == 401) {
        throw Exception('Your session has expired. Please log in again.');
      } else {
        throw Exception(
            'Failed to fetch registration status. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch registration status: $e');
    }
  }

  /// Get registration details by ID
  /// 
  /// Requires: registrationId
  /// Returns: Complete registration details with documents
  /// 
  /// Throws: Exception with error message (404 if not found)
  static Future<SellerRegistration> getRegistrationDetails(
    int registrationId,
    String accessToken,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = accessToken.isNotEmpty
          ? accessToken
          : prefs.getString('access') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      final response = await http.get(
        Uri.parse('$registrationEndpoint/$registrationId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return SellerRegistration.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Registration not found.');
      } else if (response.statusCode == 401) {
        throw Exception('Your session has expired. Please log in again.');
      } else if (response.statusCode == 403) {
        throw Exception(
            'You are not authorized to view this registration. (404)');
      } else {
        throw Exception(
            'Failed to fetch registration details. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch registration details: $e');
    }
  }

  /// Helper method to extract error messages from API response
  /// 
  /// Converts nested error objects to readable error messages
  static String _extractErrors(Map<String, dynamic> errorData) {
    final errors = <String>[];

    errorData.forEach((key, value) {
      if (value is List) {
        for (var error in value) {
          errors.add('$key: $error');
        }
      } else if (value is Map) {
        errors.add('$key: ${value.toString()}');
      } else {
        errors.add('$key: $value');
      }
    });

    return errors.isNotEmpty
        ? errors.join('\n')
        : 'An error occurred. Please try again.';
  }
}
