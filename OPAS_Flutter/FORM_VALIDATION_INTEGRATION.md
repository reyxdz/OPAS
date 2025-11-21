// FORM VALIDATION INTEGRATION GUIDE FOR SELLER SCREENS
// Phase 3.4: Client-side Validation & Error Handling

// ============================================================================
// 1. ADD PRODUCT SCREEN VALIDATION ENHANCEMENTS
// ============================================================================

// File: lib/features/seller_panel/screens/add_product_screen.dart
// Add these imports at the top:
import '../../../../../../core/utils/form_validators.dart';
import '../../../../../../widgets/error_widgets.dart';
import '../../../../../../core/services/error_handler.dart';
import '../../../../../../core/services/connectivity_service.dart';

// In _AddProductScreenState class, add:

// Field error tracking
Map<String, String> _fieldErrors = {};

// Form validation method
FormValidationResult _validateForm() {
  final errors = <String, String>{};

  // Validate product name
  final nameError = FormValidators.validateProductName(_nameController.text);
  if (nameError != null) errors['name'] = nameError;

  // Validate description
  final descError = FormValidators.validateDescription(_descriptionController.text);
  if (descError != null) errors['description'] = descError;

  // Validate price
  final priceError = FormValidators.validatePrice(_priceController.text, _ceilingPrice);
  if (priceError != null) errors['price'] = priceError;

  // Check ceiling price exceeded
  if (_priceExceedsCeiling) {
    errors['price'] = 'Price exceeds ceiling price of ₱${_ceilingPrice?.toStringAsFixed(2)}';
  }

  // Validate quantity
  final quantityError = FormValidators.validateQuantity(_quantityController.text);
  if (quantityError != null) errors['quantity'] = quantityError;

  // Validate unit
  final unitError = FormValidators.validateUnit(_unitController.text);
  if (unitError != null) errors['unit'] = unitError;

  return FormValidationResult(
    isValid: errors.isEmpty,
    fieldErrors: errors,
  );
}

