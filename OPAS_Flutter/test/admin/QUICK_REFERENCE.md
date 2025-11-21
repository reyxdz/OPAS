# 📚 Frontend Testing Quick Reference Guide

**Phase 5.2 - Quick Start & Cheat Sheet**

---

## ⚡ Quick Commands

### Run Tests

```bash
# All tests
flutter test test/admin/

# Specific test file
flutter test test/admin/test_screen_navigation.dart

# With verbose output
flutter test test/admin/ -v

# With coverage
flutter test test/admin/ --coverage

# Matching test name
flutter test test/admin/ --name "Dark Mode"
```

### Navigation Tests

```bash
flutter test test/admin/test_screen_navigation.dart -v
```

### Form Validation Tests

```bash
flutter test test/admin/test_form_validation.dart -v
```

### Error Handling Tests

```bash
flutter test test/admin/test_error_handling.dart -v
```

### Loading State Tests

```bash
flutter test test/admin/test_loading_states.dart -v
```

### Accessibility Tests

```bash
flutter test test/admin/test_accessibility.dart -v
```

---

## 🎯 Quick Examples

### Create Test Widget

```dart
import 'flutter_test_fixtures.dart';

testWidgets('test name', (tester) async {
  // Create app
  final widget = AdminTestHelper.createTestApp(MyScreen());
  
  // Pump widget
  await tester.pumpWidget(widget);
  
  // Verify
  expect(find.byType(MyScreen), findsOneWidget);
});
```

### Test on Small Phone

```dart
await ResponsiveTestHelper.pumpOnSmallPhone(tester, widget);
expect(find.byType(MyScreen), findsOneWidget);
```

### Test Form Validation

```dart
final formKey = GlobalKey<FormState>();

testWidgets('form validates', (tester) async {
  await tester.pumpWidget(AdminTestHelper.createTestApp(
    Form(
      key: formKey,
      child: TextFormField(
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Required';
          return null;
        },
      ),
    ),
  ));
  
  formKey.currentState!.validate();
  expect(find.text('Required'), findsOneWidget);
});
```

### Test Dark Mode

```dart
final widget = AccessibilityTestHelper.createDarkModeWidget(MyScreen());
await tester.pumpWidget(widget);
expect(find.byType(MyScreen), findsOneWidget);
```

### Test Error Display

```dart
final widget = NetworkErrorTestHelper.createErrorWidget('Failed');
await tester.pumpWidget(AdminTestHelper.createTestApp(widget));
expect(find.text('Failed'), findsOneWidget);
```

### Test Loading State

```dart
var isLoading = true;

testWidgets('loading spinner', (tester) async {
  await tester.pumpWidget(AdminTestHelper.createTestApp(
    isLoading ? CircularProgressIndicator() : Text('Loaded'),
  ));
  
  expect(LoadingStateTestHelper.isLoadingSpinnerVisible(tester), isTrue);
});
```

---

## 🏭 Mock Data Factories

### Create Seller

```dart
final seller = MockSellerFactory.createPendingSeller();
// Returns: {id, name, email, status, farmName, location, products}

final seller = MockSellerFactory.createApprovedSeller();
final seller = MockSellerFactory.createSuspendedSeller();
```

### Create Price Ceiling

```dart
final ceiling = MockPriceCeilingFactory.createPriceCeiling();
// Returns: {id, productName, currentCeiling, previousCeiling, ...}

final noncompliant = MockPriceCeilingFactory.createNonCompliantListing();
// Returns: {id, seller, product, listedPrice, ceiling, overagePercentage, status}
```

### Create OPAS Data

```dart
final submission = MockOPASFactory.createPendingSubmission();
// Returns: {id, seller, product, quantity, unitPrice, status, ...}

final inventory = MockOPASFactory.createInventoryItem();
// Returns: {id, product, quantity, location, expiryDate, status}

final lowStock = MockOPASFactory.createLowStockInventory();
// Returns: low stock inventory item
```

---

## 🛠️ Helper Methods

### Test Operations

```dart
// Type text
await AdminTestHelper.typeText(tester, 'text', find.byType(TextField));

// Tap widget
await AdminTestHelper.tapWidget(tester, find.text('Button'));

// Wait for settling
await AdminTestHelper.pumpAndSettle(tester);

// Find by text
final finder = AdminTestHelper.findByText('Expected');

// Find by type
final finder = AdminTestHelper.findByType(MyWidget);

// Verify exists
AdminTestHelper.expectWidgetExists(find.byType(MyWidget));
AdminTestHelper.expectTextExists('Text');
AdminTestHelper.expectMultipleWidgetsExist(find.byType(ListTile), 5);

// Scroll to widget
await AdminTestHelper.scrollToWidget(tester, find.byType(Button));
```

### Responsive Testing

