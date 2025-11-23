class ProductReview {
  final int id;
  final int productId;
  final String productName;
  final int buyerId;
  final String buyerName;
  final double rating; // 1-5 stars
  final String title;
  final String comment;
  final List<String> images;
  final int helpfulCount;
  final bool isVerifiedPurchase;
  final DateTime createdAt;

  ProductReview({
    required this.id,
    required this.productId,
    required this.productName,
    required this.buyerId,
    required this.buyerName,
    required this.rating,
    required this.title,
    required this.comment,
    required this.images,
    required this.helpfulCount,
    required this.isVerifiedPurchase,
    required this.createdAt,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? 'Unknown Product',
      buyerId: json['buyer_id'] ?? 0,
      buyerName: json['buyer_name'] ?? 'Anonymous',
      rating: (json['rating'] ?? 0).toDouble(),
      title: json['title'] ?? '',
      comment: json['comment'] ?? '',
      images: List<String>.from(json['images'] as List<dynamic>? ?? []),
      helpfulCount: json['helpful_count'] ?? 0,
      isVerifiedPurchase: json['is_verified_purchase'] ?? false,
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'product_name': productName,
    'buyer_id': buyerId,
    'buyer_name': buyerName,
    'rating': rating,
    'title': title,
    'comment': comment,
    'images': images,
    'helpful_count': helpfulCount,
    'is_verified_purchase': isVerifiedPurchase,
    'created_at': createdAt.toIso8601String(),
  };

  String get ratingDisplayString => '$rating ★';
}

class SellerFeedback {
  final int id;
  final int sellerId;
  final String sellerName;
  final int buyerId;
  final String buyerName;
  final double rating; // 1-5 stars
  final String feedbackType; // 'quality', 'communication', 'delivery', 'overall'
  final String comment;
  final bool wouldRecommend;
  final DateTime createdAt;

  SellerFeedback({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.buyerId,
    required this.buyerName,
    required this.rating,
    required this.feedbackType,
    required this.comment,
    required this.wouldRecommend,
    required this.createdAt,
  });

  factory SellerFeedback.fromJson(Map<String, dynamic> json) {
    return SellerFeedback(
      id: json['id'] ?? 0,
      sellerId: json['seller_id'] ?? 0,
      sellerName: json['seller_name'] ?? 'Unknown Seller',
      buyerId: json['buyer_id'] ?? 0,
      buyerName: json['buyer_name'] ?? 'Anonymous',
      rating: (json['rating'] ?? 0).toDouble(),
      feedbackType: json['feedback_type'] ?? 'overall',
      comment: json['comment'] ?? '',
      wouldRecommend: json['would_recommend'] ?? false,
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'seller_id': sellerId,
    'seller_name': sellerName,
    'buyer_id': buyerId,
    'buyer_name': buyerName,
    'rating': rating,
    'feedback_type': feedbackType,
    'comment': comment,
    'would_recommend': wouldRecommend,
    'created_at': createdAt.toIso8601String(),
  };
}
