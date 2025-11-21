import 'package:opas_flutter/core/services/logger_service.dart';

class SeasonalTrendForecastingService {
  SeasonalTrendForecastingService._(); // Private constructor - no instantiation

  // ============================================================================
  // Constants: Forecasting Configuration
  // ============================================================================

  // Seasonality Patterns
  static const String seasonSpring = 'SPRING';
  static const String seasonSummer = 'SUMMER';
  static const String seasonFall = 'FALL';
  static const String seasonWinter = 'WINTER';

  // Forecast Horizons
  static const int forecastHorizonShort = 14; // 2 weeks
  static const int forecastHorizonMedium = 30; // 1 month
  static const int forecastHorizonLong = 90; // 3 months
  static const int forecastHorizonLongterm = 180; // 6 months

  // Trend Classification
  static const String trendStronglyIncreasing = 'STRONGLY_INCREASING';
  static const String trendModeratelyIncreasing = 'MODERATELY_INCREASING';
  static const String trendStable = 'STABLE';
  static const String trendModeratelyDecreasing = 'MODERATELY_DECREASING';
  static const String trendStronglyDecreasing = 'STRONGLY_DECREASING';

  // Smoothing factors
  static const double alphaSmoothing = 0.3; // Exponential smoothing factor
  static const double betaTrend = 0.1; // Trend smoothing factor

  // Minimum historical data required
  static const int minimumHistoricalDays = 30;
  static const int seasonalCycleDays = 365; // Annual seasonality

  // Confidence levels
  static const double confidenceHigh = 0.95;
  static const double confidenceMedium = 0.80;
  static const double confidenceLow = 0.50;

  // ============================================================================
  // Step 1: Decompose Time Series
  // ============================================================================

  /// Decomposes time series into trend, seasonality, and residuals.
  ///
  /// Uses additive model: Y = Trend + Seasonality + Residuals
  ///
  /// Steps:
  /// 1. Extract trend using moving average
  /// 2. Detrend the data
  /// 3. Extract seasonal component
  /// 4. Calculate residuals (noise)
  ///
  /// Returns: Decomposed time series components
  /// Throws: Exception if decomposition fails
  static Future<Map<String, dynamic>> decomposeTimeSeries(
    String productId, {
    int historyDays = 90,
  }) async {
    try {
      // Get historical daily data (mock)
      final history = _generateMockProductHistory(365);
      if (history.length < minimumHistoricalDays) {
        return {
          'product_id': productId,
          'status': 'INSUFFICIENT_DATA',
          'data_points': history.length,
          'minimum_required': minimumHistoricalDays,
        };
      }

      // Extract values as list
      final values = history
          .map((h) => (h['value'] as num).toDouble())
          .toList();

      // Step 1: Calculate trend (7-day moving average)
      final trend = _calculateMovingAverage(values, 7);

      // Step 2: Detrend
      final detrended = <double>[];
      for (int i = 0; i < values.length; i++) {
        detrended.add(values[i] - trend[i]);
      }

      // Step 3: Extract seasonality (repeat pattern)
      final seasonality = _extractSeasonality(detrended, 7);

      // Step 4: Calculate residuals
      final residuals = <double>[];
      for (int i = 0; i < values.length; i++) {
        residuals.add(values[i] - trend[i] - seasonality[i]);
      }

      // Calculate component strengths
      final trendStrength = _calculateComponentStrength(trend, values);
      final seasonalityStrength =
          _calculateComponentStrength(seasonality, values);

      return {
        'product_id': productId,
        'data_points': values.length,
        'trend': trend.map((v) => v.toStringAsFixed(2)).toList(),
        'seasonality': seasonality.map((v) => v.toStringAsFixed(2)).toList(),
        'residuals': residuals.map((v) => v.toStringAsFixed(2)).toList(),
        'trend_strength_percentage': (trendStrength * 100).toStringAsFixed(2),
        'seasonality_strength_percentage': (seasonalityStrength * 100).toStringAsFixed(2),
        'status': 'SUCCESS',
      };
    } catch (e) {
      LoggerService.error(
        'Error decomposing time series',
        tag: 'TIME_SERIES_DECOMPOSITION',
        error: e,
      );
      rethrow;
    }
  }

  // ============================================================================
  // Step 2: Forecast Demand
  // ============================================================================

