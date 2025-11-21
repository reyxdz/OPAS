// Marketplace Activity Model - Represents real-time marketplace activities
// Tracks new listings, completed orders, price changes, seller activities

import 'package:flutter/material.dart';

class MarketplaceActivityModel {
  final int id;
  final String activityType;
  final int? sellerId;
  final String? sellerName;
  final int? productId;
  final String? productName;
  final String? productCategory;
  final double? amount;
  final String? description;
  final int? affectedListingId;
  final String? relatedEntityType;
  final int? relatedEntityId;
  final String? activityStatus;
  final DateTime activityTime;
  final int? viewCount;
  final bool requiresAttention;
  final String? priority;
  final Map<String, dynamic>? metadata;

  MarketplaceActivityModel({
    required this.id,
    required this.activityType,
    this.sellerId,
    this.sellerName,
    this.productId,
    this.productName,
    this.productCategory,
    this.amount,
    this.description,
    this.affectedListingId,
    this.relatedEntityType,
    this.relatedEntityId,
    this.activityStatus,
    required this.activityTime,
    this.viewCount,
    required this.requiresAttention,
    this.priority,
    this.metadata,
  });

  factory MarketplaceActivityModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceActivityModel(
      id: json['id'] as int? ?? 0,
      activityType: json['activity_type'] as String? ?? 'UNKNOWN',
      sellerId: json['seller_id'] as int?,
      sellerName: json['seller_name'] as String?,
      productId: json['product_id'] as int?,
      productName: json['product_name'] as String?,
      productCategory: json['product_category'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      description: json['description'] as String?,
      affectedListingId: json['affected_listing_id'] as int?,
      relatedEntityType: json['related_entity_type'] as String?,
      relatedEntityId: json['related_entity_id'] as int?,
      activityStatus: json['activity_status'] as String?,
      activityTime: json['activity_time'] != null
          ? DateTime.parse(json['activity_time'] as String)
          : DateTime.now(),
      viewCount: json['view_count'] as int?,
      requiresAttention: json['requires_attention'] as bool? ?? false,
      priority: json['priority'] as String? ?? 'MEDIUM',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_type': activityType,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'product_id': productId,
      'product_name': productName,
      'product_category': productCategory,
      'amount': amount,
      'description': description,
      'affected_listing_id': affectedListingId,
      'related_entity_type': relatedEntityType,
      'related_entity_id': relatedEntityId,
      'activity_status': activityStatus,
      'activity_time': activityTime.toIso8601String(),
      'view_count': viewCount,
      'requires_attention': requiresAttention,
      'priority': priority,
      'metadata': metadata,
    };
  }

  Color getPriorityColor() {
    switch (priority?.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFFF44336); // Red
      case 'MEDIUM':
        return const Color(0xFFFFC107); // Amber
      case 'LOW':
        return const Color(0xFF4CAF50); // Green
      default:
        return const Color(0xFF2196F3); // Blue
    }
  }

  String getActivityIcon() {
    switch (activityType.toUpperCase()) {
      case 'NEW_LISTING':
        return '📋'; // Document
      case 'COMPLETED_ORDER':
        return '✅'; // Check
      case 'PRICE_CHANGE':
        return '💰'; // Money
      case 'SELLER_JOINED':
        return '👤'; // Person
      case 'SELLER_SUSPENDED':
        return '🚫'; // Prohibited
      case 'LISTING_REMOVED':
        return '❌'; // X
      case 'UNUSUAL_ACTIVITY':
        return '⚠️'; // Warning
      default:
        return '📌'; // Pin
    }
  }

  String getActivityLabel() {
    switch (activityType.toUpperCase()) {
      case 'NEW_LISTING':
        return 'New Listing';
      case 'COMPLETED_ORDER':
        return 'Completed Order';
      case 'PRICE_CHANGE':
        return 'Price Change';
      case 'SELLER_JOINED':
        return 'Seller Joined';
      case 'SELLER_SUSPENDED':
        return 'Seller Suspended';
      case 'LISTING_REMOVED':
        return 'Listing Removed';
      case 'UNUSUAL_ACTIVITY':
        return 'Unusual Activity';
      default:
        return 'Activity';
    }
  }

  String formatTime() {
    final difference = DateTime.now().difference(activityTime);
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String formatAmount() {
    if (amount == null) return '';
    return 'PKR ${amount!.toStringAsFixed(2)}';
  }
}
