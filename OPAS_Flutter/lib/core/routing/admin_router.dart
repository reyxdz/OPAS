import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// SCREEN IMPORTS - Phase 3.2 Complete Admin Panel Routes
// ============================================================================

// Core layouts
import '../../features/admin_panel/screens/admin_layout.dart';
import '../../features/admin_panel/screens/admin_profile_screen.dart';

// Seller Management Screens
import '../../features/admin_panel/screens/admin_sellers_screen.dart';
import '../../features/admin_panel/screens/seller_details_admin_screen.dart';

// Price Management Screens
import '../../features/admin_panel/screens/price_ceilings_screen.dart';
import '../../features/admin_panel/screens/price_compliance_screen.dart';
import '../../features/admin_panel/screens/price_advisory_screen.dart';

// OPAS Purchasing Screens
import '../../features/admin_panel/screens/opas_submissions_screen.dart';
import '../../features/admin_panel/screens/opas_inventory_screen.dart';
import '../../features/admin_panel/screens/opas_purchase_history_screen.dart';

// Marketplace Oversight Screens
import '../../features/admin_panel/screens/marketplace_activity_screen.dart';
import '../../features/admin_panel/screens/marketplace_alerts_screen.dart';

// Note: Analytics, Reports, Announcements, Audit Log, and Settings screens
// will be created in subsequent phases or use placeholder screens

/// ============================================================================
/// AdminRouter - Phase 3.2 Implementation
/// 
/// Comprehensive role-based navigation and routing utilities for OPAS Admin Panel
/// 
/// Features:
/// - 17 admin panel routes with clean separation of concerns
/// - Role-based access control (OPAS_ADMIN, SYSTEM_ADMIN)
/// - Profile management and logout utilities
/// - Type-safe navigation methods for all admin screens
/// - Route path constants for programmatic navigation
/// - Reusable helper methods for common operations
/// 
/// Architecture Pattern:
/// - Static methods for utility functions (no instantiation needed)
/// - Clear separation between route definitions and navigation logic
/// - AdminRoutes class for route constants and metadata
/// - AdminRouter class for navigation and utility methods
/// ============================================================================

class AdminRouter {
  // ==================== ROLE CONSTANTS ====================
  static const String roleOPASAdmin = 'OPAS_ADMIN';
  static const String roleSystemAdmin = 'SYSTEM_ADMIN';
  static const String roleBuyer = 'BUYER';
  static const String roleSeller = 'SELLER';

  // ==================== AUTHENTICATION CHECKS ====================

