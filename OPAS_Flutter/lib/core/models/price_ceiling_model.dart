import 'package:flutter/material.dart';

/// Data model for price ceiling with all necessary fields and logic
class PriceCeilingModel {
  final int id;
  final int productId;
  final String productName;
  final String productCategory;
  final double currentCeiling;
  final double previousCeiling;
  final DateTime effectiveDate;
  final DateTime createdAt;
  final DateTime? lastChangedAt;
  final String? lastChangedBy;
  final String? reasonForChange;
  final int affectedListings;
  final int affectedSellers;

  PriceCeilingModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.currentCeiling,
    required this.previousCeiling,
    required this.effectiveDate,
    required this.createdAt,
    this.lastChangedAt,
    this.lastChangedBy,
    this.reasonForChange,
    required this.affectedListings,
    required this.affectedSellers,
  });

  /// Factory constructor for JSON deserialization
  factory PriceCeilingModel.fromJson(Map<String, dynamic> json) {
    return PriceCeilingModel(
      id: json['id'] as int? ?? 0,
      productId: json['product_id'] as int? ?? 0,
      productName: json['product_name'] as String? ?? 'N/A',
      productCategory: json['product_category'] as String? ?? 'General',
      currentCeiling: (json['current_ceiling'] as num?)?.toDouble() ?? 0.0,
      previousCeiling: (json['previous_ceiling'] as num?)?.toDouble() ?? 0.0,
      effectiveDate: DateTime.parse(
        json['effective_date'] as String? ?? DateTime.now().toIso8601String(),
      ),
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      lastChangedAt: json['last_changed_at'] != null
          ? DateTime.parse(json['last_changed_at'] as String)
          : null,
      lastChangedBy: json['last_changed_by'] as String?,
      reasonForChange: json['reason_for_change'] as String?,
      affectedListings: json['affected_listings'] as int? ?? 0,
      affectedSellers: json['affected_sellers'] as int? ?? 0,
    );
  }

  /// Serialize to JSON for API requests
  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'product_name': productName,
        'product_category': productCategory,
        'current_ceiling': currentCeiling,
        'previous_ceiling': previousCeiling,
        'effective_date': effectiveDate.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'last_changed_at': lastChangedAt?.toIso8601String(),
        'last_changed_by': lastChangedBy,
        'reason_for_change': reasonForChange,
        'affected_listings': affectedListings,
        'affected_sellers': affectedSellers,
      };

  /// Get percentage change from previous ceiling
  double getPercentageChange() {
    if (previousCeiling == 0) return 0.0;
    return ((currentCeiling - previousCeiling) / previousCeiling) * 100;
  }

  /// Get change direction indicator
  String getChangeDirection() {
    final change = currentCeiling - previousCeiling;
    if (change > 0) return 'increased';
    if (change < 0) return 'decreased';
    return 'unchanged';
  }

  /// Get color based on price change
  Color getChangeColor() {
    final change = currentCeiling - previousCeiling;
    if (change > 0) return Colors.green; // Price increase
    if (change < 0) return Colors.red; // Price decrease
    return Colors.grey; // No change
  }

  /// Format currency display
  String formatCeiling() => 'PKR ${currentCeiling.toStringAsFixed(2)}';
  String formatPreviousCeiling() => 'PKR ${previousCeiling.toStringAsFixed(2)}';
}
