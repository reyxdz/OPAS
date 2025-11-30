import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../screens/seller_home_screen.dart';
import '../screens/seller_profile_screen.dart';
import '../screens/notifications_screen.dart';
import '../../profile/services/notification_history_service.dart';
import '../../../services/cart_storage_service.dart';

/// Seller Layout Widget
/// Main wrapper for seller screens with navigation and state management
/// Provides uniform structure matching admin and buyer side layout
class SellerLayout extends StatefulWidget {
  const SellerLayout({super.key});

  @override
  State<SellerLayout> createState() => _SellerLayoutState();
}

class _SellerLayoutState extends State<SellerLayout> with WidgetsBindingObserver {
  int _currentScreenIndex = 0;
  bool _isInitialized = false;
  String? _sellerName;
  String? _sellerEmail;
  String? _storeName;

  static const List<String> _screenNames = [
    'Dashboard',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSellerData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeSellerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstName = prefs.getString('first_name') ?? 'Seller';
      final lastName = prefs.getString('last_name') ?? 'User';
      final email = prefs.getString('email') ?? 'seller@opas.com';
      final storeName = prefs.getString('store_name') ?? 'My Store';

      setState(() {
        _sellerName = '$firstName $lastName';
        _sellerEmail = email;
        _storeName = storeName;
        _isInitialized = true;
      });

      debugPrint('Seller data initialized: $_sellerName ($_sellerEmail)');
    } catch (e) {
      debugPrint('Error initializing seller data: $e');
      setState(() => _isInitialized = true);
    }
  }

  void _onScreenChanged(int index) {
    setState(() {
      _currentScreenIndex = index;
    });
    debugPrint('Screen changed to: ${_screenNames[index]}');
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      
      // Get the notification key using the same logic as NotificationHistoryService
      final currentUserNotificationKey = await NotificationHistoryService.getStorageKeyForLogout();
      final currentUserNotifications = prefs.getStringList(currentUserNotificationKey);
      
      // Backup cart before clearing - use CartStorageService to get items from correct storage
      final userId = prefs.getString('user_id');
      final cartKey = 'cart_items_$userId';
      
      debugPrint('🔐 Logout: Backing up notifications from key=$currentUserNotificationKey');
      debugPrint('🛒 Logout: Backing up cart from key=$cartKey');
      
      // Get cart items from CartStorageService (which handles both SQLite and SharedPreferences)
      String? cartJson;
      if (userId != null) {
        final cartService = CartStorageService();
        final cartItems = await cartService.getCartItems(userId);
        if (cartItems.isNotEmpty) {
          cartJson = jsonEncode(cartItems.map((item) => item.toJson()).toList());
          debugPrint('🛒 Logout: Retrieved ${cartItems.length} items from CartStorageService for backup');
        }
      }
      
      // Clear all preferences
      await prefs.clear();
      
      // Restore ONLY the notification history and cart
      // This ensures different users don't access each other's notifications
      if (currentUserNotifications != null) {
        await prefs.setStringList(currentUserNotificationKey, currentUserNotifications);
        debugPrint('✅ Logout: Preserved ${currentUserNotifications.length} notifications under key=$currentUserNotificationKey');
      }
      
      // Restore cart
      if (cartJson != null && userId != null) {
        await prefs.setString(cartKey, cartJson);
        debugPrint('✅ Logout: Preserved cart from key=$cartKey');
      }
      
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: _currentScreenIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_currentScreenIndex != 0) {
          _onScreenChanged(0);
        }
      },
      child: Scaffold(
        appBar: _currentScreenIndex == 0 ? _buildAppBar() : null,
        body: _buildBody(),
        drawer: _buildDrawer(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF00B464).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: IconButton(
            icon: const Icon(Icons.store),
            iconSize: 28,
            color: const Color(0xFF00B464),
            padding: EdgeInsets.zero,
            onPressed: () {
              if (_currentScreenIndex != 1) {
                _onScreenChanged(1);
              }
            },
          ),
        ),
      ),
      title: const Text(' '),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          iconSize: 32,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _currentScreenIndex,
      children: const [
        SellerHomeScreen(),
        SellerProfileScreen(),
      ],
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header with Seller Info
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF00B464),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.store,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _sellerName ?? 'Seller User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _sellerEmail ?? 'seller@opas.com',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _storeName ?? 'My Store',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Navigation Items
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Dashboard'),
            selected: _currentScreenIndex == 0,
            selectedTileColor: const Color(0xFF00B464).withOpacity(0.1),
            onTap: () {
              _onScreenChanged(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            selected: _currentScreenIndex == 1,
            selectedTileColor: const Color(0xFF00B464).withOpacity(0.1),
            onTap: () {
              _onScreenChanged(1);
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
        ],
      ),
    );
  }
}
