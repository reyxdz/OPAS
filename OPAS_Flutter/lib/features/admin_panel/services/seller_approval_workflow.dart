import 'package:flutter/foundation.dart';
import '../../../core/services/admin_service.dart';

/// ============================================================================
/// SellerApprovalWorkflow - Phase 3.3 Implementation
/// 
/// Manages the complete seller approval workflow including:
/// 1. Fetching pending seller applications
/// 2. Reviewing seller documents and credentials
/// 3. Making approval/rejection decisions
/// 4. Sending notifications to sellers
/// 5. Recording decisions in audit log
/// 
/// Architecture: Service layer using AdminService for API calls
/// Pattern: Static methods for state-free operations
/// Error Handling: Try/catch with meaningful error messages
/// ============================================================================

class SellerApprovalWorkflow {
  // ==================== STATE CONSTANTS ====================
  static const String statusPending = 'PENDING';
  static const String statusApproved = 'APPROVED';
  static const String statusRejected = 'REJECTED';
  static const String statusSuspended = 'SUSPENDED';

  // ==================== APPROVAL DECISION REASONS ====================
  static const String reasonDocumentsMissing = 'Documents Incomplete';
  static const String reasonFarmDetailsInvalid = 'Invalid Farm Details';
  static const String reasonCredentialsUnverified = 'Credentials Not Verified';
  static const String reasonSuspiciousActivity = 'Suspicious Activity';
  static const String reasonOther = 'Other';

  // ==================== STEP 1: FETCH PENDING APPLICATIONS ====================

  /// Fetch all pending seller approval applications
  /// 
  /// Returns: List of sellers with status = PENDING
  /// Used in: Admin Sellers Screen to display pending approvals
  static Future<Map<String, dynamic>> getPendingApplications({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await AdminService.getPendingSellerApprovals();
      
      return {
        'success': true,
        'data': result,
        'count': result.length,
        'page': page,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to get pending applications: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'data': [],
      };
    }
  }

  // ==================== STEP 2: REVIEW SELLER DETAILS ====================