  /// Check if user is admin (OPAS_ADMIN or SYSTEM_ADMIN)
  static Future<bool> isUserAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role');
      return role == roleOPASAdmin || role == roleSystemAdmin;
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to check admin role: $e');
      }
      return false;
    }
  }

  /// Check if user is system admin (super admin with all permissions)
  static Future<bool> isSystemAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role');
      return role == roleSystemAdmin;
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to check system admin role: $e');
      }
      return false;
    }
  }

  /// Get current user role
  static Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('role');
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to get user role: $e');
      }
      return null;
    }
  }

  // ==================== PROFILE MANAGEMENT ====================

  /// Get stored admin profile data
  static Future<Map<String, dynamic>> getAdminProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'firstName': prefs.getString('first_name') ?? '',
        'lastName': prefs.getString('last_name') ?? '',
        'email': prefs.getString('email') ?? '',
        'phoneNumber': prefs.getString('phone_number') ?? '',
        'role': prefs.getString('role') ?? roleBuyer,
        'address': prefs.getString('address') ?? '',
      };
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to get admin profile: $e');
      }
      return {};
    }
  }

  /// Update admin profile in local storage
  static Future<bool> updateAdminProfile(Map<String, String> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in data.entries) {
        await prefs.setString(entry.key, entry.value);
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to update admin profile: $e');
      }
      return false;
    }
  }

  // ==================== LOGOUT UTILITIES ====================

  /// Clear all stored user data (complete logout)
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (kDebugMode) {
        print('DEBUG: User logged out and all data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: Failed to logout: $e');
      }
      rethrow;
    }
  }

  /// Logout and navigate to login screen
  static Future<void> logoutAndNavigateToLogin(BuildContext context) async {
    await logout();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed(AdminRoutes.login);
    }
  }

  // ==================== NAVIGATION - MAIN SCREENS ====================

  /// Navigate to admin dashboard (main entry point)
  static void navigateToAdminDashboard(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AdminRoutes.adminDashboard);
  }

  /// Navigate to admin profile
  static void navigateToAdminProfile(BuildContext context) {
    Navigator.of(context).pushNamed(AdminRoutes.adminProfile);
  }

  // ==================== NAVIGATION - SELLER MANAGEMENT ====================

  /// Navigate to seller list screen
  static void navigateToAdminSellers(BuildContext context) {
    Navigator.of(context).pushNamed(AdminRoutes.adminSellers);
  }

  /// Navigate to seller details screen with seller data
  static void navigateToSellerDetails(BuildContext context, Map<String, dynamic> seller) {
    Navigator.of(context).pushNamed(
      AdminRoutes.adminSellerDetails,
      arguments: {'seller': seller},
    );
  }

  /// Navigate to pending seller approvals
  static void navigateToPendingApprovals(BuildContext context) {
    Navigator.of(context).pushNamed(AdminRoutes.adminSellerDetails);
  }

  // ==================== NAVIGATION - PRICE MANAGEMENT ====================

  /// Navigate to price ceilings screen
  static void navigateToPriceCeilings(BuildContext context) {
    Navigator.of(context).pushNamed(AdminRoutes.adminPrices);
  }

  /// Navigate to price compliance screen
  static void navigateToPriceCompliance(BuildContext context) {
    Navigator.of(context).pushNamed(AdminRoutes.adminCompliance);
  }

  /// Navigate to price advisories screen
  static void navigateToPriceAdvisories(BuildContext context) {
    Navigator.of(context).pushNamed(AdminRoutes.adminPrices);
  }

  // ==================== NAVIGATION - OPAS PURCHASING ====================

  /// Navigate to OPAS submissions list
  static void navigateToOPASSubmissions(BuildContext context) {
    Navigator.of(context).pushNamed(AdminRoutes.adminOPAS);
  }

  /// Navigate to OPAS inventory management
  static void navigateToOPASInventory(BuildContext context) {
    Navigator.of(context).pushNamed(AdminRoutes.adminOPASInventory);
  }

  /// Navigate to OPAS purchase history
  static void navigateToOPASHistory(BuildContext context) {
    Navigator.of(context).pushNamed(AdminRoutes.adminOPASHistory);
  }

  // ==================== NAVIGATION - MARKETPLACE OVERSIGHT ====================

  /// Navigate to marketplace activity screen
  static void navigateToMarketplaceActivity(BuildContext context) {
    Navigator.of(context).pushNamed(AdminRoutes.adminMarketplace);
  }

  /// Navigate to marketplace alerts screen
  static void navigateToMarketplaceAlerts(BuildContext context) {
    Navigator.of(context).pushNamed(AdminRoutes.adminAlerts);
  }

  // ==================== NAVIGATION - ANALYTICS ====================

  /// Navigate to analytics dashboard
  static void navigateToAnalytics(BuildContext context) {
    Navigator.of(context).pushNamed(AdminRoutes.adminAnalytics);
  }

  /// Navigate to price trends screen
  static void navigateToPriceTrends(BuildContext context) {
    Navigator.of(context).pushNamed(AdminRoutes.adminPriceTrends);
  }

  /// Navigate to demand forecast screen
  static void navigateToDemandForecast(BuildContext context) {
    Navigator.of(context).pushNamed(AdminRoutes.adminForecasts);
  }

  // ==================== NAVIGATION - REPORTS & ADMIN ====================

  /// Navigate to reports screen
  static void navigateToReports(BuildContext context) {
    Navigator.of(context).pushNamed(AdminRoutes.adminReports);
  }

  /// Navigate to announcements screen
  static void navigateToAnnouncements(BuildContext context) {
    Navigator.of(context).pushNamed(AdminRoutes.adminAnnouncements);
  }

  /// Navigate to audit log screen
  static void navigateToAuditLog(BuildContext context) {
    Navigator.of(context).pushNamed(AdminRoutes.adminAuditLog);
  }

  /// Navigate to admin settings screen
  static void navigateToSettings(BuildContext context) {
    Navigator.of(context).pushNamed(AdminRoutes.adminSettings);
  }

  // ==================== NAVIGATION - PUBLIC ROUTES ====================

  /// Navigate to login screen
  static void navigateToLogin(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AdminRoutes.login);
  }

  /// Navigate to buyer home screen
  static void navigateToBuyerHome(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AdminRoutes.home);
  }
}

