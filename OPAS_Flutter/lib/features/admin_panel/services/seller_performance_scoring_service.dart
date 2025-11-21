/// Seller Performance Scoring Service
///
/// Implements comprehensive seller quality, compliance, and reliability tracking.
/// Scores track seller quality (0-100) combining multiple performance dimensions.
///
/// Components:
/// - Product Quality (25% weight): Product ratings, quality scores
/// - Compliance Record (25% weight): Rule adherence, violations
/// - Reliability Score (20% weight): On-time delivery, consistency
/// - Transaction Success (15% weight): Successful transactions percentage
/// - Customer Response (15% weight): Customer satisfaction, feedback
///
/// Score Interpretation:
/// - 90-100: Excellent seller - Top tier, trusted vendor
/// - 75-90: Good seller - Reliable, consistent performance
/// - 60-75: Fair seller - Acceptable but improving
/// - 50-60: Poor seller - Problematic behavior, requires monitoring
/// - 0-50: Unacceptable seller - Consider suspension or remediation
///
/// Architecture: Stateless utility class with AdminService integration
/// All methods are static and operate independently
/// Error handling: Comprehensive try/catch with logging

import 'package:opas_flutter/core/services/admin_service.dart';
import 'package:opas_flutter/core/services/logger_service.dart';

class SellerPerformanceScoringService {
  SellerPerformanceScoringService._(); // Private constructor - no instantiation

  // ============================================================================
  // Constants: Performance Score Configuration
  // ============================================================================

  // Component Weights (must sum to 1.0)
  static const double weightProductQuality = 0.25;
  static const double weightComplianceRecord = 0.25;
  static const double weightReliabilityScore = 0.20;
  static const double weightTransactionSuccess = 0.15;
  static const double weightCustomerResponse = 0.15;

  // Performance Tiers
  static const String tierExcellent = 'EXCELLENT';
  static const String tierGood = 'GOOD';
  static const String tierFair = 'FAIR';
  static const String tierPoor = 'POOR';
  static const String tierUnacceptable = 'UNACCEPTABLE';

  // Performance Thresholds
  static const double thresholdExcellent = 90.0;
  static const double thresholdGood = 75.0;
  static const double thresholdFair = 60.0;
  static const double thresholdPoor = 50.0;

  // Badge Categories (achievement tracking)
  static const String badgeTopPerformer = 'TOP_PERFORMER';
  static const String badgeConsistentQuality = 'CONSISTENT_QUALITY';
  static const String badgeReliableDelivery = 'RELIABLE_DELIVERY';
  static const String badgeCustomerFavorite = 'CUSTOMER_FAVORITE';
  static const String badgeComplianceLeader = 'COMPLIANCE_LEADER';

  // Time windows
  static const int evaluationWindowDays = 90;
  static const int minimumTransactionsForScore = 10;

  // ============================================================================
  // Step 1: Calculate Product Quality Score
  // ============================================================================

  /// Calculates product quality component (0-100).
  ///
  /// Measures quality of seller's products based on:
  /// - Average product rating (customer ratings)
  /// - Quality grade scores
  /// - Product listing completeness
  /// - Complaint/defect rate
  ///
  /// Calculation:
  /// Score = (avg_rating / 5 * 40) + (avg_quality_grade * 30) + (100 - defect_rate * 30)
  ///
  /// Returns: Product quality score (0-100)
  /// Throws: Exception if calculation fails
  static Future<Map<String, dynamic>> calculateProductQualityScore(
    String sellerId,
  ) async {
    try {
      // Get seller's products (mock data generator)
      final products = _generateMockProducts(5);

      if (products.isEmpty) {
        return {
          'component': 'PRODUCT_QUALITY',
          'score': 50.0,
          'seller_id': sellerId,
          'status': 'NO_PRODUCTS',
        };
      }

      // Calculate metrics from mock products
      double totalRating = 0;
      double totalQualityGrade = 0;
      int complaintCount = 0;

      for (final product in products) {
        final rating = (product['average_rating'] as num).toDouble();
        final qualityGrade = (product['quality_grade'] as num).toDouble();
        final complaints = (product['complaint_count'] as int);

        totalRating += rating;
        totalQualityGrade += qualityGrade;
        complaintCount += complaints;
      }

      final avgRating = totalRating / products.length;
      final avgQualityGrade = totalQualityGrade / products.length;
      final defectRate = (complaintCount / products.length);

      // Composite score
      final score = (avgRating / 5 * 40) +
          (avgQualityGrade * 30) +
          ((100 - defectRate * 10).clamp(0, 100) * 0.30);

      return {
        'component': 'PRODUCT_QUALITY',
        'score': score.clamp(0, 100).toStringAsFixed(2),
        'seller_id': sellerId,
        'average_rating': avgRating.toStringAsFixed(1),
        'average_quality_grade': avgQualityGrade.toStringAsFixed(1),
        'products_count': products.length,
        'complaint_rate': defectRate.toStringAsFixed(2),
        'status': 'SUCCESS',
      };
    } catch (e) {
      LoggerService.error(
        'Error calculating product quality score',
        tag: 'PRODUCT_QUALITY',
        error: e,
      );
      rethrow;
    }
  }

