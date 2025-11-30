import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/price_trend_model.dart';
import '../../../core/services/api_service.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';
import '../../cart/models/cart_item_model.dart';
import '../../order_management/models/order_model.dart';
import '../../home/models/notification_model.dart';

class BuyerApiService {
  static String get baseUrl => ApiService.baseUrl;

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
        
        // Handle both paginated and direct list responses
        late final List<dynamic> products;
        if (data is List) {
          // Direct list response
          products = data;
        } else if (data is Map) {
          // Paginated response
          products = data['results'] ?? data['products'] ?? [];
        } else {
          products = [];
        }
        
        try {
          return products
              .map((p) {
                try {
                  return Product.fromJson(p as Map<String, dynamic>);
                } catch (e) {
                  debugPrint('Error parsing individual product: $p, Error: $e');
                  rethrow;
                }
              })
              .toList();
        } catch (e) {
          debugPrint('Error parsing products: $e');
          rethrow;
        }
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
      var token = prefs.getString('access') ?? '';

      // Try to place order
      var response = await http.post(
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

      // If 401 (unauthorized), try to refresh token
      if (response.statusCode == 401) {
        final refreshToken = prefs.getString('refresh') ?? '';
        if (refreshToken.isNotEmpty) {
          // Try to refresh the token
          final refreshResponse = await http.post(
            Uri.parse('$baseUrl/auth/token/refresh/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': refreshToken}),
          ).timeout(const Duration(seconds: 15));

          if (refreshResponse.statusCode == 200) {
            final refreshData = jsonDecode(refreshResponse.body);
            final newToken = refreshData['access'] ?? '';
            
            // Save new token
            await prefs.setString('access', newToken);
            token = newToken;

            // Retry the order placement with new token
            response = await http.post(
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
          }
        }
      }

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
      var token = prefs.getString('access') ?? '';

      var response = await http.get(
        Uri.parse('$baseUrl/orders/?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      // Handle 401 - try to refresh token and retry
      if (response.statusCode == 401 && token.isNotEmpty) {
        final refreshToken = prefs.getString('refresh') ?? '';
        if (refreshToken.isNotEmpty) {
          try {
            final refreshResponse = await http.post(
              Uri.parse('$baseUrl/auth/token/refresh/'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'refresh': refreshToken}),
            ).timeout(const Duration(seconds: 15));

            if (refreshResponse.statusCode == 200) {
              final refreshData = jsonDecode(refreshResponse.body);
              final newToken = refreshData['access'] ?? '';
              await prefs.setString('access', newToken);
              token = newToken;

              // Retry the request with new token
              response = await http.get(
                Uri.parse('$baseUrl/orders/?page=$page'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              ).timeout(const Duration(seconds: 15));
            }
          } catch (e) {
            // Token refresh failed, continue with original response
            debugPrint('Token refresh failed: $e');
          }
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        List<dynamic> orders = [];
        
        // Handle different response formats
        if (data is List) {
          // Response is a direct list
          orders = data;
        } else if (data is Map<String, dynamic>) {
          // Response is a map - check for results, orders, or data key
          orders = data['results'] ?? data['orders'] ?? data['data'] ?? [];
        }
        
        debugPrint('📦 Fetched ${orders.length} orders');
        return orders
            .map((o) => Order.fromJson(o as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please log in again');
      } else {
        throw Exception('Failed to fetch orders: ${response.statusCode} - ${response.body}');
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

  /// Cancel an order
  static Future<void> cancelOrder(int orderId) async {
    try {
      debugPrint('📡 Cancel order request: POST /orders/$orderId/cancel/');
      final prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('access') ?? '';

      var response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/cancel/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('📋 Cancel order response: Status ${response.statusCode}');
      debugPrint('📋 Response body: ${response.body}');

      // Handle 401 - try to refresh token and retry
      if (response.statusCode == 401 && token.isNotEmpty) {
        debugPrint('🔄 Token expired, attempting refresh...');
        final refreshToken = prefs.getString('refresh') ?? '';
        if (refreshToken.isNotEmpty) {
          try {
            final refreshResponse = await http.post(
              Uri.parse('$baseUrl/auth/token/refresh/'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'refresh': refreshToken}),
            ).timeout(const Duration(seconds: 15));

            if (refreshResponse.statusCode == 200) {
              final refreshData = jsonDecode(refreshResponse.body);
              final newToken = refreshData['access'] ?? '';
              await prefs.setString('access', newToken);
              token = newToken;
              debugPrint('✅ Token refreshed, retrying cancel order...');

              // Retry the request with new token
              response = await http.post(
                Uri.parse('$baseUrl/orders/$orderId/cancel/'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              ).timeout(const Duration(seconds: 15));
              debugPrint('📋 Retry response: Status ${response.statusCode}');
            }
          } catch (e) {
            debugPrint('❌ Token refresh failed: $e');
          }
        }
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ Order $orderId cancelled successfully');
        return;
      } else if (response.statusCode == 400) {
        try {
          final data = jsonDecode(response.body);
          throw Exception(data['detail'] ?? 'Cannot cancel this order');
        } catch (e) {
          throw Exception('Cannot cancel this order: ${response.body}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please log in again');
      } else {
        throw Exception('Failed to cancel order: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Cancel order error: $e');
      throw Exception('Failed to cancel order: $e');
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

  /// Get products with advanced filtering and pagination
  /// Params: page, limit, category, min_price, max_price, search, ordering, in_stock
  static Future<Map<String, dynamic>> getProductsPaginated(
      Map<String, dynamic> params) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      // Convert params to string map for URI
      final Map<String, String> queryParams = {};
      params.forEach((key, value) {
        if (value != null) {
          queryParams[key] = value.toString();
        }
      });

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
        final decodedBody = jsonDecode(response.body);
        debugPrint('API Response type: ${decodedBody.runtimeType}');
        debugPrint('API Response: $decodedBody');
        
        // Handle both paginated response (Map) and direct list response
        List<dynamic> results = [];
        int count = 0;
        String? next;
        String? previous;

        if (decodedBody is Map<String, dynamic>) {
          // Paginated response with metadata
          results = decodedBody['results'] ?? [];
          count = decodedBody['count'] ?? 0;
          next = decodedBody['next'];
          previous = decodedBody['previous'];
          debugPrint('Parsed as paginated response: ${results.length} products');
        } else if (decodedBody is List<dynamic>) {
          // Direct list response
          results = decodedBody;
          count = results.length;
          debugPrint('Parsed as list response: ${results.length} products');
        }

        // Parse products
        final products = results.map((json) {
          return Product.fromJson(json as Map<String, dynamic>);
        }).toList();

        return {
          'count': count,
          'next': next,
          'previous': previous,
          'results': products,
        };
      } else {
        throw Exception(
            'Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load products: $e');
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

  /// Get list of municipalities available in the marketplace
  /// Returns municipalities from Biliran province where sellers operate
  /// Matches the municipalities used in seller registration signup page
  static Future<List<String>> getMunicipalities() async {
    try {
      // Return municipalities from Biliran as used in registration
      final municipalities = [
        'All Municipalities',
        'Almeria',
        'Biliran',
        'Cabucgayan',
        'Caibiran',
        'Culaba',
        'Kawayan',
        'Maripipi',
        'Naval',
      ];
      return municipalities;
    } catch (e) {
      throw Exception('Failed to fetch municipalities: $e');
    }
  }

  /// Get all available product categories in the system
  /// Returns all known categories regardless of whether products exist
  static Future<List<String>> getAvailableCategories() async {
    try {
      // Return all known categories in the system
      final allCategories = ['VEGETABLE', 'FRUIT', 'LIVESTOCK', 'POULTRY', 'SEEDS', 'FERTILIZERS', 'FEEDS', 'MEDICINES'];
      debugPrint('✅ All system categories: $allCategories');
      return allCategories;
    } catch (e) {
      debugPrint('❌ Error fetching categories: $e');
      // Return all known categories as fallback
      return ['VEGETABLE', 'FRUIT', 'LIVESTOCK', 'POULTRY', 'SEEDS', 'FERTILIZERS', 'FEEDS', 'MEDICINES'];
    }
  }
}
