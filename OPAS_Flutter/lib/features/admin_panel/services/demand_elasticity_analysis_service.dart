import 'package:opas_flutter/core/services/logger_service.dart';

class DemandElasticityAnalysisService {
  DemandElasticityAnalysisService._(); // Private constructor - no instantiation

  // ============================================================================
  // Constants: Elasticity Analysis Configuration
  // ============================================================================

  // Elasticity Classification
  static const String elasticityPerfectlyElastic = 'PERFECTLY_ELASTIC';
  static const String elasticityElastic = 'ELASTIC';
  static const String elasticityUnitElastic = 'UNIT_ELASTIC';
  static const String elasticityInelastic = 'INELASTIC';
  static const String elasticityPerfectlyInelastic = 'PERFECTLY_INELASTIC';

  // Elasticity Thresholds
  static const double elasticThreshold = -1.0;
  static const double unitElasticThreshold = -0.9;

  // Analysis periods
  static const int shortTermWindowDays = 14;
  static const int mediumTermWindowDays = 30;
  static const int longTermWindowDays = 90;

  // Minimum data points for valid analysis
  static const int minimumDataPoints = 10;

  // Price point increments for scenarios
  static const List<double> priceScenarios = [
    -20.0, // -20% discount
    -10.0, // -10% discount
    0.0, // current price
    10.0, // +10% premium
    20.0, // +20% premium
  ];

  // ============================================================================
  // Step 1: Calculate Price Elasticity of Demand (PED)
  // ============================================================================

  /// Calculates price elasticity of demand for a product.
  ///
  /// Formula: PED = (% Change in Quantity Demanded) / (% Change in Price)
  /// PED = ((Q2 - Q1) / Q1) / ((P2 - P1) / P1)
  ///
  /// Uses linear regression on historical price/quantity data.
  /// Slope = elasticity coefficient
  ///
  /// Returns: Elasticity coefficient and classification
  /// Throws: Exception if calculation fails
  static Future<Map<String, dynamic>> calculatePriceElasticity(
    String productId, {
    int analysisDays = mediumTermWindowDays,
  }) async {
    try {
      // Get historical price and quantity data (mock)
      final history = _generateMockPriceQuantityHistory(20);

      if (history.length < minimumDataPoints) {
        return {
          'product_id': productId,
          'elasticity_coefficient': 0.0,
          'status': 'INSUFFICIENT_DATA',
          'data_points': history.length,
          'minimum_required': minimumDataPoints,
        };
      }

      // Extract price and quantity changes
      final priceChanges = <double>[];
      final quantityChanges = <double>[];

      for (int i = 1; i < history.length; i++) {
        final prevPrice = (history[i - 1]['price'] as num).toDouble();
        final currPrice = (history[i]['price'] as num).toDouble();
        final prevQuantity = (history[i - 1]['quantity'] as num).toDouble();
        final currQuantity = (history[i]['quantity'] as num).toDouble();

        if (prevPrice != 0 && prevQuantity != 0) {
          final priceChange = ((currPrice - prevPrice) / prevPrice);
          final quantityChange =
              ((currQuantity - prevQuantity) / prevQuantity);

          priceChanges.add(priceChange);
          quantityChanges.add(quantityChange);
        }
      }

      // Calculate elasticity using linear regression
      final elasticity = _calculateLinearRegression(
        priceChanges,
        quantityChanges,
      );

      return {
        'product_id': productId,
        'elasticity_coefficient': elasticity.toStringAsFixed(3),
        'elasticity_classification': _classifyElasticity(elasticity),
        'data_points_analyzed': priceChanges.length,
        'analysis_period_days': analysisDays,
        'status': 'SUCCESS',
      };
    } catch (e) {
      LoggerService.error(
        'Error calculating demand elasticity',
        tag: 'DEMAND_ELASTICITY',
        error: e,
        metadata: {'productId': productId},
      );
      rethrow;
    }
  }

  // ============================================================================
  // Step 2: Analyze Demand Response to Price Changes
  // ============================================================================