  /// Get detailed seller information for review
  /// 
  /// Includes: Personal info, farm details, documents, credentials
  /// Returns: Comprehensive seller profile with approval history
  static Future<Map<String, dynamic>> getSellerDetailsForReview(
    String sellerId,
  ) async {
    try {
      final details = await AdminService.getSellerDetails(sellerId);
      final approvalHistory = await AdminService.getSellerApprovalHistory(sellerId);

      return {
        'success': true,
        'seller': details,
        'approvalHistory': approvalHistory,
        'lastDecision': approvalHistory.isNotEmpty ? approvalHistory.first : null,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to get seller details for review: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== STEP 3: APPROVE SELLER ====================

  /// Approve a seller registration application
  /// 
  /// Process:
  /// 1. Call AdminService.approveSeller()
  /// 2. Record decision in audit log (automatic via backend)
  /// 3. Notify seller of approval
  /// 4. Update seller status to APPROVED
  /// 5. Grant marketplace access
  /// 
  /// Returns: Success/failure with updated seller status
  static Future<Map<String, dynamic>> approveSeller({
    required String sellerId,
    String? notes,
  }) async {
    try {
      // Validate input
      if (sellerId.isEmpty) {
        return {
          'success': false,
          'error': 'Seller ID is required',
        };
      }

      // Call API to approve seller
      final result = await AdminService.approveSeller(
        sellerId,
        notes: notes ?? '',
      );

      if (result['success'] != false) {
        return {
          'success': true,
          'message': 'Seller approved successfully',
          'seller': result,
          'status': statusApproved,
        };
      }

      return {
        'success': false,
        'error': result['error'] ?? 'Failed to approve seller',
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to approve seller: $e');
      }
      return {
        'success': false,
        'error': 'Error approving seller: ${e.toString()}',
      };
    }
  }

  // ==================== STEP 4: REJECT SELLER ====================

  /// Reject a seller registration application
  /// 
  /// Process:
  /// 1. Record rejection reason and admin notes
  /// 2. Update seller status to REJECTED
  /// 3. Send notification to seller with rejection reason
  /// 4. Log decision in audit trail
  /// 5. Allow seller to reapply after addressing issues
  /// 
  /// Returns: Success/failure with rejection details
  static Future<Map<String, dynamic>> rejectSeller({
    required String sellerId,
    required String reason,
    String? adminNotes,
  }) async {
    try {
      // Validate input
      if (sellerId.isEmpty) {
        return {
          'success': false,
          'error': 'Seller ID is required',
        };
      }

      if (reason.isEmpty) {
        return {
          'success': false,
          'error': 'Rejection reason is required',
        };
      }

      // Call API to reject seller
      final result = await AdminService.rejectSeller(
        sellerId,
        reason: reason,
        notes: adminNotes,
      );

      if (result['success'] != false) {
        return {
          'success': true,
          'message': 'Seller rejected successfully',
          'reason': reason,
          'seller': result,
          'status': statusRejected,
        };
      }

      return {
        'success': false,
        'error': result['error'] ?? 'Failed to reject seller',
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to reject seller: $e');
      }
      return {
        'success': false,
        'error': 'Error rejecting seller: ${e.toString()}',
      };
    }
  }

  // ==================== STEP 5: GET APPROVAL HISTORY ====================

  /// Get complete approval history for a seller
  /// 
  /// Shows all previous decisions: approvals, rejections, suspensions
  /// Includes: decision reason, admin notes, timestamp
  /// Used for: Audit trail and decision tracking
  static Future<Map<String, dynamic>> getApprovalHistory(
    String sellerId,
  ) async {
    try {
      final history = await AdminService.getSellerApprovalHistory(sellerId) as List? ?? [];

      return {
        'success': true,
        'history': history,
        'count': history.length,
        'lastDecision': history.isNotEmpty ? history.first : null,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to get approval history: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'history': [],
      };
    }
  }

  // ==================== STEP 6: SUSPEND SELLER ====================

  /// Suspend a seller account (after approval)
  /// 
  /// Process:
  /// 1. Record suspension reason and duration
  /// 2. Disable seller from marketplace
  /// 3. Remove active listings
  /// 4. Notify seller of suspension
  /// 5. Log decision in audit trail
  /// 
  /// Returns: Success/failure with suspension details
  static Future<Map<String, dynamic>> suspendSeller({
    required String sellerId,
    required String reason,
    int? durationDays,
    String? adminNotes,
  }) async {
    try {
      if (sellerId.isEmpty) {
        return {
          'success': false,
          'error': 'Seller ID is required',
        };
      }

      if (reason.isEmpty) {
        return {
          'success': false,
          'error': 'Suspension reason is required',
        };
      }

      final result = await AdminService.suspendSeller(
        sellerId,
        reason: reason,
        durationDays: durationDays,
      );

      if (result['success'] != false) {
        return {
          'success': true,
          'message': 'Seller suspended successfully',
          'seller': result,
          'status': statusSuspended,
        };
      }

      return {
        'success': false,
        'error': result['error'] ?? 'Failed to suspend seller',
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to suspend seller: $e');
      }
      return {
        'success': false,
        'error': 'Error suspending seller: ${e.toString()}',
      };
    }
  }

  // ==================== STEP 7: REACTIVATE SELLER ====================

  /// Reactivate a suspended seller account
  /// 
  /// Prerequisites: Suspension period must have ended or admin override
  /// Process:
  /// 1. Verify suspension period has passed
  /// 2. Update seller status to APPROVED
  /// 3. Restore marketplace access
  /// 4. Notify seller of reactivation
  /// 5. Log decision in audit trail
  /// 
  /// Returns: Success/failure with updated seller status
  static Future<Map<String, dynamic>> reactivateSeller(
    String sellerId,
  ) async {
    try {
      if (sellerId.isEmpty) {
        return {
          'success': false,
          'error': 'Seller ID is required',
        };
      }

      final result = await AdminService.reactivateSeller(sellerId);

      if (result['success'] != false) {
        return {
          'success': true,
          'message': 'Seller reactivated successfully',
          'seller': result,
          'status': statusApproved,
        };
      }

      return {
        'success': false,
        'error': result['error'] ?? 'Failed to reactivate seller',
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to reactivate seller: $e');
      }
      return {
        'success': false,
        'error': 'Error reactivating seller: ${e.toString()}',
      };
    }
  }

  // ==================== COMPLETE WORKFLOW EXECUTION ====================

  /// Execute complete approval workflow in sequence
  /// 
  /// Used for: Batch operations or automated workflows
  /// Returns: Result of each step
  static Future<Map<String, dynamic>> executeApprovalWorkflow({
    required String sellerId,
    required String decision, // APPROVED or REJECTED
    String? reason,
    String? adminNotes,
  }) async {
    try {
      // Get seller details first
      final detailsResult = await getSellerDetailsForReview(sellerId);
      if (!detailsResult['success']) {
        return {
          'success': false,
          'error': 'Failed to retrieve seller details',
        };
      }

      // Execute decision
      Map<String, dynamic> decisionResult;
      if (decision.toUpperCase() == 'APPROVED') {
        decisionResult = await approveSeller(
          sellerId: sellerId,
          notes: adminNotes,
        );
      } else if (decision.toUpperCase() == 'REJECTED') {
        decisionResult = await rejectSeller(
          sellerId: sellerId,
          reason: reason ?? reasonOther,
          adminNotes: adminNotes,
        );
      } else {
        return {
          'success': false,
          'error': 'Invalid decision. Use APPROVED or REJECTED',
        };
      }

      return {
        'success': decisionResult['success'],
        'sellerDetails': detailsResult,
        'decision': decisionResult,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to execute approval workflow: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== HELPER METHODS ====================

  /// Check if seller is pending approval
  static bool isPendingApproval(Map<String, dynamic> seller) {
    final status = seller['status'] as String?;
    return status?.toUpperCase() == statusPending;
  }

  /// Check if seller is approved
  static bool isApproved(Map<String, dynamic> seller) {
    final status = seller['status'] as String?;
    return status?.toUpperCase() == statusApproved;
  }

  /// Check if seller is suspended
  static bool isSuspended(Map<String, dynamic> seller) {
    final status = seller['status'] as String?;
    return status?.toUpperCase() == statusSuspended;
  }

  /// Get approval status color (for UI)
  static String getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return '#FFC107'; // Yellow
      case 'APPROVED':
        return '#4CAF50'; // Green
      case 'REJECTED':
        return '#F44336'; // Red
      case 'SUSPENDED':
        return '#FF5722'; // Deep Orange
      default:
        return '#757575'; // Gray
    }
  }

  /// Get reason description
  static String getReasonDescription(String reason) {
    switch (reason) {
      case reasonDocumentsMissing:
        return 'Required documents are incomplete or missing';
      case reasonFarmDetailsInvalid:
        return 'Farm or store details are invalid or incomplete';
      case reasonCredentialsUnverified:
        return 'Credentials could not be verified';
      case reasonSuspiciousActivity:
        return 'Suspicious activity detected';
      case reasonOther:
        return 'Other reason (see admin notes)';
      default:
        return reason;
    }
  }
}