```dart
// Phone sizes
PhoneScreenSize.small      // 375x667
PhoneScreenSize.medium     // 393x851
PhoneScreenSize.large      // 412x915
PhoneScreenSize.all        // All three

// Test on phone
await ResponsiveTestHelper.pumpOnSmallPhone(tester, widget);
await ResponsiveTestHelper.pumpOnMediumPhone(tester, widget);
await ResponsiveTestHelper.pumpOnLargePhone(tester, widget);
```

### Accessibility

```dart
// Dark mode
AccessibilityTestHelper.createDarkModeWidget(child);
AccessibilityTestHelper.createLightModeWidget(child);

// Contrast validation
AccessibilityTestHelper.isContrastRatioValid(
  Colors.white,
  Colors.grey[900]!,
); // Returns: true/false

// Font size validation
AccessibilityTestHelper.isFontSizeReadable(fontSize);

// Tap target validation
AccessibilityTestHelper.isTapTargetSufficient(Size(48, 48));

// Find by semantic label
AccessibilityTestHelper.findBySemanticLabel('Button label');
```

### Loading States

```dart
// Check visibility
LoadingStateTestHelper.isLoadingSpinnerVisible(tester);
LoadingStateTestHelper.isLoadingSpinnerHidden(tester);

// Create widgets
LoadingStateTestHelper.createLoadingWidget();
LoadingStateTestHelper.createDataLoadedWidget();
LoadingStateTestHelper.createSkeletonLoadingWidget();
```

### Network Errors

```dart
// Error messages
NetworkErrorTestHelper.connectionError
NetworkErrorTestHelper.timeoutError
NetworkErrorTestHelper.serverError
NetworkErrorTestHelper.notFoundError
NetworkErrorTestHelper.unauthorizedError

// Check visibility
NetworkErrorTestHelper.isErrorMessageDisplayed(tester, 'Error');
NetworkErrorTestHelper.isRetryButtonVisible(tester);

// Create error widget
NetworkErrorTestHelper.createErrorWidget('Error message');
```

### Form Validation

```dart
FormValidationTestHelper.validateRequired(value);
FormValidationTestHelper.validateEmail(value);
FormValidationTestHelper.validateNumberRange(
  value,
  min: 0,
  max: 10000,
);
FormValidationTestHelper.validateMinLength(value, 10);
```

---

## 📱 Phone Screen Sizes

| Size | Width | Height | Device |
|------|-------|--------|--------|
| small | 375 | 667 | iPhone SE |
| medium | 393 | 851 | Pixel 6 |
| large | 412 | 915 | Pixel 6 Pro |

---

## 🧪 Test Templates

### Template 1: Screen Rendering Test

```dart
testWidgets('screen renders correctly', (tester) async {
  final widget = AdminTestHelper.createTestApp(MyScreen());
  
  await ResponsiveTestHelper.pumpOnSmallPhone(tester, widget);
  await AdminTestHelper.pumpAndSettle(tester);
  
  expect(find.byType(MyScreen), findsOneWidget);
  expect(find.text('Expected Text'), findsOneWidget);
});
```

### Template 2: Form Validation Test

```dart
testWidgets('form validates input', (tester) async {
  final formKey = GlobalKey<FormState>();
  
  final widget = AdminTestHelper.createTestApp(
    Form(
      key: formKey,
      child: MyFormWidget(),
    ),
  );
  
  await tester.pumpWidget(widget);
  
  // Test validation
  formKey.currentState!.validate();
  expect(find.text('Error Message'), findsOneWidget);
});
```

### Template 3: Error Handling Test

```dart
testWidgets('handles errors gracefully', (tester) async {
  final widget = AdminTestHelper.createTestApp(
    NetworkErrorTestHelper.createErrorWidget('Connection failed'),
  );
  
  await tester.pumpWidget(widget);
  
  expect(find.text('Connection failed'), findsOneWidget);
  expect(NetworkErrorTestHelper.isRetryButtonVisible(tester), isTrue);
});
```

### Template 4: Loading State Test

```dart
testWidgets('loading state transitions', (tester) async {
  var isLoading = true;
  
  final widget = AdminTestHelper.createTestApp(
    StatefulBuilder(
      builder: (context, setState) => 
        isLoading ? 
          LoadingStateTestHelper.createLoadingWidget() :
          LoadingStateTestHelper.createDataLoadedWidget(),
    ),
  );
  
  await tester.pumpWidget(widget);
  expect(LoadingStateTestHelper.isLoadingSpinnerVisible(tester), isTrue);
});
```

### Template 5: Accessibility Test

```dart
testWidgets('accessibility features work', (tester) async {
  final widget = AccessibilityTestHelper.createDarkModeWidget(MyScreen());
  
  await tester.pumpWidget(widget);
  
  expect(find.byType(MyScreen), findsOneWidget);
  
  // Verify contrast
  expect(AccessibilityTestHelper.isContrastRatioValid(
    Colors.white,
    Colors.grey[900]!,
  ), isTrue);
});
```

---

## 🐛 Debugging Tips

### No MaterialApp Found

