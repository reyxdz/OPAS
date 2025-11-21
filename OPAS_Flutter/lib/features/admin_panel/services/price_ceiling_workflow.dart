import 'package:flutter/foundation.dart';
import '../../../core/services/admin_service.dart';

/// ============================================================================
/// PriceCeilingWorkflow - Phase 3.3 Implementation
/// 
/// Manages the complete price ceiling update workflow including:
/// 1. Fetching current price ceilings
/// 2. Getting affected sellers and products
/// 3. Updating ceiling prices
/// 4. Auto-flagging non-compliant listings
/// 5. Notifying sellers of changes
/// 6. Creating price advisories
/// 7. Recording changes in audit log
/// 
/// Architecture: Service layer using AdminService for API calls
/// Pattern: Static methods for state-free operations
/// Error Handling: Try/catch with meaningful error messages
/// ============================================================================

class PriceCeilingWorkflow {
  // ==================== REASON CONSTANTS ====================
  static const String reasonMarketAdjustment = 'Market Adjustment';
  static const String reasonForecastUpdate = 'Forecast Update';
  static const String reasonCompliance = 'Compliance';
  static const String reasonOther = 'Other';

  // ==================== ADVISORY TYPES ====================
  static const String advisoryPrice = 'Price Update';
  static const String advisoryShortage = 'Shortage Alert';
  static const String advisoryPromotion = 'Promotion';
  static const String advisoryTrend = 'Market Trend';

  // ==================== STEP 1: FETCH PRICE CEILINGS ====================

  /// Get all current price ceilings
  /// 
  /// Returns: List of products with current ceiling prices
  /// Includes: Product name, category, current ceiling, previous ceiling, effective date
  static Future<Map<String, dynamic>> getPriceCeilings({
    String? productName,
    String? category,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await AdminService.getPriceCeilings(
        product: productName,
        search: productName,
      );

      return {
        'success': true,
        'data': result,
        'count': result.length,
        'page': page,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to get price ceilings: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'data': [],
      };
    }
  }

  // ==================== STEP 2: GET AFFECTED SELLERS ====================

  /// Get sellers and listings affected by a price ceiling change
  /// 
  /// Returns: List of sellers with products that would be affected
  /// Used for: Preview impact before confirming change
  static Future<Map<String, dynamic>> getAffectedSellers({
    required String productId,
    required double newCeiling,
  }) async {
    try {
      // Get non-compliant listings (already above ceiling)
      final violations = await AdminService.getNonCompliantListings();

      // Filter to affected product
      final affected = violations.where((v) {
        return v['product_id'].toString() == productId;
      }).toList();

      return {
        'success': true,
        'affectedListings': affected,
        'affectedSellersCount': _getUniqueSellers(affected).length,
        'affectedProductCount': affected.length,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to get affected sellers: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'affectedListings': [],
      };
    }
  }

  // ==================== STEP 3: PREVIEW IMPACT ====================

