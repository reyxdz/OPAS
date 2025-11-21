import 'package:flutter/material.dart';

/// Data model for price non-compliance violations
class PriceComplianceModel {
  final int id;
  final int sellerId;
  final String sellerName;
  final String productName;
  final double listedPrice;
  final double ceilingPrice;
  final double overagePercentage;
  final String status; // NEW, WARNED, ADJUSTED, SUSPENDED
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final int violationCount;

  PriceComplianceModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.productName,
    required this.listedPrice,
    required this.ceilingPrice,
    required this.overagePercentage,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolutionNotes,
    required this.violationCount,
  });

  /// Factory constructor for JSON deserialization
  factory PriceComplianceModel.fromJson(Map<String, dynamic> json) {
    return PriceComplianceModel(
      id: json['id'] as int? ?? 0,
      sellerId: json['seller_id'] as int? ?? 0,
      sellerName: json['seller_name'] as String? ?? 'N/A',
      productName: json['product_name'] as String? ?? 'N/A',
      listedPrice: (json['listed_price'] as num?)?.toDouble() ?? 0.0,
      ceilingPrice: (json['ceiling_price'] as num?)?.toDouble() ?? 0.0,
      overagePercentage: (json['overage_percentage'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'NEW',
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolutionNotes: json['resolution_notes'] as String?,
      violationCount: json['violation_count'] as int? ?? 0,
    );
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'seller_id': sellerId,
        'seller_name': sellerName,
        'product_name': productName,
        'listed_price': listedPrice,
        'ceiling_price': ceilingPrice,
        'overage_percentage': overagePercentage,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'resolved_at': resolvedAt?.toIso8601String(),
        'resolution_notes': resolutionNotes,
        'violation_count': violationCount,
      };

  /// Get color based on status
  Color getStatusColor() {
    switch (status.toUpperCase()) {
      case 'NEW':
        return Colors.orange;
      case 'WARNED':
        return Colors.amber;
      case 'ADJUSTED':
        return Colors.blue;
      case 'SUSPENDED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get status display text
  String getStatusDisplay() {
    switch (status.toUpperCase()) {
      case 'NEW':
        return 'New Violation';
      case 'WARNED':
        return 'Seller Warned';
      case 'ADJUSTED':
        return 'Price Adjusted';
      case 'SUSPENDED':
        return 'Seller Suspended';
      default:
        return status;
    }
  }

  /// Get severity level
  int getSeverityLevel() {
    if (overagePercentage > 20) return 3; // Critical
    if (overagePercentage > 10) return 2; // High
    return 1; // Moderate
  }

  /// Format price for display
  String formatPrice() => 'PKR ${listedPrice.toStringAsFixed(2)}';
  String formatCeiling() => 'PKR ${ceilingPrice.toStringAsFixed(2)}';
  String formatOverage() => '${overagePercentage.toStringAsFixed(1)}%';
}