**Error**: "No MaterialApp found"  
**Fix**: Wrap widget with `AdminTestHelper.createTestApp()`

```dart
final widget = AdminTestHelper.createTestApp(MyWidget());
```

### Text Not Found

**Error**: Text not found  
**Fix**: Use `pumpAndSettle()` to wait for animations

```dart
await AdminTestHelper.pumpAndSettle(tester);
expect(find.text('Text'), findsOneWidget);
```

### Form Validation Not Working

**Error**: Validation not triggering  
**Fix**: Call `validate()` and pump

```dart
formKey.currentState!.validate();
await tester.pumpAndSettle();
```

### Wrong Phone Size

**Error**: Layout wrong for device  
**Fix**: Use `ResponsiveTestHelper` to set size

```dart
await ResponsiveTestHelper.pumpOnSmallPhone(tester, widget);
```

### Test Times Out

**Error**: Test takes too long  
**Fix**: Increase timeout or use `pumpAndSettle()`

```dart
await tester.pumpAndSettle(const Duration(seconds: 5));
```

### Dark Mode Not Applied

**Error**: Dark mode not showing  
**Fix**: Use `AccessibilityTestHelper`

```dart
final widget = AccessibilityTestHelper.createDarkModeWidget(MyScreen());
```

---

## 📊 Test Organization

```
test/admin/
├── flutter_test_fixtures.dart        (Helpers & mock data)
├── test_screen_navigation.dart       (26 tests)
├── test_form_validation.dart         (22 tests)
├── test_error_handling.dart          (13 tests)
├── test_loading_states.dart          (10 tests)
├── test_accessibility.dart           (18 tests)
├── README_FRONTEND_TESTS.md          (Full guide)
├── PHASE_5_2_SUMMARY.md              (Summary)
├── QUICK_REFERENCE.md                (This file)
└── __init__.dart                     (Package init)
```

---

## ✅ Test Checklist

When writing a new test:

- [ ] Use `AdminTestHelper.createTestApp()`
- [ ] Test on at least 2 phone sizes
- [ ] Test both light and dark modes
- [ ] Include error scenario
- [ ] Verify loading state
- [ ] Check accessibility (semantic labels)
- [ ] Use `pumpAndSettle()` for async operations
- [ ] Use factories for mock data
- [ ] Include clear test name
- [ ] Add comments for complex logic

---

## 🚀 CI/CD Integration

### Run tests in CI pipeline

```bash
#!/bin/bash
cd OPAS_Flutter
flutter test test/admin/ --coverage

# Optional: Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

### GitHub Actions example

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v1
      - run: flutter test test/admin/
```

---

## 📚 Additional Resources

- Full guide: `README_FRONTEND_TESTS.md`
- Summary: `PHASE_5_2_SUMMARY.md`
- Test examples: All test files
- Flutter docs: https://flutter.dev/docs/testing
- Dart docs: https://dart.dev/guides/testing

---

## 💡 Key Takeaways

1. **Use helpers**: Don't repeat code, use `AdminTestHelper` methods
2. **Use factories**: Create mock data with `MockSellerFactory`, etc.
3. **Test multiple sizes**: Run on all 3 phone sizes
4. **Test accessibility**: Always include dark mode tests
5. **Settle animations**: Use `pumpAndSettle()` for async operations
6. **Clear names**: Use descriptive test names
7. **Organize tests**: Group related tests together
8. **Document patterns**: Add comments to complex tests

---

## ⚡ One-Liners

```bash
# Run all tests with coverage
flutter test test/admin/ --coverage && genhtml coverage/lcov.info -o coverage/html

# Run specific test
flutter test test/admin/ --name "Dark Mode"

# Run tests matching pattern
flutter test test/admin/ --name "screen"

# Watch tests (requires external tool)
flutter test test/admin/ --watch

# Run tests on device
flutter test test/admin/ -d <device_id>
```

---

## 🎓 Learning Path

1. **Start**: Read `README_FRONTEND_TESTS.md`
2. **Review**: Look at example tests in test files
3. **Copy**: Use test templates above
4. **Modify**: Adapt templates for your tests
5. **Run**: Execute and debug
6. **Reference**: Use quick reference as you code

---

## 📞 Quick Help

| Problem | Solution | Example |
|---------|----------|---------|
| Widget not found | Add `createTestApp()` | `AdminTestHelper.createTestApp()` |
| Text not visible | Use `pumpAndSettle()` | `await AdminTestHelper.pumpAndSettle(tester)` |
| Form not validating | Call `validate()` | `formKey.currentState!.validate()` |
| Wrong phone size | Use helper | `ResponsiveTestHelper.pumpOnSmallPhone()` |
| Dark mode not working | Use helper | `AccessibilityTestHelper.createDarkModeWidget()` |

---

**Last Updated**: November 21, 2025  
**Test Suite**: 89 tests, ~2,767 lines  
**Status**: ✅ Complete and production-ready