/// ============================================================================
/// AdminRoutes - Route Constants and Metadata
/// 
/// Centralized definition of all admin panel routes with standardized naming:
/// - Format: /admin/{feature}/{screen}
/// - Support for route parameters via arguments
/// - Route descriptions for logging and debugging
/// ============================================================================

abstract class AdminRoutes {
  // ==================== ROUTE CONSTANTS - ADMIN PANEL ====================

  // Main entry point
  static const String adminDashboard = '/admin/dashboard';

  // Seller Management Routes (3 routes)
  static const String adminProfile = '/admin/profile';
  static const String adminSellers = '/admin/sellers';
  static const String adminSellerDetails = '/admin/sellers/:id';

  // Price Management Routes (3 routes)
  static const String adminPrices = '/admin/prices';
  static const String adminCompliance = '/admin/prices/compliance';
  static const String adminAdvisories = '/admin/prices/advisories';

  // OPAS Purchasing Routes (3 routes)
  static const String adminOPAS = '/admin/opas/submissions';
  static const String adminOPASInventory = '/admin/opas/inventory';
  static const String adminOPASHistory = '/admin/opas/history';

  // Marketplace Oversight Routes (2 routes)
  static const String adminMarketplace = '/admin/marketplace/activity';
  static const String adminAlerts = '/admin/marketplace/alerts';

  // Analytics & Reporting Routes (3 routes)
  static const String adminAnalytics = '/admin/analytics';
  static const String adminPriceTrends = '/admin/analytics/price-trends';
  static const String adminForecasts = '/admin/analytics/forecasts';

  // Reports & Admin Routes (4 routes)
  static const String adminReports = '/admin/reports';
  static const String adminAnnouncements = '/admin/announcements';
  static const String adminAuditLog = '/admin/audit-log';
  static const String adminSettings = '/admin/settings';

  // ==================== PUBLIC ROUTES ====================
  static const String login = '/login';
  static const String home = '/home';

  // ==================== ROUTE FACTORY ====================

