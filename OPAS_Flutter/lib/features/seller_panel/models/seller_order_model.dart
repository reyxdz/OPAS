/// Order Model for Seller
/// Represents an order received by a seller
class SellerOrder {
  final int id;
  final int sellerId;
  final int buyerId;
  final int productId;
  final String productName;
  final int quantity;
  final double totalPrice;
  final String status; // PENDING, ACCEPTED, REJECTED, FULFILLED, DELIVERED, CANCELLED
  final DateTime orderedAt;
  final DateTime? acceptedAt;
  final DateTime? fulfilledAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? rejectionReason;
  final String? buyerName;
  final String? buyerEmail;
  final String? deliveryAddress;

  SellerOrder({
    required this.id,
    required this.sellerId,
    required this.buyerId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.orderedAt,
    this.acceptedAt,
    this.fulfilledAt,
    this.deliveredAt,
    this.cancelledAt,
    this.rejectionReason,
    this.buyerName,
    this.buyerEmail,
    this.deliveryAddress,
  });

  factory SellerOrder.fromJson(Map<String, dynamic> json) {
    return SellerOrder(
      id: json['id'] ?? 0,
      sellerId: json['seller_id'] ?? 0,
      buyerId: json['buyer_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'PENDING',
      orderedAt: json['ordered_at'] != null ? DateTime.parse(json['ordered_at']) : DateTime.now(),
      acceptedAt: json['accepted_at'] != null ? DateTime.parse(json['accepted_at']) : null,
      fulfilledAt: json['fulfilled_at'] != null ? DateTime.parse(json['fulfilled_at']) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
      cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at']) : null,
      rejectionReason: json['rejection_reason'] as String?,
      buyerName: json['buyer_name'] as String?,
      buyerEmail: json['buyer_email'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'seller_id': sellerId,
    'buyer_id': buyerId,
    'product_id': productId,
    'product_name': productName,
    'quantity': quantity,
    'total_price': totalPrice,
    'status': status,
    'ordered_at': orderedAt.toIso8601String(),
    'accepted_at': acceptedAt?.toIso8601String(),
    'fulfilled_at': fulfilledAt?.toIso8601String(),
    'delivered_at': deliveredAt?.toIso8601String(),
    'cancelled_at': cancelledAt?.toIso8601String(),
    'rejection_reason': rejectionReason,
    'buyer_name': buyerName,
    'buyer_email': buyerEmail,
    'delivery_address': deliveryAddress,
  };

  bool get isPending => status == 'PENDING';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isRejected => status == 'REJECTED';
  bool get isFulfilled => status == 'FULFILLED';
  bool get isDelivered => status == 'DELIVERED';
  bool get isCancelled => status == 'CANCELLED';
  bool get canBeAccepted => status == 'PENDING';
  bool get canBeRejected => status == 'PENDING';
  bool get canBeFulfilled => status == 'ACCEPTED';
  bool get canBeDelivered => status == 'FULFILLED';
}
