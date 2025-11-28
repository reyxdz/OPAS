/// Product Model for Seller
/// Represents a product posted by a seller
class SellerProduct {
  final int id;
  final int sellerId;
  final String name;
  final String description;
  final double price;
  final double ceilingPrice;
  final int stockLevel;
  final String status; // ACTIVE, EXPIRED, PENDING
  final String? category;
  final List<String>? images;
  final Map<String, dynamic>? primaryImage;
  final String? sku;
  final String? qualityGrade;
  final String? previousStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SellerProduct({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.price,
    required this.ceilingPrice,
    required this.stockLevel,
    required this.status,
    this.category,
    this.images,
    this.primaryImage,
    this.sku,
    this.qualityGrade,
    this.previousStatus,
    required this.createdAt,
    this.updatedAt,
  });

  factory SellerProduct.fromJson(Map<String, dynamic> json) {
    return SellerProduct(
      id: _parseInt(json['id']),
      sellerId: _parseInt(json['seller_id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _parseDouble(json['price']),
      ceilingPrice: _parseDouble(json['ceiling_price']),
      stockLevel: _parseInt(json['stock_level']),
      status: json['status']?.toString() ?? 'PENDING',
      qualityGrade: json['quality_grade']?.toString(),
      previousStatus: json['previous_status']?.toString(),
      category: json['category']?.toString(),
      images: _parseImages(json['images']),
      primaryImage: json['primary_image'],
      sku: json['sku']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : null,
    );
  }

  /// Parse int from various formats (int, string, null)
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  /// Parse double from various formats (num, string, null)
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return (value as num?)?.toDouble() ?? 0.0;
  }

  /// Parse images from various formats (list of strings, list of maps, null)
  static List<String> _parseImages(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((img) {
        if (img is String) {
          return img;
        } else if (img is Map && img.containsKey('image_url')) {
          return img['image_url'].toString();
        }
        return '';
      }).where((url) => url.isNotEmpty).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'seller_id': sellerId,
    'name': name,
    'description': description,
    'price': price,
    'ceiling_price': ceilingPrice,
    'stock_level': stockLevel,
    'status': status,
    'category': category,
    'images': images,
    'primary_image': primaryImage,
    'sku': sku,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'quality_grade': qualityGrade,
    'previous_status': previousStatus,
  };

  bool get isActive => status == 'ACTIVE';
  bool get isExpired => status == 'EXPIRED';
  bool get isPending => status == 'PENDING';
  bool get isLowStock => stockLevel < 10;
  bool get priceExceedsCeiling => price > ceilingPrice;
}