  /// Build all admin routes into a map for MaterialApp/CupertinoApp
  /// 
  /// Usage:
  /// ```dart
  /// MaterialApp(
  ///   routes: AdminRoutes.getAllRoutes(),
  ///   home: const LoginScreen(),
  /// )
  /// ```
  static Map<String, WidgetBuilder> getAllRoutes() {
    return {
      // ========== MAIN LAYOUT ==========
      adminDashboard: (context) => const AdminLayout(),

      // ========== SELLER MANAGEMENT ==========
      adminProfile: (context) => const AdminProfileScreen(),
      adminSellers: (context) => const AdminSellersScreen(),
      adminSellerDetails: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map?;
        final seller = args?['seller'] as Map<String, dynamic>? ?? {};
        return SellerDetailsAdminScreen(seller: seller);
      },

      // ========== PRICE MANAGEMENT ==========
      adminPrices: (context) => const PriceCeilingsScreen(),
      adminCompliance: (context) => const PriceComplianceScreen(),
      adminAdvisories: (context) => const PriceAdvisoryScreen(),

      // ========== OPAS PURCHASING ==========
      adminOPAS: (context) => const OPASSubmissionsScreen(),
      adminOPASInventory: (context) => const OPASInventoryScreen(),
      adminOPASHistory: (context) => const OPASPurchaseHistoryScreen(),

      // ========== MARKETPLACE OVERSIGHT ==========
      adminMarketplace: (context) => const MarketplaceActivityScreen(),
      adminAlerts: (context) => const MarketplaceAlertsScreen(),

      // ========== ANALYTICS & REPORTING ==========
      // Note: These screens will be implemented in Phase 3.3
      // For now, using placeholder screens
      adminAnalytics: (context) => const AdminLayout(),
      adminPriceTrends: (context) => const AdminLayout(),
      adminForecasts: (context) => const AdminLayout(),

      // ========== REPORTS & ADMIN ==========
      // Note: These screens will be implemented in Phase 3.3
      // For now, using placeholder screens
      adminReports: (context) => const AdminLayout(),
      adminAnnouncements: (context) => const AdminLayout(),
      adminAuditLog: (context) => const AdminLayout(),
      adminSettings: (context) => const AdminLayout(),
    };
  }

  // ==================== ROUTE UTILITIES ====================

  /// Check if a route is an admin route
  static bool isAdminRoute(String routeName) {
    return routeName.startsWith('/admin');
  }

  /// Extract route path without parameters
  static String getRouteBase(String routeName) {
    return routeName.split(':').first;
  }

  /// Get human-readable description for a route
  /// 
  /// Used for logging, debugging, and UI breadcrumbs
  static String getRouteDescription(String routeName) {
    switch (routeName) {
      // Main
      case adminDashboard:
        return 'Admin Dashboard';

      // Seller Management
      case adminProfile:
        return 'Admin Profile';
      case adminSellers:
        return 'Seller Management';
      case adminSellerDetails:
        return 'Seller Details';

      // Price Management
      case adminPrices:
        return 'Price Ceilings';
      case adminCompliance:
        return 'Price Compliance';
      case adminAdvisories:
        return 'Price Advisories';

      // OPAS
      case adminOPAS:
        return 'OPAS Submissions';
      case adminOPASInventory:
        return 'OPAS Inventory';
      case adminOPASHistory:
        return 'OPAS Purchase History';

      // Marketplace
      case adminMarketplace:
        return 'Marketplace Activity';
      case adminAlerts:
        return 'Marketplace Alerts';

      // Analytics
      case adminAnalytics:
        return 'Sales Analytics';
      case adminPriceTrends:
        return 'Price Trends';
      case adminForecasts:
        return 'Demand Forecasts';

      // Reports & Admin
      case adminReports:
        return 'Reports';
      case adminAnnouncements:
        return 'Announcements';
      case adminAuditLog:
        return 'Audit Log';
      case adminSettings:
        return 'Admin Settings';

      // Public
      case login:
        return 'Login';
      case home:
        return 'Buyer Home';

      default:
        return 'Unknown Route: $routeName';
    }
  }

  /// Get icon for route (useful for navigation drawers/tabs)
  static IconData getRouteIcon(String routeName) {
    switch (routeName) {
      case adminDashboard:
        return Icons.dashboard;
      case adminProfile:
        return Icons.person;
      case adminSellers:
        return Icons.people;
      case adminSellerDetails:
        return Icons.person_outline;
      case adminPrices:
        return Icons.attach_money;
      case adminCompliance:
        return Icons.warning;
      case adminAdvisories:
        return Icons.notifications;
      case adminOPAS:
        return Icons.shopping_cart;
      case adminOPASInventory:
        return Icons.inventory_2;
      case adminOPASHistory:
        return Icons.history;
      case adminMarketplace:
        return Icons.store;
      case adminAlerts:
        return Icons.error_outline;
      case adminAnalytics:
        return Icons.analytics;
      case adminPriceTrends:
        return Icons.trending_up;
      case adminForecasts:
        return Icons.auto_awesome;
      case adminReports:
        return Icons.description;
      case adminAnnouncements:
        return Icons.campaign;
      case adminAuditLog:
        return Icons.receipt_long;
      case adminSettings:
        return Icons.settings;
      default:
        return Icons.help;
    }
  }

  /// Get all admin routes grouped by category
  static Map<String, List<String>> getRoutesByCategory() {
    return {
      'Seller Management': [adminSellers, adminSellerDetails, adminProfile],
      'Price Management': [adminPrices, adminCompliance, adminAdvisories],
      'OPAS Purchasing': [adminOPAS, adminOPASInventory, adminOPASHistory],
      'Marketplace Oversight': [adminMarketplace, adminAlerts],
      'Analytics': [adminAnalytics, adminPriceTrends, adminForecasts],
      'Reports & Admin': [adminReports, adminAnnouncements, adminAuditLog, adminSettings],
    };
  }
}