// Enhanced submit form with error handling
Future<void> _submitFormEnhanced() async {
  // Clear previous errors
  setState(() => _fieldErrors = {});

  // Validate form
  final validationResult = _validateForm();
  if (!validationResult.isValid) {
    setState(() => _fieldErrors = validationResult.fieldErrors);
    
    // Show first error in snackbar
    if (validationResult.fieldErrors.isNotEmpty) {
      final firstError = validationResult.fieldErrors.values.first;
      ErrorSnackBar.show(context, 'Form has errors', subtitle: firstError);
    }
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Check connectivity
    final connectivity = ConnectivityService();
    if (connectivity.isOffline()) {
      ErrorSnackBar.show(
        context,
        'No internet connection',
        subtitle: 'Product creation requires internet connection',
      );
      return;
    }

    final productData = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'product_type': _selectedProductType,
      'unit': _unitController.text.trim(),
      'price': double.parse(_priceController.text),
      'quantity': int.parse(_quantityController.text),
      'category': _categoryController.text.trim(),
    };

    // Create product (with error handling)
    final product = await _createProductWithErrorHandling(productData);

    // Upload images if selected
    if (_selectedImages.isNotEmpty) {
      await _uploadProductImagesWithErrorHandling(product['id'], _selectedImages);
    }

    if (mounted) {
      ErrorSnackBar.show(
        context,
        'Product created successfully',
        duration: const Duration(seconds: 2),
      );
      Navigator.of(context).pop();
    }
  } on BadRequestException catch (e) {
    _handleValidationError(e);
  } on UnauthorizedException catch (e) {
    _handleAuthError(e);
  } on APIException catch (e) {
    _handleAPIError(e);
  } catch (e) {
    _handleUnknownError(e);
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

// Create product with error handling
Future<dynamic> _createProductWithErrorHandling(Map<String, dynamic> productData) async {
  try {
    // In production, integrate RetryService for automatic retry
    final product = await SellerService.createProduct(productData);
    return product;
  } on BadRequestException catch (e) {
    rethrow;
  } catch (e) {
    rethrow;
  }
}

// Upload product images with error handling
Future<void> _uploadProductImagesWithErrorHandling(int productId, List<File> images) async {
  for (int i = 0; i < images.length; i++) {
    try {
      // Upload each image
      await SellerService.uploadProductImage(productId, images[i], isPrimary: i == 0);
    } catch (e) {
      print('Error uploading image ${i + 1}: $e');
      // Continue with other images even if one fails
    }
  }
}

// Handle validation errors
void _handleValidationError(BadRequestException error) {
  // Extract field-level errors from response
  // This assumes error.details contains field error information
  
  setState(() {
    _fieldErrors = {
      'general': ErrorHandler.getUserMessage(error),
    };
  });

  ErrorDialog.show(
    context,
    title: 'Validation Error',
    message: 'Please check the highlighted fields',
    details: error.details,
  );
}

// Handle authentication errors
void _handleAuthError(UnauthorizedException error) {
  ErrorDialog.show(
    context,
    title: 'Session Expired',
    message: ErrorHandler.getUserMessage(error),
    details: error.details,
    onDismiss: () {
      // Redirect to login
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    },
  );
}

// Handle general API errors with retry option
void _handleAPIError(APIException error) {
  final isRetryable = ErrorHandler.isRetryable(error);
  
  ErrorDialog.show(
    context,
    title: 'Error',
    message: ErrorHandler.getUserMessage(error),
    details: error.details,
    showRetryButton: isRetryable,
    onRetry: isRetryable ? () => _submitFormEnhanced() : null,
  );
}

// Handle unknown errors
void _handleUnknownError(dynamic error) {
  ErrorDialog.show(
    context,
    title: 'Unexpected Error',
    message: 'An unexpected error occurred',
    details: error.toString(),
  );
}

// Build text field with error display
Widget _buildTextField(
  TextEditingController controller,
  String label,
  String fieldKey, {
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
  int? maxLength,
}) {
  final hasError = _fieldErrors.containsKey(fieldKey);
  final error = _fieldErrors[fieldKey];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.grey.shade400,
              width: hasError ? 2 : 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.grey.shade400,
              width: hasError ? 2 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.blue,
              width: 2,
            ),
          ),
          counterText: maxLength != null ? '${controller.text.length}/$maxLength' : null,
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
      ),
      if (error != null) ...[
        const SizedBox(height: 8),
        ValidationErrorText(error),
      ],
    ],
  );
}

// ============================================================================
// 2. SUBMIT OPAS OFFER SCREEN VALIDATION
// ============================================================================

// File: lib/features/seller_panel/screens/submit_opas_offer_screen.dart

// Add validation method:
String? _validateOPASForm() {
  // Validate quantity
  final quantityError = FormValidators.validateOPASQuantity(
    _quantityController.text,
    _availableQuantity,
  );
  if (quantityError != null) return quantityError;

  // Validate quality grade
  final gradeError = FormValidators.validateQualityGrade(_selectedGrade);
  if (gradeError != null) return gradeError;

  return null;
}

