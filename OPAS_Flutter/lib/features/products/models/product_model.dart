import 'package:flutter/foundation.dart';

class Product {
  final int id;
  final String name;
  final String category;
  final String description;
  final double pricePerKilo;
  final double opasRegulatedPrice;
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

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.pricePerKilo,
    required this.opasRegulatedPrice,
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
        opasRegulatedPrice: double.tryParse(json['opas_regulated_price']?.toString() ?? '0') ?? 0,
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
    'opas_regulated_price': opasRegulatedPrice,
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
  };

  double get priceComparison => opasRegulatedPrice - pricePerKilo;
  bool get isWithinRegulatedPrice => pricePerKilo <= opasRegulatedPrice;
}