  /// Forecasts future demand using exponential smoothing.
  ///
  /// Uses Holt-Winters exponential smoothing with trend and seasonality.
  /// Formula: F(t+h) = (Level + h*Trend) * Seasonal_factor
  ///
  /// Returns: Demand forecast for specified horizon
  /// Throws: Exception if forecast fails
  static Future<Map<String, dynamic>> forecastDemand(
    String productId, {
    int horizonDays = forecastHorizonMedium,
  }) async {
    try {
      // Get historical data (mock)
      final history = _generateMockProductHistory(90);

      if (history.length < minimumHistoricalDays) {
        return {
          'product_id': productId,
          'status': 'INSUFFICIENT_DATA',
        };
      }

      // Extract values
      final values = history
          .map((h) => (h['value'] as num).toDouble())
          .toList();

      // Initialize exponential smoothing
      double level = values.first;
      double trend = (values.last - values.first) / values.length;
      final forecast = <Map<String, dynamic>>[];

      // Generate forecast for each day
      for (int day = 1; day <= horizonDays; day++) {
        // Update level with exponential smoothing
        const alpha = alphaSmoothing;
        const beta = betaTrend;

        if (day <= values.length) {
          final observation = values[day - 1];
          final prevLevel = level;
          level = alpha * observation + (1 - alpha) * (prevLevel + trend);
          trend = beta * (level - prevLevel) + (1 - beta) * trend;
        }

        // Calculate prediction
        final prediction = level + (trend * day);

        forecast.add({
          'day': day,
          'forecast_date': DateTime.now()
              .add(Duration(days: day))
              .toIso8601String()
              .split('T')[0],
          'forecasted_demand': prediction.clamp(0, double.infinity).toStringAsFixed(2),
          'confidence_interval': _calculateConfidenceInterval(prediction, day),
        });
      }

      return {
        'product_id': productId,
        'forecast_horizon_days': horizonDays,
        'forecast_method': 'EXPONENTIAL_SMOOTHING',
        'forecast_data': forecast,
        'status': 'SUCCESS',
      };
    } catch (e) {
      LoggerService.error(
        'Error forecasting demand',
        tag: 'DEMAND_FORECAST',
        error: e,
        metadata: {'productId': productId, 'horizonDays': horizonDays},
      );
      rethrow;
    }
  }

  // ============================================================================
  // Step 3: Forecast Seasonal Pattern
  // ============================================================================

  /// Forecasts seasonal patterns for next season cycle.
  ///
  /// Identifies recurring seasonal patterns and projects them forward.
  /// Detects: Day-of-week patterns, weekly patterns, monthly patterns.
  ///
  /// Returns: Seasonal forecast data
  /// Throws: Exception if forecast fails
  static Future<Map<String, dynamic>> forecastSeasonalPattern(
    String productId,
  ) async {
    try {
      // Get long historical data (mock)
      final history = _generateMockProductHistory(180);

      if (history.length < seasonalCycleDays) {
        return {
          'product_id': productId,
          'status': 'INSUFFICIENT_DATA_FOR_SEASONALITY',
          'data_points': history.length,
          'minimum_required': seasonalCycleDays,
        };
      }

      // Extract values
      final values = history
          .map((h) => (h['value'] as num).toDouble())
          .toList();

      // Calculate seasonal indices (ratio to average)
      final avgValue = values.reduce((a, b) => a + b) / values.length;
      final seasonalIndices = <double>[];

      for (final value in values) {
        seasonalIndices.add(value / avgValue);
      }

      // Detect dominant seasonal pattern
      final dominantPattern = _detectDominantSeasonalPattern(seasonalIndices);

      return {
        'product_id': productId,
        'seasonal_cycle_days': seasonalCycleDays,
        'seasonal_indices': seasonalIndices.map((i) => i.toStringAsFixed(3)).toList(),
        'dominant_pattern': dominantPattern,
        'average_value': avgValue.toStringAsFixed(2),
        'status': 'SUCCESS',
      };
    } catch (e) {
      LoggerService.error(
        'Error forecasting seasonal pattern',
        tag: 'SEASONAL_PATTERN',
        error: e,
      );
      rethrow;
    }
  }

  // ============================================================================
  // Step 4: Forecast Price Trends
  // ============================================================================

