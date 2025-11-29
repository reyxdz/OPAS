import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin_profile.dart';

/// Admin Profile Screen
/// Displays admin user information, edit profile functionality, and logout
class AdminProfileScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const AdminProfileScreen({super.key, this.onBackPressed});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  AdminProfile? _adminProfile;
  bool _isLoading = true;
  bool _isEditing = false;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeProfile();
    _loadAdminProfile();
  }

  void _initializeProfile() {
    _adminProfile = AdminProfile(
      id: 0,
      firstName: '',
      lastName: '',
      email: null,
      phoneNumber: '',
      adminRole: 'OPAS_ADMIN',
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstName = prefs.getString('first_name') ?? '';
      final lastName = prefs.getString('last_name') ?? '';
      final phoneNumber = prefs.getString('phone_number') ?? '';
      final email = prefs.getString('email') ?? '';
      final adminRole = prefs.getString('role') ?? 'OPAS_ADMIN';

      setState(() {
        _adminProfile = AdminProfile(
          id: prefs.getInt('user_id') ?? 0,
          firstName: firstName,
          lastName: lastName,
          email: email.isNotEmpty ? email : null,
          phoneNumber: phoneNumber,
          adminRole: adminRole,
          createdAt: DateTime.now(),
          isActive: true,
        );
        
        // Update form controllers
        _firstNameController.text = firstName;
        _lastNameController.text = lastName;
        _phoneNumberController.text = phoneNumber;
        _emailController.text = email;
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading admin profile: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('first_name', _firstNameController.text);
      await prefs.setString('last_name', _lastNameController.text);
      await prefs.setString('phone_number', _phoneNumberController.text);
      await prefs.setString('email', _emailController.text);

      setState(() {
        _adminProfile = AdminProfile(
          id: _adminProfile?.id ?? 0,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text.isNotEmpty ? _emailController.text : null,
          phoneNumber: _phoneNumberController.text,
          adminRole: _adminProfile?.adminRole ?? 'OPAS_ADMIN',
          createdAt: _adminProfile?.createdAt ?? DateTime.now(),
          isActive: _adminProfile?.isActive ?? true,
        );
        _isEditing = false;
      });

      if (mounted) {
        // Show success message at top using overlay
        final overlay = Overlay.of(context);
        final overlayEntry = OverlayEntry(
          builder: (context) => Positioned(
            top: 80,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B464),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Profile updated successfully',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        overlay.insert(overlayEntry);
        Future.delayed(const Duration(seconds: 2), () {
          overlayEntry.remove();
        });
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
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
    } catch (e) {
      debugPrint('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBackPressed,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBackPressed,
        ),
        title: const Text('Admin Profile'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B464).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            size: 40,
                            color: Color(0xFF00B464),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'OPAS Admin',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Display or Edit Mode
                  if (!_isEditing)
                    _buildDisplayMode(context)
                  else
                    _buildEditMode(context),
                ],
              ),
            ),
          ),
          // Action Buttons at Bottom
          Padding(
            padding: const EdgeInsets.all(16),
            child: !_isEditing
                ? Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() => _isEditing = true);
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B464),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text('Logout'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _isEditing = false);
                              _loadAdminProfile();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF00B464),
                              side: const BorderSide(color: Color(0xFF00B464), width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B464),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('Save Changes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayMode(BuildContext context) {
    if (_adminProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        _buildInfoCard(
          context,
          'Phone Number',
          _adminProfile!.phoneNumber,
          Icons.phone,
        ),
        if (_adminProfile!.email != null) ...[
          const SizedBox(height: 24),
          _buildInfoCard(
            context,
            'Email',
            _adminProfile!.email!,
            Icons.email,
          ),
        ],
      ],
    );
  }

  Widget _buildEditMode(BuildContext context) {
    return Column(
      children: [
        _buildTextField(
          'Phone Number',
          _phoneNumberController,
          Icons.phone,
        ),
        const SizedBox(height: 24),
        _buildTextField(
          'Email',
          _emailController,
          Icons.email,
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00B464), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF00B464)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFF00B464),
            width: 2,
          ),
        ),
      ),
    );
  }
}
