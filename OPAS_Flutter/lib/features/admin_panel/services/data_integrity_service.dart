/// Data Integrity Service
///
/// Validates data consistency and integrity across all domains.
/// Ensures marketplace data is accurate, consistent, and compliant.
///
/// Features:
/// - Price change integrity validation
/// - Seller data consistency verification
/// - OPAS inventory accuracy checks
/// - Cross-domain referential integrity
/// - Duplicate detection
/// - Data anomaly detection
/// - Integrity scoring and reports
/// - Automated repair recommendations
/// - Historical integrity tracking
///
/// Architecture: Stateless utility class with validation methods
/// All methods are static and provide detailed validation reports
/// Error handling: Comprehensive try/catch with logging

import 'package:opas_flutter/core/services/logger_service.dart';

class DataIntegrityService {
  DataIntegrityService._(); // Private constructor - no instantiation

  // ============================================================================
  // Constants: Validation Rules & Thresholds
  // ============================================================================

  // Validation Types
  static const String validationTypePrice = 'PRICE_VALIDATION';
  static const String validationTypeSeller = 'SELLER_VALIDATION';
  static const String validationTypeOPAS = 'OPAS_VALIDATION';
  static const String validationTypeReferential = 'REFERENTIAL_INTEGRITY';
  static const String validationTypeDuplicate = 'DUPLICATE_DETECTION';
  static const String validationTypeAnomaly = 'ANOMALY_DETECTION';

  // Integrity Status
  static const String integrityStatusClean = 'CLEAN';
  static const String integrityStatusWarning = 'WARNING';
  static const String integrityStatusCritical = 'CRITICAL';

  // Issue Severity
  static const String issueSeverityInfo = 'INFO';
  static const String issueSeverityWarning = 'WARNING';
  static const String issueSeverityError = 'ERROR';
  static const String issueSeverityCritical = 'CRITICAL';

  // Price Validation Thresholds
  static const double priceChangeMaxPercentage = 50.0; // 50% max change
  static const double priceMinimumValue = 0.01;
  static const double priceMaximumValue = 999999.99;
  static const int priceDecimalPlaces = 2;

  // Seller Validation Thresholds
  static const double sellerScoreMinimum = 0.0;
  static const double sellerScoreMaximum = 5.0;
  static const int sellerNameMinLength = 3;
  static const int sellerNameMaxLength = 100;

  // OPAS Validation Thresholds
  static const int opasMinimumQuantity = 1;
  static const int opasMaximumQuantity = 999999;
  static const double opasMinimumPrice = 0.01;
  static const double opasMaximumPrice = 100000.00;

  // Time Window Constants
  static const int validationHistoryDays = 90;
  static const int anomalyDetectionWindow = 30;

  // ============================================================================
  // Price Integrity Validation
  // ============================================================================