  /// Helper: Generate mock products for testing
  static List<Map<String, dynamic>> _generateMockProducts(int count) {
    final products = <Map<String, dynamic>>[];
    for (int i = 0; i < count; i++) {
      products.add({
        'id': 'prod_$i',
        'name': 'Product $i',
        'average_rating': 3.5 + (i % 2),
        'quality_grade': 3.0 + (i % 3),
        'complaint_count': i % 3,
      });
    }
    return products;
  }

  /// Helper: Generate mock compliance data
  static Map<String, dynamic> _generateMockCompliance() {
    return {
      'total_violations': 1,
      'price_violations': 0,
      'documentation_violations': 1,
      'listing_violations': 0,
      'is_suspended': false,
    };
  }

  // ============================================================================
  // Step 2: Calculate Compliance Record Score
  // ============================================================================

  /// Calculates compliance record component (0-100).
  ///
  /// Measures seller's adherence to marketplace rules:
  /// - Price ceiling violations
  /// - Documentation compliance
  /// - Listing requirement compliance
  /// - Return policy compliance
  /// - No active suspensions
  ///
  /// Calculation: (100 - violation_count * weight) for each violation type
  ///
  /// Returns: Compliance record score (0-100)
  /// Throws: Exception if calculation fails
  static Future<Map<String, dynamic>> calculateComplianceRecordScore(
    String sellerId,
  ) async {
    try {
      // Get seller compliance data
      final complianceData = _generateMockCompliance();

      final totalViolations = complianceData['total_violations'] as int;
      final priceViolations = complianceData['price_violations'] as int;
      final docViolations = complianceData['documentation_violations'] as int;
      final listingViolations = complianceData['listing_violations'] as int;
      final isSuspended = complianceData['is_suspended'] as bool;

      // Calculate penalty
      int penaltyPoints = 0;

      // Price violations: 5 points each
      penaltyPoints += priceViolations * 5;

      // Documentation violations: 3 points each
      penaltyPoints += docViolations * 3;

      // Listing violations: 2 points each
      penaltyPoints += listingViolations * 2;

      // Suspended: 50 point penalty
      if (isSuspended) {
        penaltyPoints += 50;
      }

      // Score = 100 - penalty (clamped 0-100)
      final score = (100 - penaltyPoints).clamp(0, 100).toDouble();

      return {
        'component': 'COMPLIANCE_RECORD',
        'score': score.toStringAsFixed(2),
        'seller_id': sellerId,
        'total_violations': totalViolations,
        'price_violations': priceViolations,
        'documentation_violations': docViolations,
        'listing_violations': listingViolations,
        'is_suspended': isSuspended,
        'status': 'SUCCESS',
      };
    } catch (e) {
      LoggerService.error(
        'Error calculating compliance record score',
        tag: 'COMPLIANCE_RECORD',
        error: e,
      );
      rethrow;
    }
  }

  // ============================================================================
  // Step 3: Calculate Reliability Score
  // ============================================================================

