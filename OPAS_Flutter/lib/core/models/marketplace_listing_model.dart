// Marketplace Listing Model - Represents active marketplace listings
// Used for monitoring and flagging suspicious/non-compliant listings

import 'package:flutter/material.dart';

class MarketplaceListingModel {
  final int id;
  final int sellerId;
  final String sellerName;
  final int productId;
  final String productName;
  final String productCategory;
  final double listedPrice;
  final double? pricePerUnit;
  final String unit; // kg, liter, piece, etc.
  final int quantity;
  final String quality; // Quality grade
  final String description;
  final List<String>? imageUrls;
  final bool hasImage;
  final double? priceCeiling;
  final double? priceOverage; // % above ceiling
  final String status; // ACTIVE, PENDING, FLAGGED, REMOVED
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final int viewCount;
  final int orderCount;
  final double sellerRating; // 0-5
  final bool isSuspicious; // Auto-flagged by system
  final String? suspiciousReason;
  final String? flagReason; // Manual flag reason
  final String? flaggedBy; // Admin who flagged
  final DateTime? flaggedAt;

  MarketplaceListingModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.listedPrice,
    this.pricePerUnit,
    required this.unit,
    required this.quantity,
    required this.quality,
    required this.description,
    this.imageUrls,
    required this.hasImage,
    this.priceCeiling,
    this.priceOverage,
    required this.status,
    required this.createdAt,
    this.lastUpdated,
    required this.viewCount,
    required this.orderCount,
    required this.sellerRating,
    required this.isSuspicious,
    this.suspiciousReason,
    this.flagReason,
    this.flaggedBy,
    this.flaggedAt,
  });

  factory MarketplaceListingModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceListingModel(
      id: json['id'] as int? ?? 0,
      sellerId: json['seller_id'] as int? ?? 0,
      sellerName: json['seller_name'] as String? ?? 'Unknown',
      productId: json['product_id'] as int? ?? 0,
      productName: json['product_name'] as String? ?? 'Unknown',
      productCategory: json['product_category'] as String? ?? 'Unknown',
      listedPrice: (json['listed_price'] as num?)?.toDouble() ?? 0.0,
      pricePerUnit: (json['price_per_unit'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? 'kg',
      quantity: json['quantity'] as int? ?? 0,
      quality: json['quality'] as String? ?? 'Standard',
      description: json['description'] as String? ?? '',
      imageUrls: (json['image_urls'] as List?)?.cast<String>(),
      hasImage: json['has_image'] as bool? ?? false,
      priceCeiling: (json['price_ceiling'] as num?)?.toDouble(),
      priceOverage: (json['price_overage'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
      viewCount: json['view_count'] as int? ?? 0,
      orderCount: json['order_count'] as int? ?? 0,
      sellerRating: (json['seller_rating'] as num?)?.toDouble() ?? 0.0,
      isSuspicious: json['is_suspicious'] as bool? ?? false,
      suspiciousReason: json['suspicious_reason'] as String?,
      flagReason: json['flag_reason'] as String?,
      flaggedBy: json['flagged_by'] as String?,
      flaggedAt: json['flagged_at'] != null
          ? DateTime.parse(json['flagged_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'product_id': productId,
      'product_name': productName,
      'product_category': productCategory,
      'listed_price': listedPrice,
      'price_per_unit': pricePerUnit,
      'unit': unit,
      'quantity': quantity,
      'quality': quality,
      'description': description,
      'image_urls': imageUrls,
      'has_image': hasImage,
      'price_ceiling': priceCeiling,
      'price_overage': priceOverage,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated?.toIso8601String(),
      'view_count': viewCount,
      'order_count': orderCount,
      'seller_rating': sellerRating,
      'is_suspicious': isSuspicious,
      'suspicious_reason': suspiciousReason,
      'flag_reason': flagReason,
      'flagged_by': flaggedBy,
      'flagged_at': flaggedAt?.toIso8601String(),
    };
  }

  bool isAboveCeiling() => priceOverage != null && priceOverage! > 0;
  bool isFlagged() => status.toUpperCase() == 'FLAGGED' || isSuspicious;
  Color getStatusColor() {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFF4CAF50); // Green
      case 'FLAGGED':
        return const Color(0xFFF44336); // Red
      case 'PENDING':
        return const Color(0xFFFFC107); // Amber
      case 'REMOVED':
        return const Color(0xFF9E9E9E); // Grey
      default:
        return const Color(0xFF2196F3); // Blue
    }
  }

  String formatPrice() => 'PKR ${listedPrice.toStringAsFixed(2)}';
  String getDaysOld() => DateTime.now().difference(createdAt).inDays.toString();
}