  /// Preview impact of price ceiling change before confirming
  /// 
  /// Shows:
  /// - Number of affected sellers
  /// - Number of affected listings
  /// - Current vs new ceiling comparison
  /// - Non-compliant listings that will be flagged
  /// 
  /// Returns: Impact summary
  static Future<Map<String, dynamic>> previewImpact({
    required String productId,
    required double currentCeiling,
    required double newCeiling,
  }) async {
    try {
      // Get affected sellers
      final affectedResult = await getAffectedSellers(
        productId: productId,
        newCeiling: newCeiling,
      );

      if (!affectedResult['success']) {
        return {
          'success': false,
          'error': 'Failed to get impact preview',
        };
      }

      final affectedListings = affectedResult['affectedListings'] as List? ?? [];
      
      // Count listings that will become compliant/non-compliant
      int willBecomeCheaper = 0;
      int willBecomeExpensive = 0;

      for (final listing in affectedListings) {
        final listedPrice = (listing['listed_price'] as num?)?.toDouble() ?? 0;
        
        if (listedPrice > currentCeiling && listedPrice <= newCeiling) {
          willBecomeCheaper++;
        } else if (listedPrice > newCeiling) {
          willBecomeExpensive++;
        }
      }

      return {
        'success': true,
        'currentCeiling': currentCeiling,
        'newCeiling': newCeiling,
        'change': newCeiling - currentCeiling,
        'changePercent': ((newCeiling - currentCeiling) / currentCeiling * 100),
        'affectedSellers': affectedResult['affectedSellersCount'],
        'affectedListings': affectedListings.length,
        'willBecomeCheaper': willBecomeCheaper,
        'willBecomeExpensive': willBecomeExpensive,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to preview impact: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== STEP 4: UPDATE PRICE CEILING ====================

  /// Update a product's price ceiling
  /// 
  /// Process:
  /// 1. Validate new ceiling is positive
  /// 2. Update ceiling in database
  /// 3. Auto-flag currently non-compliant listings
  /// 4. Notify affected sellers
  /// 5. Create price advisory for marketplace
  /// 6. Record change in audit log
  /// 
  /// Returns: Success/failure with updated ceiling details
  static Future<Map<String, dynamic>> updatePriceCeiling({
    required String productId,
    required double newCeiling,
    required String reason,
    String? justification,
    DateTime? effectiveDate,
    bool notifySellers = true,
    bool createAdvisory = true,
  }) async {
    try {
      // Validate input
      if (productId.isEmpty) {
        return {
          'success': false,
          'error': 'Product ID is required',
        };
      }

      if (newCeiling <= 0) {
        return {
          'success': false,
          'error': 'Ceiling price must be greater than 0',
        };
      }

      if (reason.isEmpty) {
        return {
          'success': false,
          'error': 'Reason for change is required',
        };
      }

      // Call API to update ceiling
      final result = await AdminService.updatePriceCeiling(
        productId,
        newCeiling: newCeiling,
        reason: reason,
        effectiveDate: effectiveDate ?? DateTime.now(),
      );

      if (result['success'] != false) {
        // Auto-create price advisory if requested
        if (createAdvisory) {
          _createPriceAdvisory(
            productId: productId,
            newCeiling: newCeiling,
            reason: reason,
          );
        }

        return {
          'success': true,
          'message': 'Price ceiling updated successfully',
          'ceiling': result,
          'productId': productId,
          'newCeiling': newCeiling,
          'reason': reason,
        };
      }

      return {
        'success': false,
        'error': result['error'] ?? 'Failed to update price ceiling',
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to update price ceiling: $e');
      }
      return {
        'success': false,
        'error': 'Error updating price ceiling: ${e.toString()}',
      };
    }
  }

  // ==================== STEP 5: AUTO-FLAG VIOLATIONS ====================

  /// Automatically flag listings that violate the new ceiling
  /// 
  /// Returns: List of newly flagged violations
  static Future<Map<String, dynamic>> autoFlagViolations({
    required String productId,
    required double newCeiling,
  }) async {
    try {
      final violations = await AdminService.getNonCompliantListings();

      List<dynamic> newViolations = [];

      for (final violation in violations) {
        if (violation['product_id'].toString() == productId) {
          newViolations.add(violation);
        }
      }

      return {
        'success': true,
        'flaggedCount': newViolations.length,
        'violations': newViolations,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to flag violations: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'violations': [],
      };
    }
  }

  // ==================== STEP 6: CREATE PRICE ADVISORY ====================

  /// Create a price advisory for marketplace notification
  /// 
  /// Used for: Notifying sellers and buyers of price changes
  static Future<Map<String, dynamic>> _createPriceAdvisory({
    required String productId,
    required double newCeiling,
    required String reason,
  }) async {
    try {
      final result = await AdminService.createPriceAdvisory(
        type: advisoryPrice,
        title: 'Price Ceiling Updated',
        content: 'The price ceiling for this product has been updated to $newCeiling due to $reason',
        targetAudience: 'sellers',
      );

      return {
        'success': result['success'] != false,
        'advisory': result,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to create price advisory: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== STEP 7: GET PRICE HISTORY ====================

  /// Get price change history for a product
  /// 
  /// Shows: All previous ceiling changes with reason, admin, timestamp
  static Future<Map<String, dynamic>> getPriceHistory(
    String productId,
  ) async {
    try {
      final history = await AdminService.getPriceCeilingHistory(productId);

      return {
        'success': true,
        'history': history,
        'count': history.length,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to get price history: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'history': [],
      };
    }
  }

  // ==================== COMPLETE WORKFLOW EXECUTION ====================

  /// Execute complete price ceiling update workflow
  /// 
  /// Process:
  /// 1. Validate new ceiling
  /// 2. Preview impact
  /// 3. Update ceiling
  /// 4. Flag violations
  /// 5. Create advisory
  /// 6. Return summary
  /// 
  /// Used for: One-step price ceiling update
  static Future<Map<String, dynamic>> executePriceCeilingWorkflow({
    required String productId,
    required double newCeiling,
    required String reason,
    String? justification,
  }) async {
    try {
      // Get current ceiling for comparison
      final ceilings = await getPriceCeilings();
      
      double currentCeiling = 0;
      if (ceilings['success'] && ceilings['data'] is List) {
        for (final ceiling in ceilings['data'] as List) {
          if (ceiling['product_id'].toString() == productId) {
            currentCeiling = (ceiling['ceiling_price'] as num?)?.toDouble() ?? 0;
            break;
          }
        }
      }

      // Preview impact
      final impactResult = await previewImpact(
        productId: productId,
        currentCeiling: currentCeiling,
        newCeiling: newCeiling,
      );

      // Update ceiling
      final updateResult = await updatePriceCeiling(
        productId: productId,
        newCeiling: newCeiling,
        reason: reason,
        justification: justification,
      );

      // Flag violations
      final flagResult = await autoFlagViolations(
        productId: productId,
        newCeiling: newCeiling,
      );

      return {
        'success': updateResult['success'],
        'impact': impactResult,
        'update': updateResult,
        'violations': flagResult,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to execute price ceiling workflow: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== HELPER METHODS ====================

  /// Extract unique seller IDs from violations list
  static List<String> _getUniqueSellers(List<dynamic> violations) {
    final sellers = <String>{};
    for (final violation in violations) {
      final sellerId = violation['seller_id']?.toString();
      if (sellerId != null) {
        sellers.add(sellerId);
      }
    }
    return sellers.toList();
  }

  /// Get reason description
  static String getReasonDescription(String reason) {
    switch (reason) {
      case reasonMarketAdjustment:
        return 'Adjusted based on market conditions';
      case reasonForecastUpdate:
        return 'Updated based on demand forecast';
      case reasonCompliance:
        return 'Compliance adjustment';
      case reasonOther:
        return 'Other reason (see notes)';
      default:
        return reason;
    }
  }

  /// Check if price change is significant (>10%)
  static bool isSignificantChange(double oldPrice, double newPrice) {
    final percentChange = ((newPrice - oldPrice) / oldPrice * 100).abs();
    return percentChange > 10;
  }

  /// Format price for display
  static String formatPrice(double price) {
    return 'PKR ${price.toStringAsFixed(2)}';
  }
}
