import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile_model.dart';
import '../services/notification_history_service.dart';
import 'seller_upgrade_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _userProfile;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userProfile = UserProfile(
        firstName: prefs.getString('first_name') ?? 'N/A',
        lastName: prefs.getString('last_name') ?? 'N/A',
        phoneNumber: prefs.getString('phone_number') ?? 'N/A',
        address: prefs.getString('address') ?? 'N/A',
      );
      _userRole = prefs.getString('role');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00B464).withOpacity(0.2),
              ),
              child: const Icon(
                Icons.person,
                size: 60,
                color: Color(0xFF00B464),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _userProfile != null
                  ? '${_userProfile!.firstName} ${_userProfile!.lastName}'
                  : 'User Profile',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 48),
            if (_userProfile != null) ...[
              _buildProfileField(
                label: 'Phone Number',
                value: _userProfile!.phoneNumber,
                icon: Icons.phone,
              ),
              const SizedBox(height: 16),
              _buildProfileField(
                label: 'Address',
                value: _userProfile!.address,
                icon: Icons.location_on,
              ),
            ] else ...[
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _userRole == 'SELLER' 
                      ? _handleMyMarketplace 
                      : _handleBecomeSeller,
                    icon: Icon(_userRole == 'SELLER' ? Icons.storefront : Icons.store),
                    label: Text(_userRole == 'SELLER' ? 'My Marketplace' : 'Be a Seller'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B464),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00B464)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get the notification key using the same logic as NotificationHistoryService
    final currentUserNotificationKey = await NotificationHistoryService.getStorageKeyForLogout();
    final currentUserNotifications = prefs.getStringList(currentUserNotificationKey);
    
    // Backup cart before clearing
    final userId = prefs.getString('user_id');
    final cartKey = 'cart_items_$userId';
    final cartJson = prefs.getString(cartKey);
    
    debugPrint('🔐 Logout: Backing up notifications from key=$currentUserNotificationKey');
    debugPrint('🛒 Logout: Backing up cart from key=$cartKey');
    
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
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _handleBecomeSeller() async {
    // Navigate to seller registration screen
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const SellerUpgradeScreen(),
      ),
    );

    // If registration was successful, update UI
    if (result == true && mounted) {
      Navigator.pop(context, true); // Return true to indicate registration started
    }
  }

  void _handleMyMarketplace() {
    // Navigate to seller marketplace/home screen
    Navigator.pushNamed(context, '/seller');
  }
}
