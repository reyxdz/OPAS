// Forecast Model - Phase 5.1 A - Demand and price predictions with confidence intervals
class ForecastModel {
  final int id;
  final int? productId;  // nullable for CSV products
  final String productName;
  final String? categoryName;  // Changed from productCategory
  final String? productType;  // Product type from classification (e.g., "Fish", "Leafy Greens")
  final String? productSubtype;  // Product subtype from classification (e.g., "Bangus", "Spinach")
  final DateTime forecastDate;
  final String forecastPeriod; // e.g., "2025-01", "Week 1"
  
  // Demand forecast fields
  final double demandForecastKg;
  final double demandLowerBound;
  final double demandUpperBound;
  
  // Price forecast fields
  final double priceForecast;
  final double priceLowerBound;
  final double priceUpperBound;
  
  // Model information
  final String confidenceLevel; // HIGH, MEDIUM, LOW
  final String modelType; // SARIMA, ARIMA, SIMPLE, INSUFFICIENT_DATA
  final bool isCurrent;

  ForecastModel({
    required this.id,
    this.productId,
    required this.productName,
    this.categoryName,
    this.productType,
    this.productSubtype,
    required this.forecastDate,
    required this.forecastPeriod,
    required this.demandForecastKg,
    required this.demandLowerBound,
    required this.demandUpperBound,
    required this.priceForecast,
    required this.priceLowerBound,
    required this.priceUpperBound,
    required this.confidenceLevel,
    required this.modelType,
    required this.isCurrent,
  });

  factory ForecastModel.fromJson(Map<String, dynamic> json) {
    return ForecastModel(
      id: json['id'] as int? ?? 0,
      productId: json['product_id'] as int?,
      productName: (json['name'] ?? json['product_name'] ?? 'Unknown') as String,
      categoryName: (json['category'] ?? json['category_name']) as String?,
      productType: (json['product_type'] ?? json['type']) as String?,
      productSubtype: (json['product_subtype'] ?? json['subtype']) as String?,
      forecastDate: json['forecast_date'] != null
          ? DateTime.parse(json['forecast_date'] as String)
          : DateTime.now(),
      forecastPeriod: json['forecast_period'] as String? ?? 'N/A',
      demandForecastKg: ((json['forecasted_demand_next_month'] ?? json['demand_forecast_kg']) as num?)?.toDouble() ?? 0.0,
      demandLowerBound: (json['demand_lower_bound'] as num?)?.toDouble() ?? 0.0,
      demandUpperBound: (json['demand_upper_bound'] as num?)?.toDouble() ?? 0.0,
      priceForecast: ((json['forecasted_price_next_month'] ?? json['price_forecast']) as num?)?.toDouble() ?? 0.0,
      priceLowerBound: (json['price_lower_bound'] as num?)?.toDouble() ?? 0.0,
      priceUpperBound: (json['price_upper_bound'] as num?)?.toDouble() ?? 0.0,
      confidenceLevel: json['confidence_level'] as String? ?? 'MEDIUM',
      modelType: json['model_type'] as String? ?? 'SIMPLE',
      isCurrent: json['is_current'] as bool? ?? false,
    );
  }

  String getConfidenceEmoji() {
    switch (confidenceLevel) {
      case 'HIGH':
        return '✅';
      case 'MEDIUM':
        return '⚠️';
      case 'LOW':
        return '❌';
      default:
        return '❓';
    }
  }

  String getDemandRange() => 
      '${demandForecastKg.toStringAsFixed(0)} kg (±${((demandUpperBound - demandForecastKg).abs()).toStringAsFixed(0)})';

  String getPriceRange() => 
      '₱${priceForecast.toStringAsFixed(2)}/kg (±₱${((priceUpperBound - priceForecast).abs()).toStringAsFixed(2)})';

  String getConfidenceBadgeColor() {
    switch (confidenceLevel) {
      case 'HIGH':
        return '#4CAF50';
      case 'MEDIUM':
        return '#FF9800';
      case 'LOW':
        return '#F44336';
      default:
        return '#9E9E9E';
    }
  }

  String getModelLabel() {
    switch (modelType) {
      case 'SARIMA':
        return 'SARIMA';
      case 'ARIMA':
        return 'ARIMA';
      case 'SIMPLE':
        return 'Simple';
      case 'INSUFFICIENT_DATA':
        return 'Insufficient Data';
      default:
        return 'Unknown';
    }
  }
}
