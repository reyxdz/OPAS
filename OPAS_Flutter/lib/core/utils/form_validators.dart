/// Form Validation Utilities
/// Client-side validation for seller forms
class FormValidators {
  /// Validate required field (non-empty string)
  static String? validateRequired(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }

  /// Validate numeric field
  static String? validateNumeric(String? value, [String fieldName = 'This field']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (int.tryParse(value) == null && double.tryParse(value) == null) {
      return '$fieldName must be a valid number';
    }
    
    return null;
  }

  /// Validate positive number
  static String? validatePositiveNumber(String? value, [String fieldName = 'This field']) {
    final numError = validateNumeric(value, fieldName);
    if (numError != null) return numError;
    
    final number = double.tryParse(value!);
    if (number != null && number <= 0) {
      return '$fieldName must be greater than zero';
    }
    
    return null;
  }

  /// Validate minimum value
  static String? validateMinValue(String? value, double minValue, [String fieldName = 'This field']) {
    final numError = validateNumeric(value, fieldName);
    if (numError != null) return numError;
    
    final number = double.tryParse(value!);
    if (number != null && number < minValue) {
      return '$fieldName must be at least $minValue';
    }
    
    return null;
  }

  /// Validate maximum value
  static String? validateMaxValue(String? value, double maxValue, [String fieldName = 'This field']) {
    final numError = validateNumeric(value, fieldName);
    if (numError != null) return numError;
    
    final number = double.tryParse(value!);
    if (number != null && number > maxValue) {
      return '$fieldName cannot exceed $maxValue';
    }
    
    return null;
  }

  /// Validate price (must be > 0 and reasonable)
  static String? validatePrice(String? value, [double? maxPrice]) {
    final numError = validatePositiveNumber(value, 'Price');
    if (numError != null) return numError;
    
    if (maxPrice != null) {
      final priceError = validateMaxValue(value, maxPrice, 'Price');
      if (priceError != null) return priceError;
    }
    
    return null;
  }

  /// Validate quantity (must be positive integer)
  static String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }
    
    final quantity = int.tryParse(value);
    if (quantity == null) {
      return 'Quantity must be a whole number';
    }
    
    if (quantity <= 0) {
      return 'Quantity must be greater than zero';
    }
    
    return null;
  }

  /// Validate phone number
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    return null;
  }

  /// Validate URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }
    
    try {
      Uri.parse(value);
      if (!value.startsWith('http://') && !value.startsWith('https://')) {
        return 'URL must start with http:// or https://';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid URL';
    }
  }

  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength, [String fieldName = 'This field']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    
    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(String? value, int maxLength, [String fieldName = 'This field']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    
    return null;
  }

  /// Validate product name
  static String? validateProductName(String? value) {
    final minError = validateMinLength(value, 3, 'Product name');
    if (minError != null) return minError;
    
    final maxError = validateMaxLength(value, 100, 'Product name');
    if (maxError != null) return maxError;
    
    return null;
  }

  /// Validate product description
  static String? validateDescription(String? value, {int minLength = 10, int maxLength = 1000}) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    
    if (value.length < minLength) {
      return 'Description must be at least $minLength characters';
    }
    
    if (value.length > maxLength) {
      return 'Description cannot exceed $maxLength characters';
    }
    
    return null;
  }

  /// Validate unit of measure
  static String? validateUnit(String? value) {
    if (value == null || value.isEmpty) {
      return 'Unit is required';
    }
    
    final validUnits = ['kg', 'g', 'pcs', 'dozen', 'box', 'liter', 'ml', 'bunch'];
    if (!validUnits.contains(value.toLowerCase())) {
      return 'Invalid unit. Valid units: ${validUnits.join(', ')}';
    }
    
    return null;
  }

  /// Validate reorder level (must be less than current stock)
  static String? validateReorderLevel(String? value, int currentStock) {
    final numError = validateNumeric(value, 'Reorder level');
    if (numError != null) return numError;
    
    final level = int.tryParse(value!);
    if (level != null && level >= currentStock) {
      return 'Reorder level must be less than current stock ($currentStock)';
    }
    
    return null;
  }

  /// Validate OPAS offer quantity (must match available quantity)
  static String? validateOPASQuantity(String? value, int availableQuantity) {
    final numError = validateQuantity(value);
    if (numError != null) return numError;
    
    final quantity = int.tryParse(value!);
    if (quantity != null && quantity > availableQuantity) {
      return 'Cannot exceed available quantity ($availableQuantity kg)';
    }
    
    return null;
  }

  /// Validate quality grade for OPAS
  static String? validateQualityGrade(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quality grade is required';
    }
    
    final validGrades = ['standard', 'premium', 'export'];
    if (!validGrades.contains(value.toLowerCase())) {
      return 'Invalid quality grade. Valid options: ${validGrades.join(', ')}';
    }
    
    return null;
  }

  /// Validate bank account number
  static String? validateBankAccount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bank account number is required';
    }
    
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length < 10 || cleaned.length > 20) {
      return 'Bank account number must be between 10 and 20 digits';
    }
    
    return null;
  }

  /// Validate store name
  static String? validateStoreName(String? value) {
    final minError = validateMinLength(value, 3, 'Store name');
    if (minError != null) return minError;
    
    final maxError = validateMaxLength(value, 100, 'Store name');
    if (maxError != null) return maxError;
    
    return null;
  }

  /// Validate farm name
  static String? validateFarmName(String? value) {
    final minError = validateMinLength(value, 3, 'Farm name');
    if (minError != null) return minError;
    
    final maxError = validateMaxLength(value, 100, 'Farm name');
    if (maxError != null) return maxError;
    
    return null;
  }

  /// Validate combination of fields (e.g., password confirmation)
  static String? validateFieldMatch(String? value, String? otherValue, String fieldName) {
    if (value != otherValue) {
      return '$fieldName does not match';
    }
    return null;
  }
}

/// Form field error state
class FormFieldError {
  final String fieldName;
  final String? errorMessage;
  final bool hasError;

  FormFieldError({
    required this.fieldName,
    this.errorMessage,
  }) : hasError = errorMessage != null && errorMessage.isNotEmpty;

  @override
  String toString() => 'FormFieldError($fieldName): $errorMessage';
}

/// Form validation result
class FormValidationResult {
  final bool isValid;
  final Map<String, String> fieldErrors;
  final List<String> generalErrors;

  FormValidationResult({
    required this.isValid,
    this.fieldErrors = const {},
    this.generalErrors = const [],
  });

  bool hasFieldError(String fieldName) => fieldErrors.containsKey(fieldName);
  
  String? getFieldError(String fieldName) => fieldErrors[fieldName];

  factory FormValidationResult.valid() {
    return FormValidationResult(isValid: true);
  }

  factory FormValidationResult.invalid({
    required Map<String, String> fieldErrors,
    List<String> generalErrors = const [],
  }) {
    return FormValidationResult(
      isValid: false,
      fieldErrors: fieldErrors,
      generalErrors: generalErrors,
    );
  }

  @override
  String toString() => 'FormValidationResult(valid: $isValid, errors: ${fieldErrors.length})';
}
