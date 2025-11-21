// Analytics Dashboard Model - Main metrics for admin dashboard
import 'package:flutter/material.dart';

class AnalyticsDashboardModel {
  final int totalSellers;
  final int pendingSellers;
  final int activeSellers;
  final int marketHealthScore; // 0-100
  final int opasInventoryCount;
  final int alertsCount;
  final double totalRevenue;
  final int ordersToday;
  final int priceViolations;
  final double averageTransaction;
  final DateTime lastUpdated;

  AnalyticsDashboardModel({
    required this.totalSellers,
    required this.pendingSellers,
    required this.activeSellers,
    required this.marketHealthScore,
    required this.opasInventoryCount,
    required this.alertsCount,
    required this.totalRevenue,
    required this.ordersToday,
    required this.priceViolations,
    required this.averageTransaction,
    required this.lastUpdated,
  });

  factory AnalyticsDashboardModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsDashboardModel(
      totalSellers: json['total_sellers'] as int? ?? 0,
      pendingSellers: json['pending_sellers'] as int? ?? 0,
      activeSellers: json['active_sellers'] as int? ?? 0,
      marketHealthScore: json['market_health_score'] as int? ?? 0,
      opasInventoryCount: json['opas_inventory_count'] as int? ?? 0,
      alertsCount: json['alerts_count'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      ordersToday: json['orders_today'] as int? ?? 0,
      priceViolations: json['price_violations'] as int? ?? 0,
      averageTransaction: (json['average_transaction'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now(),
    );
  }

  Color getHealthColor() {
    if (marketHealthScore >= 80) return const Color.fromARGB(255, 76, 175, 80);
    if (marketHealthScore >= 60) return const Color.fromARGB(255, 255, 193, 7);
    return const Color.fromARGB(255, 244, 67, 54);
  }

  String formatRevenue() => 'PKR ${(totalRevenue / 100000).toStringAsFixed(1)}L';
}
