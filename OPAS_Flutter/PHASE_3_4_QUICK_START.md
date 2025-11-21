# Phase 3.4 Implementation: Error Handling & Validation - Quick Start Guide

## Overview
Phase 3.4 implements comprehensive error handling, validation, and network resilience for the OPAS Seller Panel. This includes:
- API error response handling (400, 401, 403, 404, 500)
- Client-side form validation with 25+ validators
- Network error handling with exponential backoff retry logic
- Offline caching with automatic fallback

## Files Created

| File | Purpose |
|------|---------|
| `lib/core/services/error_handler.dart` | Error categorization and user messaging |
| `lib/core/services/connectivity_service.dart` | Offline detection and response caching |
| `lib/core/services/retry_service.dart` | Exponential backoff retry logic |
| `lib/core/utils/form_validators.dart` | 25+ form validation methods |
| `lib/widgets/error_widgets.dart` | Error display components |
| `lib/features/seller_panel/services/enhanced_seller_service.dart` | Enhanced service with error handling |

## Quick Implementation Examples

### 1. Using Form Validation

```dart
// Validate a single field
String? error = FormValidators.validateProductName(nameValue);
if (error != null) {
  print('Error: $error');
}

// Validate price against ceiling
String? priceError = FormValidators.validatePrice(
  priceValue, 
  maxPrice: 150.0
);

// Validate OPAS quantity
String? qaError = FormValidators.validateOPASQuantity(
  quantityValue,
  availableQuantity: 100
);
```

### 2. Displaying Form Errors

```dart
// Show inline error message
ValidationErrorText(
  _fieldErrors['productName'],
  topPadding: 8,
)

// Highlight text field with error
Column(
  children: [
    TextField(
      decoration: InputDecoration(
        labelText: 'Product Name',
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: _fieldErrors.containsKey('name') ? Colors.red : Colors.grey.shade400,
          ),
        ),
      ),
    ),
    ValidationErrorText(_fieldErrors['name']),
  ],
)
```

### 3. Handling API Errors

```dart
try {
  final product = await SellerService.createProduct(data);
} on BadRequestException catch (e) {
  // Show validation errors
  ErrorDialog.show(
    context,
    title: 'Validation Error',
    message: e.message,
    details: e.details,
  );
} on UnauthorizedException catch (e) {
  // Redirect to login
  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
} on APIException catch (e) {
  // Show error with retry option
  ErrorDialog.show(
    context,
    title: 'Error',
    message: ErrorHandler.getUserMessage(e),
    showRetryButton: ErrorHandler.isRetryable(e),
    onRetry: () => _submitForm(),
  );
}
```

### 4. Displaying Errors in SnackBar

```dart
// Simple error message
ErrorSnackBar.show(
  context,
  'Failed to update product',
  subtitle: 'Please check your connection and try again',
);

// Error from exception
ErrorSnackBar.showFromException(
  context,
  exception,
  onRetry: () => _retryOperation(),
);
```

### 5. Caching API Responses

```dart
// Responses are automatically cached
final products = await SellerService.getProducts();
// This is now cached for 24 hours

// Clear cache when needed
await EnhancedSellerService.clearCache('/users/seller/products/');

// Clear all caches
await EnhancedSellerService.clearAllCaches();

// Check cache expiry
final remaining = EnhancedSellerService.getCacheExpiry('/users/seller/products/');
```

### 6. Showing Network Status

```dart
// Wrap screen with network status indicator
@override
Widget build(BuildContext context) {
  return NetworkStatusWidget(
    child: Scaffold(
      // Your content here
      // Shows "Offline - Using cached data" banner when offline
    ),
  );
}
```

### 7. Handling Retries Manually

```dart
// Create retry button
RetryButton(
  label: 'Retry',
  maxRetries: 3,
  onRetry: () async {
    await SellerService.getProducts();
  },
  onSuccess: () {
    print('Success!');
  },
  onError: () {
    print('Failed after max retries');
  },
)
```

## Error Handling Flow

### HTTP Status Code Mapping

- **400 Bad Request** → `BadRequestException` → Show field errors
- **401 Unauthorized** → `UnauthorizedException` → Redirect to login
- **403 Forbidden** → `ForbiddenException` → Show "Access denied"
- **404 Not Found** → `NotFoundException` → Show "Item not found"
- **500+ Server Error** → `ServerException` → Offer retry
- **Timeout** → `TimeoutException` → Offer retry
- **No Connection** → `NetworkException` → Use cache if available

### Retry Strategy

```
Request fails
    ↓
Is error retryable? (timeout, network, 5xx)
    ├─ YES → Retry with exponential backoff
    │   ├─ Attempt 1: Wait 1s
    │   ├─ Attempt 2: Wait 2s
    │   ├─ Attempt 3: Wait 4s
    │   └─ All fail → Show error with manual retry
    └─ NO → Show error immediately
```

