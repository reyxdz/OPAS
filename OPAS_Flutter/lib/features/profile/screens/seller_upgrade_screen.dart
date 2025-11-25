import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';

class SellerUpgradeScreen extends StatefulWidget {
  const SellerUpgradeScreen({super.key});

  @override
  State<SellerUpgradeScreen> createState() => _SellerUpgradeScreenState();
}

class _SellerUpgradeScreenState extends State<SellerUpgradeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _farmNameController = TextEditingController();
  final _farmLocationController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _storeDescriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Become a Seller'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B464).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00B464)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.store, color: Color(0xFF00B464), size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'Start Selling Today',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF00B464),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Fill in your store details to upgrade your account and start selling on OPAS.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Farm Name Field
              Text(
                'Farm Name',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _farmNameController,
                decoration: InputDecoration(
                  hintText: 'Enter your farm name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.landscape),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Farm name is required';
                  }
                  if (value.length < 3) {
                    return 'Farm name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Farm Location Field
              Text(
                'Farm Location',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _farmLocationController,
                decoration: InputDecoration(
                  hintText: 'Enter your farm location (Baranggay/Municipality)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Farm location is required';
                  }
                  if (value.length < 3) {
                    return 'Location must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Store Name Field
              Text(
                'Store Name',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _storeNameController,
                decoration: InputDecoration(
                  hintText: 'Enter your store name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.store),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Store name is required';
                  }
                  if (value.length < 3) {
                    return 'Store name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Store Description Field
              Text(
                'Store Description',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _storeDescriptionController,
                decoration: InputDecoration(
                  hintText: 'Describe your store (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 4,
                maxLength: 500,
              ),
              const SizedBox(height: 32),

              // Terms & Conditions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Before you proceed:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    _buildTermItem('✓ You agree to follow OPAS seller guidelines'),
                    _buildTermItem('✓ Your account will be reviewed by our team'),
                    _buildTermItem('✓ Approval may take 24-48 hours'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Upgrade Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleUpgradeSeller,
                  icon: const Icon(Icons.upgrade),
                  label: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Upgrade to Seller'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B464),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Future<void> _handleUpgradeSeller() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access') ?? '';

      // Call API to submit seller application
      await ApiService.submitSellerApplication(
        accessToken: accessToken,
        farmName: _farmNameController.text,
        farmLocation: _farmLocationController.text,
        storeName: _storeNameController.text,
        storeDescription: _storeDescriptionController.text,
      );

      if (!mounted) return;

      // Store seller application data
      await prefs.setString('farm_name', _farmNameController.text);
      await prefs.setString('farm_location', _farmLocationController.text);
      await prefs.setString('store_name', _storeNameController.text);
      await prefs.setString('seller_status', 'PENDING');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted! Awaiting admin approval.'),
          duration: Duration(seconds: 2),
        ),
      );

      if (!mounted) return;

      // Navigate back
      Navigator.pop(context, true); // Return true to indicate application submitted
    } catch (e) {
      if (!mounted) return;

      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Check for specific error messages from backend
      if (errorMessage.contains('already have a pending application')) {
        errorMessage = 'You already have a pending seller application. Please wait for admin approval.';
      } else if (errorMessage.contains('already been approved')) {
        errorMessage = 'Congratulations! Your seller application has been approved. You are now a seller!';
      } else if (errorMessage.contains('pending application')) {
        errorMessage = 'You already have a pending seller application. Please wait for admin approval.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: errorMessage.contains('approved') ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      
      // If approved, refresh role and go back
      if (errorMessage.contains('approved')) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _farmLocationController.dispose();
    _storeNameController.dispose();
    _storeDescriptionController.dispose();
    super.dispose();
  }
}
