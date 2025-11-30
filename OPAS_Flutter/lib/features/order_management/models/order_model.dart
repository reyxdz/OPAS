class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final double pricePerKilo;
  final int quantity;
  final String unit;
  final double subtotal;
  final String imageUrl;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.pricePerKilo,
    required this.quantity,
    required this.unit,
    required this.subtotal,
    required this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? 'Unknown',
      pricePerKilo: (json['price_per_kilo'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      unit: json['unit'] ?? 'kg',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
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
    'subtotal': subtotal,
    'image_url': imageUrl,
  };
}

class Order {
  final int id;
  final String orderNumber;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String? fulfillmentMethod;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String deliveryAddress;
  final String buyerName;
  final String buyerPhone;
  final String? sellerStoreName;
  final String? sellerFarmName;
  final String? sellerFarmAddress;
  final String? sellerPhone;

  Order({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    this.fulfillmentMethod,
    required this.createdAt,
    this.completedAt,
    required this.deliveryAddress,
    required this.buyerName,
    required this.buyerPhone,
    this.sellerStoreName,
    this.sellerFarmName,
    this.sellerFarmAddress,
    this.sellerPhone,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentMethod: json['payment_method'] ?? 'cash_on_delivery',
      fulfillmentMethod: json['fulfillment_method'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'])
          : null,
      deliveryAddress: json['delivery_address'] ?? '',
      buyerName: json['buyer_name'] ?? '',
      buyerPhone: json['buyer_phone'] ?? '',
      sellerStoreName: json['seller_store_name'],
      sellerFarmName: json['seller_farm_name'],
      sellerFarmAddress: json['seller_farm_address'],
      sellerPhone: json['seller_phone'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_number': orderNumber,
    'items': items.map((item) => item.toJson()).toList(),
    'total_amount': totalAmount,
    'status': status,
    'payment_method': paymentMethod,
    'fulfillment_method': fulfillmentMethod,
    'created_at': createdAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'delivery_address': deliveryAddress,
    'buyer_name': buyerName,
    'buyer_phone': buyerPhone,
    'seller_store_name': sellerStoreName,
    'seller_farm_name': sellerFarmName,
    'seller_farm_address': sellerFarmAddress,
    'seller_phone': sellerPhone,
  };

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isConfirmed => status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'accepted';
  bool get isCompleted => status.toLowerCase() == 'completed' || status.toLowerCase() == 'delivered' || status.toLowerCase() == 'fulfilled';
  bool get isCancelled => status.toLowerCase() == 'cancelled' || status.toLowerCase() == 'rejected';
}