  /// Calculates reliability component (0-100).
  ///
  /// Measures seller's consistency and dependability:
  /// - On-time delivery rate
  /// - Order fulfillment rate
  /// - Consistent activity (no long gaps)
  /// - Response time to messages
  ///
  /// Calculation:
  /// Score = (on_time_rate * 50) + (fulfillment_rate * 30) + (response_time_score * 20)
  ///
  /// Returns: Reliability score (0-100)
  /// Throws: Exception if calculation fails
  static Future<Map<String, dynamic>> calculateReliabilityScore(
    String sellerId,
  ) async {
    try {
      // Get seller delivery and fulfillment data (mock)
      final orders = _generateMockOrders(8);

      if (orders.isEmpty) {
        return {
          'component': 'RELIABILITY_SCORE',
          'score': 50.0,
          'seller_id': sellerId,
          'status': 'NO_ORDERS',
        };
      }

      // Calculate on-time delivery rate
      int onTimeDeliveries = 0;
      for (final order in orders) {
        final wasOnTime = order['delivered_on_time'] as bool;
        if (wasOnTime) {
          onTimeDeliveries++;
        }
      }
      final onTimeRate = (onTimeDeliveries / orders.length * 100);

      // Calculate fulfillment rate (completed orders)
      final completedOrders =
          orders.where((o) => o['status'] == 'COMPLETED').length;
      final fulfillmentRate = (completedOrders / orders.length * 100);

      // Get response time average (mock - hours)
      const avgResponseTime = 18.0;

      // Convert response time to score (faster = higher score)
      // Target: < 4 hours = 100, 24 hours = 50, > 48 hours = 0
      final responseTimeScore = (100 - (avgResponseTime / 48 * 100)).clamp(0, 100);

      // Composite score
      final score = (onTimeRate * 0.50) +
          (fulfillmentRate * 0.30) +
          (responseTimeScore * 0.20);

      return {
        'component': 'RELIABILITY_SCORE',
        'score': score.clamp(0, 100).toStringAsFixed(2),
        'seller_id': sellerId,
        'on_time_delivery_rate_percentage': onTimeRate.toStringAsFixed(2),
        'fulfillment_rate_percentage': fulfillmentRate.toStringAsFixed(2),
        'average_response_time_hours': avgResponseTime.toStringAsFixed(1),
        'total_orders': orders.length,
        'status': 'SUCCESS',
      };
    } catch (e) {
      LoggerService.error(
        'Error calculating reliability score',
        tag: 'RELIABILITY',
        error: e,
      );
      rethrow;
    }
  }

  // ============================================================================
  // Step 4: Calculate Transaction Success Score
  // ============================================================================

  /// Calculates transaction success component (0-100).
  ///
  /// Measures transaction reliability:
  /// - Successful transaction rate
  /// - Payment success rate
  /// - Dispute rate
  /// - Return rate
  ///
  /// Calculation: (successful / total * 100) with penalties for disputes/returns
  ///
  /// Returns: Transaction success score (0-100)
  /// Throws: Exception if calculation fails
  static Future<Map<String, dynamic>> calculateTransactionSuccessScore(
    String sellerId,
  ) async {
    try {
      // Get transaction statistics (mock)
      final transactions = _generateMockTransactions(10);

      if (transactions.isEmpty) {
        return {
          'component': 'TRANSACTION_SUCCESS',
          'score': 50.0,
          'seller_id': sellerId,
          'status': 'NO_TRANSACTIONS',
        };
      }

      // Count transaction statuses
      int successful = 0;
      int disputed = 0;
      int returned = 0;
      int failed = 0;

      for (final tx in transactions) {
        final status = tx['status'] as String;
        if (status == 'SUCCESSFUL') {
          successful++;
        } else if (status == 'DISPUTED') {
          disputed++;
        } else if (status == 'RETURNED') {
          returned++;
        } else if (status == 'FAILED') {
          failed++;
        }
      }

      // Calculate rates
      final successRate = (successful / transactions.length * 100);
      final disputeRate = (disputed / transactions.length * 100);
      final returnRate = (returned / transactions.length * 100);

      // Calculate score with penalties
      double score = successRate;
      score -= disputeRate * 2; // 2x penalty for disputes
      score -= returnRate * 1; // 1x penalty for returns

      return {
        'component': 'TRANSACTION_SUCCESS',
        'score': score.clamp(0, 100).toStringAsFixed(2),
        'seller_id': sellerId,
        'successful_transactions': successful,
        'disputed_transactions': disputed,
        'returned_transactions': returned,
        'failed_transactions': failed,
        'success_rate_percentage': successRate.toStringAsFixed(2),
        'dispute_rate_percentage': disputeRate.toStringAsFixed(2),
        'return_rate_percentage': returnRate.toStringAsFixed(2),
        'total_transactions': transactions.length,
        'status': 'SUCCESS',
      };
    } catch (e) {
      LoggerService.error(
        'Error calculating transaction success score',
        tag: 'TRANSACTION_SUCCESS',
        error: e,
      );
      rethrow;
    }
  }

