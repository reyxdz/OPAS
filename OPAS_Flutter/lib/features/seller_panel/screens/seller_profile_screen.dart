import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      setState(() {
        _firstName = prefs.getString('first_name') ?? 'First';
        _lastName = prefs.getString('last_name') ?? 'Name';
        _phoneNumber = prefs.getString('phone_number') ?? 'Not provided';
        _address = prefs.getString('address') ?? 'Not provided';
        _storeName = prefs.getString('store_name') ?? 'My Store';
        _farmName = prefs.getString('farm_name') ?? 'My Farm';
        
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
    await prefs.clear();
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