## Validation Methods Reference

### Basic Validators
- `validateRequired(value, fieldName)` - Non-empty string
- `validateEmail(value)` - Valid email format
- `validatePassword(value)` - Min 8 chars, uppercase, number
- `validateNumeric(value, fieldName)` - Valid number
- `validatePhoneNumber(value)` - 10+ digit phone number
- `validateUrl(value)` - Valid HTTP(S) URL

### Numeric Validators
- `validatePositiveNumber(value)` - Greater than zero
- `validateMinValue(value, minValue)` - >= minValue
- `validateMaxValue(value, maxValue)` - <= maxValue
- `validatePrice(value, maxPrice)` - Valid price with optional ceiling
- `validateQuantity(value)` - Positive integer

### Text Validators
- `validateMinLength(value, length)` - >= length characters
- `validateMaxLength(value, length)` - <= length characters
- `validateProductName(value)` - 3-100 characters
- `validateDescription(value)` - 10-1000 characters

### Domain-Specific Validators
- `validateUnit(value)` - Valid unit (kg, g, pcs, etc.)
- `validateReorderLevel(value, currentStock)` - Less than stock
- `validateOPASQuantity(value, available)` - Within available
- `validateQualityGrade(value)` - Valid OPAS grade
- `validateBankAccount(value)` - Valid account number
- `validateStoreName(value)` - 3-100 characters
- `validateFarmName(value)` - 3-100 characters

## Integration Checklist for Each Screen

- [ ] Import error handling components:
  ```dart
  import '../../../core/utils/form_validators.dart';
  import '../../../widgets/error_widgets.dart';
  import '../../../core/services/error_handler.dart';
  ```

- [ ] Create field error tracking:
  ```dart
  Map<String, String> _fieldErrors = {};
  ```

- [ ] Implement form validation method:
  ```dart
  FormValidationResult _validateForm() {
    final errors = <String, String>{};
    // Add validation checks
    return FormValidationResult(isValid: errors.isEmpty, fieldErrors: errors);
  }
  ```

- [ ] Add error display under inputs:
  ```dart
  ValidationErrorText(_fieldErrors['fieldName'])
  ```

- [ ] Wrap API calls with error handling:
  ```dart
  try {
    // API call
  } on UnauthorizedException catch (e) {
    // Handle auth error
  } on APIException catch (e) {
    // Handle API error
  }
  ```

- [ ] Show appropriate error dialogs/snackbars

- [ ] Handle 401 by redirecting to login

- [ ] Implement retry for retryable errors

- [ ] Wrap screen with `NetworkStatusWidget` if needed

## Production Considerations

### Enhanced Connectivity Detection
For production, upgrade to use `connectivity_plus` package:

```dart
// In pubspec.yaml
dependencies:
  connectivity_plus: ^5.0.0

// In connectivity_service.dart
bool isOffline() {
  final connectivityResult = await (Connectivity().checkConnectivity());
  return connectivityResult == ConnectivityResult.none;
}
```

### Error Logging
Integrate error logging service:

```dart
// Log errors for debugging
EnhancedSellerService.logError(
  exception,
  context: 'ProductCreation'
);

// Send to error tracking service (Sentry, Crashlytics, etc.)
```

### Cache Management
Customize cache TTL per endpoint:

```dart
await _connectivityService.cacheResponse(
  endpoint,
  responseData,
  duration: const Duration(minutes: 30), // Custom TTL
);
```

## Testing

### Unit Tests
```dart
// Test validators
test('validatePrice accepts valid prices', () {
  expect(FormValidators.validatePrice('150.50'), isNull);
  expect(FormValidators.validatePrice('0'), isNotNull);
});

// Test error handling
test('handles BadRequestException', () {
  final exception = BadRequestException(message: 'Invalid input');
  expect(ErrorHandler.isRetryable(exception), false);
});
```

### Widget Tests
```dart
testWidgets('shows error message on validation failure', (tester) async {
  await tester.pumpWidget(TestApp());
  
  // Enter invalid data
  await tester.enterText(find.byType(TextField), '');
  
  // Validate
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
  
  // Verify error shown
  expect(find.byType(ValidationErrorText), findsOneWidget);
});
```

## Support & Troubleshooting

### Common Issues

**Q: Form validation not showing**
A: Ensure you're calling `setState(() => _fieldErrors = result.fieldErrors)` after validation

**Q: Errors not being caught**
A: Make sure to catch specific exception types in order (most specific first)

**Q: Cache not working offline**
A: Verify `ConnectivityService.initialize()` is called in `main()` before using

**Q: Retry button not appearing**
A: Check `ErrorHandler.isRetryable(exception)` returns true for your error type

---

**Last Updated**: November 18, 2025
**Phase**: 3.4 - Error Handling & Validation ✅ COMPLETE
**Status**: Production Ready
