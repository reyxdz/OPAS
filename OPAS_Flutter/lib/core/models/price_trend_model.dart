// Price Trend Model - Tracks price movements and compliance
class PriceTrendModel {
  final String productName;
  final DateTime date;
  final double currentPrice;
  final double priceTarget;
  final double overagePercentage;
  final String complianceStatus;

  PriceTrendModel({
    required this.productName,
    required this.date,
    required this.currentPrice,
    required this.priceTarget,
    required this.overagePercentage,
    required this.complianceStatus,
  });

  factory PriceTrendModel.fromJson(Map<String, dynamic> json) {
    return PriceTrendModel(
      productName: json['product_name'] as String? ?? 'Unknown',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      priceTarget: (json['price_target'] as num?)?.toDouble() ?? 0.0,
      overagePercentage: (json['overage_percentage'] as num?)?.toDouble() ?? 0.0,
      complianceStatus: json['compliance_status'] as String? ?? 'Unknown',
    );
  }

  String getComplianceColor() {
    if (complianceStatus == 'compliant') return '#4CAF50';
    if (complianceStatus == 'warning') return '#FF9800';
    return '#F44336';
  }

  bool isCompliant() => complianceStatus == 'compliant';
}

// Enhanced Price Trend with Historical and Forecast Data
class PriceTrend {
  final int id;
  final String productName;
  final String category;
  final double currentPrice;
  final double opasRegulatedPrice;
  final double previousPrice;
  final double priceChange;
  final double percentageChange;
  final List<PriceDataPoint> historicalData;
  final List<PriceDataPoint> forecastedData;
  final DateTime lastUpdated;

  PriceTrend({
    required this.id,
    required this.productName,
    required this.category,
    required this.currentPrice,
    required this.opasRegulatedPrice,
    required this.previousPrice,
    required this.priceChange,
    required this.percentageChange,
    required this.historicalData,
    required this.forecastedData,
    required this.lastUpdated,
  });

  factory PriceTrend.fromJson(Map<String, dynamic> json) {
    return PriceTrend(
      id: json['id'] ?? 0,
      productName: json['product_name'] ?? 'Unknown',
      category: json['category'] ?? 'General',
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      opasRegulatedPrice: (json['opas_regulated_price'] ?? 0).toDouble(),
      previousPrice: (json['previous_price'] ?? 0).toDouble(),
      priceChange: (json['price_change'] ?? 0).toDouble(),
      percentageChange: (json['percentage_change'] ?? 0).toDouble(),
      historicalData: (json['historical_data'] as List<dynamic>?)
              ?.map((item) => PriceDataPoint.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      forecastedData: (json['forecasted_data'] as List<dynamic>?)
              ?.map((item) => PriceDataPoint.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated:
          DateTime.tryParse(json['last_updated'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_name': productName,
    'category': category,
    'current_price': currentPrice,
    'opas_regulated_price': opasRegulatedPrice,
    'previous_price': previousPrice,
    'price_change': priceChange,
    'percentage_change': percentageChange,
    'historical_data': historicalData.map((item) => item.toJson()).toList(),
    'forecasted_data': forecastedData.map((item) => item.toJson()).toList(),
    'last_updated': lastUpdated.toIso8601String(),
  };

  bool get isPriceIncreasing => priceChange > 0;
  bool get isPriceDecreasing => priceChange < 0;
  bool get isWithinRegulatedPrice => currentPrice <= opasRegulatedPrice;
}

class PriceDataPoint {
  final DateTime date;
  final double price;
  final bool isForecast;

  PriceDataPoint({
    required this.date,
    required this.price,
    this.isForecast = false,
  });

  factory PriceDataPoint.fromJson(Map<String, dynamic> json) {
    return PriceDataPoint(
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      price: (json['price'] ?? 0).toDouble(),
      isForecast: json['is_forecast'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'price': price,
    'is_forecast': isForecast,
  };
}