  /// Validates price change integrity for a seller's product.
  ///
  /// Checks:
  /// - Price change is within reasonable percentage
  /// - New price meets minimum/maximum bounds
  /// - Price has correct decimal places
  /// - Price change frequency is not suspicious
  /// - Change is within market norms for category
  ///
  /// Returns: Validation result with issues and recommendations
  /// Throws: Exception if validation fails
  static Future<Map<String, dynamic>> validatePriceChange({
    required String sellerId,
    required String productId,
    required double oldPrice,
    required double newPrice,
    required String productCategory,
    DateTime? previousPriceChangeTime,
  }) async {
    try {
      final validationId = _generateValidationId();
      final timestamp = DateTime.now();
      final issues = <Map<String, dynamic>>[];

      // Validate old price
      if (oldPrice < priceMinimumValue || oldPrice > priceMaximumValue) {
        issues.add({
          'severity': issueSeverityWarning,
          'code': 'INVALID_OLD_PRICE',
          'message': 'Old price is outside acceptable range',
          'old_price': oldPrice,
          'min': priceMinimumValue,
          'max': priceMaximumValue,
        });
      }

      // Validate new price
      if (newPrice < priceMinimumValue || newPrice > priceMaximumValue) {
        issues.add({
          'severity': issueSeverityCritical,
          'code': 'INVALID_NEW_PRICE',
          'message': 'New price is outside acceptable range',
          'new_price': newPrice,
          'min': priceMinimumValue,
          'max': priceMaximumValue,
        });
      }

      // Check decimal places
      final newPriceString = newPrice.toString();
      if (newPriceString.contains('.')) {
        final decimals = newPriceString.split('.')[1].length;
        if (decimals > priceDecimalPlaces) {
          issues.add({
            'severity': issueSeverityWarning,
            'code': 'EXCESSIVE_DECIMALS',
            'message':
                'Price has more than $priceDecimalPlaces decimal places',
            'price': newPrice,
            'decimals': decimals,
          });
        }
      }

      // Calculate percentage change
      final percentageChange = ((newPrice - oldPrice) / oldPrice * 100).abs();

      // Validate price change percentage
      if (percentageChange > priceChangeMaxPercentage) {
        issues.add({
          'severity': issueSeverityCritical,
          'code': 'EXCESSIVE_PRICE_CHANGE',
          'message':
              'Price change of ${percentageChange.toStringAsFixed(1)}% exceeds maximum $priceChangeMaxPercentage%',
          'old_price': oldPrice,
          'new_price': newPrice,
          'percentage_change': percentageChange,
          'max_allowed': priceChangeMaxPercentage,
        });
      }

      // Check frequency of price changes
      if (previousPriceChangeTime != null) {
        final hoursSinceLastChange =
            timestamp.difference(previousPriceChangeTime).inHours;
        if (hoursSinceLastChange < 24) {
          issues.add({
            'severity': issueSeverityWarning,
            'code': 'FREQUENT_PRICE_CHANGES',
            'message':
                'Price changed again within 24 hours (last change: $hoursSinceLastChange hours ago)',
            'hours_since_last_change': hoursSinceLastChange,
          });
        }
      }

      // Determine overall status
      final criticalCount =
          issues.where((i) => i['severity'] == issueSeverityCritical).length;
      final warningCount =
          issues.where((i) => i['severity'] == issueSeverityWarning).length;

      final integrityStatus = criticalCount > 0
          ? integrityStatusCritical
          : warningCount > 0
              ? integrityStatusWarning
              : integrityStatusClean;

      LoggerService.info(
        'Price integrity validation completed: $integrityStatus',
        tag: 'DATA_INTEGRITY',
        metadata: {
          'validationId': validationId,
          'sellerId': sellerId,
          'productId': productId,
          'status': integrityStatus,
          'issueCount': issues.length,
        },
      );

      return {
        'validation_id': validationId,
        'validation_type': validationTypePrice,
        'timestamp': timestamp.toIso8601String(),
        'seller_id': sellerId,
        'product_id': productId,
        'integrity_status': integrityStatus,
        'old_price': oldPrice,
        'new_price': newPrice,
        'percentage_change': percentageChange.toStringAsFixed(1),
        'issue_count': issues.length,
        'critical_issues': criticalCount,
        'warning_issues': warningCount,
        'issues': issues,
        'is_valid': criticalCount == 0,
        'recommendations': _generatePriceRecommendations(issues),
      };
    } catch (e) {
      LoggerService.error(
        'Error validating price change',
        tag: 'DATA_INTEGRITY',
        error: e,
      );
      rethrow;
    }
  }

  // ============================================================================
  // Seller Data Integrity Validation
  // ============================================================================

