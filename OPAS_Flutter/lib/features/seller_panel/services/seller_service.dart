import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: unused_import
import '../models/index.dart';
import '../../../core/services/api_service.dart';

/// Seller Service
/// Handles all seller-related API calls with comprehensive endpoint coverage
/// Total: 43 endpoints across 9 categories
class SellerService {
  // Use dynamic baseUrl from ApiService instead of hardcoded IP
  static String get baseUrl => ApiService.baseUrl;

  /// Get access token from SharedPreferences
  static Future<String> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access') ?? '';
    if (token.isEmpty) {
      throw Exception('No access token found. User may not be logged in.');
    }
    return token;
  }

  /// Refresh token if expired
  static Future<void> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh') ?? '';
      if (refreshToken.isEmpty) throw Exception('No refresh token available');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await prefs.setString('access', data['access'] ?? '');
      } else {
        throw Exception('Token refresh failed');
      }
    } catch (e) {
      throw Exception('Failed to refresh token: $e');
    }
  }

  /// Make authenticated HTTP request with automatic token refresh
  static Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final token = await _getAccessToken();
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      http.Response response;
      if (method == 'GET') {
        response = await http.get(url, headers: headers).timeout(const Duration(seconds: 30));
      } else if (method == 'POST') {
        response = await http.post(url, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 30));
      } else if (method == 'PUT') {
        response = await http.put(url, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 30));
      } else if (method == 'DELETE') {
        response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 30));
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }

      // If token expired, refresh and retry
      if (response.statusCode == 401) {
        await _refreshToken();
        final newToken = await _getAccessToken();
        headers['Authorization'] = 'Bearer $newToken';

        if (method == 'GET') {
          response = await http.get(url, headers: headers).timeout(const Duration(seconds: 30));
        } else if (method == 'POST') {
          response = await http.post(url, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 30));
        } else if (method == 'PUT') {
          response = await http.put(url, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 30));
        } else if (method == 'DELETE') {
          response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 30));
        }
      }

      return response;
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  // ============================================================================
  // PROFILE ENDPOINTS (3)
  // ============================================================================

  /// GET /api/users/seller/profile/ - Get seller profile
  static Future<SellerProfile> getSellerProfile() async {
    final response = await _makeRequest('GET', '/users/seller/profile/');
    if (response.statusCode == 200) {
      return SellerProfile.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch profile: ${response.statusCode}');
  }

  /// PUT /api/seller/profile/ - Update seller profile
  static Future<SellerProfile> updateSellerProfile(Map<String, dynamic> profileData) async {
    final response = await _makeRequest('PUT', '/users/seller/profile/', body: profileData);
    if (response.statusCode == 200) {
      return SellerProfile.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update profile: ${response.statusCode}');
  }

  /// POST /api/seller/profile/submit_documents/ - Submit seller documents
  static Future<Map<String, dynamic>> submitDocuments(Map<String, dynamic> documentData) async {
    final response = await _makeRequest('POST', '/users/seller/profile/submit_documents/', body: documentData);
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to submit documents: ${response.statusCode}');
  }

  // ============================================================================
  // PRODUCT MANAGEMENT ENDPOINTS (10)
  // ============================================================================

  /// GET /api/seller/products/ - List all products
  static Future<List<SellerProduct>> getProducts() async {
    final response = await _makeRequest('GET', '/users/seller/products/');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((p) => SellerProduct.fromJson(p)).toList();
    }
    throw Exception('Failed to fetch products: ${response.statusCode}');
  }

  /// POST /api/seller/products/ - Create new product
  static Future<SellerProduct> createProduct(Map<String, dynamic> productData) async {
    final response = await _makeRequest('POST', '/users/seller/products/', body: productData);
    if (response.statusCode == 201) {
      return SellerProduct.fromJson(jsonDecode(response.body));
    }

    // Try to include server error details in the thrown exception to aid debugging
    String body = response.body;
    String message = 'Failed to create product: ${response.statusCode}';
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map && parsed.isNotEmpty) {
        message = '$message - ${parsed.toString()}';
      } else if (parsed is List && parsed.isNotEmpty) {
        message = '$message - ${parsed.take(3).toList().toString()}';
      }
    } catch (_) {
      // keep raw body on failure to parse
      if (body.trim().isNotEmpty) message = '$message - $body';
    }

    throw Exception(message);
  }

  /// GET /api/seller/products/{id}/ - Get specific product
  static Future<SellerProduct> getProduct(int productId) async {
    final response = await _makeRequest('GET', '/users/seller/products/$productId/');
    if (response.statusCode == 200) {
      return SellerProduct.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch product: ${response.statusCode}');
  }

  /// PUT /api/seller/products/{id}/ - Update product
  static Future<SellerProduct> updateProduct(int productId, Map<String, dynamic> productData) async {
    final response = await _makeRequest('PUT', '/users/seller/products/$productId/', body: productData);
    if (response.statusCode == 200) {
      return SellerProduct.fromJson(jsonDecode(response.body));
    }

    // Expose server response when update fails to make debugging easier
    String body = response.body;
    String message = 'Failed to update product: ${response.statusCode}';
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map && parsed.isNotEmpty) {
        message = '$message - ${parsed.toString()}';
      } else if (parsed is List && parsed.isNotEmpty) {
        message = '$message - ${parsed.take(3).toList().toString()}';
      }
    } catch (_) {
      if (body.trim().isNotEmpty) message = '$message - $body';
    }

    throw Exception(message);
  }

  /// DELETE /api/seller/products/{id}/ - Delete product
  static Future<void> deleteProduct(int productId) async {
    final response = await _makeRequest('DELETE', '/users/seller/products/$productId/');
    if (response.statusCode != 204) {
      throw Exception('Failed to delete product: ${response.statusCode}');
    }
  }

  /// GET /api/seller/products/active/ - Get active products
  static Future<List<SellerProduct>> getActiveProducts() async {
    final response = await _makeRequest('GET', '/users/seller/products/active/');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((p) => SellerProduct.fromJson(p)).toList();
    }
    throw Exception('Failed to fetch active products: ${response.statusCode}');
  }

  /// GET /api/seller/products/expired/ - Get expired products
  static Future<List<SellerProduct>> getExpiredProducts() async {
    final response = await _makeRequest('GET', '/users/seller/products/expired/');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((p) => SellerProduct.fromJson(p)).toList();
    }
    throw Exception('Failed to fetch expired products: ${response.statusCode}');
  }

  /// POST /api/seller/products/check_ceiling_price/ - Check ceiling price
  static Future<Map<String, dynamic>> checkCeilingPrice(Map<String, dynamic> priceData) async {
    final response = await _makeRequest('POST', '/users/seller/products/check_ceiling_price/', body: priceData);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to check ceiling price: ${response.statusCode}');
  }

  /// GET /api/seller/products/get_categories/ - Get product categories
  static Future<List<Map<String, dynamic>>> getProductCategories() async {
    final response = await _makeRequest('GET', '/users/seller/products/get_categories/');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((c) => c as Map<String, dynamic>).toList();
    }
    throw Exception('Failed to fetch product categories: ${response.statusCode}');
  }

  /// POST /api/seller/products/check_stock_availability/ - Check stock availability
  /// Phase 3.2: Stock Level Management
  /// Validates if sufficient stock exists before accepting orders
  static Future<Map<String, dynamic>> checkStockAvailability({
    required int productId,
    required int quantityRequired,
  }) async {
    final response = await _makeRequest(
      'POST',
      '/users/seller/products/check_stock_availability/',
      body: {
        'product_id': productId,
        'quantity_required': quantityRequired,
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to check stock availability: ${response.statusCode}');
  }

  // ============================================================================
  // SELL TO OPAS ENDPOINTS (4)
  // ============================================================================

  /// POST /api/seller/sell-to-opas/submit/ - Submit bulk offer to OPAS
  static Future<Map<String, dynamic>> submitToOPAS(Map<String, dynamic> offerData) async {
    final response = await _makeRequest('POST', '/users/seller/sell-to-opas/submit/', body: offerData);
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to submit to OPAS: ${response.statusCode}');
  }

  /// GET /api/seller/sell-to-opas/pending/ - Get pending OPAS submissions
  static Future<List<Map<String, dynamic>>> getPendingOPASSubmissions() async {
    final response = await _makeRequest('GET', '/users/seller/sell-to-opas/pending/');
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch pending submissions: ${response.statusCode}');
  }

  /// GET /api/seller/sell-to-opas/history/ - Get OPAS transaction history
  static Future<List<Map<String, dynamic>>> getOPASHistory() async {
    final response = await _makeRequest('GET', '/users/seller/sell-to-opas/history/');
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch history: ${response.statusCode}');
  }

  /// GET /api/seller/sell-to-opas/{id}/status/ - Get specific submission status
  static Future<Map<String, dynamic>> getOPASSubmissionStatus(int submissionId) async {
    final response = await _makeRequest('GET', '/users/seller/sell-to-opas/$submissionId/status/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch submission status: ${response.statusCode}');
  }

  // ============================================================================
  // ORDER MANAGEMENT ENDPOINTS (8)
  // ============================================================================

  /// GET /api/seller/orders/incoming/ - Get incoming orders
  static Future<List<SellerOrder>> getIncomingOrders() async {
    final response = await _makeRequest('GET', '/users/seller/orders/incoming/');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((o) => SellerOrder.fromJson(o)).toList();
    }
    throw Exception('Failed to fetch incoming orders: ${response.statusCode}');
  }

  /// POST /api/seller/orders/{id}/accept/ - Accept order
  static Future<SellerOrder> acceptOrder(int orderId) async {
    final response = await _makeRequest('POST', '/users/seller/orders/$orderId/accept/');
    if (response.statusCode == 200) {
      return SellerOrder.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to accept order: ${response.statusCode}');
  }

  /// POST /api/seller/orders/{id}/reject/ - Reject order
  static Future<SellerOrder> rejectOrder(int orderId, {String? reason}) async {
    final Map<String, dynamic> body = reason != null ? {'reason': reason} : {};
    final response = await _makeRequest('POST', '/users/seller/orders/$orderId/reject/', body: body.isNotEmpty ? body : null);
    if (response.statusCode == 200) {
      return SellerOrder.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to reject order: ${response.statusCode}');
  }

  /// POST /api/seller/orders/{id}/mark_fulfilled/ - Mark order as fulfilled
  static Future<SellerOrder> markOrderFulfilled(int orderId) async {
    final response = await _makeRequest('POST', '/users/seller/orders/$orderId/mark_fulfilled/');
    if (response.statusCode == 200) {
      return SellerOrder.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to mark fulfilled: ${response.statusCode}');
  }

  /// POST /api/seller/orders/{id}/mark_delivered/ - Mark order as delivered
  static Future<SellerOrder> markOrderDelivered(int orderId) async {
    final response = await _makeRequest('POST', '/users/seller/orders/$orderId/mark_delivered/');
    if (response.statusCode == 200) {
      return SellerOrder.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to mark delivered: ${response.statusCode}');
  }

  /// GET /api/seller/orders/completed/ - Get completed orders
  static Future<List<SellerOrder>> getCompletedOrders() async {
    final response = await _makeRequest('GET', '/users/seller/orders/completed/');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((o) => SellerOrder.fromJson(o)).toList();
    }
    throw Exception('Failed to fetch completed orders: ${response.statusCode}');
  }

  /// GET /api/seller/orders/pending/ - Get pending orders
  static Future<List<SellerOrder>> getPendingOrders() async {
    final response = await _makeRequest('GET', '/users/seller/orders/pending/');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((o) => SellerOrder.fromJson(o)).toList();
    }
    throw Exception('Failed to fetch pending orders: ${response.statusCode}');
  }

  /// GET /api/seller/orders/cancelled/ - Get cancelled orders
  static Future<List<SellerOrder>> getCancelledOrders() async {
    final response = await _makeRequest('GET', '/users/seller/orders/cancelled/');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((o) => SellerOrder.fromJson(o)).toList();
    }
    throw Exception('Failed to fetch cancelled orders: ${response.statusCode}');
  }

  /// GET /api/seller/orders/ - Get all orders (wrapper method)
  static Future<List<SellerOrder>> getOrders() async {
    final response = await _makeRequest('GET', '/users/seller/orders/');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((o) => SellerOrder.fromJson(o)).toList();
    }
    throw Exception('Failed to fetch orders: ${response.statusCode}');
  }

  /// POST /api/seller/orders/{id}/fulfill/ - Mark order as fulfilled (wrapper)
  static Future<SellerOrder> fulfillOrder(int orderId) async {
    return markOrderFulfilled(orderId);
  }

  /// POST /api/seller/orders/{id}/deliver/ - Mark order as delivered (wrapper)
  static Future<SellerOrder> deliverOrder(int orderId) async {
    return markOrderDelivered(orderId);
  }

  // ============================================================================
  // INVENTORY TRACKING ENDPOINTS (4)
  // ============================================================================

  /// GET /api/seller/inventory/overview/ - Get inventory overview
  static Future<Map<String, dynamic>> getInventoryOverview() async {
    final response = await _makeRequest('GET', '/users/seller/inventory/overview/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch inventory overview: ${response.statusCode}');
  }

  /// GET /api/seller/inventory/by_product/ - Get inventory by product
  static Future<List<Map<String, dynamic>>> getInventoryByProduct() async {
    final response = await _makeRequest('GET', '/users/seller/inventory/by_product/');
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch inventory by product: ${response.statusCode}');
  }

  /// GET /api/seller/inventory/low_stock/ - Get low stock alerts
  /// Phase 3.2: Stock Level Management
  /// Returns map with low_stock_products list and summary counts
  static Future<Map<String, dynamic>> getLowStockAlerts() async {
    final response = await _makeRequest('GET', '/users/seller/inventory/low_stock/');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Handle both list and map responses
      if (data is Map<String, dynamic>) {
        return data;
      }
      
      // Legacy: if response is a list, wrap it
      if (data is List) {
        return {
          'low_stock_products': data,
          'total_low_stock_count': data.length,
          'critical_count': data.where((p) => (p['current_stock'] ?? 0) == 0).length,
          'warning_count': data.where((p) => (p['current_stock'] ?? 0) > 0).length,
        };
      }
      
      return data as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch low stock alerts: ${response.statusCode}');
  }

  /// GET /api/seller/inventory/movement/ - Get inventory movement history
  static Future<List<Map<String, dynamic>>> getInventoryMovement() async {
    final response = await _makeRequest('GET', '/users/seller/inventory/movement/');
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch inventory movement: ${response.statusCode}');
  }

  /// PUT /api/seller/products/{id}/ - Update product stock and minimum stock
  static Future<Map<String, dynamic>> updateProductStock(
    int productId,
    int newStock,
    int newMinimumStock,
  ) async {
    final response = await _makeRequest(
      'PUT',
      '/users/seller/products/$productId/',
      body: {
        'stock_level': newStock,
        'minimum_stock': newMinimumStock,
      },
    );
    
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to update product stock: ${response.statusCode}');
  }

  // ============================================================================
  // DEMAND FORECASTING ENDPOINTS (4)
  // ============================================================================

  /// GET /api/seller/forecast/next_month/ - Get next month forecast
  static Future<List<SellerForecast>> getNextMonthForecast() async {
    final response = await _makeRequest('GET', '/users/seller/forecast/next_month/');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((f) => SellerForecast.fromJson(f)).toList();
    }
    throw Exception('Failed to fetch forecast: ${response.statusCode}');
  }

  /// GET /api/seller/forecast/product/{product}/ - Get forecast for specific product
  static Future<SellerForecast> getProductForecast(int productId) async {
    final response = await _makeRequest('GET', '/users/seller/forecast/product/$productId/');
    if (response.statusCode == 200) {
      return SellerForecast.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch product forecast: ${response.statusCode}');
  }

  /// GET /api/seller/forecast/historical/ - Get historical forecast data
  static Future<List<Map<String, dynamic>>> getHistoricalForecast() async {
    final response = await _makeRequest('GET', '/users/seller/forecast/historical/');
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch historical forecast: ${response.statusCode}');
  }

  /// GET /api/seller/forecast/insights/ - Get forecast insights
  static Future<Map<String, dynamic>> getForecastInsights() async {
    final response = await _makeRequest('GET', '/users/seller/forecast/insights/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch forecast insights: ${response.statusCode}');
  }

  /// POST /api/seller/forecast/generate/ - Generate forecast for specific product (NEW)
  static Future<SellerForecast> generateForecast(int productId) async {
    final response = await _makeRequest(
      'POST',
      '/users/seller/forecast/generate/',
      body: {'product_id': productId},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return SellerForecast.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to generate forecast: ${response.statusCode}');
  }

  /// GET /api/seller/forecast/trend_data/ - Get trend chart data (NEW)
  static Future<Map<String, dynamic>> getTrendData(int productId) async {
    final response = await _makeRequest('GET', '/users/seller/forecast/trend_data/?product_id=$productId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch trend data: ${response.statusCode}');
  }

  // ============================================================================
  // PAYOUT TRACKING ENDPOINTS (4)
  // ============================================================================

  /// GET /api/seller/payouts/ - Get all payouts
  static Future<List<SellerPayout>> getPayouts() async {
    final response = await _makeRequest('GET', '/users/seller/payouts/');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((p) => SellerPayout.fromJson(p)).toList();
    }
    throw Exception('Failed to fetch payouts: ${response.statusCode}');
  }

  /// GET /api/seller/payouts/pending/ - Get pending payouts
  static Future<List<SellerPayout>> getPendingPayouts() async {
    final response = await _makeRequest('GET', '/users/seller/payouts/pending/');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((p) => SellerPayout.fromJson(p)).toList();
    }
    throw Exception('Failed to fetch pending payouts: ${response.statusCode}');
  }

  /// GET /api/seller/payouts/completed/ - Get completed payouts
  static Future<List<SellerPayout>> getCompletedPayouts() async {
    final response = await _makeRequest('GET', '/users/seller/payouts/completed/');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((p) => SellerPayout.fromJson(p)).toList();
    }
    throw Exception('Failed to fetch completed payouts: ${response.statusCode}');
  }

  /// GET /api/seller/payouts/earnings/ - Get earnings summary
  static Future<Map<String, dynamic>> getEarningsSummary() async {
    final response = await _makeRequest('GET', '/users/seller/payouts/earnings/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch earnings summary: ${response.statusCode}');
  }

  // ============================================================================
  // ANALYTICS ENDPOINTS (6)
  // ============================================================================

  /// GET /api/seller/analytics/dashboard/ - Get dashboard analytics
  static Future<Map<String, dynamic>> getDashboardAnalytics() async {
    final response = await _makeRequest('GET', '/users/seller/analytics/dashboard/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch dashboard analytics: ${response.statusCode}');
  }

  /// GET /api/seller/analytics/daily/ - Get daily analytics
  static Future<Map<String, dynamic>> getDailyAnalytics() async {
    final response = await _makeRequest('GET', '/users/seller/analytics/daily/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch daily analytics: ${response.statusCode}');
  }

  /// GET /api/seller/analytics/weekly/ - Get weekly analytics
  static Future<Map<String, dynamic>> getWeeklyAnalytics() async {
    final response = await _makeRequest('GET', '/users/seller/analytics/weekly/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch weekly analytics: ${response.statusCode}');
  }

  /// GET /api/seller/analytics/monthly/ - Get monthly analytics
  static Future<Map<String, dynamic>> getMonthlyAnalytics() async {
    final response = await _makeRequest('GET', '/users/seller/analytics/monthly/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch monthly analytics: ${response.statusCode}');
  }

  /// GET /api/seller/analytics/top_products/ - Get top performing products
  static Future<List<Map<String, dynamic>>> getTopProducts() async {
    final response = await _makeRequest('GET', '/users/seller/analytics/top_products/');
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch top products: ${response.statusCode}');
  }

  /// GET /api/seller/analytics/top_products/ - Alias for getTopProducts
  static Future<List<Map<String, dynamic>>> getAnalyticsTopProducts() async {
    return getTopProducts();
  }

  /// GET /api/seller/analytics/forecast_vs_actual/ - Get forecast vs actual comparison
  static Future<Map<String, dynamic>> getForecastVsActual() async {
    final response = await _makeRequest('GET', '/users/seller/analytics/forecast_vs_actual/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch forecast vs actual: ${response.statusCode}');
  }

  // ============================================================================
  // SELL TO OPAS ENDPOINTS (Phase 2.5)
  // ============================================================================

  /// GET /api/seller/sell-to-opas/ - List OPAS requests
  static Future<List<Map<String, dynamic>>> getSellToOPASRequests() async {
    final response = await _makeRequest('GET', '/users/seller/sell-to-opas/');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data is List ? data : []);
    }
    throw Exception('Failed to fetch OPAS requests: ${response.statusCode}');
  }

  /// POST /api/seller/sell-to-opas/create/ - Submit OPAS offer
  static Future<Map<String, dynamic>?> submitOPASoffer({
    required String productType,
    required int quantity,
    required String qualityGrade,
    required int estimatedPrice,
  }) async {
    final body = {
      'product_type': productType,
      'quantity': quantity,
      'quality_grade': qualityGrade,
      'offered_price': estimatedPrice,
    };

    final response = await _makeRequest(
      'POST',
      '/users/seller/sell-to-opas/create/',
      body: body,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to submit OPAS offer: ${response.statusCode}');
  }

  /// GET /api/seller/sell-to-opas/{id}/ - Get OPAS request details
  static Future<Map<String, dynamic>> getOPASRequestDetails(int id) async {
    final response =
        await _makeRequest('GET', '/users/seller/sell-to-opas/$id/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch OPAS request details: ${response.statusCode}');
  }

  /// POST /api/seller/sell-to-opas/{id}/cancel/ - Cancel OPAS offer
  static Future<Map<String, dynamic>> cancelOPASOffer(int id) async {
    final response =
        await _makeRequest('POST', '/users/seller/sell-to-opas/$id/cancel/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to cancel OPAS offer: ${response.statusCode}');
  }

  // ============================================================================
  // IMAGE UPLOAD ENDPOINTS (3)
  // ============================================================================

  /// Make multipart HTTP request with file upload
  static Future<http.StreamedResponse> _makeMultipartRequest(
    String method,
    String endpoint, {
    required String filePath,
    required String fieldName,
    Map<String, String>? additionalFields,
  }) async {
    try {
      final token = await _getAccessToken();
      final url = Uri.parse('$baseUrl$endpoint');
      
      final request = http.MultipartRequest(method, url)
        ..headers['Authorization'] = 'Bearer $token';
      
      // Determine MIME type based on file extension
      String mimeType = 'image/jpeg'; // default
      if (filePath.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (filePath.toLowerCase().endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (filePath.toLowerCase().endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (filePath.toLowerCase().endsWith('.jpg') || filePath.toLowerCase().endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      }
      
      // Add file with proper MIME type
      final file = await http.MultipartFile.fromPath(
        fieldName, 
        filePath,
        contentType: http.MediaType.parse(mimeType),
      );
      request.files.add(file);
      
      // Add additional fields if provided
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }
      
      return await request.send().timeout(const Duration(seconds: 30));
    } catch (e) {
      throw Exception('Multipart request failed: $e');
    }
  }

  /// POST /api/users/seller/products/{productId}/upload_image/ - Upload product image
  static Future<Map<String, dynamic>> uploadProductImage({
    required int productId,
    required String imagePath,
    required bool isPrimary,
    String? altText,
  }) async {
    try {
      final additionalFields = {
        'is_primary': isPrimary.toString(),
        if (altText != null && altText.isNotEmpty) 'alt_text': altText,
      };

      final streamedResponse = await _makeMultipartRequest(
        'POST',
        '/users/seller/products/$productId/upload_image/',
        filePath: imagePath,
        fieldName: 'image',
        additionalFields: additionalFields,
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Invalid image file');
      } else if (response.statusCode == 404) {
        throw Exception('Product not found');
      }
      throw Exception('Failed to upload image: ${response.statusCode} - ${response.body}');
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  /// GET /api/users/seller/products/{productId}/images/ - Get product images
  static Future<List<Map<String, dynamic>>> getProductImages(int productId) async {
    final response = await _makeRequest('GET', '/users/seller/products/$productId/images/');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    }
    throw Exception('Failed to fetch product images: ${response.statusCode}');
  }

  /// DELETE /api/users/seller/products/{productId}/delete_image/ - Delete product image
  static Future<void> deleteProductImage({
    required int productId,
    required int imageId,
  }) async {
    final response = await _makeRequest(
      'DELETE',
      '/users/seller/products/$productId/delete_image/?image_id=$imageId',
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete image: ${response.statusCode}');
    }
  }

  // ============================================================================
  // NOTIFICATION ENDPOINTS (2)
  // ============================================================================

  /// GET /api/users/seller/notifications/ - Get seller notifications
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await _makeRequest('GET', '/users/seller/notifications/');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    }
    throw Exception('Failed to fetch notifications: ${response.statusCode}');
  }

  /// POST /api/users/seller/notifications/{id}/mark_read/ - Mark notification as read
  static Future<Map<String, dynamic>> markNotificationAsRead(int notificationId) async {
    final response =
        await _makeRequest('POST', '/users/seller/notifications/$notificationId/mark_read/');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to mark notification as read: ${response.statusCode}');
  }

  /// GET /api/users/seller/announcements/ - Get admin announcements
  static Future<List<Map<String, dynamic>>> getAnnouncements() async {
    final response = await _makeRequest('GET', '/users/seller/announcements/');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    }
    throw Exception('Failed to fetch announcements: ${response.statusCode}');
  }

  /// POST /api/users/seller/announcements/{id}/mark_read/ - Mark announcement as read
  static Future<Map<String, dynamic>> markAnnouncementAsRead(int announcementId) async {
    final response =
        await _makeRequest('POST', '/users/seller/announcements/$announcementId/mark_read/');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to mark announcement as read: ${response.statusCode}');
  }
}
