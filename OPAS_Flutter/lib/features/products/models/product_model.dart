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
  final int sellerId;
  final String sellerName;
  final double sellerRating;
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
    required this.sellerId,
    required this.sellerName,
    required this.sellerRating,
    required this.isAvailable,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      category: json['category'] ?? 'General',
      description: json['description'] ?? '',
      pricePerKilo: (json['price_per_kilo'] ?? 0).toDouble(),
      opasRegulatedPrice: (json['opas_regulated_price'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
      unit: json['unit'] ?? 'kg',
      imageUrl: json['image_url'] ?? '',
      sellerId: json['seller_id'] ?? 0,
      sellerName: json['seller_name'] ?? 'Unknown Seller',
      sellerRating: (json['seller_rating'] ?? 0).toDouble(),
      isAvailable: json['is_available'] ?? true,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
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
    'seller_id': sellerId,
    'seller_name': sellerName,
    'seller_rating': sellerRating,
    'is_available': isAvailable,
    'created_at': createdAt.toIso8601String(),
  };

  double get priceComparison => opasRegulatedPrice - pricePerKilo;
  bool get isWithinRegulatedPrice => pricePerKilo <= opasRegulatedPrice;
}
