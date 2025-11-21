// Forecast Model - Demand and sales predictions
class ForecastModel {
  final String productName;
  final DateTime forecastDate;
  final int predictedDemand;
  final double confidence;
  final String seasonality;
  final String trend;
  final String recommendation;

  ForecastModel({
    required this.productName,
    required this.forecastDate,
    required this.predictedDemand,
    required this.confidence,
    required this.seasonality,
    required this.trend,
    required this.recommendation,
  });

  factory ForecastModel.fromJson(Map<String, dynamic> json) {
    return ForecastModel(
      productName: json['product_name'] as String? ?? 'Unknown',
      forecastDate: json['forecast_date'] != null
          ? DateTime.parse(json['forecast_date'] as String)
          : DateTime.now(),
      predictedDemand: json['predicted_demand'] as int? ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      seasonality: json['seasonality'] as String? ?? 'normal',
      trend: json['trend'] as String? ?? 'stable',
      recommendation: json['recommendation'] as String? ?? 'No recommendation',
    );
  }

  String getConfidenceBadgeColor() {
    if (confidence >= 0.8) return '#4CAF50';
    if (confidence >= 0.6) return '#FF9800';
    return '#F44336';
  }

  String getTrendIcon() {
    if (trend == 'increasing') return '📈';
    if (trend == 'decreasing') return '📉';
    return '➡️';
  }

  String getConfidencePercentage() => '${(confidence * 100).toStringAsFixed(0)}%';
}