  /// Forecasts future price movements based on historical trends.
  ///
  /// Uses linear regression and trend analysis.
  /// Detects: Increasing trends, decreasing trends, stability.
  ///
  /// Returns: Price forecast data
  /// Throws: Exception if forecast fails
  static Future<Map<String, dynamic>> forecastPriceTrend(
    String productId, {
    int horizonDays = forecastHorizonMedium,
  }) async {
    try {
      // Get price history (mock)
      final history = _generateMockPriceHistory(90);

      if (history.length < minimumHistoricalDays) {
        return {
          'product_id': productId,
          'status': 'INSUFFICIENT_DATA',
        };
      }

      // Extract prices
      final prices = history
          .map((h) => (h['price'] as num).toDouble())
          .toList();

      // Calculate trend using linear regression
      final slope = _calculateLinearTrendSlope(prices);

      // Classify trend
      final trendClass = _classifyTrend(slope);

      // Generate forecast
      final forecast = <Map<String, dynamic>>[];
      final lastPrice = prices.last;

      for (int day = 1; day <= horizonDays; day++) {
        final forecastedPrice = lastPrice + (slope * day);

        forecast.add({
          'day': day,
          'forecast_date': DateTime.now()
              .add(Duration(days: day))
              .toIso8601String()
              .split('T')[0],
          'forecasted_price': forecastedPrice.clamp(0, double.infinity).toStringAsFixed(2),
          'trend_direction': trendClass,
          'confidence_interval': _calculateConfidenceInterval(forecastedPrice, day),
        });
      }

      return {
        'product_id': productId,
        'forecast_horizon_days': horizonDays,
        'forecast_method': 'LINEAR_REGRESSION',
        'trend_slope': slope.toStringAsFixed(4),
        'trend_classification': trendClass,
        'forecast_data': forecast,
        'status': 'SUCCESS',
      };
    } catch (e) {
      LoggerService.error(
        'Error forecasting price trend',
        tag: 'PRICE_TREND',
        error: e,
      );
      rethrow;
    }
  }

  // ============================================================================
  // Step 5: Generate Forecast Insights
  // ============================================================================

  /// Generates market insights from forecasts.
  ///
  /// Returns: Actionable insights for strategy planning
  /// Throws: Exception if generation fails
  static Future<List<String>> generateForecastInsights(
    String productId,
  ) async {
    try {
      final insights = <String>[];

      // Get demand forecast
      final demandForecast =
          await forecastDemand(productId, horizonDays: forecastHorizonLong);
      final priceForecast =
          await forecastPriceTrend(productId, horizonDays: forecastHorizonLong);
      final decomposition = await decomposeTimeSeries(productId);

      // Extract data
      final demandData = demandForecast['forecast_data'] as List?;
      final priceData = priceForecast['forecast_data'] as List?;
      final trendStrength =
          double.tryParse(decomposition['trend_strength_percentage'].toString()) ?? 0;

      // Demand insights
      if (demandData != null && demandData.isNotEmpty) {
        final firstForecast =
            double.tryParse(demandData.first['forecasted_demand'].toString()) ?? 0;
        final lastForecast =
            double.tryParse(demandData.last['forecasted_demand'].toString()) ?? 0;

        if (lastForecast > firstForecast) {
          insights.add(
              'Demand expected to INCREASE ${((lastForecast / firstForecast - 1) * 100).toStringAsFixed(1)}% over next 90 days');
        } else {
          insights.add(
              'Demand expected to DECREASE ${((1 - lastForecast / firstForecast) * 100).toStringAsFixed(1)}% over next 90 days');
        }
      }

      // Price insights
      if (priceData != null && priceData.isNotEmpty) {
        final trendClass = priceForecast['trend_classification'] as String;
        if (trendClass.contains('INCREASING')) {
          insights.add('Prices trending UPWARD - consider opportunistic sales');
        } else if (trendClass.contains('DECREASING')) {
          insights.add('Prices trending DOWNWARD - manage inventory carefully');
        }
      }

      // Seasonality insights
      if (trendStrength > 30) {
        insights.add('Strong seasonal pattern detected - plan accordingly');
      }

      return insights;
    } catch (e) {
      LoggerService.error(
        'Error generating forecast insights',
        tag: 'FORECAST_INSIGHTS',
        error: e,
      );
      rethrow;
    }
  }

  // ============================================================================
  // Orchestration Method: Generate Seasonal Forecast Report
  // ============================================================================