  /// Analyzes how demand responds to price changes.
  ///
  /// Simulates demand at different price points using elasticity.
  /// Formula: Q2 = Q1 * (1 + (elasticity * price_change %))
  ///
  /// Returns: Demand predictions at different price scenarios
  /// Throws: Exception if analysis fails
  static Future<Map<String, dynamic>> analyzeDemandResponse(
    String productId,
  ) async {
    try {
      // Get current product data (mock)
      final product = _generateMockProduct();
      final currentPrice = (product['price'] as num).toDouble();
      final currentQuantity = (product['monthly_sales'] as num).toDouble();

      // Get elasticity
      final elasticityData = await calculatePriceElasticity(productId);
      final elasticity =
          double.tryParse(elasticityData['elasticity_coefficient'].toString()) ??
              -0.5;

      // Project demand at different price points
      final projections = <Map<String, dynamic>>[];

      for (final priceScenario in priceScenarios) {
        final priceChange = priceScenario / 100; // Convert % to decimal
        final newPrice = currentPrice * (1 + priceChange);

        // Calculate projected quantity: Q_new = Q_current * (1 + elasticity * price_change)
        final projectedQuantity =
            currentQuantity * (1 + (elasticity * priceChange));

        // Calculate revenue impact
        final currentRevenue = currentPrice * currentQuantity;
        final projectedRevenue = newPrice * projectedQuantity.clamp(0, double.infinity);
        final revenueChange =
            ((projectedRevenue - currentRevenue) / currentRevenue * 100);

        projections.add({
          'price_scenario_percentage': priceScenario,
          'new_price': newPrice.toStringAsFixed(2),
          'projected_quantity': projectedQuantity.clamp(0, double.infinity).toStringAsFixed(0),
          'current_quantity': currentQuantity.toStringAsFixed(0),
          'quantity_change_percentage':
              ((projectedQuantity - currentQuantity) / currentQuantity * 100)
                  .toStringAsFixed(2),
          'projected_revenue': projectedRevenue.toStringAsFixed(2),
          'current_revenue': currentRevenue.toStringAsFixed(2),
          'revenue_change_percentage': revenueChange.toStringAsFixed(2),
        });
      }

      // Find optimal price (maximum revenue)
      final optimalProjection = _findOptimalPrice(projections);

      return {
        'product_id': productId,
        'current_price': currentPrice.toStringAsFixed(2),
        'current_quantity': currentQuantity.toStringAsFixed(0),
        'elasticity_coefficient': elasticity.toStringAsFixed(3),
        'elasticity_classification': _classifyElasticity(elasticity),
        'demand_projections': projections,
        'optimal_price_scenario': optimalProjection,
        'analysis_timestamp': DateTime.now().toIso8601String(),
        'status': 'SUCCESS',
      };
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // Step 3: Perform Competitive Elasticity Analysis
  // ============================================================================

  /// Compares elasticity across competing products.
  ///
  /// Analyzes how different products respond to price changes.
  /// Identifies which products are price-sensitive vs. price-inert.
  ///
  /// Returns: Competitive elasticity comparison
  /// Throws: Exception if analysis fails
  static Future<Map<String, dynamic>> performCompetitiveElasticityAnalysis(
    String categoryId,
  ) async {
    try {
      // Get all products in category (mock)
      final products = _generateMockCompetitors(8);

      if (products.isEmpty) {
        return {
          'category_id': categoryId,
          'status': 'NO_PRODUCTS',
        };
      }

      final elasticityComparison = <Map<String, dynamic>>[];

      for (final product in products) {
        final productId = product['id'] as String;

        try {
          // Calculate elasticity for each product
          final elasticityData = await calculatePriceElasticity(productId);
          final elasticity =
              double.tryParse(elasticityData['elasticity_coefficient'].toString()) ??
                  0.0;

          elasticityComparison.add({
            'product_id': productId,
            'product_name': product['name'],
            'current_price': (product['price'] as num).toDouble(),
            'elasticity_coefficient': elasticity.toStringAsFixed(3),
            'elasticity_classification': _classifyElasticity(elasticity),
            'price_sensitive': elasticity < elasticThreshold,
          });
        } catch (e) {
          //
        }
      }

      // Sort by elasticity (most elastic first)
      elasticityComparison.sort((a, b) {
        final elasticityA = double.tryParse(a['elasticity_coefficient'].toString()) ?? 0;
        final elasticityB = double.tryParse(b['elasticity_coefficient'].toString()) ?? 0;
        return elasticityA.compareTo(elasticityB);
      });

      return {
        'category_id': categoryId,
        'products_analyzed': elasticityComparison.length,
        'elasticity_comparison': elasticityComparison,
        'most_elastic_product': elasticityComparison.isNotEmpty
            ? elasticityComparison.first
            : null,
        'most_inelastic_product': elasticityComparison.isNotEmpty
            ? elasticityComparison.last
            : null,
        'analysis_timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // Step 4: Generate Price Optimization Recommendations
  // ============================================================================

  /// Generates price optimization recommendations based on elasticity.
  ///
  /// Returns: Actionable pricing strategy recommendations
  /// Throws: Exception if recommendations fail
  static Future<Map<String, dynamic>> generatePricingRecommendations(
    String productId,
  ) async {
    try {
      // Get elasticity and demand response
      final demandResponse = await analyzeDemandResponse(productId);
      final elasticity = double.tryParse(
            demandResponse['elasticity_coefficient'].toString(),
          ) ??
          -0.5;

      // Get product details (mock)
      final product = _generateMockProduct();
      final currentPrice = (product['current_price'] as num).toDouble();
      final optimalScenario =
          demandResponse['optimal_price_scenario'] as Map<String, dynamic>;

      final recommendations = <String>[];
      final strategy = <String, dynamic>{};

      // Recommendation logic based on elasticity
      if (elasticity < elasticThreshold) {
        // Elastic - demand very responsive
        recommendations.add('Product has ELASTIC demand - customers price-sensitive');
        recommendations
            .add('Small price increases will significantly reduce quantity sold');
        recommendations.add('Consider maintaining competitive pricing');
        strategy['strategy'] = 'MAINTAIN_COMPETITIVE_PRICING';
        strategy['reason'] = 'Elastic demand makes price increases counterproductive';
      } else if (elasticity > -1.0 && elasticity < 0) {
        // Inelastic - demand not very responsive
        recommendations.add('Product has INELASTIC demand - customers not price-sensitive');
        recommendations.add('Price increases have minimal impact on quantity sold');
        recommendations.add('Opportunity to increase prices and improve margins');
        strategy['strategy'] = 'CONSIDER_PRICE_INCREASE';
        strategy['reason'] = 'Inelastic demand supports higher prices';
      }

      // Optimal price recommendation
      final optimalPrice =
          optimalScenario['new_price'] ?? currentPrice.toStringAsFixed(2);
      final revenueImprovement =
          optimalScenario['revenue_change_percentage'] ?? '0';

      recommendations.add(
          'Optimal price point: \$$optimalPrice (projected $revenueImprovement% revenue change)');

      return {
        'product_id': productId,
        'current_price': currentPrice.toStringAsFixed(2),
        'elasticity_coefficient': elasticity.toStringAsFixed(3),
        'elasticity_classification': demandResponse['elasticity_classification'],
        'pricing_strategy': strategy,
        'recommendations': recommendations,
        'optimal_price': optimalPrice,
        'projected_revenue_change_percentage': revenueImprovement,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // Orchestration Method: Complete Elasticity Analysis Report
  // ============================================================================

  /// Generates comprehensive elasticity analysis report.
  ///
  /// Steps:
  /// 1. Calculate PED for all products
  /// 2. Analyze demand response curves
  /// 3. Compare elasticity across category
  /// 4. Generate pricing recommendations
  /// 5. Create optimization report
  ///
  /// Returns: Complete elasticity analysis report
  /// Throws: Exception if report generation fails
  static Future<Map<String, dynamic>>
      generateCompleteElasticityReport() async {
    try {
      final startTime = DateTime.now();

      // Get all products (mock)
      final products = _generateMockProducts(15);

      final elasticityAnalyses = <Map<String, dynamic>>[];
      int processedCount = 0;
      int errorCount = 0;

      for (final product in products) {
        try {
          final productId = product['id'] as String;

          // Analyze demand response
          final analysis = await analyzeDemandResponse(productId);
          elasticityAnalyses.add(analysis);

          processedCount++;
        } catch (e) {
          errorCount++;
        }
      }

      // Find insights
      final elasticProducts = elasticityAnalyses
          .where(
            (a) => (a['elasticity_classification'] as String).contains('ELASTIC'),
          )
          .toList();

      final inelasticProducts = elasticityAnalyses
          .where(
            (a) =>
                (a['elasticity_classification'] as String).contains('INELASTIC'),
          )
          .toList();

      final executionTime =
          DateTime.now().difference(startTime).inMilliseconds;

      return {
        'report_type': 'DEMAND_ELASTICITY_ANALYSIS',
        'total_products_analyzed': processedCount,
        'error_count': errorCount,
        'elastic_products_count': elasticProducts.length,
        'inelastic_products_count': inelasticProducts.length,
        'elasticity_analyses': elasticityAnalyses,
        'execution_time_ms': executionTime,
        'report_timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Classifies elasticity based on coefficient.
  static String _classifyElasticity(double elasticity) {
    if (elasticity.abs() > 2.0) {
      return elasticityPerfectlyElastic;
    } else if (elasticity < elasticThreshold) {
      return elasticityElastic;
    } else if ((elasticity - unitElasticThreshold).abs() < 0.1) {
      return elasticityUnitElastic;
    } else if (elasticity > unitElasticThreshold && elasticity < 0) {
      return elasticityInelastic;
    } else if (elasticity == 0) {
      return elasticityPerfectlyInelastic;
    }
    return elasticityInelastic;
  }

  /// Calculates linear regression slope (elasticity).
  static double _calculateLinearRegression(
    List<double> xValues,
    List<double> yValues,
  ) {
    if (xValues.length != yValues.length || xValues.isEmpty) {
      return 0.0;
    }

    final n = xValues.length.toDouble();

    // Calculate means
    final xMean = xValues.reduce((a, b) => a + b) / n;
    final yMean = yValues.reduce((a, b) => a + b) / n;

    // Calculate slope
    double numerator = 0;
    double denominator = 0;

    for (int i = 0; i < xValues.length; i++) {
      numerator += (xValues[i] - xMean) * (yValues[i] - yMean);
      denominator += (xValues[i] - xMean) * (xValues[i] - xMean);
    }

    if (denominator == 0) return 0.0;

    return numerator / denominator;
  }

  /// Finds optimal price point (maximum revenue).
  static Map<String, dynamic> _findOptimalPrice(
    List<Map<String, dynamic>> projections,
  ) {
    Map<String, dynamic>? optimal;
    double maxRevenue = 0;

    for (final projection in projections) {
      final revenue =
          double.tryParse(projection['projected_revenue'].toString()) ?? 0;

      if (revenue > maxRevenue) {
        maxRevenue = revenue;
        optimal = projection;
      }
    }

    return optimal ?? projections.first;
  }

  // ============================================================================
  // Helper Methods: Mock Data Generators
  // ============================================================================

  /// Generate mock price and quantity history
  static List<Map<String, dynamic>> _generateMockPriceQuantityHistory(
      int dataPoints) {
    final history = <Map<String, dynamic>>[];
    double price = 100.0;
    int quantity = 500;

    for (int i = 0; i < dataPoints; i++) {
      price += (i % 2 == 0 ? 2.5 : -1.5); // Price fluctuation
      quantity += (i % 2 == 0 ? -20 : 15); // Quantity inverse correlation

      history.add({
        'date': DateTime.now().subtract(Duration(days: dataPoints - i)).toString(),
        'price': price.clamp(50, 150),
        'quantity': quantity.clamp(100, 1000),
      });
    }
    return history;
  }

  /// Generate mock product data
  static Map<String, dynamic> _generateMockProduct() {
    return {
      'id': 'prod_001',
      'name': 'Sample Product',
      'price': 99.99,
      'category': 'Electronics',
      'current_quantity': 450,
      'average_rating': 4.5,
      'monthly_sales': 250,
    };
  }

  /// Generate mock competitor products
  static List<Map<String, dynamic>> _generateMockCompetitors(int count) {
    final competitors = <Map<String, dynamic>>[];
    for (int i = 0; i < count; i++) {
      competitors.add({
        'id': 'comp_$i',
        'name': 'Competitor Product $i',
        'price': 95.0 + (i * 5),
        'rating': 4.0 + (i % 2),
        'monthly_sales': 200 + (i * 50),
      });
    }
    return competitors;
  }

  /// Generate mock products list
  static List<Map<String, dynamic>> _generateMockProducts(int count) {
    final products = <Map<String, dynamic>>[];
    for (int i = 0; i < count; i++) {
      products.add({
        'id': 'prod_$i',
        'name': 'Product $i',
        'price': 50.0 + (i * 2),
        'rating': 3.5 + (i % 3),
        'monthly_sales': 100 + (i * 20),
      });
    }
    return products;
  }
}

