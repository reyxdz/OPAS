import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';

/// Admin Product Approval Service
/// Handles all admin-side operations for product approvals
/// 
/// Implements:
/// - List pending products awaiting approval
/// - Approve products to make them active
/// - Reject products with reason
class ProductApprovalService {
  static String get _baseUrl => ApiService.baseUrl;
  static const String _endpoint = '/admin/products';
  static const Duration _timeout = Duration(seconds: 30);

  /// Get list of pending products
  /// 
  /// Returns: List of products with PENDING status
  /// 
  /// Throws:
  /// - 401: Unauthorized (no/invalid token)
  /// - 403: Forbidden (not admin role)
  /// - 500: Server error
  static Future<Map<String, dynamic>> getPendingProducts() async {
    try {
      // Get access token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access');
      if (token == null) {
        throw 'Authentication token not found. Please log in.';
      }

      // Make request
      final response = await http
          .get(
            Uri.parse('$_baseUrl$_endpoint/pending/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(_timeout);

      // Handle response
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw 'Unauthorized: Authentication token expired. Please log in again.';
      } else if (response.statusCode == 403) {
        throw 'Forbidden: You do not have permission to view pending products.';
      } else {
        throw 'Failed to load pending products: Server error (${response.statusCode})';
      }
    } catch (e) {
      throw 'Error loading pending products: $e';
    }
  }

  /// Approve a product
  /// 
  /// Parameters:
  /// - productId: ID of product to approve
  /// 
  /// Returns: Updated product data
  /// 
  /// Throws:
  /// - 401: Unauthorized
  /// - 403: Forbidden
  /// - 404: Product not found
  /// - 500: Server error
  static Future<Map<String, dynamic>> approveProduct(int productId) async {
    try {
      // Get access token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access');
      if (token == null) {
        throw 'Authentication token not found. Please log in.';
      }

      // Make request
      final response = await http
          .post(
            Uri.parse('$_baseUrl$_endpoint/$productId/approve/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(_timeout);

      // Handle response
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw 'Unauthorized: Authentication token expired. Please log in again.';
      } else if (response.statusCode == 403) {
        throw 'Forbidden: You do not have permission to approve products.';
      } else if (response.statusCode == 404) {
        throw 'Product not found.';
      } else {
        throw 'Failed to approve product: Server error (${response.statusCode})';
      }
    } catch (e) {
      throw 'Error approving product: $e';
    }
  }

  /// Reject a product
  /// 
  /// Parameters:
  /// - productId: ID of product to reject
  /// - reason: Reason for rejection
  /// 
  /// Returns: Updated product data
  /// 
  /// Throws:
  /// - 400: Invalid data (missing reason, etc.)
  /// - 401: Unauthorized
  /// - 403: Forbidden
  /// - 404: Product not found
  /// - 500: Server error
  static Future<Map<String, dynamic>> rejectProduct(
    int productId, {
    required String reason,
  }) async {
    try {
      // Validate input
      if (reason.trim().isEmpty) {
        throw 'Rejection reason is required.';
      }

      // Get access token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access');
      if (token == null) {
        throw 'Authentication token not found. Please log in.';
      }

      // Prepare payload
      final payload = {
        'reason': reason.trim(),
      };

      // Make request
      final response = await http
          .post(
            Uri.parse('$_baseUrl$_endpoint/$productId/reject/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      // Handle response
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw _extractErrors(error);
      } else if (response.statusCode == 401) {
        throw 'Unauthorized: Authentication token expired. Please log in again.';
      } else if (response.statusCode == 403) {
        throw 'Forbidden: You do not have permission to reject products.';
      } else if (response.statusCode == 404) {
        throw 'Product not found.';
      } else {
        throw 'Failed to reject product: Server error (${response.statusCode})';
      }
    } catch (e) {
      throw 'Error rejecting product: $e';
    }
  }

  /// Extract error messages from API error response
  static String _extractErrors(Map<String, dynamic> errorData) {
    final errors = <String>[];

    errorData.forEach((key, value) {
      if (value is List) {
        for (var item in value) {
          errors.add('$key: $item');
        }
      } else if (value is Map) {
        errors.add('$key: ${value.toString()}');
      } else {
        errors.add('$key: $value');
      }
    });

    return errors.isEmpty ? 'Unknown error occurred' : errors.join(', ');
  }
}
