/// Forecast Model for Seller (Enhanced Phase 3.3)
/// Represents demand forecasting data with advanced analytics for seller products
class SellerForecast {
  final int id;
  final int sellerId;
  final int productId;
  final String productName;
  final int forecastedDemand;
  final int? actualDemand;
  final double confidenceScore;
  final String trend; // UPTREND, DOWNTREND, STABLE
  final double volatility; // 0-100%
  final double growthRate; // -100% to +100%
  final double trendMultiplier;
  final double surplusProbability;
  final double stockoutProbability;
  final String riskLevel; // LOW, MEDIUM, HIGH
  final DateTime forecastDate;
  final DateTime? actualDate;
  final int recommendedStock;
  final int historicalSalesCount;
  final double averageDailySales;
  final List<String> recommendations;
  final bool seasonalityDetected;

  SellerForecast({
    required this.id,
    required this.sellerId,
    required this.productId,
    required this.productName,
    required this.forecastedDemand,
    this.actualDemand,
    required this.confidenceScore,
    required this.trend,
    required this.volatility,
    required this.growthRate,
    required this.trendMultiplier,
    required this.surplusProbability,
    required this.stockoutProbability,
    required this.riskLevel,
    required this.forecastDate,
    this.actualDate,
    required this.recommendedStock,
    required this.historicalSalesCount,
    required this.averageDailySales,
    required this.recommendations,
    required this.seasonalityDetected,
  });

  factory SellerForecast.fromJson(Map<String, dynamic> json) {
    return SellerForecast(
      id: json['id'] ?? 0,
      sellerId: json['seller'] ?? 0,
      productId: json['product'] ?? 0,
      productName: json['product_name'] ?? 'Unknown',
      forecastedDemand: json['forecasted_demand'] ?? 0,
      actualDemand: json['actual_demand'],
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      trend: json['trend'] ?? 'STABLE',
      volatility: (json['volatility'] as num?)?.toDouble() ?? 0.0,
      growthRate: (json['growth_rate'] as num?)?.toDouble() ?? 0.0,
      trendMultiplier: (json['trend_multiplier'] as num?)?.toDouble() ?? 1.0,
      surplusProbability: (json['surplus_probability'] as num?)?.toDouble() ?? 0.0,
      stockoutProbability: (json['stockout_probability'] as num?)?.toDouble() ?? 0.0,
      riskLevel: json['risk_level'] ?? 'MEDIUM',
      forecastDate: json['forecast_date'] != null ? DateTime.parse(json['forecast_date']) : DateTime.now(),
      actualDate: json['actual_date'] != null ? DateTime.parse(json['actual_date']) : null,
      recommendedStock: json['recommended_stock'] ?? 0,
      historicalSalesCount: json['historical_sales_count'] ?? 0,
      averageDailySales: (json['average_daily_sales'] as num?)?.toDouble() ?? 0.0,
      recommendations: List<String>.from(json['recommendations'] ?? []),
      seasonalityDetected: json['seasonality_detected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'seller': sellerId,
    'product': productId,
    'product_name': productName,
    'forecasted_demand': forecastedDemand,
    'actual_demand': actualDemand,
    'confidence_score': confidenceScore,
    'trend': trend,
    'volatility': volatility,
    'growth_rate': growthRate,
    'trend_multiplier': trendMultiplier,
    'surplus_probability': surplusProbability,
    'stockout_probability': stockoutProbability,
    'risk_level': riskLevel,
    'forecast_date': forecastDate.toIso8601String(),
    'actual_date': actualDate?.toIso8601String(),
    'recommended_stock': recommendedStock,
    'historical_sales_count': historicalSalesCount,
    'average_daily_sales': averageDailySales,
    'recommendations': recommendations,
    'seasonality_detected': seasonalityDetected,
  };

  // Getters for easy access
  bool get isLowRisk => riskLevel == 'LOW';
  bool get isMediumRisk => riskLevel == 'MEDIUM';
  bool get isHighRisk => riskLevel == 'HIGH';
  bool get isUptrend => trend == 'UPTREND';
  bool get isDowntrend => trend == 'DOWNTREND';
  bool get isStable => trend == 'STABLE';
  int get demandVariance => actualDemand != null ? (actualDemand! - forecastedDemand).abs() : 0;
  double get accuracy => confidenceScore;
  bool get hasHighSurplusRisk => surplusProbability > 50;
  bool get hasHighStockoutRisk => stockoutProbability > 50;
  bool get needsAttention => isHighRisk || hasHighSurplusRisk || hasHighStockoutRisk;
  String get trendEmoji {
    if (isUptrend) return '📈';
    if (isDowntrend) return '📉';
    return '➡️';
  }
}
