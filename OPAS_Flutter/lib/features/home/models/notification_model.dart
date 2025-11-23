class BuyerNotification {
  final int id;
  final String title;
  final String message;
  final String type; // 'price_change', 'restock', 'promotion', 'announcement', 'order_update'
  final int? relatedProductId;
  final String? relatedProductName;
  final int? relatedOrderId;
  final bool isRead;
  final DateTime createdAt;

  BuyerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.relatedProductId,
    this.relatedProductName,
    this.relatedOrderId,
    required this.isRead,
    required this.createdAt,
  });

  factory BuyerNotification.fromJson(Map<String, dynamic> json) {
    return BuyerNotification(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Notification',
      message: json['message'] ?? '',
      type: json['type'] ?? 'announcement',
      relatedProductId: json['related_product_id'],
      relatedProductName: json['related_product_name'],
      relatedOrderId: json['related_order_id'],
      isRead: json['is_read'] ?? false,
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type,
    'related_product_id': relatedProductId,
    'related_product_name': relatedProductName,
    'related_order_id': relatedOrderId,
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
  };

  String get icon {
    switch (type) {
      case 'price_change':
        return '💰';
      case 'restock':
        return '📦';
      case 'promotion':
        return '🎉';
      case 'order_update':
        return '📋';
      default:
        return '📢';
    }
  }
}

class PriceChangeNotification extends BuyerNotification {
  final double oldPrice;
  final double newPrice;

  PriceChangeNotification({
    required int id,
    required String title,
    required String message,
    required this.oldPrice,
    required this.newPrice,
    int? relatedProductId,
    String? relatedProductName,
    required bool isRead,
    required DateTime createdAt,
  }) : super(
    id: id,
    title: title,
    message: message,
    type: 'price_change',
    relatedProductId: relatedProductId,
    relatedProductName: relatedProductName,
    isRead: isRead,
    createdAt: createdAt,
  );

  factory PriceChangeNotification.fromJson(Map<String, dynamic> json) {
    return PriceChangeNotification(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Price Update',
      message: json['message'] ?? '',
      oldPrice: (json['old_price'] ?? 0).toDouble(),
      newPrice: (json['new_price'] ?? 0).toDouble(),
      relatedProductId: json['related_product_id'],
      relatedProductName: json['related_product_name'],
      isRead: json['is_read'] ?? false,
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  double get priceChange => newPrice - oldPrice;
  double get percentageChange => (priceChange / oldPrice) * 100;
  bool get isPriceIncrease => priceChange > 0;
}