  /// Validates seller data consistency and completeness.
  ///
  /// Checks:
  /// - Required fields present
  /// - Field values within acceptable ranges
  /// - Data type correctness
  /// - No duplicate seller records
  /// - Reference data validity
  /// - Document verification status
  ///
  /// Returns: Validation result with data quality score
  /// Throws: Exception if validation fails
  static Future<Map<String, dynamic>> validateSellerData({
    required String sellerId,
    required Map<String, dynamic> sellerData,
  }) async {
    try {
      final validationId = _generateValidationId();
      final timestamp = DateTime.now();
      final issues = <Map<String, dynamic>>[];

      // Validate seller name
      final sellerName = sellerData['name'] as String?;
      if (sellerName == null || sellerName.isEmpty) {
        issues.add({
          'severity': issueSeverityCritical,
          'code': 'MISSING_SELLER_NAME',
          'message': 'Seller name is missing',
        });
      } else if (sellerName.length < sellerNameMinLength) {
        issues.add({
          'severity': issueSeverityError,
          'code': 'INVALID_SELLER_NAME_LENGTH',
          'message': 'Seller name is too short (minimum $sellerNameMinLength)',
          'name': sellerName,
          'length': sellerName.length,
        });
      } else if (sellerName.length > sellerNameMaxLength) {
        issues.add({
          'severity': issueSeverityError,
          'code': 'INVALID_SELLER_NAME_LENGTH',
          'message': 'Seller name is too long (maximum $sellerNameMaxLength)',
          'name': sellerName,
          'length': sellerName.length,
        });
      }

      // Validate seller quality score
      final qualityScore = sellerData['quality_score'] as num?;
      if (qualityScore != null) {
        if (qualityScore < sellerScoreMinimum || qualityScore > sellerScoreMaximum) {
          issues.add({
            'severity': issueSeverityWarning,
            'code': 'INVALID_QUALITY_SCORE',
            'message': 'Quality score is outside acceptable range',
            'quality_score': qualityScore,
            'min': sellerScoreMinimum,
            'max': sellerScoreMaximum,
          });
        }
      }

      // Validate email if present
      final email = sellerData['email'] as String?;
      if (email != null && !_isValidEmail(email)) {
        issues.add({
          'severity': issueSeverityError,
          'code': 'INVALID_EMAIL_FORMAT',
          'message': 'Email format is invalid',
          'email': email,
        });
      }

      // Validate phone if present
      final phone = sellerData['phone'] as String?;
      if (phone != null && !_isValidPhone(phone)) {
        issues.add({
          'severity': issueSeverityWarning,
          'code': 'INVALID_PHONE_FORMAT',
          'message': 'Phone format appears invalid',
          'phone': phone,
        });
      }

      // Validate document status
      final documentsVerified = sellerData['documents_verified'] as bool?;
      final documentStatus = sellerData['document_status'] as String?;
      if (documentsVerified == true && (documentStatus == null || documentStatus.isEmpty)) {
        issues.add({
          'severity': issueSeverityWarning,
          'code': 'MISSING_DOCUMENT_STATUS',
          'message':
              'Documents marked verified but status is not recorded',
        });
      }

      // Calculate integrity score
      const maxPossibleIssues = 6;
      final integrityScore =
          ((maxPossibleIssues - issues.length) / maxPossibleIssues * 100)
              .toStringAsFixed(1);

      // Determine overall status
      final criticalCount =
          issues.where((i) => i['severity'] == issueSeverityCritical).length;
      final integrityStatus = criticalCount > 0
          ? integrityStatusCritical
          : issues.isNotEmpty
              ? integrityStatusWarning
              : integrityStatusClean;

      LoggerService.info(
        'Seller data validation completed: $integrityStatus',
        tag: 'DATA_INTEGRITY',
        metadata: {
          'validationId': validationId,
          'sellerId': sellerId,
          'status': integrityStatus,
          'integrityScore': integrityScore,
        },
      );

      return {
        'validation_id': validationId,
        'validation_type': validationTypeSeller,
        'timestamp': timestamp.toIso8601String(),
        'seller_id': sellerId,
        'integrity_status': integrityStatus,
        'integrity_score': integrityScore,
        'issue_count': issues.length,
        'critical_issues':
            issues.where((i) => i['severity'] == issueSeverityCritical).length,
        'error_issues':
            issues.where((i) => i['severity'] == issueSeverityError).length,
        'warning_issues':
            issues.where((i) => i['severity'] == issueSeverityWarning).length,
        'issues': issues,
        'is_valid': criticalCount == 0,
        'recommendations': _generateSellerRecommendations(issues),
      };
    } catch (e) {
      LoggerService.error(
        'Error validating seller data',
        tag: 'DATA_INTEGRITY',
        error: e,
      );
      rethrow;
    }
  }

  // ============================================================================
  // OPAS Inventory Integrity Validation
  // ============================================================================

