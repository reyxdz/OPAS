import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/seller_registration_model.dart';
import '../services/seller_registration_service.dart';
import '../widgets/farm_info_form_widget.dart';
import '../widgets/store_info_form_widget.dart';
import '../widgets/document_upload_widget.dart';
import '../widgets/registration_status_widget.dart';

/// Seller Registration Screen
/// Main screen for buyer-to-seller registration workflow
/// 
/// Handles:
/// - Farm information collection
/// - Store information collection
/// - Document upload management
/// - Terms & Conditions acceptance
/// - Registration submission
/// 
/// CORE PRINCIPLES APPLIED:
/// - User Experience: Multi-step form, clear progress indication
/// - Input Validation: Server-side validation with field-level feedback
/// - Security: Token-based authentication, secure API calls
/// - Resource Management: Efficient API calls, state preservation
class SellerRegistrationScreen extends StatefulWidget {
  const SellerRegistrationScreen({super.key});

  @override
  State<SellerRegistrationScreen> createState() =>
      _SellerRegistrationScreenState();
}

class _SellerRegistrationScreenState extends State<SellerRegistrationScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _acceptedTerms = false;
  final Map<String, String> _fieldErrors = {};
  SellerRegistration? _currentRegistration;

  // Form Controllers
  final _farmNameController = TextEditingController();
  final _farmLocationController = TextEditingController();
  final _farmSizeController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _storeDescriptionController = TextEditingController();

  List<String> _selectedProducts = [];
  final Map<String, bool> _uploadedDocuments = {
    'BUSINESS_PERMIT': false,
    'VALID_GOVERNMENT_ID': false,
  };

  @override
  void initState() {
    super.initState();
    _loadExistingRegistration();
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _farmLocationController.dispose();
    _farmSizeController.dispose();
    _storeNameController.dispose();
    _storeDescriptionController.dispose();
    super.dispose();
  }

  /// Load existing registration if user already started
  Future<void> _loadExistingRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      if (token.isEmpty) return;

      final registration =
          await SellerRegistrationService.getMyRegistration(token);
      if (registration != null) {
        setState(() {
          _currentRegistration = registration;
          // Pre-fill form with existing data
          _farmNameController.text = registration.farmName;
          _farmLocationController.text = registration.farmLocation;
          _farmSizeController.text = registration.farmSize;
          _storeNameController.text = registration.storeName;
          _storeDescriptionController.text = registration.storeDescription;
          _selectedProducts = registration.productsGrown;
        });
      }
    } catch (e) {
      // User has no existing registration, proceed with new one
    }
  }

  /// Validate current step
  bool _validateStep(int step) {
    _fieldErrors.clear();

    if (step == 0) {
      // Farm Information Validation
      if (_farmNameController.text.trim().length < 3) {
        _fieldErrors['farm_name'] = 'Farm name must be at least 3 characters';
      }
      if (_farmLocationController.text.trim().isEmpty) {
        _fieldErrors['farm_location'] = 'Farm location is required';
      }
      if (_farmSizeController.text.trim().isEmpty) {
        _fieldErrors['farm_size'] = 'Farm size is required';
      }
      if (_selectedProducts.isEmpty) {
        _fieldErrors['products_grown'] = 'Please select at least one product';
      }
    } else if (step == 1) {
      // Store Information Validation
      if (_storeNameController.text.trim().length < 3) {
        _fieldErrors['store_name'] = 'Store name must be at least 3 characters';
      }
      if (_storeDescriptionController.text.trim().length < 10) {
        _fieldErrors['store_description'] =
            'Store description must be at least 10 characters';
      }
    } else if (step == 2) {
      // Documents Validation
      if (!_uploadedDocuments['BUSINESS_PERMIT']! ||
          !_uploadedDocuments['VALID_GOVERNMENT_ID']!) {
        _fieldErrors['documents'] = 'All documents are required';
      }
    } else if (step == 3) {
      // Terms Validation
      if (!_acceptedTerms) {
        _fieldErrors['terms'] = 'You must accept the terms and conditions';
      }
    }

    setState(() {});
    return _fieldErrors.isEmpty;
  }

  /// Submit registration
  Future<void> _submitRegistration() async {
    if (!_validateStep(3)) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access') ?? '';

      if (token.isEmpty) {
        _showErrorSnackBar('Authentication failed. Please log in again.');
        return;
      }

      final registration =
          await SellerRegistrationService.submitRegistration(
        farmName: _farmNameController.text.trim(),
        farmLocation: _farmLocationController.text.trim(),
        farmSize: _farmSizeController.text.trim(),
        productsGrown: _selectedProducts,
        storeName: _storeNameController.text.trim(),
        storeDescription: _storeDescriptionController.text.trim(),
        accessToken: token,
      );

      setState(() {
        _currentRegistration = registration;
      });

      _showSuccessSnackBar('Registration submitted successfully!');

      // Navigate to status view after successful submission
      if (mounted) {
        setState(() => _currentStep = 4);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to submit registration: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Handle document upload
  Future<void> _handleDocumentUpload(String documentType) async {
    // TODO: Integrate with file picker
    // For now, show mock success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$documentType upload functionality coming soon'),
        duration: const Duration(seconds: 2),
      ),
    );

    // Mock upload success for demo
    setState(() {
      _uploadedDocuments[documentType] = true;
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show registration status if already registered
    if (_currentRegistration != null && _currentStep == 4) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Registration Status'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: RegistrationStatusWidget(
            registration: _currentRegistration,
            onReapply: () {
              setState(() {
                _currentStep = 0;
                _acceptedTerms = false;
                _fieldErrors.clear();
              });
            },
          ),
        ),
      );
    }

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator
            _buildProgressIndicator(),
            const SizedBox(height: 32),

            // Step Content
            _buildStepContent(),
            const SizedBox(height: 32),

            // Navigation Buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  /// Build progress indicator
  Widget _buildProgressIndicator() {
    final steps = [
      'Farm',
      'Store',
      'Documents',
      'Terms',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (index) {
            final isActive = _currentStep >= index;
            final isCurrent = _currentStep == index;

            return Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? const Color(0xFF00B464)
                        : Colors.grey[300],
                  ),
                  child: Center(
                    child: isCurrent
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  steps[index],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: isCurrent ? FontWeight.bold : null,
                      ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            minHeight: 4,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFF00B464),
            ),
          ),
        ),
      ],
    );
  }

  /// Build step content based on current step
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return FarmInfoFormWidget(
          farmNameController: _farmNameController,
          farmLocationController: _farmLocationController,
          farmSizeController: _farmSizeController,
          selectedProducts: _selectedProducts,
          onProductsChanged: (products) {
            setState(() => _selectedProducts = products);
          },
          fieldErrors: _fieldErrors,
        );
      case 1:
        return StoreInfoFormWidget(
          storeNameController: _storeNameController,
          storeDescriptionController: _storeDescriptionController,
          fieldErrors: _fieldErrors,
        );
      case 2:
        return DocumentUploadWidget(
          onDocumentUpload: _handleDocumentUpload,
          uploadedDocuments: _uploadedDocuments,
          fieldErrors: _fieldErrors,
        );
      case 3:
        return _buildTermsSection();
      default:
        return const SizedBox.shrink();
    }
  }

  /// Build terms and conditions section
  Widget _buildTermsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terms & Conditions',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTermItem('Accurate Information',
                  'I confirm all provided information is accurate and complete'),
              _buildTermItem('Document Authenticity',
                  'I certify that all submitted documents are original and valid'),
              _buildTermItem('Compliance',
                  'I agree to comply with all OPAS terms of service and policies'),
              _buildTermItem(
                'Right to Verify',
                'I grant OPAS the right to verify my information with government agencies',
              ),
              _buildTermItem(
                'Account Termination',
                'I understand that providing false information may result in account termination',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Checkbox(
              value: _acceptedTerms,
              onChanged: (value) {
                setState(() => _acceptedTerms = value ?? false);
              },
              activeColor: const Color(0xFF00B464),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _acceptedTerms = !_acceptedTerms);
                },
                child: Text(
                  'I accept the Terms & Conditions *',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
        if (_fieldErrors.containsKey('terms'))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _fieldErrors['terms']!,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  /// Build term item
  Widget _buildTermItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check, color: Color(0xFF00B464), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build navigation buttons
  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() => _currentStep--);
              },
              child: const Text('Previous'),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (_currentStep < 3) {
                      if (_validateStep(_currentStep)) {
                        setState(() => _currentStep++);
                      }
                    } else {
                      _submitRegistration();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B464),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _currentStep < 3 ? 'Next' : 'Submit Application',
                  ),
          ),
        ),
      ],
    );
  }
}
