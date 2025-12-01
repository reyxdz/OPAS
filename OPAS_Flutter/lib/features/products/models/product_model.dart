import 'package:flutter/foundation.dart';

class Product {
  final int id;
  final String name;
  final String category;
  final String description;
  final double pricePerKilo;
  final int stock;
  final String unit;
  final String imageUrl;
  final List<String> imageUrls; // Multiple images from detail endpoint
  final int sellerId;
  final String sellerName;
  final double sellerRating;
  final String? farmLocation;
  final bool isAvailable;
  final DateTime createdAt;
  final String? fulfillmentMethods; // e.g., "delivery", "pickup", "delivery_and_pickup"
  final int initialStock;
  final int baselineStock;
  final DateTime stockBaselineUpdatedAt;
  final double stockPercentage;
  final String stockStatus;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.pricePerKilo,
    required this.stock,
    required this.unit,
    required this.imageUrl,
    this.imageUrls = const [],
    required this.sellerId,
    required this.sellerName,
    required this.sellerRating,
    this.farmLocation,
    required this.isAvailable,
    required this.createdAt,
    this.fulfillmentMethods,
    required this.initialStock,
    required this.baselineStock,
    required this.stockBaselineUpdatedAt,
    required this.stockPercentage,
    required this.stockStatus,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      // Parse images array from detail endpoint
      List<String> imageUrls = [];
      if (json['images'] is List) {
        imageUrls = (json['images'] as List)
            .map((img) {
              if (img is Map && img['image_url'] != null) {
                return img['image_url'].toString();
              } else if (img is String) {
                return img;
              }
              return null;
            })
            .where((url) => url != null)
            .cast<String>()
            .toList();
      }

      // Get primary image URL
      String primaryImage = '';
      if (imageUrls.isNotEmpty) {
        primaryImage = imageUrls.first;
      } else {
        primaryImage = json['primary_image']?.toString() ?? 
                       json['image_url']?.toString() ?? '';
      }

      return Product(
        id: json['id'] ?? 0,
        name: json['name']?.toString() ?? 'Unknown',
        // Category can be int (category ID) or null - convert safely to string
        category: json['category'] != null ? json['category'].toString() : 'GENERAL',
        description: json['description']?.toString() ?? '',
        pricePerKilo: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
        stock: json['stock_level'] ?? json['stock'] ?? 0,
        unit: json['unit']?.toString() ?? 'kg',
        imageUrl: primaryImage,
        imageUrls: imageUrls,
        sellerId: int.tryParse(json['seller_id']?.toString() ?? '0') ?? 0,
        // seller_name can be null - provide fallback
        sellerName: (json['seller_name'] != null && json['seller_name'].toString().isNotEmpty) 
            ? json['seller_name'].toString() 
            : 'Unknown Seller',
        sellerRating: double.tryParse(json['seller_rating']?.toString() ?? '0') ?? 0,
        farmLocation: (json['farm_location'] != null && json['farm_location'].toString().isNotEmpty)
            ? json['farm_location'].toString()
            : null,
        isAvailable: json['is_available'] ?? json['is_in_stock'] ?? true,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
        fulfillmentMethods: (json['fulfillment_methods'] != null && json['fulfillment_methods'].toString().isNotEmpty)
            ? json['fulfillment_methods'].toString()
            : null,
        initialStock: json['initial_stock'] ?? 0,
        baselineStock: json['baseline_stock'] ?? 0,
        stockBaselineUpdatedAt: json['stock_baseline_updated_at'] != null 
            ? DateTime.parse(json['stock_baseline_updated_at'].toString())
            : DateTime.now(),
        stockPercentage: double.tryParse(json['stock_percentage']?.toString() ?? '100') ?? 100.0,
        stockStatus: json['stock_status']?.toString() ?? 'HIGH',
      );
    } catch (e, stackTrace) {
      debugPrint('Error in Product.fromJson: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'description': description,
    'price_per_kilo': pricePerKilo,
    'stock': stock,
    'unit': unit,
    'image_url': imageUrl,
    'image_urls': imageUrls,
    'seller_id': sellerId,
    'seller_name': sellerName,
    'seller_rating': sellerRating,
    'farm_location': farmLocation,
    'is_available': isAvailable,
    'created_at': createdAt.toIso8601String(),
    'fulfillment_methods': fulfillmentMethods,
    'initial_stock': initialStock,
    'baseline_stock': baselineStock,
    'stock_baseline_updated_at': stockBaselineUpdatedAt.toIso8601String(),
    'stock_percentage': stockPercentage,
    'stock_status': stockStatus,
  };

}
