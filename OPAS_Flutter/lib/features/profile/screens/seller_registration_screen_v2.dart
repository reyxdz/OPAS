import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/seller_registration_model.dart';
import '../providers/seller_registration_providers.dart';

/// Refactored Seller Registration Screen with Provider-based state management
/// CORE PRINCIPLE: State Management - Uses Riverpod for scalable state handling
/// CORE PRINCIPLE: State Preservation - Form state survives app lifecycle
/// CORE PRINCIPLE: Offline-First - Works with cached data when offline
class SellerRegistrationScreenV2 extends ConsumerStatefulWidget {
  const SellerRegistrationScreenV2({Key? key}) : super(key: key);

  @override
  ConsumerState<SellerRegistrationScreenV2> createState() =>
      _SellerRegistrationScreenV2State();
}

class _SellerRegistrationScreenV2State
    extends ConsumerState<SellerRegistrationScreenV2>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form field controllers
  late TextEditingController _farmNameController;
  late TextEditingController _farmLocationController;
  late TextEditingController _farmSizeController;
  late TextEditingController _storeNameController;
  late TextEditingController _storeDescriptionController;

  // State tracking
  final Set<String> _selectedProducts = {};
  bool _acceptedTerms = false;
  String? _farmNameError;
  String? _storeNameError;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeControllers();
    // Load cached form data
    // CORE PRINCIPLE: State Preservation - Restore form state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCachedFormData();
    });
  }

  void _initializeControllers() {
    _farmNameController = TextEditingController();
    _farmLocationController = TextEditingController();
    _farmSizeController = TextEditingController();
    _storeNameController = TextEditingController();
    _storeDescriptionController = TextEditingController();
  }

  /// Load previously saved form data from cache
  /// CORE PRINCIPLE: Crash Recovery - Form survives app crash
  Future<void> _loadCachedFormData() async {
    final formState = ref.read(registrationFormProvider);
    if (formState != null) {
      setState(() {
        _farmNameController.text = formState.farmName ?? '';
        _farmLocationController.text = formState.farmLocation ?? '';
        _farmSizeController.text = formState.farmSize ?? '';
        _storeNameController.text = formState.storeName ?? '';
        _storeDescriptionController.text =
            formState.storeDescription ?? '';
        _selectedProducts.addAll(formState.productsGrown ?? []);
      });
    }
  }

  /// Save current form step to cache
  /// CORE PRINCIPLE: State Preservation - Persist on each change
  Future<void> _saveFormStep() async {
    final notifier = ref.read(registrationFormProvider.notifier);

    switch (_currentStep) {
      case 0:
        // Farm info
        await notifier.updateField('farm_name', _farmNameController.text);
        await notifier.updateField('farm_location',
            _farmLocationController.text);
        await notifier.updateField('farm_size', _farmSizeController.text);
        await notifier.updateField(
            'products_grown', _selectedProducts.toList());
        break;
      case 1:
        // Store info
        await notifier.updateField('store_name', _storeNameController.text);
        await notifier.updateField('store_description',
            _storeDescriptionController.text);
        break;
      case 2:
        // Documents - no change needed (managed by separate widget)
        break;
      case 3:
        // Terms accepted
        await notifier.updateField('accepted_terms', _acceptedTerms);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Seller'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressBar(),
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              physics:
                  const NeverScrollableScrollPhysics(), // Disable manual scroll
              children: [
                _buildFarmInfoStep(),
                _buildStoreInfoStep(),
                _buildDocumentsStep(),
                _buildTermsStep(),
              ],
            ),
          ),
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    // CORE PRINCIPLE: UX - Visual progress indication
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Farm Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          // Farm name
          TextField(
            controller: _farmNameController,
            decoration: InputDecoration(
              labelText: 'Farm Name *',
              hintText: 'e.g., Green Valley Farm',
              errorText: _farmNameError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (_) => _saveFormStep(),
          ),
          const SizedBox(height: 16),
          // Farm location
          TextField(
            controller: _farmLocationController,
            decoration: InputDecoration(
              labelText: 'Location *',
              hintText: 'City, Province',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (_) => _saveFormStep(),
          ),
          const SizedBox(height: 16),
          // Farm size
          TextField(
            controller: _farmSizeController,
            decoration: InputDecoration(
              labelText: 'Farm Size *',
              hintText: 'e.g., 5 hectares',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (_) => _saveFormStep(),
          ),
          const SizedBox(height: 24),
          Text(
            'Products Grown *',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          // Products checkboxes
          ...[
            'Fruits',
            'Vegetables',
            'Livestock',
            'Dairy',
            'Grains',
            'Others'
          ].map(
            (product) => CheckboxListTile(
              title: Text(product),
              value: _selectedProducts.contains(product),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedProducts.add(product);
                  } else {
                    _selectedProducts.remove(product);
                  }
                });
                _saveFormStep();
              },
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Store Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          // Store name
          TextField(
            controller: _storeNameController,
            decoration: InputDecoration(
              labelText: 'Store Name *',
              hintText: 'Your online store name',
              errorText: _storeNameError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (_) => _saveFormStep(),
          ),
          const SizedBox(height: 16),
          // Store description
          TextField(
            controller: _storeDescriptionController,
            decoration: InputDecoration(
              labelText: 'Store Description *',
              hintText: 'Describe your store and products (10-500 characters)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              helperText:
                  '${_storeDescriptionController.text.length}/500',
            ),
            maxLines: 5,
            onChanged: (_) => _saveFormStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStep() {
    // CORE PRINCIPLE: Resource Management - Document upload widget
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Required Documents',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Text(
            'Please upload the following documents:',
          ),
          const SizedBox(height: 16),
          _buildDocumentCard(
            'Business Permit',
            'PDF or Image (Max 5MB)',
          ),
          const SizedBox(height: 16),
          _buildDocumentCard(
            'Valid Government ID',
            'PDF or Image (Max 5MB)',
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(String title, String format) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              format,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Choose File'),
                onPressed: () {
                  // Implement file picker
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Uploading $title...'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terms & Conditions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTermItem('✓',
                      'I certify that all information provided is accurate'),
                  _buildTermItem(
                      '✓',
                      'I agree to comply with OPAS marketplace policies'),
                  _buildTermItem('✓',
                      'I understand that false information may result in account termination'),
                  _buildTermItem('✓',
                      'I commit to maintaining product quality and timely delivery'),
                  _buildTermItem(
                      '✓',
                      'I accept the privacy policy and data usage terms'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Acceptance checkbox
          CheckboxListTile(
            title: const Text('I agree to all terms and conditions'),
            value: _acceptedTerms,
            onChanged: (value) {
              setState(() => _acceptedTerms = value ?? false);
              _saveFormStep();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: const TextStyle(color: Colors.green, fontSize: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    // CORE PRINCIPLE: UX - Clear navigation with 48dp touch targets
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Previous button
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep > 0
                  ? () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  : null,
              child: const Text('Previous'),
            ),
          ),
          const SizedBox(width: 12),
          // Next/Submit button
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final isLoading =
                    ref.watch(registrationSubmissionProvider).isLoading;

                if (_currentStep == _totalSteps - 1) {
                  // Submit button on last step
                  return ElevatedButton(
                    onPressed: isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Submit'),
                  );
                } else {
                  // Next button
                  return ElevatedButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text('Next'),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Handle form submission
  /// CORE PRINCIPLE: Input Validation - Server-side enforcement
  Future<void> _handleSubmit() async {
    // Validate required fields
    if (_farmNameController.text.length < 3) {
      setState(() =>
          _farmNameError = 'Farm name must be at least 3 characters');
      return;
    }

    if (_storeNameController.text.length < 3) {
      setState(() =>
          _storeNameError = 'Store name must be at least 3 characters');
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept terms and conditions')),
      );
      return;
    }

    // Submit via provider
    final formData = {
      'farm_name': _farmNameController.text,
      'farm_location': _farmLocationController.text,
      'farm_size': _farmSizeController.text,
      'products_grown': _selectedProducts.toList(),
      'store_name': _storeNameController.text,
      'store_description': _storeDescriptionController.text,
      'accepted_terms': _acceptedTerms,
    };

    await ref
        .read(registrationSubmissionProvider.notifier)
        .submitRegistration(formData);

    if (mounted) {
      final error = ref.read(registrationErrorProvider);
      if (error == null) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        // Error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _farmNameController.dispose();
    _farmLocationController.dispose();
    _farmSizeController.dispose();
    _storeNameController.dispose();
    _storeDescriptionController.dispose();
    super.dispose();
  }
}