  /// Generates comprehensive seasonal trend forecast report.
  ///
  /// Steps:
  /// 1. Get all products
  /// 2. Forecast demand for each
  /// 3. Forecast prices for each
  /// 4. Generate seasonal patterns
  /// 5. Create market outlook
  ///
  /// Returns: Complete forecast report
  /// Throws: Exception if report generation fails
  static Future<Map<String, dynamic>>
      generateSeasonalForecastReport() async {
    try {
      final startTime = DateTime.now();

      // Get all products (mock)
      final allProducts = _generateMockProducts(25);

      final forecasts = <Map<String, dynamic>>[];
      int processedCount = 0;
      int errorCount = 0;

      for (final product in allProducts) {
        try {
          final productId = product['id'] as String;

          // Generate forecasts
          final demandForecast =
              await forecastDemand(productId, horizonDays: forecastHorizonMedium);
          final priceForecast =
              await forecastPriceTrend(productId, horizonDays: forecastHorizonMedium);
          final insights = await generateForecastInsights(productId);

          forecasts.add({
            'product_id': productId,
            'product_name': product['name'],
            'demand_forecast': demandForecast,
            'price_forecast': priceForecast,
            'insights': insights,
          });

          processedCount++;
        } catch (e) {
          LoggerService.error(
            'Error processing product in seasonal forecasting',
            tag: 'SEASONAL_FORECAST',
            error: e,
          );
          errorCount++;
        }
      }

      // Aggregate insights
      final allInsights = <String>[];
      for (final forecast in forecasts) {
        final productInsights = forecast['insights'] as List?;
        if (productInsights != null) {
          allInsights.addAll(productInsights.cast<String>());
        }
      }

      // Determine market outlook
      final marketOutlook = _determinemarketOutlook(forecasts);

      final executionTime =
          DateTime.now().difference(startTime).inMilliseconds;

      return {
        'report_type': 'SEASONAL_TREND_FORECAST',
        'total_products_forecasted': processedCount,
        'error_count': errorCount,
        'forecasts': forecasts,
        'market_outlook': marketOutlook,
        'aggregate_insights': allInsights,
        'execution_time_ms': executionTime,
        'report_timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      LoggerService.error(
        'Error generating seasonal forecast report',
        tag: 'SEASONAL_REPORT',
        error: e,
      );
      rethrow;
    }
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Calculates moving average.
  static List<double> _calculateMovingAverage(
    List<double> values,
    int windowSize,
  ) {
    final result = <double>[];

    for (int i = 0; i < values.length; i++) {
      int start = (i - windowSize ~/ 2).clamp(0, values.length - 1);
      int end = (i + windowSize ~/ 2).clamp(0, values.length - 1);

      double sum = 0;
      for (int j = start; j <= end; j++) {
        sum += values[j];
      }

      result.add(sum / (end - start + 1));
    }

    return result;
  }

  /// Extracts seasonal component.
  static List<double> _extractSeasonality(
    List<double> detrended,
    int period,
  ) {
    final result = List<double>.filled(detrended.length, 0);

    // Average seasonal indices for each period
    for (int i = 0; i < period; i++) {
      double sum = 0;
      int count = 0;

      for (int j = i; j < detrended.length; j += period) {
        sum += detrended[j];
        count++;
      }

      final seasonal = (count > 0 ? sum / count : 0).toDouble();

      for (int j = i; j < detrended.length; j += period) {
        result[j] = seasonal;
      }
    }

    return result;
  }

  /// Calculates component strength (0-1).
  static double _calculateComponentStrength(
    List<double> component,
    List<double> original,
  ) {
    if (component.isEmpty || original.isEmpty) return 0;

    double componentVariance = 0;
    double originalVariance = 0;

    final componentMean =
        component.reduce((a, b) => a + b) / component.length;
    final originalMean = original.reduce((a, b) => a + b) / original.length;

    for (int i = 0; i < component.length; i++) {
      componentVariance += (component[i] - componentMean) * (component[i] - componentMean);
      originalVariance += (original[i] - originalMean) * (original[i] - originalMean);
    }

    if (originalVariance == 0) return 0;

    return (componentVariance / originalVariance).clamp(0, 1);
  }

  /// Calculates confidence interval.
  static Map<String, String> _calculateConfidenceInterval(
    double forecast,
    int horizon,
  ) {
    // Simple confidence interval based on forecast distance
    final margin = forecast * 0.1 * (horizon / 30); // 10% per month

    return {
      'lower_bound': (forecast - margin).clamp(0, double.infinity).toStringAsFixed(2),
      'upper_bound': (forecast + margin).toStringAsFixed(2),
    };
  }

  /// Detects dominant seasonal pattern.
  static String _detectDominantSeasonalPattern(List<double> indices) {
    // Simplified: return pattern name based on magnitude
    final maxIndex = indices.reduce((a, b) => a > b ? a : b);

    if (maxIndex > 1.5) {
      return 'STRONG_SEASONALITY';
    } else if (maxIndex > 1.2) {
      return 'MODERATE_SEASONALITY';
    }
    return 'WEAK_SEASONALITY';
  }

  /// Calculates linear trend slope.
  static double _calculateLinearTrendSlope(List<double> values) {
    if (values.length < 2) return 0;

    double numerator = 0;
    double denominator = 0;
    final n = values.length.toDouble();
    final mean = values.reduce((a, b) => a + b) / n;

    for (int i = 0; i < values.length; i++) {
      numerator += (i - (n - 1) / 2) * (values[i] - mean);
      denominator += (i - (n - 1) / 2) * (i - (n - 1) / 2);
    }

    return denominator == 0 ? 0 : numerator / denominator;
  }

  /// Classifies trend based on slope.
  static String _classifyTrend(double slope) {
    if (slope > 0.1) {
      return trendStronglyIncreasing;
    } else if (slope > 0.01) {
      return trendModeratelyIncreasing;
    } else if (slope > -0.01) {
      return trendStable;
    } else if (slope > -0.1) {
      return trendModeratelyDecreasing;
    }
    return trendStronglyDecreasing;
  }

  /// Determines market outlook.
  static String _determinemarketOutlook(
    List<Map<String, dynamic>> forecasts,
  ) {
    int increasingCount = 0;
    int decreasingCount = 0;

    for (final forecast in forecasts) {
      final priceData = forecast['price_forecast'] as Map<String, dynamic>?;
      if (priceData != null) {
        final trend = priceData['trend_classification'] as String?;
        if (trend?.contains('INCREASING') == true) {
          increasingCount++;
        } else if (trend?.contains('DECREASING') == true) {
          decreasingCount++;
        }
      }
    }

    if (increasingCount > decreasingCount * 2) {
      return 'BULLISH_MARKET';
    } else if (decreasingCount > increasingCount * 2) {
      return 'BEARISH_MARKET';
    }
    return 'STABLE_MARKET';
  }

  // ============================================================================
  // Helper Methods: Mock Data Generators
  // ============================================================================

  /// Generate mock product history data
  static List<Map<String, dynamic>> _generateMockProductHistory(int days) {
    final history = <Map<String, dynamic>>[];
    double baseSales = 100.0;

    for (int i = 0; i < days; i++) {
      final dayOfWeek = i % 7; // 0-6 for day of week
      baseSales += (i % 3 == 0 ? 15.0 : -5.0) + (dayOfWeek == 5 || dayOfWeek == 6 ? 20.0 : 0); // Weekend boost

      history.add({
        'date': DateTime.now().subtract(Duration(days: days - i)).toString(),
        'sales': baseSales.clamp(10, 500),
        'quantity': (baseSales * 2).toInt(),
      });
    }
    return history;
  }

  /// Generate mock price history data
  static List<Map<String, dynamic>> _generateMockPriceHistory(int days) {
    final history = <Map<String, dynamic>>[];
    double basePrice = 99.99;

    for (int i = 0; i < days; i++) {
      basePrice += (i % 2 == 0 ? 0.5 : -0.25);

      history.add({
        'date': DateTime.now().subtract(Duration(days: days - i)).toString(),
        'price': basePrice.clamp(79.99, 119.99),
      });
    }
    return history;
  }

  /// Generate mock products list
  static List<Map<String, dynamic>> _generateMockProducts(int count) {
    final products = <Map<String, dynamic>>[];
    for (int i = 0; i < count; i++) {
      products.add({
        'id': 'prod_$i',
        'name': 'Product $i',
        'price': 50.0 + (i * 2),
        'category': 'Category ${i % 5}',
        'monthly_sales': 200 + (i * 10),
      });
    }
    return products;
  }
}

