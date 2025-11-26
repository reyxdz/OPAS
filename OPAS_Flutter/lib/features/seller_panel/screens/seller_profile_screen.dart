import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/services/api_service.dart';
import '../../profile/services/notification_history_service.dart';
import 'edit_seller_profile_screen.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  late String _firstName;
  late String _lastName;
  late String _phoneNumber;
  late String _address;
  late String _storeName;
  late String _farmName;
  bool _isLoading = true;

  // Edit controllers
  TextEditingController? _farmNameController;
  TextEditingController? _storeNameController;
  TextEditingController? _phoneNumberController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers first
    _farmNameController = TextEditingController();
    _storeNameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _farmNameController?.dispose();
    _storeNameController?.dispose();
    _phoneNumberController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access') ?? '';
      
      // Try to fetch user profile from API
      if (accessToken.isNotEmpty) {
        try {
          final response = await http.get(
            Uri.parse('${ApiService.baseUrl}/users/seller/profile/'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final userData = jsonDecode(response.body) as Map<String, dynamic>;
            
            debugPrint('✓ API Profile Response: $userData');
            
            setState(() {
              _firstName = userData['first_name'] ?? prefs.getString('first_name') ?? 'First';
              _lastName = userData['last_name'] ?? prefs.getString('last_name') ?? 'Name';
              _phoneNumber = userData['phone_number'] ?? prefs.getString('phone_number') ?? 'Not provided';
              _address = userData['address'] ?? prefs.getString('address') ?? 'Not provided';
              
              // Store name from API (or use cached value if empty)
              final apiStoreName = userData['store_name'];
              _storeName = (apiStoreName != null && apiStoreName.toString().isNotEmpty) 
                  ? apiStoreName.toString() 
                  : (prefs.getString('store_name')?.isNotEmpty == true ? prefs.getString('store_name')! : 'Not set');
              
              // Farm name - construct from municipality and barangay
              final farmMunicipality = userData['farm_municipality'];
              final farmBarangay = userData['farm_barangay'];
              if (farmMunicipality != null && farmMunicipality.toString().isNotEmpty &&
                  farmBarangay != null && farmBarangay.toString().isNotEmpty) {
                _farmName = '$farmBarangay, $farmMunicipality';
              } else {
                _farmName = (prefs.getString('farm_name')?.isNotEmpty == true ? prefs.getString('farm_name')! : 'Not set');
              }
              
              debugPrint('✓ Store Name: $_storeName');
              debugPrint('✓ Farm Name: $_farmName');
              
              // Initialize controllers with current values
              _farmNameController?.text = _farmName;
              _storeNameController?.text = _storeName;
              _phoneNumberController?.text = _phoneNumber;
              
              _isLoading = false;
            });
            return;
          } else {
            debugPrint('✗ API returned ${response.statusCode}: ${response.body}');
          }
        } catch (e) {
          // If API fails, continue with SharedPreferences
          debugPrint('✗ API fetch failed: $e, using SharedPreferences');
        }
      }
      
      // Fallback to SharedPreferences if API not available
      setState(() {
        _firstName = prefs.getString('first_name') ?? 'First';
        _lastName = prefs.getString('last_name') ?? 'Name';
        _phoneNumber = prefs.getString('phone_number') ?? 'Not provided';
        _address = prefs.getString('address') ?? 'Not provided';
        _storeName = (prefs.getString('store_name')?.isNotEmpty ?? false) ? prefs.getString('store_name')! : 'Not set';
        _farmName = (prefs.getString('farm_name')?.isNotEmpty ?? false) ? prefs.getString('farm_name')! : 'Not set';
        
        debugPrint('✓ Using SharedPreferences - Store: $_storeName, Farm: $_farmName');
        
        // Initialize controllers with current values
        _farmNameController?.text = _farmName;
        _storeNameController?.text = _storeName;
        _phoneNumberController?.text = _phoneNumber;
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }


  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get the notification key using the same logic as NotificationHistoryService
    final currentUserNotificationKey = await NotificationHistoryService.getStorageKeyForLogout();
    final currentUserNotifications = prefs.getStringList(currentUserNotificationKey);
    
    debugPrint('🔐 Logout: Backing up notifications from key=$currentUserNotificationKey');
    
    // Clear all preferences
    await prefs.clear();
    
    // Restore ONLY the notification history
    // This ensures different users don't access each other's notifications
    if (currentUserNotifications != null) {
      await prefs.setStringList(currentUserNotificationKey, currentUserNotifications);
      debugPrint('✅ Logout: Preserved ${currentUserNotifications.length} notifications under key=$currentUserNotificationKey');
    }
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00B464).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00B464).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00B464),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.store,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_firstName $_lastName',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _storeName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Active Seller',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile Information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditSellerProfileScreen(
                          farmName: _farmName,
                          storeName: _storeName,
                          phoneNumber: _phoneNumber,
                          onSave: (farmName, storeName, phoneNumber) async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('farm_name', farmName);
                            await prefs.setString('store_name', storeName);
                            await prefs.setString('phone_number', phoneNumber);
                            
                            setState(() {
                              _farmName = farmName;
                              _storeName = storeName;
                              _phoneNumber = phoneNumber;
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF00B464),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.edit,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildProfileField(
              label: 'Full Name',
              value: '$_firstName $_lastName',
              icon: Icons.person,
            ),
            const SizedBox(height: 12),
            _buildProfileField(
              label: 'Phone Number',
              value: _phoneNumber,
              icon: Icons.phone,
            ),
            const SizedBox(height: 12),
            _buildProfileField(
              label: 'Address',
              value: _address,
              icon: Icons.location_on,
            ),
            const SizedBox(height: 24),

            // Farm/Store Information
            Text(
              'Farm & Store Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildProfileField(
              label: 'Farm Name',
              value: _farmName,
              icon: Icons.agriculture,
            ),
            const SizedBox(height: 12),
            _buildProfileField(
              label: 'Store Name',
              value: _storeName,
              icon: Icons.storefront,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      icon: const Icon(Icons.shopping_cart, size: 18),
                      label: const Text('Buyer Mode', style: TextStyle(fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B464),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Logout', style: TextStyle(fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
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
}
