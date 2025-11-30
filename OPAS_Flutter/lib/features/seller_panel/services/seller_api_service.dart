import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';
import '../../order_management/models/order_model.dart';
import '../models/seller_order_model.dart';

class SellerApiService {
  static String get baseUrl => ApiService.baseUrl;

  /// ==================== SELLER ORDER MANAGEMENT ====================
  
  /// Get incoming orders for seller
  static Future<List<Order>> getIncomingOrders({int page = 1}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/users/seller/orders/incoming/?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle different response formats
        List<dynamic> orders = [];
        if (data is List) {
          orders = data;
        } else if (data is Map) {
          if (data['results'] is List) {
            orders = data['results'];
          } else if (data['orders'] is List) {
            orders = data['orders'];
          }
        }
        
        return orders
            .map((o) => Order.fromJson(o as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch incoming orders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch incoming orders: $e');
    }
  }

  /// Get all orders for seller (with status filtering)
  static Future<List<Order>> getSellerOrders({
    String? status,
    int page = 1,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      Map<String, String> queryParams = {'page': page.toString()};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$baseUrl/users/seller/orders/').replace(
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
        final List<dynamic> orders = data['results'] ?? data['orders'] ?? [];
        return orders
            .map((o) => Order.fromJson(o as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch seller orders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch seller orders: $e');
    }
  }

  /// Get order detail for seller
  static Future<Order> getSellerOrderDetail(int orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/users/seller/orders/$orderId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to fetch order detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch order detail: $e');
    }
  }

  /// Accept an order
  static Future<void> acceptOrder(int orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.post(
        Uri.parse('$baseUrl/users/seller/orders/$orderId/accept/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Order accept successful: $data');
      } else {
        throw Exception('Failed to accept order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to accept order: $e');
    }
  }

  /// Reject an order
  static Future<void> rejectOrder(int orderId, {String? reason}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.post(
        Uri.parse('$baseUrl/users/seller/orders/$orderId/reject/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: reason != null ? jsonEncode({'reason': reason}) : null,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Order reject successful: $data');
      } else {
        throw Exception('Failed to reject order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to reject order: $e');
    }
  }

  /// Mark order as fulfilled
  static Future<Order> markOrderFulfilled(int orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.post(
        Uri.parse('$baseUrl/users/seller/orders/$orderId/mark_fulfilled/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to mark order fulfilled: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to mark order fulfilled: $e');
    }
  }

  /// Mark order as delivered
  static Future<Order> markOrderDelivered(int orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.post(
        Uri.parse('$baseUrl/users/seller/orders/$orderId/mark_delivered/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to mark order delivered: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to mark order delivered: $e');
    }
  }

  /// Get completed orders
  static Future<List<Order>> getCompletedOrders({int page = 1}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/users/seller/orders/completed/?page=$page'),
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
        throw Exception('Failed to fetch completed orders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch completed orders: $e');
    }
  }

  /// Get pending orders
  static Future<List<SellerOrder>> getPendingOrders({int page = 1}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/users/seller/orders/pending/?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle different response formats
        List<dynamic> orders = [];
        if (data is List) {
          // If response is directly a list
          orders = data;
        } else if (data is Map) {
          // If response is a dict with various possible keys
          if (data['results'] is List) {
            orders = data['results'];
          } else if (data['orders'] is List) {
            orders = data['orders'];
          }
        }
        
        debugPrint('📊 Pending Orders API: Received ${orders.length} orders');
        
        return orders
            .map((o) => SellerOrder.fromJson(o as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch pending orders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch pending orders: $e');
    }
  }

  /// Get cancelled orders
  static Future<List<Order>> getCancelledOrders({int page = 1}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/users/seller/orders/cancelled/?page=$page'),
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
        throw Exception('Failed to fetch cancelled orders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch cancelled orders: $e');
    }
  }
}
