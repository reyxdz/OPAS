import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:opas_flutter/features/admin_panel/services/admin_audit_trail_service.dart';

/// Admin Service Layer - Phase 3.1
/// 
/// Comprehensive API integration for admin panel operations across 6 feature domains:
/// - Seller Management (9 methods): governance & approval workflows
/// - Price Management (8 methods): market regulation & compliance
/// - OPAS Purchasing (9 methods): bulk purchasing & inventory
/// - Marketplace Oversight (4 methods): activity monitoring & alerts
/// - Analytics & Reporting (5 methods): insights & data export
/// - Notifications (5 methods): alerts & announcements
/// 
/// Total: 50+ service methods with clean architecture
/// Architecture: Service layer with error handling, logging, and type safety
/// Pattern: Static methods for API communication
/// Returns: Map<String, dynamic> for flexibility, List<dynamic> for collections
class AdminService {
  static const String baseUrl = 'http://localhost:8000/api';
  static const String adminEndpoint = '$baseUrl/admin';

  /// ============================================================================
  /// HELPER METHODS
  /// ============================================================================

  /// Get HTTP headers with auth token
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? prefs.getString('access') ?? '';

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  /// ============================================================================
  /// SELLER MANAGEMENT (9 methods)
  /// ============================================================================
  /// Operations: View sellers, approve/reject, suspend/reactivate, audit history

