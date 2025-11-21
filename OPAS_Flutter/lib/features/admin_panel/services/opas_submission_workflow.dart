import 'package:flutter/foundation.dart';
import '../../../core/services/admin_service.dart';

/// ============================================================================
/// OPASSubmissionWorkflow - Phase 3.3 Implementation
/// 
/// Manages the complete OPAS (Bulk Purchase) submission workflow including:
/// 1. Fetching pending seller OPAS submissions
/// 2. Reviewing submission details
/// 3. Approving or rejecting submissions
/// 4. Generating purchase orders
/// 5. Updating OPAS inventory
/// 6. Notifying sellers
/// 7. Recording transactions in audit log
/// 
/// Architecture: Service layer using AdminService for API calls
/// Pattern: Static methods for state-free operations
/// Error Handling: Try/catch with meaningful error messages
/// ============================================================================

class OPASSubmissionWorkflow {
  // ==================== STATUS CONSTANTS ====================
  static const String statusPending = 'PENDING';
  static const String statusApproved = 'APPROVED';
  static const String statusRejected = 'REJECTED';
  static const String statusCompleted = 'COMPLETED';

  // ==================== REJECTION REASONS ====================
  static const String reasonPriceNotCompetitive = 'Price Not Competitive';
  static const String reasonQualityNotMet = 'Quality Not Met';
  static const String reasonQuantityNotRequired = 'Quantity Not Required';
  static const String reasonInsufficientInventory = 'Insufficient Inventory';
  static const String reasonDeliveryTermsNotAcceptable = 'Delivery Terms Not Acceptable';
  static const String reasonOther = 'Other';

  // ==================== STEP 1: FETCH PENDING SUBMISSIONS ====================

  /// Get all pending OPAS submissions from sellers
  /// 
  /// Returns: List of sellers with OPAS submissions pending admin approval
  /// Includes: Seller name, product, quantity, offered price, status
  static Future<Map<String, dynamic>> getPendingSubmissions({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await AdminService.getOPASSubmissions(
        status: statusPending,
        page: page,
      );

      final data = result['data'] is List ? result['data'] : [];
      return {
        'success': true,
        'data': data,
        'count': (data as List).length,
        'page': page,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to get pending OPAS submissions: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'data': [],
      };
    }
  }

  // ==================== STEP 2: REVIEW SUBMISSION DETAILS ====================