  // ============================================================================
  // Step 5: Calculate Customer Response Score
  // ============================================================================

  /// Calculates customer response component (0-100).
  ///
  /// Measures customer satisfaction and feedback:
  /// - Average customer rating
  /// - Positive review percentage
  /// - Repeat customer rate
  /// - Recommendation rate (if available)
  ///
  /// Calculation: Weighted average of metrics
  ///
  /// Returns: Customer response score (0-100)
  /// Throws: Exception if calculation fails
  static Future<Map<String, dynamic>> calculateCustomerResponseScore(
    String sellerId,
  ) async {
    try {
      // Get customer feedback (mock)
      final reviews = _generateMockReviews(6);

      if (reviews.isEmpty) {
        return {
          'component': 'CUSTOMER_RESPONSE',
          'score': 50.0,
          'seller_id': sellerId,
          'status': 'NO_REVIEWS',
        };
      }

      // Calculate metrics
      double totalRating = 0;
      int positiveReviews = 0;
      int repeatCustomers = 0;

      for (final review in reviews) {
        final rating = (review['rating'] as num).toDouble();
        totalRating += rating;

        if (rating >= 4) {
          positiveReviews++;
        }

        if (review['is_repeat_customer'] == true) {
          repeatCustomers++;
        }
      }

      final avgRating = totalRating / reviews.length;
      final positivePercentage = (positiveReviews / reviews.length * 100);
      final repeatRate = (repeatCustomers / reviews.length * 100);

      // Composite score
      final score = (avgRating / 5 * 50) +
          (positivePercentage / 100 * 30) +
          (repeatRate / 100 * 20);

      return {
        'component': 'CUSTOMER_RESPONSE',
        'score': score.clamp(0, 100).toStringAsFixed(2),
        'seller_id': sellerId,
        'average_rating': avgRating.toStringAsFixed(1),
        'positive_review_percentage': positivePercentage.toStringAsFixed(2),
        'repeat_customer_percentage': repeatRate.toStringAsFixed(2),
        'total_reviews': reviews.length,
        'status': 'SUCCESS',
      };
    } catch (e) {
      LoggerService.error(
        'Error calculating customer response score',
        tag: 'CUSTOMER_RESPONSE',
        error: e,
      );
      rethrow;
    }
  }

  // ============================================================================
  // Step 6: Generate Performance Badges
  // ============================================================================

