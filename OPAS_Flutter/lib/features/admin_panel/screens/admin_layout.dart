import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/admin_home_screen.dart';
import '../screens/admin_profile_screen.dart';

/// Admin Layout Widget
/// Main wrapper for admin screens with navigation and state management
/// Provides uniform structure matching buyer side layout
class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> with WidgetsBindingObserver {
  int _currentScreenIndex = 0;
  bool _isInitialized = false;
  String? _adminName;
  String? _adminEmail;

  // Screen options for admin navigation
  static const List<String> _screenNames = [
    'Dashboard',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAdminData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeAdminData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstName = prefs.getString('first_name') ?? 'Admin';
      final lastName = prefs.getString('last_name') ?? 'User';
      final email = prefs.getString('email') ?? 'admin@opas.com';

      setState(() {
        _adminName = '$firstName $lastName';
        _adminEmail = email;
        _isInitialized = true;
      });

      debugPrint('Admin data initialized: $_adminName ($_adminEmail)');
    } catch (e) {
      debugPrint('Error initializing admin data: $e');
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
      await prefs.clear();
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
        if (!didPop && _currentScreenIndex != 0) {
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
            icon: const Icon(Icons.admin_panel_settings),
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
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          iconSize: 32,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No new notifications'),
                duration: Duration(seconds: 1),
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
        AdminHomeScreen(),
        AdminProfileScreen(),
      ],
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header with Admin Info
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
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _adminName ?? 'Admin User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _adminEmail ?? 'admin@opas.com',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
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

          // Settings Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Settings',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help coming soon')),
              );
            },
          ),

          const Divider(),

          // Logout
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