// Submit with validation:
Future<void> _submitOPASOfferEnhanced() async {
  final validationError = _validateOPASForm();
  if (validationError != null) {
    ErrorSnackBar.show(context, 'Validation Error', subtitle: validationError);
    return;
  }

  setState(() => _isLoading = true);

  try {
    final quantity = int.parse(_quantityController.text);
    final estimatedPrice = _calculatePrice(quantity, _selectedGrade);

    final offerData = {
      'product_type': _productType,
      'quantity': quantity,
      'quality_grade': _selectedGrade,
      'estimated_price': estimatedPrice,
    };

    // Submit with error handling
    await SellerService.submitOPASoffer(offerData);

    if (mounted) {
      ErrorSnackBar.show(
        context,
        'Offer submitted successfully',
        duration: const Duration(seconds: 2),
      );
      Navigator.of(context).pop();
    }
  } on BadRequestException catch (e) {
    ErrorDialog.show(
      context,
      title: 'Invalid Offer',
      message: ErrorHandler.getUserMessage(e),
      details: e.details,
    );
  } on APIException catch (e) {
    ErrorDialog.show(
      context,
      title: 'Error',
      message: ErrorHandler.getUserMessage(e),
      details: e.details,
      showRetryButton: ErrorHandler.isRetryable(e),
      onRetry: () => _submitOPASOfferEnhanced(),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

// ============================================================================
// 3. UPDATE STOCK SCREEN VALIDATION
// ============================================================================

// File: lib/features/seller_panel/screens/update_stock_screen.dart

// Add validation method:
String? _validateStockForm() {
  // Validate quantity
  final quantityError = FormValidators.validateQuantity(_quantityController.text);
  if (quantityError != null) return quantityError;

  // Validate reorder level if provided
  if (_reorderLevelController.text.isNotEmpty) {
    final level = int.tryParse(_reorderLevelController.text);
    if (level != null && level > int.parse(_quantityController.text)) {
      return 'Reorder level cannot be greater than current stock';
    }
  }

  return null;
}

// Submit with validation:
Future<void> _updateStockEnhanced() async {
  final validationError = _validateStockForm();
  if (validationError != null) {
    ErrorSnackBar.show(context, 'Validation Error', subtitle: validationError);
    return;
  }

  setState(() => _isLoading = true);

  try {
    final updateData = {
      'quantity': int.parse(_quantityController.text),
      'minimum_stock_level': int.tryParse(_reorderLevelController.text) ?? 10,
    };

    await SellerService.updateProductStock(_productId, updateData);

    if (mounted) {
      ErrorSnackBar.show(
        context,
        'Stock updated successfully',
        duration: const Duration(seconds: 2),
      );
      Navigator.of(context).pop();
    }
  } on APIException catch (e) {
    ErrorDialog.showFromException(
      context,
      e,
      onRetry: () => _updateStockEnhanced(),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

// ============================================================================
// 4. GLOBAL ERROR HANDLING IN SELLER HOME SCREEN
// ============================================================================

// File: lib/features/seller_panel/screens/seller_home_screen.dart

// Add network error handling in build:
@override
Widget build(BuildContext context) {
  return NetworkStatusWidget(
    child: Scaffold(
      // ... rest of build
    ),
  );
}

// Handle API errors in data fetching:
Future<void> _loadDashboardData() async {
  try {
    final dashboard = await SellerService.getDashboardAnalytics();
    setState(() {
      _dashboardData = dashboard;
      _isLoading = false;
    });
  } on UnauthorizedException catch (e) {
    _handleAuthError(e);
  } on APIException catch (e) {
    if (mounted) {
      ErrorSnackBar.showFromException(
        context,
        e,
        onRetry: () => _loadDashboardData(),
      );
    }
  }
}

void _handleAuthError(UnauthorizedException error) {
  if (mounted) {
    ErrorDialog.show(
      context,
      title: 'Session Expired',
      message: 'Your session has expired. Please log in again.',
      onDismiss: () {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      },
    );
  }
}

// ============================================================================
// VALIDATION FIELD BUILDERS HELPER CLASS
// ============================================================================

class FormFieldBuilder {
  static Widget emailField(
    TextEditingController controller,
    String? error,
  ) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email),
            errorText: error,
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: error != null ? Colors.red : Colors.grey.shade400,
              ),
            ),
          ),
        ),
        if (error != null) ValidationErrorText(error),
      ],
    );
  }

  static Widget priceField(
    TextEditingController controller,
    String? error,
    double? ceiling,
  ) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Price (₱)',
            prefixIcon: const Icon(Icons.money),
            helperText: ceiling != null ? 'Max: ₱${ceiling.toStringAsFixed(2)}' : null,
            errorText: error,
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: error != null ? Colors.red : Colors.grey.shade400,
              ),
            ),
          ),
          keyboardType: TextInputType.number,
        ),
        if (error != null) ValidationErrorText(error),
      ],
    );
  }

  static Widget quantityField(
    TextEditingController controller,
    String? error,
  ) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Quantity',
            prefixIcon: const Icon(Icons.shopping_bag),
            errorText: error,
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: error != null ? Colors.red : Colors.grey.shade400,
              ),
            ),
          ),
          keyboardType: TextInputType.number,
        ),
        if (error != null) ValidationErrorText(error),
      ],
    );
  }
}