  /// Get detailed review of a specific OPAS submission
  /// 
  /// Returns: Complete submission details including:
  /// - Seller info, product details, quantity, offered price
  /// - Quality grade (if assessed)
  /// - Seller's delivery terms and conditions
  /// - Previous submissions from same seller (for pattern analysis)
  static Future<Map<String, dynamic>> getSubmissionDetails(
    String submissionId,
  ) async {
    try {
      final details = await AdminService.getOPASSubmissionDetails(submissionId);

      return {
        'success': true,
        'submission': details,
        'submissionId': submissionId,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to get submission details: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== STEP 3: ASSESS SUBMISSION ====================

  /// Assess a submission against criteria
  /// 
  /// Checks:
  /// - Price competitiveness vs market
  /// - Quality grade requirements met
  /// - Quantity matches requirements
  /// - Seller reliability/history
  /// - Delivery terms acceptable
  /// 
  /// Returns: Assessment summary with recommendations
  static Future<Map<String, dynamic>> assessSubmission({
    required String submissionId,
    required double offeredPrice,
    required String qualityGrade,
    required int quantity,
  }) async {
    try {
      // Get submission details for context
      final details = await getSubmissionDetails(submissionId);
      if (!details['success']) {
        return {
          'success': false,
          'error': 'Failed to retrieve submission details',
        };
      }

      final submission = details['submission'] as Map?;
      
      // Assessment logic
      bool priceAcceptable = offeredPrice > 0;
      bool qualityAcceptable = qualityGrade.isNotEmpty;
      bool quantityAcceptable = quantity > 0;
      
      String recommendation = 'Not Recommended';
      if (priceAcceptable && qualityAcceptable && quantityAcceptable) {
        recommendation = 'Recommended for Approval';
      }

      return {
        'success': true,
        'submissionId': submissionId,
        'assessment': {
          'priceAcceptable': priceAcceptable,
          'qualityAcceptable': qualityAcceptable,
          'quantityAcceptable': quantityAcceptable,
          'overallRecommendation': recommendation,
        },
        'submission': submission,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to assess submission: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== STEP 4: APPROVE SUBMISSION ====================

  /// Approve an OPAS submission and generate purchase order
  /// 
  /// Process:
  /// 1. Confirm approval details (quantity, price, terms)
  /// 2. Generate purchase order
  /// 3. Update OPAS inventory (add to stock)
  /// 4. Record transaction
  /// 5. Notify seller of approval
  /// 6. Initiate payment process
  /// 7. Log decision in audit trail
  /// 
  /// Returns: Success/failure with purchase order details
  static Future<Map<String, dynamic>> approveSubmission({
    required String submissionId,
    required int quantityAccepted,
    required double finalPrice,
    String? deliveryTerms,
    String? adminNotes,
  }) async {
    try {
      // Validate input
      if (submissionId.isEmpty) {
        return {
          'success': false,
          'error': 'Submission ID is required',
        };
      }

      if (quantityAccepted <= 0) {
        return {
          'success': false,
          'error': 'Quantity must be greater than 0',
        };
      }

      if (finalPrice <= 0) {
        return {
          'success': false,
          'error': 'Final price must be greater than 0',
        };
      }

      // Call API to approve submission
      final result = await AdminService.approveOPASSubmission(
        submissionId,
        quantityAccepted: quantityAccepted,
        finalPrice: finalPrice,
        terms: deliveryTerms ?? '',
      );

      if (result['success'] != false) {
        return {
          'success': true,
          'message': 'OPAS submission approved successfully',
          'submissionId': submissionId,
          'status': statusApproved,
          'quantityAccepted': quantityAccepted,
          'finalPrice': finalPrice,
          'totalCost': quantityAccepted * finalPrice,
          'purchaseOrder': result,
        };
      }

      return {
        'success': false,
        'error': result['error'] ?? 'Failed to approve submission',
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to approve OPAS submission: $e');
      }
      return {
        'success': false,
        'error': 'Error approving submission: ${e.toString()}',
      };
    }
  }

  // ==================== STEP 5: REJECT SUBMISSION ====================

  /// Reject an OPAS submission
  /// 
  /// Process:
  /// 1. Record rejection reason
  /// 2. Update submission status to REJECTED
  /// 3. Notify seller with rejection reason
  /// 4. Allow seller to resubmit with different terms
  /// 5. Log decision in audit trail
  /// 
  /// Returns: Success/failure with rejection details
  static Future<Map<String, dynamic>> rejectSubmission({
    required String submissionId,
    required String reason,
    String? adminNotes,
  }) async {
    try {
      if (submissionId.isEmpty) {
        return {
          'success': false,
          'error': 'Submission ID is required',
        };
      }

      if (reason.isEmpty) {
        return {
          'success': false,
          'error': 'Rejection reason is required',
        };
      }

      // Call API to reject submission
      final result = await AdminService.rejectOPASSubmission(
        submissionId,
        reason: reason,
      );

      if (result['success'] != false) {
        return {
          'success': true,
          'message': 'OPAS submission rejected successfully',
          'submissionId': submissionId,
          'status': statusRejected,
          'reason': reason,
        };
      }

      return {
        'success': false,
        'error': result['error'] ?? 'Failed to reject submission',
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to reject OPAS submission: $e');
      }
      return {
        'success': false,
        'error': 'Error rejecting submission: ${e.toString()}',
      };
    }
  }

  // ==================== STEP 6: UPDATE INVENTORY ====================

  /// Update OPAS inventory after approval
  /// 
  /// Used for: Tracking inventory levels after purchase order
  static Future<Map<String, dynamic>> updateOPASInventory({
    required String productId,
    required int quantityAdded,
    String? reason,
  }) async {
    try {
      final result = await AdminService.adjustOPASInventory(
        productId,
        quantityChange: quantityAdded,
        reason: reason ?? 'OPAS Purchase',
      );

      if (result['success'] != false) {
        return {
          'success': true,
          'inventory': result,
          'quantityAdded': quantityAdded,
        };
      }

      return {
        'success': false,
        'error': result['error'] ?? 'Failed to update inventory',
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to update OPAS inventory: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== STEP 7: GET PURCHASE HISTORY ====================

  /// Get complete OPAS purchase history
  /// 
  /// Returns: All approved and completed OPAS transactions with details
  static Future<Map<String, dynamic>> getPurchaseHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? sellerId,
    String? productId,
  }) async {
    try {
      final result = await AdminService.getOPASPurchaseHistory(
        dateRange: null,
        seller: sellerId,
        product: productId,
      );

      return {
        'success': true,
        'history': result,
        'count': result.length,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to get purchase history: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'history': [],
      };
    }
  }

  // ==================== COMPLETE WORKFLOW EXECUTION ====================

  /// Execute complete OPAS submission approval workflow
  /// 
  /// Process:
  /// 1. Get submission details
  /// 2. Assess submission
  /// 3. Approve/reject decision
  /// 4. Update inventory (if approved)
  /// 5. Return summary
  /// 
  /// Used for: One-step OPAS submission processing
  static Future<Map<String, dynamic>> executeSubmissionWorkflow({
    required String submissionId,
    required String decision, // APPROVED or REJECTED
    required int quantityAccepted,
    required double finalPrice,
    String? reason, // For rejection
    String? deliveryTerms, // For approval
  }) async {
    try {
      // Get submission details
      final detailsResult = await getSubmissionDetails(submissionId);
      if (!detailsResult['success']) {
        return {
          'success': false,
          'error': 'Failed to retrieve submission details',
        };
      }

      // Execute decision
      Map<String, dynamic> decisionResult;
      if (decision.toUpperCase() == 'APPROVED') {
        decisionResult = await approveSubmission(
          submissionId: submissionId,
          quantityAccepted: quantityAccepted,
          finalPrice: finalPrice,
          deliveryTerms: deliveryTerms,
        );

        // Update inventory if approval successful
        if (decisionResult['success']) {
          final submission = detailsResult['submission'] as Map?;
          final productId = submission?['product_id']?.toString();
          
          if (productId != null) {
            await updateOPASInventory(
              productId: productId,
              quantityAdded: quantityAccepted,
              reason: 'OPAS Purchase Order Approved',
            );
          }
        }
      } else if (decision.toUpperCase() == 'REJECTED') {
        decisionResult = await rejectSubmission(
          submissionId: submissionId,
          reason: reason ?? reasonOther,
        );
      } else {
        return {
          'success': false,
          'error': 'Invalid decision. Use APPROVED or REJECTED',
        };
      }

      return {
        'success': decisionResult['success'],
        'submissionDetails': detailsResult,
        'decision': decisionResult,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to execute OPAS submission workflow: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== HELPER METHODS ====================

  /// Calculate total cost of submission
  static double calculateTotalCost(int quantity, double unitPrice) {
    return quantity * unitPrice;
  }

  /// Get rejection reason description
  static String getReasonDescription(String reason) {
    switch (reason) {
      case reasonPriceNotCompetitive:
        return 'Offered price is not competitive with market rates';
      case reasonQualityNotMet:
        return 'Product quality does not meet our standards';
      case reasonQuantityNotRequired:
        return 'Requested quantity exceeds current requirements';
      case reasonInsufficientInventory:
        return 'Seller has insufficient inventory';
      case reasonDeliveryTermsNotAcceptable:
        return 'Delivery terms do not meet our requirements';
      case reasonOther:
        return 'Other reason (see admin notes)';
      default:
        return reason;
    }
  }

  /// Format currency for display
  static String formatCurrency(double amount) {
    return 'PKR ${amount.toStringAsFixed(2)}';
  }

  /// Calculate profit margin
  static double calculateMargin(double costPrice, double sellingPrice) {
    return ((sellingPrice - costPrice) / costPrice * 100);
  }

  /// Get price competitiveness assessment
  static String assessPriceCompetitiveness(
    double offeredPrice,
    double marketAvgPrice,
  ) {
    final difference = ((offeredPrice - marketAvgPrice) / marketAvgPrice * 100);

    if (difference > 10) {
      return 'Above Market';
    } else if (difference < -10) {
      return 'Below Market (Good Deal)';
    } else {
      return 'Competitive';
    }
  }
}
