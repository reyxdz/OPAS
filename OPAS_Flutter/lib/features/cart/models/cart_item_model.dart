class CartItem {
  final String id;
  final String productId;
  final String productName;
  final double price;
  int quantity;
  final String unit;
  final String? imageUrl;
  final String sellerId;
  final String sellerName;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.unit,
    this.imageUrl,
    required this.sellerId,
    required this.sellerName,
  });

  double get subtotal => price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '0',
      productName: json['product_name'] ?? 'Unknown',
      price: (json['price'] ?? json['price_per_kilo'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      unit: json['unit'] ?? 'kg',
      imageUrl: json['image_url'],
      sellerId: json['seller_id']?.toString() ?? '0',
      sellerName: json['seller_name'] ?? 'Unknown Seller',
    );
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      price: map['price'] as double,
      quantity: map['quantity'] as int,
      unit: map['unit'] ?? 'kg',
      imageUrl: map['image_url'] as String?,
      sellerId: map['seller_id'] as String? ?? '0',
      sellerName: map['seller_name'] as String? ?? 'Unknown Seller',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'product_name': productName,
    'price': price,
    'quantity': quantity,
    'unit': unit,
    'image_url': imageUrl,
    'seller_id': sellerId,
    'seller_name': sellerName,
  };

  Map<String, dynamic> toMap() => {
    'id': id,
    'product_id': productId,
    'product_name': productName,
    'price': price,
    'quantity': quantity,
    'unit': unit,
    'image_url': imageUrl,
    'seller_id': sellerId,
    'seller_name': sellerName,
  };
}
