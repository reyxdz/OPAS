import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/seller_panel/screens/seller_layout.dart';
import '../../features/seller_panel/screens/seller_profile_screen.dart';
import '../../features/seller_panel/screens/product_listing_screen.dart';
import '../../features/seller_panel/screens/add_product_screen.dart';
import '../../features/seller_panel/screens/orders_listing_screen.dart';
import '../../features/seller_panel/screens/inventory_listing_screen.dart';
import '../../features/seller_panel/screens/sales_analytics_screen.dart';
import '../../features/seller_panel/screens/revenue_breakdown_screen.dart';
import '../../features/seller_panel/screens/opas_requests_screen.dart';
import '../../features/seller_panel/screens/submit_opas_offer_screen.dart';
import '../../features/seller_panel/screens/opas_history_screen.dart';
import '../../features/seller_panel/screens/payouts_listing_screen.dart';
import '../../features/seller_panel/screens/wallet_screen.dart';
import '../../features/seller_panel/screens/request_payout_screen.dart';
import '../../features/seller_panel/screens/notifications_screen.dart';

/// SellerRouter provides role-based navigation and routing utilities
/// for the OPAS Seller Panel
class SellerRouter {
  /// Seller role constants
  static const String roleSeller = 'SELLER';
  static const String roleSellerApproved = 'SELLER_APPROVED';
  static const String roleSellerPending = 'SELLER_PENDING';
  static const String roleSellerSuspended = 'SELLER_SUSPENDED';
  static const String roleOPASAdmin = 'OPAS_ADMIN';
  static const String roleBuyer = 'BUYER';

  /// Check if user is seller (any seller status)
  static Future<bool> isUserSeller() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role');
      return role == roleSeller || 
             role == roleSellerApproved || 
             role == roleSellerPending || 
             role == roleSellerSuspended;
    } catch (e) {
      return false;
    }
  }

  /// Check if seller is approved
  static Future<bool> isSellerApproved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sellerStatus = prefs.getString('seller_status');
      return sellerStatus == 'APPROVED';
    } catch (e) {
      return false;
    }
  }

  /// Check if seller is pending approval
  static Future<bool> isSellerPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sellerStatus = prefs.getString('seller_status');
      return sellerStatus == 'PENDING';
    } catch (e) {
      return false;
    }
  }

  /// Check if seller is suspended
  static Future<bool> isSellerSuspended() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sellerStatus = prefs.getString('seller_status');
      return sellerStatus == 'SUSPENDED';
    } catch (e) {
      return false;
    }
  }

  /// Get current user role
  static Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('role');
    } catch (e) {
      return null;
    }
  }

  /// Get seller status (PENDING, APPROVED, REJECTED, SUSPENDED)
  static Future<String?> getSellerStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('seller_status');
    } catch (e) {
      return null;
    }
  }

  // ==================== ROUTE CONSTANTS ====================

  /// Route constants
  static const String seller = '/seller';
  static const String sellerProfile = '/seller/profile';
  static const String sellerProducts = '/seller/products';
  static const String sellerProductAdd = '/seller/products/add';
  static const String sellerProductEdit = '/seller/products/edit';
  static const String sellerOrders = '/seller/orders';
  static const String sellerInventory = '/seller/inventory';
  static const String sellerInventoryUpdate = '/seller/inventory/update';
  static const String sellerAnalytics = '/seller/analytics';
  static const String sellerRevenue = '/seller/revenue';
  static const String sellerOPAS = '/seller/opas';
  static const String sellerOPASSubmit = '/seller/opas/submit';
  static const String sellerOPASHistory = '/seller/opas/history';
  static const String sellerWallet = '/seller/wallet';
  static const String sellerPayouts = '/seller/payouts';
  static const String sellerRequestPayout = '/seller/request-payout';
  static const String sellerNotifications = '/seller/notifications';
  static const String login = '/login';
  static const String home = '/home';

  /// Get stored seller profile data
  static Future<Map<String, dynamic>> getSellerProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'firstName': prefs.getString('first_name') ?? '',
        'lastName': prefs.getString('last_name') ?? '',
        'email': prefs.getString('email'),
        'phoneNumber': prefs.getString('phone_number') ?? '',
        'role': prefs.getString('role') ?? roleBuyer,
        'sellerStatus': prefs.getString('seller_status') ?? 'PENDING',
        'farmName': prefs.getString('farm_name'),
        'storeName': prefs.getString('store_name'),
        'address': prefs.getString('address'),
      };
    } catch (e) {
      return {};
    }
  }

  /// Update seller profile locally (SharedPreferences)
  static Future<bool> updateSellerProfile(Map<String, String> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in data.entries) {
        await prefs.setString(entry.key, entry.value);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== NAVIGATION METHODS ====================

  /// Navigate to seller dashboard with replacement (clears history)
  static void navigateToSellerDashboard(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(SellerRouter.seller);
  }

  /// Navigate to seller profile
  static void navigateToSellerProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SellerProfileScreen()),
    );
  }

  /// Navigate to seller home (default seller view)
  static void navigateToSellerHome(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(SellerRouter.seller);
  }

  /// Navigate to login screen and clear all history
  static void navigateToLogin(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(login);
  }

  /// Navigate to buyer home screen (switch role)
  static void navigateToBuyerHome(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(home);
  }

  // ==================== LOGOUT UTILITIES ====================

  /// Logout seller (clear SharedPreferences)
  static Future<bool> logoutSeller() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Logout and navigate to login screen
  static Future<void> logoutAndNavigateToLogin(BuildContext context) async {
    await logoutSeller();
    if (context.mounted) {
      navigateToLogin(context);
    }
  }

  /// Get all seller routes
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      seller: (context) => const SellerLayout(),
      sellerProfile: (context) => const SellerProfileScreen(),
      sellerProducts: (context) => const ProductListingScreen(),
      sellerProductAdd: (context) => const AddProductScreen(),
      sellerOrders: (context) => const OrdersListingScreen(),
      sellerInventory: (context) => const InventoryListingScreen(),
      sellerAnalytics: (context) => const SalesAnalyticsScreen(),
      sellerRevenue: (context) => const RevenueBreakdownScreen(),
      sellerOPAS: (context) => const OPASRequestsScreen(),
      sellerOPASSubmit: (context) => const SubmitOPASOfferScreen(),
      sellerOPASHistory: (context) => const OPASHistoryScreen(),
      sellerWallet: (context) => const WalletScreen(),
      sellerPayouts: (context) => const PayoutsListingScreen(),
      sellerRequestPayout: (context) => const RequestPayoutScreen(),
      sellerNotifications: (context) => const NotificationsScreen(),
    };
  }

  /// Check if a route is a seller route
  static bool isSellerRoute(String routeName) {
    return routeName.startsWith('/seller');
  }

  /// Get route description for logging/debugging
  static String getRouteDescription(String routeName) {
    switch (routeName) {
      case seller:
        return 'Seller Dashboard';
      case sellerProfile:
        return 'Seller Profile';
      case sellerProducts:
        return 'Product Listing';
      case sellerProductAdd:
        return 'Add Product';
      case sellerProductEdit:
        return 'Edit Product';
      case sellerOrders:
        return 'Orders';
      case sellerInventory:
        return 'Inventory Management';
      case sellerInventoryUpdate:
        return 'Update Stock';
      case sellerAnalytics:
        return 'Sales & Analytics';
      case sellerRevenue:
        return 'Revenue Breakdown';
      case sellerOPAS:
        return 'OPAS Requests';
      case sellerOPASSubmit:
        return 'Submit OPAS Offer';
      case sellerOPASHistory:
        return 'OPAS History';
      case sellerNotifications:
        return 'Notifications';
      case login:
        return 'Login';
      case home:
        return 'Buyer Home';
      default:
        return 'Unknown Route';
    }
  }
}

