import 'package:shared_preferences/shared_preferences.dart';

class AdminRole {
  static const String superAdmin = 'SUPER_ADMIN';
  static const String sellerManager = 'SELLER_MANAGER';
  static const String priceManager = 'PRICE_MANAGER';
  static const String analyticsAdmin = 'ANALYTICS_ADMIN';
}

class AdminPermissions {
  /// Get the current admin's role from SharedPreferences
  static Future<String> getAdminRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('admin_role') ?? AdminRole.superAdmin;
  }

  /// Check if admin can approve/reject sellers
  static Future<bool> canApproveSellers() async {
    final role = await getAdminRole();
    return role == AdminRole.superAdmin || role == AdminRole.sellerManager;
  }

  /// Check if admin can manage prices
  static Future<bool> canManagePrices() async {
    final role = await getAdminRole();
    return role == AdminRole.superAdmin || role == AdminRole.priceManager;
  }

  /// Check if admin can view analytics
  static Future<bool> canViewAnalytics() async {
    final role = await getAdminRole();
    return role == AdminRole.superAdmin || role == AdminRole.analyticsAdmin;
  }

  /// Check if admin can manage suspensions
  static Future<bool> canManageSuspensions() async {
    final role = await getAdminRole();
    return role == AdminRole.superAdmin || role == AdminRole.sellerManager;
  }

  /// Check if admin can view sellers
  static Future<bool> canViewSellers() async {
    final role = await getAdminRole();
    return role != AdminRole.analyticsAdmin; // Everyone except Analytics Admin
  }

  /// Check if admin can manage inventory
  static Future<bool> canManageInventory() async {
    final role = await getAdminRole();
    return role == AdminRole.superAdmin || role == AdminRole.priceManager;
  }

  /// Check if admin has full access
  static Future<bool> isSuperAdmin() async {
    final role = await getAdminRole();
    return role == AdminRole.superAdmin;
  }

  /// Get admin role display name
  static String getRoleDisplayName(String role) {
    switch (role) {
      case AdminRole.superAdmin:
        return 'Super Admin';
      case AdminRole.sellerManager:
        return 'Seller Manager';
      case AdminRole.priceManager:
        return 'Price Manager';
      case AdminRole.analyticsAdmin:
        return 'Analytics Admin';
      default:
        return 'Admin';
    }
  }

  /// Get admin role description
  static String getRoleDescription(String role) {
    switch (role) {
      case AdminRole.superAdmin:
        return 'Full access to all features';
      case AdminRole.sellerManager:
        return 'Approve/reject sellers, manage accounts';
      case AdminRole.priceManager:
        return 'Manage prices, ceilings, compliance';
      case AdminRole.analyticsAdmin:
        return 'View reports and analytics (read-only)';
      default:
        return 'Admin user';
    }
  }
}
