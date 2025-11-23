import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/price_trend_model.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';
import '../../cart/models/cart_item_model.dart';
import '../../order_management/models/order_model.dart';
import '../../home/models/notification_model.dart';

class BuyerApiService {
  static const String baseUrl = 'http://10.113.93.34:8000/api';

  /// ==================== PRODUCT BROWSING ====================
  /// Get all products with optional filtering
  static Future<List<Product>> getAllProducts({
    String? category,
    double? minPrice,
    double? maxPrice,
    String? searchTerm,
    int page = 1,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      Map<String, String> queryParams = {'page': page.toString()};
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (minPrice != null) {
        queryParams['min_price'] = minPrice.toString();
      }
      if (maxPrice != null) {
        queryParams['max_price'] = maxPrice.toString();
      }
      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams['search'] = searchTerm;
      }

      final uri = Uri.parse('$baseUrl/products/').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> products =
            data['results'] ?? data['products'] ?? [];
        return products
            .map((p) => Product.fromJson(p as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Get product by ID with detailed information
  static Future<Product> getProductDetail(int productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception(
            'Failed to fetch product details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch product details: $e');
    }
  }

  /// ==================== CART MANAGEMENT ====================
  /// Add item to cart
  static Future<CartItem> addToCart(int productId, int quantity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.post(
        Uri.parse('$baseUrl/cart/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'product_id': productId,
          'quantity': quantity,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CartItem.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to add to cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to add to cart: $e');
    }
  }

  /// Get all items in cart
  static Future<List<CartItem>> getCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/cart/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        return items
            .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch cart: $e');
    }
  }

  /// Update cart item quantity
  static Future<CartItem> updateCartItem(int cartItemId, int quantity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.put(
        Uri.parse('$baseUrl/cart/$cartItemId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'quantity': quantity}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CartItem.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to update cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update cart: $e');
    }
  }

  /// Remove item from cart
  static Future<bool> removeFromCart(int cartItemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.delete(
        Uri.parse('$baseUrl/cart/$cartItemId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to remove from cart: $e');
    }
  }

  /// ==================== ORDER MANAGEMENT ====================
  /// Place a new order
  static Future<Order> placeOrder({
    required List<int> cartItemIds,
    required String paymentMethod,
    required String deliveryAddress,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.post(
        Uri.parse('$baseUrl/orders/create/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'cart_items': cartItemIds,
          'payment_method': paymentMethod,
          'delivery_address': deliveryAddress,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to place order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to place order: $e');
    }
  }

  /// Get all orders for the current buyer
  static Future<List<Order>> getBuyerOrders({int page = 1}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/orders/?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> orders = data['results'] ?? data['orders'] ?? [];
        return orders
            .map((o) => Order.fromJson(o as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch orders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  /// Get order details
  static Future<Order> getOrderDetail(int orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to fetch order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  /// ==================== PRICING TRANSPARENCY ====================
  /// Get price trends for a product
  static Future<PriceTrend> getPriceTrend(int productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/price-trends/$productId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PriceTrend.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to fetch price trend: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch price trend: $e');
    }
  }

  /// Get price trends for category
  static Future<List<PriceTrend>> getCategoryPriceTrends(String category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/price-trends/category/$category/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> trends = data['trends'] ?? [];
        return trends
            .map((t) => PriceTrend.fromJson(t as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch price trends: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch price trends: $e');
    }
  }

  /// ==================== NOTIFICATIONS ====================
  /// Get buyer notifications
  static Future<List<BuyerNotification>> getNotifications({int page = 1}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/notifications/?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> notifications =
            data['results'] ?? data['notifications'] ?? [];
        return notifications
            .map((n) => BuyerNotification.fromJson(n as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  /// Mark notification as read
  static Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'is_read': true}),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// ==================== REVIEWS & FEEDBACK ====================
  /// Get product reviews
  static Future<List<ProductReview>> getProductReviews(int productId,
      {int page = 1}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId/reviews/?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> reviews = data['results'] ?? data['reviews'] ?? [];
        return reviews
            .map((r) => ProductReview.fromJson(r as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch reviews: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  /// Submit product review
  static Future<ProductReview> submitProductReview({
    required int productId,
    required double rating,
    required String title,
    required String comment,
    List<String> images = const [],
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.post(
        Uri.parse('$baseUrl/products/$productId/reviews/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'rating': rating,
          'title': title,
          'comment': comment,
          'images': images,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProductReview.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to submit review: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  /// Submit seller feedback
  static Future<SellerFeedback> submitSellerFeedback({
    required int orderId,
    required double rating,
    required String feedbackType,
    required String comment,
    required bool wouldRecommend,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/feedback/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'rating': rating,
          'feedback_type': feedbackType,
          'comment': comment,
          'would_recommend': wouldRecommend,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SellerFeedback.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to submit feedback: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }
}