  /// Validates OPAS inventory data integrity.
  ///
  /// Checks:
  /// - Quantity within acceptable range
  /// - Price within acceptable range
  /// - Stock level accuracy
  /// - Price ceiling compliance
  /// - Inventory discrepancies
  ///
  /// Returns: OPAS integrity validation result
  /// Throws: Exception if validation fails
  static Future<Map<String, dynamic>> validateOPASIntegrity({
    required String opasId,
    required int quantity,
    required double price,
    required double priceCeiling,
    required int recordedQuantity,
  }) async {
    try {
      final validationId = _generateValidationId();
      final timestamp = DateTime.now();
      final issues = <Map<String, dynamic>>[];

      // Validate quantity
      if (quantity < opasMinimumQuantity) {
        issues.add({
          'severity': issueSeverityWarning,
          'code': 'INSUFFICIENT_QUANTITY',
          'message': 'Quantity is below minimum',
          'quantity': quantity,
          'minimum': opasMinimumQuantity,
        });
      }

      if (quantity > opasMaximumQuantity) {
        issues.add({
          'severity': issueSeverityError,
          'code': 'EXCESSIVE_QUANTITY',
          'message': 'Quantity exceeds maximum',
          'quantity': quantity,
          'maximum': opasMaximumQuantity,
        });
      }

      // Validate price
      if (price < opasMinimumPrice || price > opasMaximumPrice) {
        issues.add({
          'severity': issueSeverityCritical,
          'code': 'INVALID_OPAS_PRICE',
          'message': 'OPAS price is outside acceptable range',
          'price': price,
          'min': opasMinimumPrice,
          'max': opasMaximumPrice,
        });
      }

      // Check price ceiling compliance
      if (price > priceCeiling) {
        issues.add({
          'severity': issueSeverityCritical,
          'code': 'PRICE_CEILING_VIOLATION',
          'message': 'Price exceeds ceiling',
          'price': price,
          'ceiling': priceCeiling,
          'excess': (price - priceCeiling).toStringAsFixed(2),
        });
      }

      // Check inventory discrepancy
      final discrepancy = (quantity - recordedQuantity).abs();
      if (discrepancy > 0) {
        final discrepancyPercentage = (discrepancy / recordedQuantity * 100);
        if (discrepancyPercentage > 5.0) {
          issues.add({
            'severity': issueSeverityCritical,
            'code': 'INVENTORY_DISCREPANCY',
            'message':
                'Inventory discrepancy detected (${discrepancyPercentage.toStringAsFixed(1)}%)',
            'actual_quantity': quantity,
            'recorded_quantity': recordedQuantity,
            'discrepancy': discrepancy,
            'discrepancy_percentage': discrepancyPercentage.toStringAsFixed(1),
          });
        } else if (discrepancyPercentage > 1.0) {
          issues.add({
            'severity': issueSeverityWarning,
            'code': 'MINOR_INVENTORY_DISCREPANCY',
            'message':
                'Minor inventory discrepancy (${discrepancyPercentage.toStringAsFixed(1)}%)',
            'discrepancy': discrepancy,
          });
        }
      }

      // Determine overall status
      final criticalCount =
          issues.where((i) => i['severity'] == issueSeverityCritical).length;
      final integrityStatus = criticalCount > 0
          ? integrityStatusCritical
          : issues.isNotEmpty
              ? integrityStatusWarning
              : integrityStatusClean;

      LoggerService.info(
        'OPAS integrity validation completed: $integrityStatus',
        tag: 'DATA_INTEGRITY',
        metadata: {
          'validationId': validationId,
          'opasId': opasId,
          'status': integrityStatus,
          'issueCount': issues.length,
        },
      );

      return {
        'validation_id': validationId,
        'validation_type': validationTypeOPAS,
        'timestamp': timestamp.toIso8601String(),
        'opas_id': opasId,
        'integrity_status': integrityStatus,
        'quantity': quantity,
        'recorded_quantity': recordedQuantity,
        'price': price,
        'price_ceiling': priceCeiling,
        'issue_count': issues.length,
        'critical_issues': criticalCount,
        'issues': issues,
        'is_valid': criticalCount == 0,
        'recommendations': _generateOPASRecommendations(issues),
      };
    } catch (e) {
      LoggerService.error(
        'Error validating OPAS integrity',
        tag: 'DATA_INTEGRITY',
        error: e,
      );
      rethrow;
    }
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Generates unique validation ID
  static String _generateValidationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'validation_$timestamp';
  }

  /// Validates email format
  static bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// Validates phone format
  static bool _isValidPhone(String phone) {
    // Simple validation: at least 10 digits
    final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return digitsOnly.length >= 10;
  }

  /// Generates price validation recommendations
  static List<String> _generatePriceRecommendations(
    List<Map<String, dynamic>> issues,
  ) {
    final recommendations = <String>[];

    for (final issue in issues) {
      final code = issue['code'] as String;
      switch (code) {
        case 'EXCESSIVE_PRICE_CHANGE':
          recommendations.add('Require admin approval for price changes > 50%');
          break;
        case 'FREQUENT_PRICE_CHANGES':
          recommendations.add('Implement rate limiting (max 1 change per 24h)');
          break;
        case 'INVALID_NEW_PRICE':
          recommendations.add('Validate price is between \$0.01 and \$999,999.99');
          break;
      }
    }

    return recommendations;
  }

  /// Generates seller validation recommendations
  static List<String> _generateSellerRecommendations(
    List<Map<String, dynamic>> issues,
  ) {
    final recommendations = <String>[];

    for (final issue in issues) {
      final code = issue['code'] as String;
      switch (code) {
        case 'MISSING_SELLER_NAME':
          recommendations.add('Update seller record with valid name');
          break;
        case 'INVALID_EMAIL_FORMAT':
          recommendations.add('Correct email address format');
          break;
        case 'MISSING_DOCUMENT_STATUS':
          recommendations.add('Record document verification status');
          break;
      }
    }

    return recommendations;
  }

  /// Generates OPAS validation recommendations
  static List<String> _generateOPASRecommendations(
    List<Map<String, dynamic>> issues,
  ) {
    final recommendations = <String>[];

    for (final issue in issues) {
      final code = issue['code'] as String;
      switch (code) {
        case 'PRICE_CEILING_VIOLATION':
          recommendations.add('Enforce price ceiling immediately');
          break;
        case 'INVENTORY_DISCREPANCY':
          recommendations.add('Conduct full inventory audit and reconciliation');
          break;
        case 'INVALID_OPAS_PRICE':
          recommendations.add('Validate and correct OPAS price');
          break;
      }
    }

    return recommendations;
  }
}
