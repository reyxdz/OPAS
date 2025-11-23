class CartItem {
  final int id;
  final int productId;
  final String productName;
  final double pricePerKilo;
  int quantity;
  final String unit;
  final String imageUrl;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.pricePerKilo,
    required this.quantity,
    required this.unit,
    required this.imageUrl,
  });

  double get subtotal => pricePerKilo * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? 'Unknown',
      pricePerKilo: (json['price_per_kilo'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      unit: json['unit'] ?? 'kg',
      imageUrl: json['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'product_name': productName,
    'price_per_kilo': pricePerKilo,
    'quantity': quantity,
    'unit': unit,
    'image_url': imageUrl,
  };
}