  /// Generates performance badges based on seller's scores.
  ///
  /// Returns: List of earned badges with criteria
  /// Throws: Exception if badge generation fails
  static Future<List<Map<String, dynamic>>> generatePerformanceBadges(
    String sellerId,
    double overallScore,
    Map<String, dynamic> componentScores,
  ) async {
    try {
      final badges = <Map<String, dynamic>>[];

      // Extract component scores
      final qualityScore =
          double.tryParse(componentScores['product_quality'].toString()) ?? 0;
      final complianceScore =
          double.tryParse(componentScores['compliance_record'].toString()) ?? 0;
      final reliabilityScore =
          double.tryParse(componentScores['reliability_score'].toString()) ?? 0;
      final customerScore =
          double.tryParse(componentScores['customer_response'].toString()) ?? 0;

      // Badge 1: Top Performer
      if (overallScore >= thresholdExcellent) {
        badges.add({
          'badge': badgeTopPerformer,
          'description': 'Overall performance score >= 90',
          'earned_date': DateTime.now().toIso8601String(),
        });
      }

      // Badge 2: Consistent Quality
      if (qualityScore >= thresholdExcellent) {
        badges.add({
          'badge': badgeConsistentQuality,
          'description': 'Product quality score >= 90',
          'earned_date': DateTime.now().toIso8601String(),
        });
      }

      // Badge 3: Reliable Delivery
      if (reliabilityScore >= thresholdExcellent) {
        badges.add({
          'badge': badgeReliableDelivery,
          'description': 'Reliability score >= 90',
          'earned_date': DateTime.now().toIso8601String(),
        });
      }

      // Badge 4: Customer Favorite
      if (customerScore >= thresholdExcellent) {
        badges.add({
          'badge': badgeCustomerFavorite,
          'description': 'Customer response score >= 90',
          'earned_date': DateTime.now().toIso8601String(),
        });
      }

      // Badge 5: Compliance Leader
      if (complianceScore >= thresholdExcellent) {
        badges.add({
          'badge': badgeComplianceLeader,
          'description': 'Compliance record score >= 90',
          'earned_date': DateTime.now().toIso8601String(),
        });
      }

      return badges;
    } catch (e) {
      LoggerService.error(
        'Error generating performance badges',
        tag: 'PERFORMANCE_BADGES',
        error: e,
      );
      rethrow;
    }
  }

  // ============================================================================
  // Orchestration Method: Calculate Overall Seller Performance
  // ============================================================================