  /// Fetch all sellers with optional filtering and pagination
  /// 
  /// Parameters:
  ///   - status: Filter by PENDING/APPROVED/SUSPENDED (optional)
  ///   - page: Pagination page number (default: 1)
  ///   - search: Search by seller name/email (optional)
  /// 
  /// Returns: {sellers: [{id, name, email, status, registrationDate, ...}], total: int}
  static Future<Map<String, dynamic>> getSellers({
    String? status,
    int page = 1,
    String? search,
  }) async {
    try {
      String url = '$adminEndpoint/sellers/?page=$page';
      if (status != null) url += '&status=$status';
      if (search != null) url += '&search=${Uri.encodeComponent(search)}';

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to fetch sellers: ${response.statusCode}');
      }
    } catch (e) {
      return {'sellers': [], 'total': 0, 'error': e.toString()};
    }
  }

  /// Get detailed information about a specific seller
  /// 
  /// Parameters:
  ///   - id: Seller ID (required)
  /// 
  /// Returns: {id, name, email, phone, farmInfo, documents, registrationDate, status, ...}
  /// Includes: Personal info, farm details, all documents, approval history
  static Future<Map<String, dynamic>> getSellerDetails(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$adminEndpoint/sellers/$id/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 404) {
        throw Exception('Seller not found');
      } else {
        throw Exception('Failed to fetch seller details: ${response.statusCode}');
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Get list of sellers pending approval
  /// 
  /// Returns: [{id, name, email, submissionDate, documents, farmInfo}]
  /// Purpose: Admin dashboard widget showing pending approvals
  static Future<List<dynamic>> getPendingSellerApprovals() async {
    try {
      final response = await http.get(
        Uri.parse('$adminEndpoint/sellers/pending-approvals/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final approvals = data is List ? data : data['approvals'] ?? [];
        return approvals;
      } else {
        throw Exception('Failed to fetch pending approvals: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Approve a seller registration
  /// 
  /// Parameters:
  ///   - id: Seller ID (required)
  ///   - notes: Optional admin notes for approval
  /// 
  /// Returns: {success: bool, sellerId: String, status: 'APPROVED', timestamp: String}
  /// Side effects: Seller gains marketplace access, notification sent to seller
  static Future<Map<String, dynamic>> approveSeller(
    String id, {
    String? notes,
  }) async {
    try {
      final body = {
        'admin_notes': notes ?? '',
      };

      final response = await http.post(
        Uri.parse('$adminEndpoint/sellers/$id/approve/'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Record audit trail
        await AdminAuditTrailService.recordAuditTrail(
          action: AdminAuditTrailService.actionSellerApprove,
          category: AdminAuditTrailService.actionCategorySeller,
          adminId: 'admin_001',
          entityType: 'seller',
          entityId: id,
          beforeState: {'status': 'PENDING'},
          afterState: {'status': 'APPROVED'},
          severity: AdminAuditTrailService.severityHigh,
          reason: 'Seller registration approval',
          notes: notes,
        );

        return data;
      } else {
        throw Exception('Failed to approve seller: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Reject a seller registration
  /// 
  /// Parameters:
  ///   - id: Seller ID (required)
  ///   - reason: Rejection reason code (required)
  ///   - notes: Detailed admin notes for seller
  /// 
  /// Returns: {success: bool, sellerId: String, status: 'REJECTED', timestamp: String}
  /// Side effects: Seller notified, registration closed
  static Future<Map<String, dynamic>> rejectSeller(
    String id, {
    required String reason,
    String? notes,
  }) async {
    try {
      final body = {
        'reason': reason,
        'admin_notes': notes ?? '',
      };

      final response = await http.post(
        Uri.parse('$adminEndpoint/sellers/$id/reject/'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Record audit trail
        await AdminAuditTrailService.recordAuditTrail(
          action: AdminAuditTrailService.actionSellerReject,
          category: AdminAuditTrailService.actionCategorySeller,
          adminId: 'admin_001',
          entityType: 'seller',
          entityId: id,
          beforeState: {'status': 'PENDING'},
          afterState: {'status': 'REJECTED'},
          severity: AdminAuditTrailService.severityHigh,
          reason: 'Seller registration rejection',
          notes: '$reason: $notes',
        );

        return data;
      } else {
        throw Exception('Failed to reject seller: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Suspend a seller account (temporary or permanent)
  /// 
  /// Parameters:
  ///   - id: Seller ID (required)
  ///   - reason: Suspension reason (required)
  ///   - durationDays: Number of days to suspend (null = permanent)
  /// 
  /// Returns: {success: bool, sellerId: String, status: 'SUSPENDED', expiryDate: String?}
  /// Side effects: Seller cannot list/sell, existing listings hidden, notifications sent
  static Future<Map<String, dynamic>> suspendSeller(
    String id, {
    required String reason,
    int? durationDays,
  }) async {
    try {
      final body = {
        'reason': reason,
        'duration_days': durationDays,
      };

      final response = await http.post(
        Uri.parse('$adminEndpoint/sellers/$id/suspend/'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Record audit trail
        await AdminAuditTrailService.recordAuditTrail(
          action: AdminAuditTrailService.actionSellerSuspend,
          category: AdminAuditTrailService.actionCategorySeller,
          adminId: 'admin_001',
          entityType: 'seller',
          entityId: id,
          beforeState: {'status': 'ACTIVE'},
          afterState: {'status': 'SUSPENDED', 'duration_days': durationDays},
          severity: AdminAuditTrailService.severityCritical,
          reason: 'Seller account suspension',
          notes: '$reason (${durationDays ?? 'permanent'} days)',
        );

        return data;
      } else {
        throw Exception('Failed to suspend seller: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Reactivate a suspended seller
  /// 
  /// Parameters:
  ///   - id: Seller ID (required)
  /// 
  /// Returns: {success: bool, sellerId: String, status: 'APPROVED'}
  /// Side effects: Seller can resume operations, suspension lifted
  static Future<Map<String, dynamic>> reactivateSeller(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$adminEndpoint/sellers/$id/reactivate/'),
        headers: await _getHeaders(),
        body: json.encode({}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to reactivate seller: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get seller approval history (audit trail)
  /// 
  /// Parameters:
  ///   - id: Seller ID (required)
  /// 
  /// Returns: [{timestamp, adminId, adminName, action, notes, status, reason?}]
  /// Purpose: Full history of all approval/rejection/suspension decisions
  static Future<List<dynamic>> getSellerApprovalHistory(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$adminEndpoint/sellers/$id/approval-history/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final history = data is List ? data : data['history'] ?? [];
        return history;
      } else {
        throw Exception('Failed to fetch approval history: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Get price violations for a specific seller
  /// 
  /// Parameters:
  ///   - id: Seller ID (required)
  /// 
  /// Returns: [{productId, productName, listedPrice, ceiling, violationPercentage, date, status}]
  /// Purpose: Show seller's compliance violations
  static Future<List<dynamic>> getSellerViolations(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$adminEndpoint/sellers/$id/violations/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final violations = data is List ? data : data['violations'] ?? [];
        return violations;
      } else {
        throw Exception('Failed to fetch violations: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// ============================================================================
  /// PRICE MANAGEMENT (8 methods)
  /// ============================================================================
  /// Operations: Set/update ceilings, monitor compliance, send price advisories

  /// Get all price ceilings with optional filtering
  /// 
  /// Parameters:
  ///   - product: Filter by product name (optional)
  ///   - search: Search filter (optional)
  /// 
  /// Returns: [{productId, productName, currentCeiling, previousCeiling, effectiveDate, lastChanged, ...}]
  static Future<List<dynamic>> getPriceCeilings({
    String? product,
    String? search,
  }) async {
    try {
      String url = '$adminEndpoint/prices/ceilings/';
      if (product != null) url += '?product=$product';
      if (search != null) url += '${product != null ? '&' : '?'}search=${Uri.encodeComponent(search)}';

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ceilings = data is List ? data : data['ceilings'] ?? [];
        return ceilings;
      } else {
        throw Exception('Failed to fetch price ceilings: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Update a product's price ceiling
  /// 
  /// Parameters:
  ///   - productId: Product ID (required)
  ///   - newCeiling: New ceiling price (required)
  ///   - reason: Reason for change (e.g., 'Market Adjustment', 'Forecast Update')
  ///   - effectiveDate: Date ceiling becomes effective (required)
  /// 
  /// Returns: {success: bool, productId: String, newCeiling: num, effectiveDate: String}
  /// Side effects: Non-compliant listings flagged, sellers notified, price advisory created
  static Future<Map<String, dynamic>> updatePriceCeiling(
    String productId, {
    required num newCeiling,
    required String reason,
    required DateTime effectiveDate,
  }) async {
    try {
      final body = {
        'product_id': productId,
        'new_ceiling': newCeiling,
        'reason': reason,
        'effective_date': effectiveDate.toIso8601String(),
      };

      final response = await http.put(
        Uri.parse('$adminEndpoint/prices/ceilings/$productId/'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Record audit trail
        await AdminAuditTrailService.recordAuditTrail(
          action: AdminAuditTrailService.actionPriceCeilingUpdate,
          category: AdminAuditTrailService.actionCategoryPrice,
          adminId: 'admin_001',
          entityType: 'product_price_ceiling',
          entityId: productId,
          beforeState: {'ceiling': 'unknown'},
          afterState: {'ceiling': newCeiling, 'effective_date': effectiveDate.toIso8601String()},
          severity: AdminAuditTrailService.severityHigh,
          reason: 'Price ceiling update',
          notes: '$reason - Effective: ${effectiveDate.toIso8601String()}',
        );

        return data;
      } else {
        throw Exception('Failed to update price ceiling: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get price change history for a product
  /// 
  /// Parameters:
  ///   - productId: Product ID (required)
  /// 
  /// Returns: [{timestamp, previousCeiling, newCeiling, reason, adminId, adminName, effectiveDate}]
  /// Purpose: Audit trail of ceiling changes
  static Future<List<dynamic>> getPriceCeilingHistory(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$adminEndpoint/prices/ceilings/$productId/history/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final history = data is List ? data : data['history'] ?? [];
        return history;
      } else {
        throw Exception('Failed to fetch price history: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Get listings that exceed their product's price ceiling
  /// 
  /// Returns: [{sellerId, sellerName, productId, productName, listedPrice, ceiling, excessPercentage, flaggedDate}]
  /// Purpose: Identify non-compliant sellers for enforcement action
  static Future<List<dynamic>> getNonCompliantListings() async {
    try {
      final response = await http.get(
        Uri.parse('$adminEndpoint/prices/non-compliant/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final listings = data is List ? data : data['listings'] ?? [];
        return listings;
      } else {
        throw Exception('Failed to fetch non-compliant listings: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Flag a seller for price violation
  /// 
  /// Parameters:
  ///   - sellerId: Seller ID (required)
  ///   - productId: Product ID (required)
  ///   - listedPrice: Current listed price (required)
  /// 
  /// Returns: {success: bool, flagId: String, status: 'NEW'}
  /// Side effects: Violation recorded, seller gets warning notification
  static Future<Map<String, dynamic>> flagPriceViolation(
    String sellerId,
    String productId, {
    required num listedPrice,
  }) async {
    try {
      final body = {
        'seller_id': sellerId,
        'product_id': productId,
        'listed_price': listedPrice,
      };

      final response = await http.post(
        Uri.parse('$adminEndpoint/prices/flag-violation/'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to flag violation: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Create a price advisory for marketplace display
  /// 
  /// Parameters:
  ///   - type: Advisory type (e.g., 'Price Update', 'Shortage Alert', 'Promotion')
  ///   - title: Advisory title (required)
  ///   - content: Advisory message (required)
  ///   - targetAudience: 'all', 'sellers', or 'buyers'
  /// 
  /// Returns: {success: bool, advisoryId: String, status: 'PUBLISHED'}
  /// Side effects: Broadcast to marketplace, visible to targeted users
  static Future<Map<String, dynamic>> createPriceAdvisory({
    required String type,
    required String title,
    required String content,
    String targetAudience = 'all',
  }) async {
    try {
      final body = {
        'type': type,
        'title': title,
        'content': content,
        'target_audience': targetAudience,
      };

      final response = await http.post(
        Uri.parse('$adminEndpoint/prices/advisories/'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to create price advisory: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get all active price advisories
  /// 
  /// Returns: [{advisoryId, type, title, content, targetAudience, publishedDate, status}]
  static Future<List<dynamic>> getPriceAdvisories() async {
    try {
      final response = await http.get(
        Uri.parse('$adminEndpoint/prices/advisories/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final advisories = data is List ? data : data['advisories'] ?? [];
        return advisories;
      } else {
        throw Exception('Failed to fetch price advisories: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Delete a price advisory
  /// 
  /// Parameters:
  ///   - id: Advisory ID (required)
  /// 
  /// Returns: {success: bool, advisoryId: String}
  /// Side effects: Advisory removed from marketplace display
  static Future<Map<String, dynamic>> deletePriceAdvisory(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$adminEndpoint/prices/advisories/$id/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'advisoryId': id};
      } else {
        throw Exception('Failed to delete price advisory: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// ============================================================================
  /// OPAS PURCHASING (9 methods)
  /// ============================================================================
  /// Operations: Review bulk submissions, manage inventory, track purchases

  /// Get OPAS submissions from sellers (with optional filtering)
  /// 
  /// Parameters:
  ///   - status: Filter by status (PENDING/APPROVED/REJECTED) (optional)
  ///   - page: Pagination page (default: 1)
  /// 
  /// Returns: {submissions: [{id, sellerId, sellerName, productId, productName, quantity, unitPrice, status, submissionDate}], total: int}
  static Future<Map<String, dynamic>> getOPASSubmissions({
    String? status,
    int page = 1,
  }) async {
    try {
      String url = '$adminEndpoint/opas/submissions/?page=$page';
      if (status != null) url += '&status=$status';

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to fetch OPAS submissions: ${response.statusCode}');
      }
    } catch (e) {
      return {'submissions': [], 'total': 0, 'error': e.toString()};
    }
  }

  /// Get details of a specific OPAS submission
  /// 
  /// Parameters:
  ///   - id: Submission ID (required)
  /// 
  /// Returns: {id, sellerId, sellerName, productId, productName, quantity, unitPrice, qualityGrade, estimatedValue, submissionDate, description, ...}
  static Future<Map<String, dynamic>> getOPASSubmissionDetails(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$adminEndpoint/opas/submissions/$id/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 404) {
        throw Exception('Submission not found');
      } else {
        throw Exception('Failed to fetch submission details: ${response.statusCode}');
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Approve an OPAS submission
  /// 
  /// Parameters:
  ///   - id: Submission ID (required)
  ///   - quantityAccepted: Approved quantity (required)
  ///   - finalPrice: Final agreed price per unit (required)
  ///   - terms: Delivery terms/notes (optional)
  /// 
  /// Returns: {success: bool, submissionId: String, purchaseOrderId: String, status: 'APPROVED'}
  /// Side effects: Purchase order created, inventory updated, seller notified, payment initiated
  static Future<Map<String, dynamic>> approveOPASSubmission(
    String id, {
    required int quantityAccepted,
    required num finalPrice,
    String? terms,
  }) async {
    try {
      final body = {
        'quantity_accepted': quantityAccepted,
        'final_price': finalPrice,
        'terms': terms ?? '',
      };

      final response = await http.post(
        Uri.parse('$adminEndpoint/opas/submissions/$id/approve/'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Record audit trail
        await AdminAuditTrailService.recordAuditTrail(
          action: AdminAuditTrailService.actionOPASApprove,
          category: AdminAuditTrailService.actionCategoryOPAS,
          adminId: 'admin_001',
          entityType: 'opas_submission',
          entityId: id,
          beforeState: {'status': 'PENDING', 'quantity': 0, 'price': 0},
          afterState: {
            'status': 'APPROVED',
            'quantity_accepted': quantityAccepted,
            'final_price': finalPrice,
          },
          severity: AdminAuditTrailService.severityHigh,
          reason: 'OPAS submission approval',
          notes: 'Approved quantity: $quantityAccepted, Price: $finalPrice, Terms: $terms',
        );

        return data;
      } else {
        throw Exception('Failed to approve submission: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Reject an OPAS submission
  /// 
  /// Parameters:
  ///   - id: Submission ID (required)
  ///   - reason: Rejection reason (required)
  /// 
  /// Returns: {success: bool, submissionId: String, status: 'REJECTED'}
  /// Side effects: Seller notified, can resubmit with different terms
  static Future<Map<String, dynamic>> rejectOPASSubmission(
    String id, {
    required String reason,
  }) async {
    try {
      final body = {'reason': reason};

      final response = await http.post(
        Uri.parse('$adminEndpoint/opas/submissions/$id/reject/'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Record audit trail
        await AdminAuditTrailService.recordAuditTrail(
          action: AdminAuditTrailService.actionOPASReject,
          category: AdminAuditTrailService.actionCategoryOPAS,
          adminId: 'admin_001',
          entityType: 'opas_submission',
          entityId: id,
          beforeState: {'status': 'PENDING'},
          afterState: {'status': 'REJECTED'},
          severity: AdminAuditTrailService.severityHigh,
          reason: 'OPAS submission rejection',
          notes: reason,
        );

        return data;
      } else {
        throw Exception('Failed to reject submission: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get current OPAS inventory (all items in stock)
  /// 
  /// Parameters:
  ///   - status: Filter by status (OK/LOW_STOCK/EXPIRING) (optional)
  ///   - page: Pagination page (default: 1)
  /// 
  /// Returns: {inventory: [{productId, productName, quantity, storageLocation, expiryDate, status}], total: int}
  static Future<Map<String, dynamic>> getOPASInventory({
    String? status,
    int page = 1,
  }) async {
    try {
      String url = '$adminEndpoint/opas/inventory/?page=$page';
      if (status != null) url += '&status=$status';

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to fetch OPAS inventory: ${response.statusCode}');
      }
    } catch (e) {
      return {'inventory': [], 'total': 0, 'error': e.toString()};
    }
  }

  /// Adjust OPAS inventory quantity (manual adjustment with reason)
  /// 
  /// Parameters:
  ///   - productId: Product ID (required)
  ///   - quantityChange: Quantity delta (positive for add, negative for reduce)
  ///   - reason: Reason for adjustment (e.g., 'Consumed', 'Spoiled', 'Recount')
  /// 
  /// Returns: {success: bool, productId: String, newQuantity: int}
  /// Purpose: FIFO inventory management with audit trail
  static Future<Map<String, dynamic>> adjustOPASInventory(
    String productId, {
    required int quantityChange,
    required String reason,
  }) async {
    try {
      final body = {
        'product_id': productId,
        'quantity_change': quantityChange,
        'reason': reason,
      };

      final response = await http.post(
        Uri.parse('$adminEndpoint/opas/inventory/adjust/'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to adjust inventory: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get inventory items with low stock
  /// 
  /// Returns: [{productId, productName, quantity, minimumThreshold, alert: 'LOW_STOCK'}]
  /// Purpose: Alert admin to inventory shortages
  static Future<List<dynamic>> getOPASInventoryLowStock() async {
    try {
      final response = await http.get(
        Uri.parse('$adminEndpoint/opas/inventory/low-stock/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data is List ? data : data['items'] ?? [];
        return items;
      } else {
        throw Exception('Failed to fetch low stock items: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Get inventory items expiring soon
  /// 
  /// Returns: [{productId, productName, quantity, expiryDate, daysToExpiry, alert: 'EXPIRING'}]
  /// Purpose: Alert admin to expiring produce
  static Future<List<dynamic>> getOPASInventoryExpiring() async {
    try {
      final response = await http.get(
        Uri.parse('$adminEndpoint/opas/inventory/expiring/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data is List ? data : data['items'] ?? [];
        return items;
      } else {
        throw Exception('Failed to fetch expiring items: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Get OPAS purchase history (all transactions)
  /// 
  /// Parameters:
  ///   - dateRange: Optional date range filter {from: DateTime, to: DateTime}
  ///   - seller: Optional seller ID filter
  ///   - product: Optional product ID filter
  /// 
  /// Returns: [{transactionId, sellerId, sellerName, productId, productName, quantity, totalAmount, date, status}]
  /// Purpose: Audit trail of all OPAS purchases
  static Future<List<dynamic>> getOPASPurchaseHistory({
    Map<String, dynamic>? dateRange,
    String? seller,
    String? product,
  }) async {
    try {
      String url = '$adminEndpoint/opas/purchase-history/';
      List<String> params = [];

      if (dateRange != null) {
        if (dateRange['from'] != null) {
          params.add('from_date=${(dateRange['from'] as DateTime).toIso8601String()}');
        }
        if (dateRange['to'] != null) {
          params.add('to_date=${(dateRange['to'] as DateTime).toIso8601String()}');
        }
      }
      if (seller != null) params.add('seller=$seller');
      if (product != null) params.add('product=$product');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final history = data is List ? data : data['history'] ?? [];
        return history;
      } else {
        throw Exception('Failed to fetch purchase history: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// ============================================================================
  /// MARKETPLACE OVERSIGHT (4 methods)
  /// ============================================================================
  /// Operations: Monitor activity, flag listings, manage alerts

  /// Get all marketplace listings (with optional filtering)
  /// 
  /// Parameters:
  ///   - search: Search by seller name or product (optional)
  ///   - filters: Map of filter criteria {category, priceRange, dateRange} (optional)
  /// 
  /// Returns: [{sellerId, sellerName, productId, productName, price, quantity, listedDate, status}]
  static Future<List<dynamic>> getMarketplaceListings({
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    try {
      String url = '$adminEndpoint/marketplace/listings/';
      List<String> params = [];

      if (search != null) params.add('search=${Uri.encodeComponent(search)}');
      if (filters != null) {
        if (filters['category'] != null) params.add('category=${filters['category']}');
        if (filters['priceRange'] != null) {
          params.add('price_min=${filters['priceRange']['min']}');
          params.add('price_max=${filters['priceRange']['max']}');
        }
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final listings = data is List ? data : data['listings'] ?? [];
        return listings;
      } else {
        throw Exception('Failed to fetch listings: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Flag a suspicious or inappropriate listing
  /// 
  /// Parameters:
  ///   - listingId: Listing ID (required)
  ///   - reason: Flag reason (required)
  ///   - severity: 'low', 'medium', 'high' (default: 'medium')
  /// 
  /// Returns: {success: bool, listingId: String, flagId: String, status: 'FLAGGED'}
  static Future<Map<String, dynamic>> flagListing(
    String listingId, {
    required String reason,
    String severity = 'medium',
  }) async {
    try {
      final body = {
        'listing_id': listingId,
        'reason': reason,
        'severity': severity,
      };

      final response = await http.post(
        Uri.parse('$adminEndpoint/marketplace/listings/$listingId/flag/'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to flag listing: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Remove a listing from marketplace
  /// 
  /// Parameters:
  ///   - listingId: Listing ID (required)
  ///   - reason: Removal reason (required)
  /// 
  /// Returns: {success: bool, listingId: String, status: 'REMOVED'}
  /// Side effects: Listing hidden from marketplace, seller notified
  static Future<Map<String, dynamic>> removeListing(
    String listingId, {
    required String reason,
  }) async {
    try {
      final body = {'reason': reason};

      final response = await http.post(
        Uri.parse('$adminEndpoint/marketplace/listings/$listingId/remove/'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to remove listing: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get marketplace alerts/flags (categorized)
  /// 
  /// Parameters:
  ///   - category: Filter by category (e.g., 'price_violations', 'seller_issues') (optional)
  ///   - status: Filter by status ('open', 'resolved') (optional)
  /// 
  /// Returns: [{alertId, category, severity, affectedListing, reason, createdDate, status}]
  static Future<List<dynamic>> getMarketplaceAlerts({
    String? category,
    String? status,
  }) async {
    try {
      String url = '$adminEndpoint/marketplace/alerts/';
      List<String> params = [];

      if (category != null) params.add('category=$category');
      if (status != null) params.add('status=$status');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final alerts = data is List ? data : data['alerts'] ?? [];
        return alerts;
      } else {
        throw Exception('Failed to fetch marketplace alerts: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// ============================================================================
  /// ANALYTICS & REPORTING (5 methods)
  /// ============================================================================
  /// Operations: Dashboard metrics, trend analysis, forecasting, report generation

  /// Get admin dashboard summary statistics
  /// 
  /// Returns: {
  ///   seller_metrics: {total, pending, active, suspended, approval_rate},
  ///   market_metrics: {active_listings, sales_today, sales_month, avg_transaction},
  ///   opas_metrics: {pending, approved_month, total_inventory, inventory_value},
  ///   price_compliance: {compliant, non_compliant, compliance_rate},
  ///   alerts: {total_open, price_violations, inventory_alerts},
  ///   marketplace_health_score: 0-100
  /// }
  static Future<Map<String, dynamic>> getAdminDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$adminEndpoint/analytics/dashboard/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to fetch dashboard stats: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'seller_metrics': {},
        'market_metrics': {},
        'opas_metrics': {},
        'price_compliance': {},
        'alerts': {},
        'marketplace_health_score': 0,
        'error': e.toString(),
      };
    }
  }

  /// Get sales trend data over time
  /// 
  /// Parameters:
  ///   - timeframe: 'daily', 'weekly', 'monthly' (default: 'daily')
  ///   - dateRange: {from: DateTime, to: DateTime} (optional, default: last 30 days)
  /// 
  /// Returns: [{date, totalSales, totalTransactions, topProduct, topSeller}]
  static Future<List<dynamic>> getSalesTrends({
    String timeframe = 'daily',
    Map<String, dynamic>? dateRange,
  }) async {
    try {
      String url = '$adminEndpoint/analytics/sales-trends/?timeframe=$timeframe';

      if (dateRange != null) {
        if (dateRange['from'] != null) {
          url += '&from_date=${(dateRange['from'] as DateTime).toIso8601String()}';
        }
        if (dateRange['to'] != null) {
          url += '&to_date=${(dateRange['to'] as DateTime).toIso8601String()}';
        }
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final trends = data is List ? data : data['trends'] ?? [];
        return trends;
      } else {
        throw Exception('Failed to fetch sales trends: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Get price trend data for products
  /// 
  /// Parameters:
  ///   - products: List of product IDs to track (optional, default: top 10 products)
  ///   - dateRange: {from: DateTime, to: DateTime} (optional, default: last 30 days)
  /// 
  /// Returns: [{productId, productName, dates: [date], prices: [price], ceiling: number}]
  static Future<List<dynamic>> getPriceTrends({
    List<String>? products,
    Map<String, dynamic>? dateRange,
  }) async {
    try {
      String url = '$adminEndpoint/analytics/price-trends/';
      List<String> params = [];

      if (products != null && products.isNotEmpty) {
        params.add('products=${products.join(",")}');
      }

      if (dateRange != null) {
        if (dateRange['from'] != null) {
          params.add('from_date=${(dateRange['from'] as DateTime).toIso8601String()}');
        }
        if (dateRange['to'] != null) {
          params.add('to_date=${(dateRange['to'] as DateTime).toIso8601String()}');
        }
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final trends = data is List ? data : data['trends'] ?? [];
        return trends;
      } else {
        throw Exception('Failed to fetch price trends: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Get demand forecast data
  /// 
  /// Parameters:
  ///   - timeframe: 'week', 'month', 'quarter' (default: 'month')
  /// 
  /// Returns: [{productId, productName, forecastedDemand, confidence, seasonalTrend, recommendation}]
  /// Purpose: Guide admin pricing and procurement decisions
  static Future<List<dynamic>> getDemandForecast({
    String timeframe = 'month',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$adminEndpoint/analytics/demand-forecast/?timeframe=$timeframe'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final forecast = data is List ? data : data['forecast'] ?? [];
        return forecast;
      } else {
        throw Exception('Failed to fetch demand forecast: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Generate a comprehensive report
  /// 
  /// Parameters:
  ///   - reportType: 'sales_summary', 'opas_purchases', 'seller_participation', 'market_impact'
  ///   - filters: {dateRange, category, seller} (optional)
  ///   - format: 'json', 'csv', 'pdf' (default: 'json')
  /// 
  /// Returns: {reportId, reportType, generatedDate, data: {...}, downloadUrl: String}
  /// Note: For format='pdf'/'csv', downloadUrl provides file for download
  static Future<Map<String, dynamic>> generateReport(
    String reportType, {
    Map<String, dynamic>? filters,
    String format = 'json',
  }) async {
    try {
      final body = {
        'report_type': reportType,
        'format': format,
        if (filters != null) 'filters': filters,
      };

      final response = await http.post(
        Uri.parse('$adminEndpoint/reports/generate/'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to generate report: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// ============================================================================
  /// NOTIFICATIONS (5 methods)
  /// ============================================================================
  /// Operations: Admin alerts, announcements, broadcast notifications

  /// Get admin alerts (system notifications for admin)
  /// 
  /// Parameters:
  ///   - category: Filter by category (e.g., 'price_violation', 'inventory', 'seller_issue')
  ///   - status: Filter by status ('unread', 'read', 'resolved')
  /// 
  /// Returns: [{alertId, category, title, message, severity, createdDate, status}]
  static Future<List<dynamic>> getAdminAlerts({
    String? category,
    String? status,
  }) async {
    try {
      String url = '$adminEndpoint/notifications/alerts/';
      List<String> params = [];

      if (category != null) params.add('category=$category');
      if (status != null) params.add('status=$status');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final alerts = data is List ? data : data['alerts'] ?? [];
        return alerts;
      } else {
        throw Exception('Failed to fetch admin alerts: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Mark an alert as acknowledged/reviewed
  /// 
  /// Parameters:
  ///   - id: Alert ID (required)
  /// 
  /// Returns: {success: bool, alertId: String, status: 'ACKNOWLEDGED'}
  static Future<Map<String, dynamic>> acknowledgeAlert(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$adminEndpoint/notifications/alerts/$id/acknowledge/'),
        headers: await _getHeaders(),
        body: json.encode({}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to acknowledge alert: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Send an announcement to marketplace (sellers/buyers)
  /// 
  /// Parameters:
  ///   - title: Announcement title (required)
  ///   - content: Announcement message (required)
  ///   - targetAudience: 'all', 'sellers', 'buyers', or specific seller IDs list
  ///   - scheduleTime: DateTime for scheduled announcement (optional, null = immediate)
  /// 
  /// Returns: {success: bool, announcementId: String, status: 'PUBLISHED'/'SCHEDULED'}
  /// Side effects: Notification sent to target audience, visible in their apps
  static Future<Map<String, dynamic>> sendAnnouncement({
    required String title,
    required String content,
    dynamic targetAudience = 'all',
    DateTime? scheduleTime,
  }) async {
    try {
      final body = {
        'title': title,
        'content': content,
        'target_audience': targetAudience is String
            ? targetAudience
            : targetAudience is List
                ? targetAudience.join(',')
                : 'all',
        if (scheduleTime != null) 'schedule_time': scheduleTime.toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$adminEndpoint/notifications/announcements/'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to send announcement: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get all announcements with optional filtering
  /// 
  /// Parameters:
  ///   - status: Filter by announcement status ('draft', 'published', 'archived', optional)
  ///   - type: Filter by announcement type (optional)
  /// 
  /// Returns: [{announcementId, title, content, targetAudience, publishedDate, status, readCount}]
  static Future<List<dynamic>> getAnnouncements({
    String? status,
    String? type,
  }) async {
    try {
      String endpoint = '$adminEndpoint/notifications/announcements/';
      
      // Build query parameters
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (type != null) queryParams['type'] = type;
      
      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }

      final response = await http.get(
        Uri.parse(endpoint),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final announcements = data is List ? data : data['announcements'] ?? [];
        return announcements;
      } else {
        throw Exception('Failed to fetch announcements: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Create a new announcement (v2)
  /// 
  /// Parameters:
  ///   - data: Map containing announcement details
  ///     - title: Announcement title (required)
  ///     - content: Announcement content (required)
  ///     - targetAudience: Target audience type (required)
  ///     - scheduleTime: When to post announcement (optional)
  ///     - status: Draft or Published (default: 'draft')
  /// 
  /// Returns: Created announcement object with ID
  /// Side effects: New announcement created in backend
  static Future<Map<String, dynamic>> createAnnouncementV2(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$adminEndpoint/notifications/announcements/'),
        headers: await _getHeaders(),
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData is Map<String, dynamic>
            ? responseData
            : {'success': true, 'data': responseData};
      } else {
        throw Exception('Failed to create announcement: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update an existing announcement
  /// 
  /// Parameters:
  ///   - id: Announcement ID (required)
  ///   - data: Map containing fields to update
  ///     - title: Updated title (optional)
  ///     - content: Updated content (optional)
  ///     - targetAudience: Updated target audience (optional)
  ///     - status: Updated status (optional)
  /// 
  /// Returns: Updated announcement object
  /// Side effects: Announcement record updated in backend
  static Future<Map<String, dynamic>> updateAnnouncement(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$adminEndpoint/notifications/announcements/$id/'),
        headers: await _getHeaders(),
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData is Map<String, dynamic>
            ? responseData
            : {'success': true, 'data': responseData};
      } else {
        throw Exception('Failed to update announcement: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Delete an announcement
  /// 
  /// Parameters:
  ///   - id: Announcement ID to delete (required)
  /// 
  /// Returns: Success confirmation or error message
  /// Side effects: Announcement permanently deleted from backend
  static Future<Map<String, dynamic>> deleteAnnouncement(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$adminEndpoint/notifications/announcements/$id/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'message': 'Announcement deleted'};
      } else {
        throw Exception('Failed to delete announcement: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get broadcast notification history (delivery status)
  /// 
  /// Returns: [{announcementId, title, targetAudience, publishedDate, deliveredCount, readCount, failureCount}]
  /// Purpose: Track announcement delivery and engagement
  static Future<List<dynamic>> getBroadcastHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$adminEndpoint/notifications/broadcast-history/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final history = data is List ? data : data['history'] ?? [];
        return history;
      } else {
        throw Exception('Failed to fetch broadcast history: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// ============================================================================
  /// ADMIN SETTINGS & AUDIT LOG (5 methods) - Phase 2.7
  /// ============================================================================
  /// Operations: Manage admin preferences, track audit trail

  /// Get admin settings for current user
  /// 
  /// Returns: {settingId, enableEmailNotifications, enablePushNotifications, ...}
  static Future<Map<String, dynamic>> getAdminSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$adminEndpoint/settings/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is Map<String, dynamic> ? data : {};
      } else {
        throw Exception('Failed to fetch admin settings: ${response.statusCode}');
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Update admin settings for current user
  /// 
  /// Parameters:
  ///   - settingsData: Map of settings to update
  /// 
  /// Returns: {success: bool, updated: bool}
  /// Side effects: Settings persisted for admin user
  static Future<Map<String, dynamic>> updateAdminSettings(
    Map<String, dynamic> settingsData,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$adminEndpoint/settings/'),
        headers: {...headers, 'X-HTTP-Method-Override': 'PUT'},
        body: json.encode(settingsData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data is Map<String, dynamic> ? data : {'success': true};
      } else {
        throw Exception('Failed to update admin settings: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get audit logs with optional filtering
  /// 
  /// Parameters:
  ///   - actionType: Filter by action type (optional)
  ///   - adminId: Filter by admin ID (optional)
  ///   - fromDate: Start date for filtering (optional)
  ///   - toDate: End date for filtering (optional)
  ///   - page: Pagination page (default: 1)
  /// 
  /// Returns: [{logId, adminId, adminName, actionType, actionDescription, status, timestamp, ...}]
  static Future<List<dynamic>> getAuditLogs({
    String? actionType,
    String? adminId,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
  }) async {
    try {
      String url = '$adminEndpoint/audit-logs/?page=$page';
      
      if (actionType != null) url += '&action_type=$actionType';
      if (adminId != null) url += '&admin_id=$adminId';
      if (fromDate != null) url += '&from_date=${fromDate.toIso8601String()}';
      if (toDate != null) url += '&to_date=${toDate.toIso8601String()}';

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final logs = data is List ? data : (data is Map ? data['results'] ?? [] : []);
        return logs;
      } else {
        throw Exception('Failed to fetch audit logs: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Export audit logs to file
  /// 
  /// Parameters:
  ///   - actionType: Filter by action type (optional)
  ///   - adminId: Filter by admin ID (optional)
  ///   - fromDate: Start date (optional)
  ///   - toDate: End date (optional)
  ///   - format: Export format 'csv', 'pdf', or 'excel' (default: 'csv')
  /// 
  /// Returns: {success: bool, downloadUrl: String, format: String}
  /// Purpose: Export audit trail for compliance
  static Future<Map<String, dynamic>> exportAuditLog({
    String? actionType,
    String? adminId,
    DateTime? fromDate,
    DateTime? toDate,
    String format = 'csv',
  }) async {
    try {
      final body = {
        'format': format,
        if (actionType != null) 'action_type': actionType,
        if (adminId != null) 'admin_id': adminId,
        if (fromDate != null) 'from_date': fromDate.toIso8601String(),
        if (toDate != null) 'to_date': toDate.toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$adminEndpoint/audit-logs/export/'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data is Map<String, dynamic> ? data : {'success': true, 'format': format};
      } else {
        throw Exception('Failed to export audit logs: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get detailed information about a specific audit log entry
  /// 
  /// Parameters:
  ///   - logId: Audit log ID (required)
  /// 
  /// Returns: {logId, adminId, adminName, actionType, actionDescription, status, timestamp, metadata, errorMessage, ...}
  /// Purpose: View full details of an admin action
  static Future<Map<String, dynamic>> getAuditLogDetails(String logId) async {
    try {
      final response = await http.get(
        Uri.parse('$adminEndpoint/audit-logs/$logId/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is Map<String, dynamic> ? data : {};
      } else if (response.statusCode == 404) {
        throw Exception('Audit log not found');
      } else {
        throw Exception('Failed to fetch audit log details: ${response.statusCode}');
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Resolve an alert with notes (mark as resolved)
  /// 
  /// Parameters:
  ///   - alertId: Alert ID (required)
  ///   - notes: Resolution notes (required)
  /// 
  /// Returns: {success: bool, alertId: String, status: 'RESOLVED'}
  /// Side effects: Alert marked as resolved, notes recorded
  static Future<Map<String, dynamic>> resolveAlert(
    String alertId,
    String notes,
  ) async {
    try {
      final body = {
        'resolution_notes': notes,
      };

      final response = await http.post(
        Uri.parse('$adminEndpoint/notifications/alerts/$alertId/resolve/'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data is Map<String, dynamic> ? data : {'success': true};
      } else {
        throw Exception('Failed to resolve alert: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}




