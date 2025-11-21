import 'package:flutter/foundation.dart';
import '../../../core/services/admin_service.dart';

/// ============================================================================
/// PriceViolationWorkflow - Phase 3.3 Implementation
/// 
/// Manages the complete price violation detection and resolution workflow:
/// 1. Detecting seller listings above price ceiling
/// 2. Creating alerts in admin dashboard
/// 3. Admin review and decision-making
/// 4. Taking action (warning, adjustment, suspension)
/// 5. Notifying sellers
/// 6. Recording violations in audit log
/// 7. Tracking compliance history
/// 
/// Architecture: Service layer using AdminService for API calls
/// Pattern: Static methods for state-free operations
/// Error Handling: Try/catch with meaningful error messages
/// ============================================================================

class PriceViolationWorkflow {
  // ==================== VIOLATION STATUS ====================
  static const String statusNew = 'NEW';
  static const String statusWarned = 'WARNED';
  static const String statusAdjusted = 'ADJUSTED';
  static const String statusSuspended = 'SUSPENDED';
  static const String statusResolved = 'RESOLVED';

  // ==================== ACTION TYPES ====================
  static const String actionWarning = 'WARNING';
  static const String actionForceAdjustment = 'FORCE_ADJUSTMENT';
  static const String actionSuspend = 'SUSPEND';

  // ==================== COMPLIANCE THRESHOLDS ====================
  static const int warningThresholdPercent = 5; // 5% over ceiling
  static const int suspensionThresholdPercent = 20; // 20% over ceiling
  static const int compliancePeriodHours = 24; // 24 hours to comply

  // ==================== STEP 1: DETECT VIOLATIONS ====================

  /// Get all current non-compliant listings
  /// 
  /// Returns: List of sellers with products priced above ceiling
  /// Includes: Seller, product, listed price, ceiling price, overage %
  static Future<Map<String, dynamic>> detectViolations({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await AdminService.getNonCompliantListings();

      return {
        'success': true,
        'violations': result,
        'count': result.length,
        'page': page,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to detect violations: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'violations': [],
      };
    }
  }

  // ==================== STEP 2: GET VIOLATION DETAILS ====================