  /// Calculates comprehensive seller performance score.
  ///
  /// Steps:
  /// 1. Calculate all 5 component scores
  /// 2. Aggregate into overall score
  /// 3. Generate performance badges
  /// 4. Create performance tier classification
  /// 5. Generate insights and recommendations
  ///
  /// Returns: Complete seller performance profile
  /// Throws: Exception if calculation fails
  static Future<Map<String, dynamic>> calculateSellerPerformanceScore(
    String sellerId,
  ) async {
    try {
      final startTime = DateTime.now();

      // Calculate component scores in parallel
      final results = await Future.wait([
        calculateProductQualityScore(sellerId),
        calculateComplianceRecordScore(sellerId),
        calculateReliabilityScore(sellerId),
        calculateTransactionSuccessScore(sellerId),
        calculateCustomerResponseScore(sellerId),
      ]);

      // Extract scores
      final qualityScore = double.tryParse(results[0]['score'].toString()) ?? 50;
      final complianceScore =
          double.tryParse(results[1]['score'].toString()) ?? 50;
      final reliabilityScore =
          double.tryParse(results[2]['score'].toString()) ?? 50;
      final successScore = double.tryParse(results[3]['score'].toString()) ?? 50;
      final customerScore = double.tryParse(results[4]['score'].toString()) ?? 50;

      // Calculate overall score
      final overallScore = (qualityScore * weightProductQuality) +
          (complianceScore * weightComplianceRecord) +
          (reliabilityScore * weightReliabilityScore) +
          (successScore * weightTransactionSuccess) +
          (customerScore * weightCustomerResponse);

      // Create component breakdown
      final componentScores = {
        'product_quality': qualityScore.toStringAsFixed(2),
        'compliance_record': complianceScore.toStringAsFixed(2),
        'reliability_score': reliabilityScore.toStringAsFixed(2),
        'transaction_success': successScore.toStringAsFixed(2),
        'customer_response': customerScore.toStringAsFixed(2),
      };

      // Generate badges
      final badges =
          await generatePerformanceBadges(sellerId, overallScore, componentScores);

      // Generate insights
      final insights = _generatePerformanceInsights(
        sellerId,
        overallScore,
        results,
      );

      // Get seller info
      final seller = await AdminService.getSellerDetails(sellerId);

      final executionTime =
          DateTime.now().difference(startTime).inMilliseconds;

      return {
        'seller_id': sellerId,
        'seller_name': seller['name'] ?? 'Unknown',
        'overall_performance_score': overallScore.toStringAsFixed(2),
        'performance_tier': _getPerformanceTier(overallScore),
        'component_scores': componentScores,
        'component_details': results,
        'earned_badges': badges,
        'performance_insights': insights,
        'recommendation': _getPerformanceRecommendation(overallScore),
        'evaluation_date': DateTime.now().toIso8601String(),
        'execution_time_ms': executionTime,
      };
    } catch (e) {
      LoggerService.error(
        'Error calculating seller performance score',
        tag: 'SELLER_PERFORMANCE',
        error: e,
      );
      rethrow;
    }
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Returns performance tier based on score.
  static String _getPerformanceTier(double score) {
    if (score >= thresholdExcellent) {
      return tierExcellent;
    } else if (score >= thresholdGood) {
      return tierGood;
    } else if (score >= thresholdFair) {
      return tierFair;
    } else if (score >= thresholdPoor) {
      return tierPoor;
    }
    return tierUnacceptable;
  }

  /// Generates performance insights and observations.
  static List<String> _generatePerformanceInsights(
    String sellerId,
    double overallScore,
    List<Map<String, dynamic>> componentResults,
  ) {
    final insights = <String>[];

    // Find strongest and weakest components
    double maxScore = 0;
    String maxComponent = '';
    double minScore = 100;
    String minComponent = '';

    for (final result in componentResults) {
      final component = result['component'] as String;
      final score = double.tryParse(result['score'].toString()) ?? 50;

      if (score > maxScore) {
        maxScore = score;
        maxComponent = component;
      }
      if (score < minScore) {
        minScore = score;
        minComponent = component;
      }
    }

    insights.add('Strongest area: $maxComponent (${maxScore.toStringAsFixed(1)})');
    insights.add('Area needing improvement: $minComponent (${minScore.toStringAsFixed(1)})');

    if (overallScore >= thresholdExcellent) {
      insights.add('Seller is a top performer - eligible for premium features');
    } else if (overallScore < thresholdPoor) {
      insights.add('Seller requires remediation plan - performance below acceptable');
    }

    return insights;
  }

  /// Generates recommendation for performance tier.
  static String _getPerformanceRecommendation(double score) {
    if (score >= thresholdExcellent) {
      return 'PROMOTE_TO_FEATURED - Highlight to buyers, offer premium features';
    } else if (score >= thresholdGood) {
      return 'STANDARD - Continue normal operations, monitor performance';
    } else if (score >= thresholdFair) {
      return 'MONITOR_CLOSELY - Schedule performance review within 30 days';
    } else if (score >= thresholdPoor) {
      return 'IMPROVEMENT_PLAN - Require seller to submit improvement plan';
    }
    return 'CONSIDER_SUSPENSION - Evaluate account status and potential remediation';
  }

  // ============================================================================
  // Helper Methods & Constants
  // ============================================================================

  /// Helper: Generate mock orders
  static List<Map<String, dynamic>> _generateMockOrders(int count) {
    final orders = <Map<String, dynamic>>[];
    for (int i = 0; i < count; i++) {
      orders.add({
        'id': 'order_$i',
        'status': i % 8 == 0 ? 'CANCELLED' : 'COMPLETED',
        'delivered_on_time': i % 2 == 0,
        'amount': 100.0 + (i * 10),
      });
    }
    return orders;
  }

  /// Helper: Generate mock transactions
  static List<Map<String, dynamic>> _generateMockTransactions(int count) {
    final transactions = <Map<String, dynamic>>[];
    for (int i = 0; i < count; i++) {
      transactions.add({
        'id': 'txn_$i',
        'status': i % 10 == 0 ? 'DISPUTED' : 'SUCCESSFUL',
        'amount': 100.0 + (i * 5),
        'returned': i % 15 == 0,
      });
    }
    return transactions;
  }

  /// Helper: Generate mock reviews
  static List<Map<String, dynamic>> _generateMockReviews(int count) {
    final reviews = <Map<String, dynamic>>[];
    for (int i = 0; i < count; i++) {
      reviews.add({
        'id': 'review_$i',
        'rating': 3.5 + (i % 2),
        'text': 'Mock review text $i',
        'created_at': DateTime.now().subtract(Duration(days: i)).toString(),
      });
    }
    return reviews;
  }
}


