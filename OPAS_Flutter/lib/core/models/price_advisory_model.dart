import 'package:flutter/material.dart';

/// Data model for price advisories
class PriceAdvisoryModel {
  final int id;
  final String title;
  final String content;
  final String type; // Price Update, Shortage Alert, Promotion, Market Trend
  final String targetAudience; // ALL, BUYERS, SELLERS, SPECIFIC
  final DateTime createdAt;
  final DateTime effectiveDate;
  final DateTime? expiryDate;
  final bool isActive;
  final int viewsCount;
  final String createdBy;

  PriceAdvisoryModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.targetAudience,
    required this.createdAt,
    required this.effectiveDate,
    this.expiryDate,
    required this.isActive,
    required this.viewsCount,
    required this.createdBy,
  });

  /// Factory constructor for JSON deserialization
  factory PriceAdvisoryModel.fromJson(Map<String, dynamic> json) {
    return PriceAdvisoryModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'N/A',
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? 'Price Update',
      targetAudience: json['target_audience'] as String? ?? 'ALL',
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      effectiveDate: DateTime.parse(
        json['effective_date'] as String? ?? DateTime.now().toIso8601String(),
      ),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      viewsCount: json['views_count'] as int? ?? 0,
      createdBy: json['created_by'] as String? ?? 'Admin',
    );
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'type': type,
        'target_audience': targetAudience,
        'created_at': createdAt.toIso8601String(),
        'effective_date': effectiveDate.toIso8601String(),
        'expiry_date': expiryDate?.toIso8601String(),
        'is_active': isActive,
        'views_count': viewsCount,
        'created_by': createdBy,
      };

  /// Get color based on type
  Color getTypeColor() {
    switch (type) {
      case 'Price Update':
        return Colors.blue;
      case 'Shortage Alert':
        return Colors.orange;
      case 'Promotion':
        return Colors.green;
      case 'Market Trend':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Get icon based on type
  IconData getTypeIcon() {
    switch (type) {
      case 'Price Update':
        return Icons.trending_up;
      case 'Shortage Alert':
        return Icons.warning;
      case 'Promotion':
        return Icons.local_offer;
      case 'Market Trend':
        return Icons.analytics;
      default:
        return Icons.info;
    }
  }

  /// Check if advisory has expired
  bool isExpired() {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// Check if advisory is currently active (within date range)
  bool isCurrentlyActive() {
    final now = DateTime.now();
    final afterEffective = now.isAfter(effectiveDate) || now.isAtSameMomentAs(effectiveDate);
    final beforeExpiry = expiryDate == null || now.isBefore(expiryDate!);
    return isActive && afterEffective && beforeExpiry;
  }

  /// Get advisory status display
  String getStatus() {
    if (!isActive) return 'Inactive';
    if (isExpired()) return 'Expired';
    if (isCurrentlyActive()) return 'Active';
    if (DateTime.now().isBefore(effectiveDate)) return 'Scheduled';
    return 'Unknown';
  }

  /// Get status color
  Color getStatusColor() {
    final status = getStatus();
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Scheduled':
        return Colors.blue;
      case 'Expired':
        return Colors.grey;
      case 'Inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