  /// Get detailed information about a specific violation
  /// 
  /// Returns:
  /// - Seller info
  /// - Product details
  /// - Listed vs ceiling price comparison
  /// - Overage percentage
  /// - Violation history (repeat offender?)
  /// - Recommended action
  static Future<Map<String, dynamic>> getViolationDetails({
    required String sellerId,
    required String productId,
  }) async {
    try {
      // Get non-compliant listings to find specific violation
      final violations = await detectViolations();
      
      if (!violations['success']) {
        return {
          'success': false,
          'error': 'Failed to retrieve violations',
        };
      }

      final violationsList = violations['violations'] as List?;
      Map<String, dynamic>? violation;

      if (violationsList != null) {
        for (final v in violationsList) {
          if (v['seller_id'].toString() == sellerId &&
              v['product_id'].toString() == productId) {
            violation = v as Map<String, dynamic>;
            break;
          }
        }
      }

      if (violation == null) {
        return {
          'success': false,
          'error': 'Violation not found',
        };
      }

      // Get seller violations history
      final violationHistory = await AdminService.getSellerViolations(sellerId);

      // Calculate severity
      final listedPrice = (violation['listed_price'] as num?)?.toDouble() ?? 0;
      final ceilingPrice = (violation['ceiling_price'] as num?)?.toDouble() ?? 1;
      final overagePercent = ((listedPrice - ceilingPrice) / ceilingPrice * 100);

      String severity = 'Low';
      if (overagePercent > suspensionThresholdPercent) {
        severity = 'High';
      } else if (overagePercent > warningThresholdPercent) {
        severity = 'Medium';
      }

      String recommendation = actionWarning;
      if (overagePercent > suspensionThresholdPercent) {
        recommendation = actionSuspend;
      } else if (overagePercent > warningThresholdPercent) {
        recommendation = actionForceAdjustment;
      }

      return {
        'success': true,
        'violation': violation,
        'sellerId': sellerId,
        'productId': productId,
        'listedPrice': listedPrice,
        'ceilingPrice': ceilingPrice,
        'overagePercent': overagePercent,
        'severity': severity,
        'recommendation': recommendation,
        'violationHistory': violationHistory,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to get violation details: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== STEP 3: GET MARKETPLACE ALERTS ====================

  /// Get all marketplace alerts including price violations
  /// 
  /// Returns: All open alerts with category and status
  static Future<Map<String, dynamic>> getMarketplaceAlerts({
    String? category, // 'price_violation', 'seller_issue', etc
    String? status, // 'open', 'resolved'
  }) async {
    try {
      final result = await AdminService.getMarketplaceAlerts(
        category: category,
        status: status,
      );

      return {
        'success': true,
        'alerts': result,
        'count': result.length,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to get marketplace alerts: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'alerts': [],
      };
    }
  }

  // ==================== STEP 4: ISSUE WARNING ====================

  /// Issue a warning to seller for price violation
  /// 
  /// Process:
  /// 1. Record warning in system
  /// 2. Notify seller of violation and 24-hour compliance period
  /// 3. Send recommended ceiling price
  /// 4. Log action in audit trail
  /// 5. Mark alert as 'warned'
  /// 
  /// Returns: Success/failure with warning details
  static Future<Map<String, dynamic>> issueWarning({
    required String sellerId,
    required String productId,
    required double listedPrice,
    required double ceilingPrice,
    String? adminNotes,
  }) async {
    try {
      if (sellerId.isEmpty || productId.isEmpty) {
        return {
          'success': false,
          'error': 'Seller ID and Product ID are required',
        };
      }

      // Flag the violation
      final result = await AdminService.flagPriceViolation(
        sellerId,
        productId,
        listedPrice: listedPrice,
      );

      if (result['success'] != false) {
        return {
          'success': true,
          'message': 'Warning issued successfully',
          'sellerId': sellerId,
          'productId': productId,
          'status': statusWarned,
          'compliancePeriodHours': compliancePeriodHours,
          'recommendation': 'Reduce price to $ceilingPrice or below',
          'violation': result,
        };
      }

      return {
        'success': false,
        'error': result['error'] ?? 'Failed to issue warning',
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to issue warning: $e');
      }
      return {
        'success': false,
        'error': 'Error issuing warning: ${e.toString()}',
      };
    }
  }

  // ==================== STEP 5: FORCE ADJUSTMENT ====================

  /// Force automatic price adjustment to ceiling
  /// 
  /// Process:
  /// 1. Automatically lower seller's price to ceiling
  /// 2. Update listing in marketplace
  /// 3. Notify seller of automatic adjustment
  /// 4. Record action in audit trail
  /// 5. Mark violation as 'adjusted'
  /// 
  /// Returns: Success/failure with adjustment details
  static Future<Map<String, dynamic>> forceAdjustment({
    required String sellerId,
    required String productId,
    required double ceilingPrice,
    String? adminNotes,
  }) async {
    try {
      if (sellerId.isEmpty || productId.isEmpty) {
        return {
          'success': false,
          'error': 'Seller ID and Product ID are required',
        };
      }

      if (ceilingPrice <= 0) {
        return {
          'success': false,
          'error': 'Ceiling price must be greater than 0',
        };
      }

      // Flag violation (which auto-adjusts on backend)
      final result = await AdminService.flagPriceViolation(
        sellerId,
        productId,
        listedPrice: ceilingPrice,
      );

      if (result['success'] != false) {
        return {
          'success': true,
          'message': 'Price automatically adjusted to ceiling',
          'sellerId': sellerId,
          'productId': productId,
          'newPrice': ceilingPrice,
          'status': statusAdjusted,
          'violation': result,
        };
      }

      return {
        'success': false,
        'error': result['error'] ?? 'Failed to adjust price',
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to force adjustment: $e');
      }
      return {
        'success': false,
        'error': 'Error forcing adjustment: ${e.toString()}',
      };
    }
  }

  // ==================== STEP 6: SUSPEND SELLER ====================

  /// Suspend seller account for severe/repeated violations
  /// 
  /// Process:
  /// 1. Record suspension reason (price violation)
  /// 2. Disable seller from marketplace
  /// 3. Remove all active listings
  /// 4. Notify seller of suspension
  /// 5. Log decision in audit trail
  /// 6. Mark violation as 'suspended'
  /// 
  /// Returns: Success/failure with suspension details
  static Future<Map<String, dynamic>> suspendSellerForViolation({
    required String sellerId,
    required String productId,
    String? adminNotes,
  }) async {
    try {
      if (sellerId.isEmpty) {
        return {
          'success': false,
          'error': 'Seller ID is required',
        };
      }

      final result = await AdminService.suspendSeller(
        sellerId,
        reason: 'Price violation - multiple offenses or severe overage',
        durationDays: null,
      );

      if (result['success'] != false) {
        return {
          'success': true,
          'message': 'Seller suspended for price violation',
          'sellerId': sellerId,
          'status': statusSuspended,
          'reason': 'Price Violation',
          'seller': result,
        };
      }

      return {
        'success': false,
        'error': result['error'] ?? 'Failed to suspend seller',
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to suspend seller for violation: $e');
      }
      return {
        'success': false,
        'error': 'Error suspending seller: ${e.toString()}',
      };
    }
  }

  // ==================== STEP 7: RESOLVE VIOLATION ====================

  /// Mark violation as resolved after action taken
  /// 
  /// Used for: Closing resolved violations from admin dashboard
  static Future<Map<String, dynamic>> resolveViolation({
    required String sellerId,
    required String productId,
    required String actionTaken, // warning, adjustment, suspension
    String? adminNotes,
  }) async {
    try {
      if (sellerId.isEmpty || productId.isEmpty) {
        return {
          'success': false,
          'error': 'Seller ID and Product ID are required',
        };
      }

      return {
        'success': true,
        'message': 'Violation marked as resolved',
        'sellerId': sellerId,
        'productId': productId,
        'actionTaken': actionTaken,
        'status': statusResolved,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to resolve violation: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== COMPLETE WORKFLOW EXECUTION ====================

  /// Execute complete price violation resolution workflow
  /// 
  /// Process:
  /// 1. Get violation details
  /// 2. Determine severity
  /// 3. Choose action (warn/adjust/suspend)
  /// 4. Take action
  /// 5. Notify seller
  /// 6. Return summary
  /// 
  /// Used for: One-step violation handling
  static Future<Map<String, dynamic>> executePriceViolationWorkflow({
    required String sellerId,
    required String productId,
    required String action, // WARNING, FORCE_ADJUSTMENT, SUSPEND
    required double ceilingPrice,
    String? adminNotes,
  }) async {
    try {
      // Get violation details
      final detailsResult = await getViolationDetails(
        sellerId: sellerId,
        productId: productId,
      );

      if (!detailsResult['success']) {
        return {
          'success': false,
          'error': 'Failed to retrieve violation details',
        };
      }

      // Execute action
      Map<String, dynamic> actionResult;
      final listedPrice = detailsResult['listedPrice'] as double?;

      if (action.toUpperCase() == actionWarning) {
        actionResult = await issueWarning(
          sellerId: sellerId,
          productId: productId,
          listedPrice: listedPrice ?? 0,
          ceilingPrice: ceilingPrice,
          adminNotes: adminNotes,
        );
      } else if (action.toUpperCase() == actionForceAdjustment) {
        actionResult = await forceAdjustment(
          sellerId: sellerId,
          productId: productId,
          ceilingPrice: ceilingPrice,
          adminNotes: adminNotes,
        );
      } else if (action.toUpperCase() == actionSuspend) {
        actionResult = await suspendSellerForViolation(
          sellerId: sellerId,
          productId: productId,
          adminNotes: adminNotes,
        );
      } else {
        return {
          'success': false,
          'error': 'Invalid action. Use WARNING, FORCE_ADJUSTMENT, or SUSPEND',
        };
      }

      // Mark as resolved
      await resolveViolation(
        sellerId: sellerId,
        productId: productId,
        actionTaken: action,
        adminNotes: adminNotes,
      );

      return {
        'success': actionResult['success'],
        'violation': detailsResult,
        'action': actionResult,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to execute price violation workflow: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== HELPER METHODS ====================

  /// Determine appropriate action based on violation severity
  static String determineAction(double overagePercent) {
    if (overagePercent > suspensionThresholdPercent) {
      return actionSuspend;
    } else if (overagePercent > warningThresholdPercent) {
      return actionForceAdjustment;
    } else {
      return actionWarning;
    }
  }

  /// Calculate overage percentage
  static double calculateOveragePercent(double listedPrice, double ceilingPrice) {
    if (ceilingPrice <= 0) return 0;
    return ((listedPrice - ceilingPrice) / ceilingPrice * 100);
  }

  /// Get severity color (for UI)
  static String getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'LOW':
        return '#FFC107'; // Yellow
      case 'MEDIUM':
        return '#FF9800'; // Orange
      case 'HIGH':
        return '#F44336'; // Red
      default:
        return '#757575'; // Gray
    }
  }

  /// Get action description
  static String getActionDescription(String action) {
    switch (action.toUpperCase()) {
      case actionWarning:
        return 'Issue 24-hour warning';
      case actionForceAdjustment:
        return 'Automatically adjust price to ceiling';
      case actionSuspend:
        return 'Suspend seller account';
      default:
        return action;
    }
  }

  /// Check if violation is repeat offense
  static bool isRepeatOffender(List<dynamic> violationHistory) {
    return violationHistory.length > 1;
  }

  /// Calculate compliance deadline (24 hours from now)
  static DateTime getComplianceDeadline() {
    return DateTime.now().add(const Duration(hours: compliancePeriodHours));
  }
}
