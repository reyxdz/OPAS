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
