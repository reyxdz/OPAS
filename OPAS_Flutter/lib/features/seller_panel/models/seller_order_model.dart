/// Order Model for Seller
/// Represents an order received by a seller
/// Matches SellerOrderSerializer from backend
class SellerOrder {
  final int id;
  final String orderNumber;
  final int seller;
  final int buyer;
  final int product;
  final String productName;
  final int quantity;
  final double pricePerUnit;
  final double totalAmount;
  final String status; // pending, accepted, rejected, fulfilled, delivered, cancelled
  final String? rejectionReason;
  final String? deliveryLocation;
  final String? deliveryDate;
  final String? statusDisplay;
  final bool? canBeAccepted;
  final bool? canBeRejected;
  final bool? canBeFulfilled;
  final bool? canBeDelivered;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? fulfilledAt;
  final DateTime? deliveredAt;
  final DateTime? updatedAt;
  final String? buyerName;
  final String? buyerPhone;

  SellerOrder({
    required this.id,
    required this.orderNumber,
    required this.seller,
    required this.buyer,
    required this.product,
    required this.productName,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalAmount,
    required this.status,
    this.rejectionReason,
    this.deliveryLocation,
    this.deliveryDate,
    this.statusDisplay,
    this.canBeAccepted,
    this.canBeRejected,
    this.canBeFulfilled,
    this.canBeDelivered,
    required this.createdAt,
    this.acceptedAt,
    this.fulfilledAt,
    this.deliveredAt,
    this.updatedAt,
    this.buyerName,
    this.buyerPhone,
  });

  factory SellerOrder.fromJson(Map<String, dynamic> json) {
    return SellerOrder(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      seller: json['seller'] ?? 0,
      buyer: json['buyer'] ?? 0,
      product: json['product'] ?? 0,
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      pricePerUnit: (json['price_per_unit'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      deliveryLocation: json['delivery_location'] as String?,
      deliveryDate: json['delivery_date'] as String?,
      statusDisplay: json['status_display'] as String?,
      canBeAccepted: json['can_be_accepted'] as bool?,
      canBeRejected: json['can_be_rejected'] as bool?,
      canBeFulfilled: json['can_be_fulfilled'] as bool?,
      canBeDelivered: json['can_be_delivered'] as bool?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      acceptedAt: json['accepted_at'] != null ? DateTime.parse(json['accepted_at']) : null,
      fulfilledAt: json['fulfilled_at'] != null ? DateTime.parse(json['fulfilled_at']) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      buyerName: json['buyer_name'] as String?,
      buyerPhone: json['buyer_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_number': orderNumber,
    'seller': seller,
    'buyer': buyer,
    'product': product,
    'product_name': productName,
    'quantity': quantity,
    'price_per_unit': pricePerUnit,
    'total_amount': totalAmount,
    'status': status,
    'rejection_reason': rejectionReason,
    'delivery_location': deliveryLocation,
    'delivery_date': deliveryDate,
    'status_display': statusDisplay,
    'can_be_accepted': canBeAccepted,
    'can_be_rejected': canBeRejected,
    'can_be_fulfilled': canBeFulfilled,
    'can_be_delivered': canBeDelivered,
    'created_at': createdAt.toIso8601String(),
    'accepted_at': acceptedAt?.toIso8601String(),
    'fulfilled_at': fulfilledAt?.toIso8601String(),
    'delivered_at': deliveredAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'buyer_name': buyerName,
    'buyer_phone': buyerPhone,
  };

  bool get isPending => status == 'PENDING' || status == 'pending';
  bool get isAccepted => status == 'ACCEPTED' || status == 'accepted';
  bool get isRejected => status == 'REJECTED' || status == 'rejected';
  bool get isFulfilled => status == 'FULFILLED' || status == 'fulfilled';
  bool get isDelivered => status == 'DELIVERED' || status == 'delivered';
  bool get isCancelled => status == 'CANCELLED' || status == 'cancelled';
}
