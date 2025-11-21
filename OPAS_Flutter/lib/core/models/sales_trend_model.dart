// Sales Trend Model - Represents sales data over time
class SalesTrendModel {
  final DateTime date;
  final double salesAmount;
  final int orderCount;
  final String category;

  SalesTrendModel({
    required this.date,
    required this.salesAmount,
    required this.orderCount,
    required this.category,
  });

  factory SalesTrendModel.fromJson(Map<String, dynamic> json) {
    return SalesTrendModel(
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      salesAmount: (json['sales_amount'] as num?)?.toDouble() ?? 0.0,
      orderCount: json['order_count'] as int? ?? 0,
      category: json['category'] as String? ?? 'Unknown',
    );
  }

  String formatAmount() => 'PKR ${salesAmount.toStringAsFixed(0)}';
}
