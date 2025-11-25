import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';
import '../models/admin_registration_list_model.dart';

/// Admin Registration Service
/// Handles all admin-side operations for seller registrations
/// 
/// Implements:
/// - List pending/approved/rejected registrations with filtering and pagination
/// - Get registration details with full information
/// - Approve registrations with optional admin notes
/// - Reject registrations with reason and notes
/// - Request more information from sellers
/// - CORE PRINCIPLES: Resource Management, Input Validation, Authorization, Idempotency
class SellerRegistrationAdminService {
  static String get _baseUrl => ApiService.baseUrl;
  static const String _endpoint = '/admin/sellers/registrations';
  static const Duration _timeout = Duration(seconds: 30);

  /// Get list of registrations with optional filters
  /// 
  /// Parameters:
  /// - status: Filter by status (PENDING, APPROVED, REJECTED, REQUEST_MORE_INFO)
  /// - page: Pagination page number (default 1)
  /// - pageSize: Items per page (default 20)
  /// - search: Search by buyer name or email
  /// - sortBy: Sort field (submitted_at, days_pending, buyer_name)
  /// - sortOrder: Sort direction (asc, desc)
  /// 
  /// Returns: List of AdminRegistrationListItem
  /// 
  /// Throws:
  /// - 400: Invalid filter parameters
  /// - 401: Unauthorized (no/invalid token)
  /// - 403: Forbidden (not admin role)
  /// - 500: Server error
  static Future<List<AdminRegistrationListItem>> getRegistrationsList({
    String? status,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      // Get access token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access');
      if (token == null) {
        throw 'Authentication token not found. Please log in.';
      }

      // Build query parameters
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      // Add optional filters
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sort_by'] = sortBy;
      }
      if (sortOrder != null && sortOrder.isNotEmpty) {
        queryParams['sort_order'] = sortOrder;
      }

      // Build URL with query parameters
      final uri = Uri.parse('$_baseUrl$_endpoint/')
          .replace(queryParameters: queryParams);

      // Make request
      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(_timeout);

      // Handle response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List? ?? [];

        return results
            .map((item) => AdminRegistrationListItem.fromJson(
              item as Map<String, dynamic>,
            ))
            .toList();
      } else if (response.statusCode == 401) {
        throw 'Unauthorized: Authentication token expired. Please log in again.';
      } else if (response.statusCode == 403) {
        throw 'Forbidden: You do not have permission to view registrations.';
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw 'Invalid filter parameters: ${error['detail'] ?? 'Unknown error'}';
      } else {
        throw 'Failed to load registrations: Server error (${response.statusCode})';
      }
    } catch (e) {
      throw 'Error loading registrations: $e';
    }
  }

  /// Get detailed registration information
  /// 
  /// Parameters:
  /// - registrationId: ID of the registration to retrieve
  /// 
  /// Returns: AdminRegistrationDetail with full information
  /// 
  /// Throws:
  /// - 401: Unauthorized
  /// - 403: Forbidden (not admin or not authorized)
  /// - 404: Registration not found
  /// - 500: Server error
  static Future<AdminRegistrationDetail> getRegistrationDetails(
    int registrationId,
  ) async {
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
            Uri.parse('$_baseUrl$_endpoint/$registrationId/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(_timeout);

      // Handle response
      if (response.statusCode == 200) {
        return AdminRegistrationDetail.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else if (response.statusCode == 401) {
        throw 'Unauthorized: Authentication token expired. Please log in again.';
      } else if (response.statusCode == 403) {
        throw 'Forbidden: You do not have permission to view this registration.';
      } else if (response.statusCode == 404) {
        throw 'Registration not found.';
      } else {
        throw 'Failed to load registration details: Server error (${response.statusCode})';
      }
    } catch (e) {
      throw 'Error loading registration details: $e';
    }
  }

  /// Approve a registration
  /// 
  /// Parameters:
  /// - registrationId: ID of registration to approve
  /// - adminNotes: Optional notes from admin
  /// 
  /// Returns: Updated AdminRegistrationDetail
  /// 
  /// Throws:
  /// - 400: Invalid data
  /// - 401: Unauthorized
  /// - 403: Forbidden
  /// - 404: Registration not found
  /// - 500: Server error
  static Future<AdminRegistrationDetail> approveRegistration(
    int registrationId, {
    String? adminNotes,
  }) async {
    try {
      // Get access token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access');
      if (token == null) {
        throw 'Authentication token not found. Please log in.';
      }

      // Prepare payload
      final payload = {
        'admin_notes': adminNotes?.trim() ?? '',
      };

      // Make request
      final response = await http
          .post(
            Uri.parse('$_baseUrl$_endpoint/$registrationId/approve/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      // Handle response
      if (response.statusCode == 200) {
        return AdminRegistrationDetail.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw _extractErrors(error);
      } else if (response.statusCode == 401) {
        throw 'Unauthorized: Authentication token expired. Please log in again.';
      } else if (response.statusCode == 403) {
        throw 'Forbidden: You do not have permission to approve registrations.';
      } else if (response.statusCode == 404) {
        throw 'Registration not found.';
      } else {
        throw 'Failed to approve registration: Server error (${response.statusCode})';
      }
    } catch (e) {
      throw 'Error approving registration: $e';
    }
  }

  /// Reject a registration
  /// 
  /// Parameters:
  /// - registrationId: ID of registration to reject
  /// - rejectionReason: Reason for rejection
  /// - adminNotes: Additional notes from admin
  /// 
  /// Returns: Updated AdminRegistrationDetail
  /// 
  /// Throws:
  /// - 400: Invalid data (missing reason, etc.)
  /// - 401: Unauthorized
  /// - 403: Forbidden
  /// - 404: Registration not found
  /// - 500: Server error
  static Future<AdminRegistrationDetail> rejectRegistration(
    int registrationId, {
    required String rejectionReason,
    String? adminNotes,
  }) async {
    try {
      // Validate input
      if (rejectionReason.trim().isEmpty) {
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
        'rejection_reason': rejectionReason.trim(),
        'admin_notes': adminNotes?.trim() ?? '',
      };

      // Make request
      final response = await http
          .post(
            Uri.parse('$_baseUrl$_endpoint/$registrationId/reject/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      // Handle response
      if (response.statusCode == 200) {
        return AdminRegistrationDetail.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw _extractErrors(error);
      } else if (response.statusCode == 401) {
        throw 'Unauthorized: Authentication token expired. Please log in again.';
      } else if (response.statusCode == 403) {
        throw 'Forbidden: You do not have permission to reject registrations.';
      } else if (response.statusCode == 404) {
        throw 'Registration not found.';
      } else {
        throw 'Failed to reject registration: Server error (${response.statusCode})';
      }
    } catch (e) {
      throw 'Error rejecting registration: $e';
    }
  }

  /// Request more information from seller
  /// 
  /// Parameters:
  /// - registrationId: ID of registration
  /// - requiredInfo: Description of required information
  /// - deadlineInDays: Days until deadline (default 7)
  /// - adminNotes: Additional notes
  /// 
  /// Returns: Updated AdminRegistrationDetail
  /// 
  /// Throws:
  /// - 400: Invalid data
  /// - 401: Unauthorized
  /// - 403: Forbidden
  /// - 404: Registration not found
  /// - 500: Server error
  static Future<AdminRegistrationDetail> requestMoreInfo(
    int registrationId, {
    required String requiredInfo,
    int deadlineInDays = 7,
    String? adminNotes,
  }) async {
    try {
      // Validate input
      if (requiredInfo.trim().isEmpty) {
        throw 'Required information description is required.';
      }

      // Get access token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access');
      if (token == null) {
        throw 'Authentication token not found. Please log in.';
      }

      // Prepare payload
      final payload = {
        'required_info': requiredInfo.trim(),
        'deadline_in_days': deadlineInDays,
        'admin_notes': adminNotes?.trim() ?? '',
      };

      // Make request
      final response = await http
          .post(
            Uri.parse('$_baseUrl$_endpoint/$registrationId/request-info/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      // Handle response
      if (response.statusCode == 200) {
        return AdminRegistrationDetail.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw _extractErrors(error);
      } else if (response.statusCode == 401) {
        throw 'Unauthorized: Authentication token expired. Please log in again.';
      } else if (response.statusCode == 403) {
        throw 'Forbidden: You do not have permission to request information.';
      } else if (response.statusCode == 404) {
        throw 'Registration not found.';
      } else {
        throw 'Failed to request information: Server error (${response.statusCode})';
      }
    } catch (e) {
      throw 'Error requesting more information: $e';
    }
  }

  /// Extract error messages from API error response
  /// Converts nested error objects to readable user messages
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