/// Route definitions and configuration for seller routes
abstract class SellerRoutes {
  // ==================== ROUTE PATHS ====================
  static const String seller = '/seller';
  static const String sellerProfile = '/seller/profile';
  static const String sellerDashboard = '/seller/dashboard';
  static const String sellerProducts = '/seller/products';
  static const String sellerProductAdd = '/seller/products/add';
  static const String sellerProductEdit = '/seller/products/edit';
  static const String sellerOrders = '/seller/orders';
  static const String sellerInventory = '/seller/inventory';
  static const String sellerInventoryUpdate = '/seller/inventory/update';
  static const String sellerAnalytics = '/seller/analytics';
  static const String sellerRevenue = '/seller/revenue';

  // ==================== PUBLIC ROUTES ====================
  static const String login = '/login';
  static const String home = '/home';

  /// Check if a route is a seller route
  static bool isSellerRoute(String routeName) {
    return routeName.startsWith('/seller');
  }

  /// Get route description for logging/debugging
  static String getRouteDescription(String routeName) {
    switch (routeName) {
      case seller:
        return 'Seller Dashboard';
      case sellerProfile:
        return 'Seller Profile';
      case sellerDashboard:
        return 'Seller Home';
      case sellerProducts:
        return 'Product Listing';
      case sellerProductAdd:
        return 'Add Product';
      case sellerProductEdit:
        return 'Edit Product';
      case sellerOrders:
        return 'Orders';
      case sellerInventory:
        return 'Inventory Management';
      case sellerInventoryUpdate:
        return 'Update Stock';
      case sellerAnalytics:
        return 'Sales & Analytics';
      case sellerRevenue:
        return 'Revenue Breakdown';
      case login:
        return 'Login';
      case home:
        return 'Buyer Home';
      default:
        return 'Unknown Route';
    }
  }
}
